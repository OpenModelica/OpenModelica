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

encapsulated package InstSection
" file:        InstSection.mo
  package:     InstSection
  description: Model instantiation

  RCS: $Id$

  This module is responsible for instantiation of Modelica equation
  and algorithm sections (including connect equations)."

public import Absyn;
public import ClassInf;
public import Connect;
public import ConnectionGraph;
public import DAE;
public import Env;
public import InnerOuter;
public import Prefix;
public import SCode;

protected import Algorithm;
protected import Ceval;
protected import ComponentReference;
protected import Config;
protected import ConnectUtil;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSimplifyTypes;
protected import Flags;
protected import Inst;
protected import InstDAE;
protected import InstFunction;
protected import InstTypes;
protected import NFInstUtil;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import Patternm;
protected import PrefixUtil;
protected import Static;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import System;
protected import ErrorExt;
protected import SCodeDump;
//protected import DAEDump;

protected type Ident = DAE.Ident "an identifier";
protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";
protected constant Boolean alwaysUnroll = true;

public function instEquation
"author: LS, ELN

  Instantiates an equation by calling
  instEquationCommon with Inital set
  to NON_INITIAL."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,unrollForLoops,inGraph)
    local
      Env.Env env;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq,eqn;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String str;

    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq),impl,_,graph) /* impl */
      equation
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl,graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    case (_,_,_,_,_,_,_,SCode.EQUATION(eEquation = eqn),_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str= SCodeDump.equationStr(eqn,SCodeDump.defaultOptions);
        Debug.fprint(Flags.FAILTRACE, "- instEquation failed eqn:");
        Debug.fprint(Flags.FAILTRACE, str);
        Debug.fprint(Flags.FAILTRACE, "\n");
      then
        fail();
  end matchcontinue;
end instEquation;

protected function instEEquation
"Instantiation of EEquation, used in for loops and if-equations."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache cache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (cache,outEnv,outIH,outDae,outSets,outState,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,unrollForLoops,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      Env.Env env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,_,graph)
      equation
        (cache,env,ih,dae,csets_1,ci_state_1,graph) =
        instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    // failure
    case(cache,_,_,_,_,_,_,eq,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Inst.instEEquation failed for " +& SCodeDump.equationStr(eq,SCodeDump.defaultOptions));
    then fail();

  end matchcontinue;
end instEEquation;

public function instInitialEquation
"author: LS, ELN
  Instantiates initial equation by calling inst_equation_common with Inital
  set to INITIAL."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,unrollForLoops,inGraph)
    local
      Env.Env env;
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq),impl,_,graph)
      equation
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache, env, ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- instInitialEquation failed\n");
      then
        fail();

  end matchcontinue;
end instInitialEquation;

protected function instEInitialEquation
"Instantiates initial EEquation used in for loops and if equations "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  match (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,unrollForLoops,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      Env.Env env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,_,graph) /* impl */
      equation
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

  end match;
end instEInitialEquation;

protected function instEquationCommon
"The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.

  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  instEquationCommon2(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,Error.getNumErrorMessages());
end instEquationCommon;

protected function instEquationCommon2
"The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.

  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Integer errorCount;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,errorCount)
    local
      String s;
      ClassInf.State state;

    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        state = ClassInf.trans(inState,ClassInf.FOUND_EQUATION());
        (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) = instEquationCommonWork(inCache,inEnv,inIH,inMod,inPrefix,inSets,state,inEEquation,inInitial,inBoolean,inGraph,DAE.FLATTEN(inEEquation,NONE()));
        (outDae,_,_) = DAEUtil.traverseDAE(outDae,DAE.emptyFuncTree,Expression.traverseSubexpressionsHelper,(ExpressionSimplify.simplifyWork,(ExpressionSimplifyTypes.optionSimplifyOnly)));
      then (outCache,outEnv,outIH,outDae,outSets,outState,outGraph);

    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        failure(_ = ClassInf.trans(inState,ClassInf.FOUND_EQUATION()));
        s = ClassInf.printStateStr(inState);
        Error.addSourceMessage(Error.EQUATION_TRANSITION_FAILURE, {s}, SCode.equationFileInfo(inEEquation));
      then fail();

    // We only want to print a generic error message if no other error message was printed
    // Providing two error messages for the same error is confusing (but better than none)
    else
      equation
        true = errorCount == Error.getNumErrorMessages();
        s = "\n" +& SCodeDump.equationStr(inEEquation,SCodeDump.defaultOptions);
        Error.addSourceMessage(Error.EQUATION_GENERIC_FAILURE, {s}, SCode.equationFileInfo(inEEquation));
      then
        fail();

  end matchcontinue;
end instEquationCommon2;

protected function instEquationCommonWork
"The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.

  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input DAE.SymbolicOperation flattenOp;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,flattenOp)
    local
      list<DAE.Properties> props;
      Connect.Sets csets_1,csets;
      DAE.DAElist dae;
      ClassInf.State ci_state_1,ci_state,ci_state_2;
      Env.Env env,env_1,env_2;
      DAE.Mod mods,mod;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,cr,cr1,cr2;
      SCode.Initial initial_;
      Boolean impl;
      String i,s;
      Absyn.Exp e2,e1,e,ee,e3;
      list<Absyn.Exp> conditions;
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e_1,e_2,e3_1,e3_2;
      DAE.Properties prop1,prop2,prop3;
      list<SCode.EEquation> b,fb,el,eel;
      list<list<SCode.EEquation>> tb;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> eex;
      DAE.Type id_t;
      Values.Value v;
      DAE.ComponentRef cr_1;
      SCode.EEquation eqn,eq;
      Env.Cache cache;
      list<Values.Value> valList;
      list<DAE.Exp> expl1;
      list<Boolean> blist;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<tuple<Absyn.ComponentRef, Integer>> lst;
      tuple<Absyn.ComponentRef, Integer> tpl;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts1,daeElts2;
      list<list<DAE.Element>> daeLLst;
      DAE.Const cnst;
      Absyn.Info info;
      DAE.Element daeElt2;
      list<DAE.ComponentRef> lhsCrefs,lhsCrefsRec;
      Integer i1,ipriority;
      list<DAE.Element> daeElts,daeElts3;
      DAE.ComponentRef cr_,cr1_,cr2_;
      DAE.Type t;
      DAE.Properties tprop1,tprop2;
      Real priority;
      DAE.Exp exp;
      Option<Values.Value> containsEmpty;
      SCode.Comment comment;

    // connect statements
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_CONNECT(crefLeft = c1,crefRight = c2,info = info),initial_,impl,graph,_)
      equation
        (cache,env,ih,csets_1,dae,graph) = instConnect(cache,env,ih, csets,  pre, c1, c2, impl, graph, info);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    // equality equations e1 = e2
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_EQUALS(expLeft = e1,expRight = e2,info = info,comment=comment),initial_,impl,graph,_)
      equation
         // Do static analysis and constant evaluation of expressions.
        // Gives expression and properties
        // (Type  bool | (Type  Const as (bool | Const list))).
        // For a function, it checks the funtion name.
        // Also the function call\'s in parameters are type checked with
        // the functions definition\'s inparameters. This is done with
        // regard to the position of the input arguments.

        // equality equation (cr1,...,crn) = fn(...)?
        checkTupleCallEquationMessage(e1,e2,info);

        //  Returns the output parameters from the function.
        (cache,e1_1,prop1,_) = Static.elabExp(cache, env, e1, impl, NONE(), true /*do vectorization*/, pre, info);
        (cache,e2_1,prop2,_) = Static.elabExp(cache, env, e2, impl, NONE(), true /*do vectorization*/, pre, info);
        (cache, e1_1, prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl, info);
        (cache, e2_1, prop2) = Ceval.cevalIfConstant(cache, env, e2_1, prop2, impl, info);
        (cache,e1_1,e2_1,prop1) = condenseArrayEquation(cache,env,e1,e2,e1_1,e2_1,prop1,prop2,impl,pre,info);

        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, ih, e1_1, pre);
        (cache,e2_2) = PrefixUtil.prefixExp(cache,env, ih, e2_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        source = DAEUtil.addCommentToSource(source,SOME(comment));
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);
        //Check that the lefthandside and the righthandside get along.
        dae = instEqEquation(e1_2, prop1, e2_2, prop2, source, initial_, impl);

        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets,ci_state_1,graph);



    /*
    case (cache,env,ih,mods,pre,csets,ci_state,eqn as SCode.EQ_EQUALS(expLeft = e1,expRight = e2,info = info),initial_,impl,graph)
      equation
        failure(checkTupleCallEquation(e1,e2));
        s = SCodeDump.equationStr(eqn);
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY,{s},info);
      then fail();*/

    // if-equation
    // if the condition is constant this case will select the correct branch and remove the if-equation
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.NON_INITIAL(),impl,graph,_)
      equation
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        DAE.PROP(DAE.T_BOOL(varLst = _),cnst) = Types.propsAnd(props);
        true = Types.isParameterOrConstant(cnst);
        (cache,valList,_) = Ceval.cevalList(cache, env, expl1, impl, NONE(), Absyn.NO_MSG(),0);
        // check if valList contains Values.EMPTY()
        containsEmpty = ValuesUtil.containsEmpty(valList);
        generateNoConstantBindingError(containsEmpty, info);
        blist = List.map(valList,ValuesUtil.valueBool);
        b = Util.selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEEquation, b, impl, alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

    // if-equation
    // If we are doing checkModel we might get an if-equation whose condition is
    // a parameter without a binding, and which DAEUtil.ifEqToExpr can't handle.
    // If the model would have been instantiated one of the branches would have
    // been chosen, so this case therefore chooses one of the branches.
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.NON_INITIAL(),impl,graph,_)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (cache, _,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        DAE.PROP(DAE.T_BOOL(varLst = _),DAE.C_PARAM()) = Types.propsAnd(props);
        b = Util.selectList({true}, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEEquation, b, impl, alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

    // initial if-equation
    // if the condition is constant this case will select the correct branch and remove the initial if-equation
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.INITIAL(),impl,graph,_)
      equation
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        DAE.PROP(DAE.T_BOOL(varLst = _),cnst) = Types.propsAnd(props);
        true = Types.isParameterOrConstant(cnst);
        (cache,valList,_) = Ceval.cevalList(cache, env, expl1, impl, NONE(), Absyn.NO_MSG(),0);
        blist = List.map(valList,ValuesUtil.valueBool);
        b = Util.selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEInitialEquation, b, impl, alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

    // if equation when condition is not constant
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info = info),SCode.NON_INITIAL(),impl,graph,_)
      equation
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        DAE.PROP(DAE.T_BOOL(varLst = _),_) = Types.propsAnd(props);
        (cache,expl1) = PrefixUtil.prefixExpList(cache, env, ih, expl1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache, env,ih, mod, pre, csets, ci_state, tb, false, impl, graph);
        (cache,_,ih,DAE.DAE(daeElts2),_,_,graph) = Inst.instList(cache,env_1,ih, mod, pre, csets, ci_state, instEEquation, fb, impl, alwaysUnroll, graph) "There are no connections inside if-clauses." ;
        dae = DAE.DAE({DAE.IF_EQUATION(expl1,daeLLst,daeElts2,source)});
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

    // initial if equation  when condition is not constant
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb, info = info),SCode.INITIAL(),impl,graph,_)
      equation
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        DAE.PROP(DAE.T_BOOL(varLst = _),_) = Types.propsAnd(props);
        (cache,expl1) = PrefixUtil.prefixExpList(cache, env, ih, expl1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache,env,ih, mod, pre, csets, ci_state, tb, true, impl, graph);
        (cache,_,ih,DAE.DAE(daeElts2),_,_,graph) = Inst.instList(cache,env_1,ih, mod, pre, csets, ci_state, instEInitialEquation, fb, impl, alwaysUnroll, graph) "There are no connections inside if-clauses." ;
        dae = DAE.DAE({DAE.INITIAL_IF_EQUATION(expl1,daeLLst,daeElts2,source)});
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

    // when equation statement
    // When statements are instantiated by evaluating the conditional expression.
    case (cache,env,ih,mod,pre,csets,ci_state, eq as SCode.EQ_WHEN(condition = e,eEquationLst = el,elseBranches = ((ee,eel) :: eex),info=info),(initial_ as SCode.NON_INITIAL()),impl,graph,_)
      equation
        checkWhenEquation(eq);
        (cache,e_1,prop1,_) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        (cache, e_1, prop1) = Ceval.cevalIfConstant(cache, env, e_1, prop1, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        (cache,env_1,ih,DAE.DAE(daeElts1),_,_,graph) = Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEEquation, el, impl, alwaysUnroll, graph);
        lhsCrefs = DAEUtil.verifyWhenEquation(daeElts1);
        (cache,env_2,ih,DAE.DAE(daeElts3 as (daeElt2 :: _)),_,ci_state_1,graph) = instEquationCommon(cache,env_1,ih, mod, pre, csets, ci_state,
          SCode.EQ_WHEN(ee,eel,eex,SCode.noComment,info), initial_, impl, graph);
        lhsCrefsRec = DAEUtil.verifyWhenEquation(daeElts3);
        i1 = listLength(lhsCrefs);
        lhsCrefs = List.unionOnTrue(lhsCrefs,lhsCrefsRec,ComponentReference.crefEqual);
        //TODO: fix error reporting print(" listLength pre:" +& intString(i1) +& " post: " +& intString(listLength(lhsCrefs)) +& "\n");
        true = intEq(listLength(lhsCrefs),i1);
        ci_state_2 = instEquationCommonCiTrans(ci_state_1, initial_);
        dae = DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,SOME(daeElt2),source)});
      then
        (cache,env_2,ih,dae,csets,ci_state_2,graph);

    case (cache,env,ih,mod,pre,csets,ci_state, eq as SCode.EQ_WHEN(condition = e,eEquationLst = el,elseBranches = {}, info = info),(initial_ as SCode.NON_INITIAL()),impl,graph,_)
      equation
        checkWhenEquation(eq);
        (cache,e_1,prop1,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, prop1) = Ceval.cevalIfConstant(cache, env, e_1, prop1, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        (cache,env_1,ih,DAE.DAE(daeElts1),_,_,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, el, impl, alwaysUnroll, graph);
        _ = DAEUtil.verifyWhenEquation(daeElts1);
        // TODO: fix error reporting, print(" exps: " +& stringDelimitList(List.map(lhsCrefs,ComponentReference.printComponentRefStr),", ") +& "\n");
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        dae = DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,NONE(),source)});
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

    // seems unnecessary to handle when equations that are initial for loops
    // The loop expression is evaluated to a constant array of integers, and then the loop is unrolled.

    // Implicit range
    case (_,_,_,_,_,_,_,SCode.EQ_FOR(index = i,range = NONE(),eEquationLst = el,info=info),_,_,_,_)
      equation
        ({}) = SCode.findIteratorInEEquationLst(i,el);
        Error.addSourceMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i},info);
      then
        fail();

    // for i loop ... end for; NOTE: This construct is encoded as range being NONE()
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = NONE(),eEquationLst = el, info=info),initial_,impl,graph,_)
      equation
        (lst as _::_)=SCode.findIteratorInEEquationLst(i,el);
        tpl=List.first(lst);
        e=rangeExpression(tpl);
        (cache,e_1,DAE.PROP(type_ = DAE.T_ARRAY(ty = id_t), constFlag = cnst),_) =
          Static.elabExp(cache,env, e, impl,NONE(),true, pre, info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl,NONE(), Absyn.MSG(info), 0) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache, env_1, ih, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl, graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    // for i in <expr> loop .. end for;
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = SOME(e),eEquationLst = el,info=info),initial_,impl,graph,_)
      equation
        (cache,e_1,DAE.PROP(type_ = DAE.T_ARRAY(ty = id_t), constFlag = cnst),_) = Static.elabExp(cache,env, e, impl,NONE(),true, pre, info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl,NONE(), Absyn.NO_MSG(), 0) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache, env_1, ih, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    // A for-equation with a parameter range without binding, which is ok when
    // doing checkModel. Use a range {1} to check that the loop can be instantiated.
    case (cache, env, ih, mod, pre, csets, ci_state, SCode.EQ_FOR(index = i, range = SOME(e), eEquationLst = el,info=info), initial_, impl, graph,_)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (cache, _, DAE.PROP(type_ = DAE.T_ARRAY(ty = id_t), constFlag = cnst as DAE.C_PARAM()), _) =
          Static.elabExp(cache, env, e, impl,NONE(), true, pre,info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        v = Values.ARRAY({Values.INTEGER(1)}, {1});
        (cache, dae, csets_1, graph) = unroll(cache, env_1, ih, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl, graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache, env, ih, dae, csets_1, ci_state_1, graph);

    // for i in <expr> loop .. end for;
    // where <expr> is not constant or parameter expression
    case (cache,env,_,_,pre,_,_,SCode.EQ_FOR(index = _,range = SOME(e),eEquationLst = _,info=info),_,impl,_,_)
      equation
        (cache,e_1,DAE.PROP(type_ = DAE.T_ARRAY(ty = _), constFlag = DAE.C_VAR()),_)
          = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);

        s = ExpressionDump.printExpStr(e_1);
        Error.addSourceMessage(Error.NON_PARAMETER_ITERATOR_RANGE, {s}, info);
      then
        fail();

    // assert statements
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_ASSERT(condition = e1,message = e2,level = e3, info = info),_,impl,graph,_)
      equation
        (cache,e1_1,prop1 as DAE.PROP(DAE.T_BOOL(varLst = _),_),_) = Static.elabExp(cache,env, e1, impl,NONE(),true,pre,info) "assert statement" ;
        (cache,e2_1,prop2 as DAE.PROP(DAE.T_STRING(varLst = _),_),_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache,e3_1,prop3 as DAE.PROP(DAE.T_ENUMERATION(path = Absyn.FULLYQUALIFIED(Absyn.IDENT("AssertionLevel"))),_),_) = Static.elabExp(cache,env, e3, impl,NONE(),true,pre,info);

        (cache,e1_1,prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl, info);
        (cache,e2_1,prop2) = Ceval.cevalIfConstant(cache, env, e2_1, prop2, impl, info);
        (cache,e3_1,prop3) = Ceval.cevalIfConstant(cache, env, e3_1, prop3, impl, info);

        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);
        (cache,e2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_1, pre);
        (cache,e3_2) = PrefixUtil.prefixExp(cache, env, ih, e3_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        dae = DAE.DAE({DAE.ASSERT(e1_2,e2_2,e3_2,source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    // terminate statements
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_TERMINATE(message= e1, info=info),_,impl,graph,_)
      equation
        (cache,e1_1,prop1 as DAE.PROP(DAE.T_STRING(varLst = _),_),_) = Static.elabExp(cache,env, e1, impl,NONE(),true,pre,info);
        (cache, e1_1, prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl, info);
        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        dae = DAE.DAE({DAE.TERMINATE(e1_2,source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    // reinit statement
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_REINIT(cref = cr,expReinit = e2,info = info),initial_,impl,graph,_)
      equation
        (cache,SOME((e1_1 as DAE.CREF(cr_1,t),tprop1,_))) =
          Static.elabCrefNoEval(cache,env, cr, impl,false,pre,info) "reinit statement" ;
        true = checkReinitType(t, tprop1, cr_1, info);
        (cache,e2_1,tprop2,_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache, e2_1, tprop2) = Ceval.cevalIfConstant(cache, env, e2_1, tprop2, impl, info);
        (e2_1,_) = Types.matchProp(e2_1,tprop2,tprop1,true);
        (cache,e1_1,e2_1,tprop1) = condenseArrayEquation(cache,env,Absyn.CREF(cr),e2,e1_1,e2_1,tprop1,tprop2,impl,pre,info);
        (cache,e2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_1, pre);
        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        DAE.DAE(daeElts) = instEqEquation(e1_2, tprop1, e2_2, tprop2, source, initial_, impl);
        daeElts = List.map(daeElts,makeDAEArrayEqToReinitForm);
        dae = DAE.DAE(daeElts);
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    // Connections.root(cr)
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,exp=Absyn.CALL(
              function_ = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("root", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {}))),_,_,graph,_)
      equation
        (cache,SOME((DAE.CREF(cr_,_),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addDefiniteRoot(graph, cr_);
      then
        (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    // Connections.potentialRoot(cr)
    // TODO: Merge all cases for potentialRoot below using standard way of handling named/positional arguments and type conversion Integer->Real
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,exp=Absyn.CALL(
              function_ = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {}))),_,_,graph,_)
      equation
        (cache,SOME((DAE.CREF(cr_,_),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, 0.0);
      then
        (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    // Connections.potentialRoot(cr,priority) - priority as Integer positinal argument
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,exp=Absyn.CALL(
              function_ = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr),Absyn.INTEGER(ipriority)}, {}))),_,_,graph,_)
      equation
        (cache,SOME((DAE.CREF(cr_,_),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, intReal(ipriority));
      then
        (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    // Connections.potentialRoot(cr,priority =prio ) - priority as named argument
    case (cache,env,ih,_,_,csets,ci_state,SCode.EQ_NORETCALL(info=info,exp=Absyn.CALL(
              function_ = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(_)}, {Absyn.NAMEDARG("priority", Absyn.REAL(_))}))),_,_,graph,_)
      equation
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_INTEGER,
          {"Second", "Connections.potentialRoot", ""}, info);
      then
        (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    // Connections.branch(cr1,cr2)
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,exp=Absyn.CALL(
              function_ = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("branch", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr1), Absyn.CREF(cr2)}, {}))),_,_,graph,_)
      equation
        (cache,SOME((DAE.CREF(cr1_,_),_,_))) = Static.elabCref(cache,env, cr1, false /* ??? */,false,pre,info);
        (cache,SOME((DAE.CREF(cr2_,_),_,_))) = Static.elabCref(cache,env, cr2, false /* ??? */,false,pre,info);
        (cache,cr1_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr1_);
        (cache,cr2_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr2_);
        graph = ConnectionGraph.addBranch(graph, cr1_, cr2_);
      then
        (cache,env,ih,DAE.emptyDae,csets,ci_state,graph);

    // no return calls
    case (cache,env,ih,_,pre,csets,ci_state,SCode.EQ_NORETCALL(exp = e, info = info),_,impl,graph,_)
      equation
        (cache,exp,_,_) = Static.elabExp(cache,env,e,impl,NONE(),false,pre,info);
        // This is probably an external function call that the user wants to evaluat at runtime
        // (cache, exp, prop1) = Ceval.cevalIfConstant(cache, env, exp, prop1, impl, info);
        (cache,exp) = PrefixUtil.prefixExp(cache,env,ih,exp,pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        source = DAEUtil.addSymbolicTransformation(source,flattenOp);

        dae = instEquationNoRetCallVectorization(exp,inInitial,source);
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    // failure
    case (_,env,_,_,_,_,_,eqn,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = SCodeDump.equationStr(eqn,SCodeDump.defaultOptions);
        Debug.fprint(Flags.FAILTRACE, "- instEquationCommonWork failed for eqn: ");
        Debug.fprint(Flags.FAILTRACE, s +& " in scope:" +& Env.getEnvNameStr(env) +& "\n");
        //print("ENV: " +& Env.printEnvStr(env) +& "\n");
      then
        fail();
  end matchcontinue;
end instEquationCommonWork;

protected function checkReinitType
  "Checks that the base type of the given type is Real, otherwise it prints an
   error message that the first argument to reinit must be a subtype of Real."
  input DAE.Type inType;
  input DAE.Properties inProperties;
  input DAE.ComponentRef inCref;
  input Absyn.Info inInfo;
  output Boolean outSucceeded;
algorithm
  outSucceeded := matchcontinue(inType, inProperties, inCref, inInfo)
    local
      DAE.Type ty;
      String cref_str, ty_str, cnst_str;
      DAE.Const cnst;

    case (_, _, _, _)
      equation
        ty = Types.arrayElementType(inType);
        false = Types.isReal(ty);
        cref_str = ComponentReference.printComponentRefStr(inCref);
        ty_str = Types.unparseType(ty);
        Error.addSourceMessage(Error.REINIT_MUST_BE_REAL,
          {cref_str, ty_str}, inInfo);
      then
        false;

    case (_, DAE.PROP(constFlag = cnst), _, _)
      equation
        false = Types.isVar(cnst);
        cnst_str = Types.unparseConst(cnst);
        cref_str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.REINIT_MUST_BE_VAR,
          {cref_str, cnst_str}, inInfo);
      then
        false;

    else true;

  end matchcontinue;
end checkReinitType;


/*protected function checkTupleCallEquation "Check if the two expressions make up a proper tuple function call.
Returns the error on failure."
  input Absyn.Exp left;
  input Absyn.Exp right;
algorithm
  _ := matchcontinue (left,right)
    local
      list<Absyn.Exp> crs;
    case (Absyn.TUPLE(crs),Absyn.CALL(functionArgs = _))
      equation
        _ = List.map(crs,Absyn.expCref);
      then ();
    case (left,_)
      equation
        failure(Absyn.TUPLE(_) = left);
      then ();
  end matchcontinue;
end checkTupleCallEquation;*/

protected function checkTupleCallEquationMessage "A version of checkTupleCallEquation
which produces appropriate error message if the check fails"
  input Absyn.Exp left;
  input Absyn.Exp right;
  input Absyn.Info info;
algorithm
  _ := matchcontinue (left,right,info)
    local
      list<Absyn.Exp> crs;
      String s1,s2,s;
    case (Absyn.TUPLE(crs),Absyn.CALL(functionArgs = _),_)
      equation
        _ = List.map(crs,Absyn.expCref);
      then ();
    case (_,_,_)
      equation
        failure(Absyn.TUPLE(_) = left);
      then ();
    case (Absyn.TUPLE(_),_,_)
      equation
        s1 = Dump.printExpStr(left);
        s2 = Dump.printExpStr(right);
        s = stringAppendList({s1," = ",s2,";"});
        Error.addSourceMessage(Error.TUPLE_ASSIGN_CREFS_ONLY,{s},info);
      then fail();
    case (Absyn.TUPLE(_),_,_)
      equation
        failure(Absyn.CALL(_,_) = right);
        s1 = Dump.printExpStr(left);
        s2 = Dump.printExpStr(right);
        s = stringAppendList({s1," = ",s2,";"});
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY,{s},info);
      then fail();
  end matchcontinue;
end checkTupleCallEquationMessage;

protected function instEquationNoRetCallVectorization "creates DAE for NORETCALLs and also performs vectorization if needed"
  input DAE.Exp exp;
  input SCode.Initial initial_;
  input DAE.ElementSource source "the origin of the element";
  output DAE.DAElist dae;
algorithm
  dae := match (exp,initial_,source)
    case(_,SCode.NON_INITIAL(),_) equation
      then DAE.DAE({DAE.NORETCALL(exp,source)});
    case(_,SCode.INITIAL(),_) equation
      then DAE.DAE({DAE.INITIAL_NORETCALL(exp,source)});
  end match;
end instEquationNoRetCallVectorization;

protected function makeDAEArrayEqToReinitForm "
Author: BZ, 2009-02
Function for transforming DAE equations into DAE.REINIT form, used by instEquationCommon   "
  input DAE.Element inEq;
  output DAE.Element outEqn;
algorithm
  outEqn := matchcontinue(inEq)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e2,e;
      DAE.Type t;
      DAE.ElementSource source "the origin of the element";

    case(DAE.EQUATION(DAE.CREF(componentRef=cr1),e,source))
      then DAE.REINIT(cr1,e,source);

    case(DAE.DEFINE(cr1,e,source))
      then DAE.REINIT(cr1,e,source);

    case(DAE.EQUEQUATION(cr1,cr2,source))
      equation
        t = ComponentReference.crefLastType(cr2);
        e2 = Expression.makeCrefExp(cr2,t);
      then
        DAE.REINIT(cr1,e2,source);

    case(DAE.ARRAY_EQUATION(exp=DAE.CREF(componentRef=cr1),array=e,source=source))
      then DAE.REINIT(cr1,e,source);

    else equation print("Failure in: makeDAEArrayEqToReinitForm\n"); then fail();

  end matchcontinue;
end makeDAEArrayEqToReinitForm;

protected function condenseArrayEquation "This function transforms makes the two sides of an array equation
into its condensed form. By default, most array variables are vectorized,
i.e. v becomes {v[1],v[2],..,v[n]}. But for array equations containing function calls this is not wanted.
This function detect this case and elaborates expressions without vectorization."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp ie1;
  input Absyn.Exp ie2;
  input DAE.Exp elabedE1;
  input DAE.Exp elabedE2;
  input DAE.Properties iprop "To determine if array equation";
  input DAE.Properties iprop2 "To determine if array equation";
  input Boolean impl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outE1;
  output DAE.Exp outE2;
  output DAE.Properties oprop "If we have an expandable tuple";
algorithm
  (outCache,outE1,outE2,oprop) := matchcontinue(inCache,inEnv,ie1,ie2,elabedE1,elabedE2,iprop,iprop2,impl,inPrefix,info)
    local
      Env.Cache cache;
      Env.Env env;
      Boolean b3,b4;
      DAE.Exp elabedE1_2, elabedE2_2;
      DAE.Properties prop1,prop,prop2;
      Prefix.Prefix pre;
      Absyn.Exp e1,e2;

    case(cache,env,e1,e2,_,_,prop,prop2,_,pre,_) equation
      b3 = Types.isPropTupleArray(prop);
      b4 = Types.isPropTupleArray(prop2);
      true = boolOr(b3,b4);
      true = Expression.containFunctioncall(elabedE2);
      (e1,prop) = expandTupleEquationWithWild(e1,prop2,prop);
      (cache,elabedE1_2,prop1,_) = Static.elabExp(cache,env, e1, impl,NONE(),false,pre,info);
      (cache, elabedE1_2, prop1) = Ceval.cevalIfConstant(cache, env, elabedE1_2, prop1, impl, info);
      (cache,elabedE2_2,prop2,_) = Static.elabExp(cache,env, e2, impl,NONE(),false,pre,info);
      (cache, elabedE2_2, prop2) = Ceval.cevalIfConstant(cache, env, elabedE2_2, prop2, impl, info);
      then
        (cache,elabedE1_2,elabedE2_2,prop);
    case(cache,_,_,_,_,_,prop,_,_,_,_)
    then (cache,elabedE1,elabedE2,prop);
  end matchcontinue;
end condenseArrayEquation;

protected function expandTupleEquationWithWild
"Author BZ 2008-06
The function expands the inExp, Absyn.EXP, to contain as many elements as the, DAE.Properties, propCall does.
The expand adds the elements at the end and they are containing Absyn.WILD() exps with type Types.ANYTYPE. "
  input Absyn.Exp inExp;
  input DAE.Properties propCall;
  input DAE.Properties propTuple;
  output Absyn.Exp outExp;
  output DAE.Properties oprop;
algorithm
  (outExp,oprop) := matchcontinue(inExp,propCall,propTuple)
  local
    list<Absyn.Exp> aexpl,aexpl2;
    list<DAE.Type> typeList;
    Integer fillValue "The amount of elements to add";
    DAE.Type propType;
    list<DAE.Type> lst,lst2;
    DAE.TypeSource ts;
    list<DAE.TupleConst> tupleConst,tupleConst2;
    DAE.Const tconst;

  case(Absyn.TUPLE(aexpl),
    DAE.PROP_TUPLE( DAE.T_TUPLE(typeList, _), _),
    (DAE.PROP_TUPLE(DAE.T_TUPLE(lst,ts), DAE.TUPLE_CONST(tupleConst)
    )))
    equation
      fillValue = (listLength(typeList)-listLength(aexpl));
      lst2 = List.fill(DAE.T_ANYTYPE_DEFAULT,fillValue) "types";
      aexpl2 = List.fill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions";
      tupleConst2 = List.fill(DAE.SINGLE_CONST(DAE.C_VAR()),fillValue) "TupleConst's";
      aexpl = listAppend(aexpl,aexpl2);
      lst = listAppend(lst,lst2);
      tupleConst = listAppend(tupleConst,tupleConst2);
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE(DAE.T_TUPLE(lst,ts),DAE.TUPLE_CONST(tupleConst)));

  case(_, DAE.PROP_TUPLE(DAE.T_TUPLE(typeList,_), _), DAE.PROP(propType,tconst))
    equation
      fillValue = (listLength(typeList)-1);
      aexpl2 = List.fill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions";
      lst2 = List.fill(DAE.T_ANYTYPE_DEFAULT,fillValue) "types";
      tupleConst2 = List.fill(DAE.SINGLE_CONST(DAE.C_VAR()),fillValue) "TupleConst's";
      aexpl = inExp::aexpl2;
      lst = propType::lst2;
      tupleConst = DAE.SINGLE_CONST(tconst)::tupleConst2;
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE(DAE.T_TUPLE(lst,DAE.emptyTypeSource),DAE.TUPLE_CONST(tupleConst)));

  case(_,_,_)
    equation
      false = Types.isPropTuple(propCall);
      then (inExp,propTuple);
      else equation print("expand_Tuple_Equation_With_Wild failed \n");then fail();
  end matchcontinue;
end expandTupleEquationWithWild;


protected function instEquationCommonCiTrans
"updats The ClassInf state machine when an equation is instantiated."
  input ClassInf.State inState;
  input SCode.Initial inInitial;
  output ClassInf.State outState;
algorithm
  outState := match (inState,inInitial)
    local ClassInf.State ci_state_1,ci_state;
    case (ci_state,SCode.NON_INITIAL())
      equation
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.FOUND_EQUATION());
      then
        ci_state_1;
    case (ci_state,SCode.INITIAL()) then ci_state;
  end match;
end instEquationCommonCiTrans;

protected function unroll "Unrolling a loop is a way of removing the non-linear structure of
  the FOR clause by explicitly repeating the body of the loop once
  for each iteration."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input Ident inIdent;
  input DAE.Type inIteratorType;
  input Values.Value inValue;
  input list<SCode.EEquation> inSCodeEEquationLst;
  input SCode.Initial inInitial;
  input Boolean inImplicit;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outDae,outSets,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inIdent,inIteratorType,inValue,inSCodeEEquationLst,inInitial,inImplicit,inGraph)
    local
      Connect.Sets csets,csets_1,csets_2;
      Env.Env env_1,env_2,env_3,env;
      DAE.DAElist dae1,dae2,dae;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      String i;
      Values.Value fst;
      list<Values.Value> rest;
      list<SCode.EEquation> eqs;
      SCode.Initial initial_;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      list<Integer> dims;
      Integer dim;
      DAE.Type ty;
      InstanceHierarchy ih;

    case (cache,_,_,_,_,csets,_,_,_,Values.ARRAY(valueLst = {}),_,_,_,graph)
    then (cache,DAE.emptyDae,csets,graph);  /* impl */

    // array equation, use instEEquation
    case (cache,env,ih,mods,pre,csets,ci_state,i,ty,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.NON_INITIAL()),impl,graph)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, ty, DAE.VALBOUND(fst,DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        /* use instEEquation*/
        (cache,_,_,dae1,csets_1,ci_state_1,graph) =
          Inst.instList(cache, env_2, ih, mods, pre, csets, ci_state, instEEquation, eqs, impl, alwaysUnroll, graph);
        (cache,dae2,csets_2,graph) = unroll(cache, env, ih, mods, pre, csets_1, ci_state_1, i, ty, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);

     // initial array equation, use instEInitialEquation
    case (cache,env,ih,mods,pre,csets,ci_state,i,ty,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.INITIAL()),impl,graph)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, ty, DAE.VALBOUND(fst,DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        // Use instEInitialEquation
        (cache,_,_,dae1,csets_1,ci_state_1,graph) =
          Inst.instList(cache, env_2, ih, mods, pre, csets, ci_state, instEInitialEquation, eqs, impl, alwaysUnroll, graph);
        (cache,dae2,csets_2,graph) = unroll(cache, env, ih, mods, pre, csets_1, ci_state_1, i, ty, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.unroll failed: " +& ValuesUtil.valString(inValue));
      then
        fail();
  end matchcontinue;
end unroll;

protected function addForLoopScope
"Adds a scope to the environment used in for loops.
 adrpo NOTE:
   The variability of the iterator SHOULD
   be determined by the range constantness!"
  input Env.Env env;
  input Ident iterName;
  input DAE.Type iterType;
  input SCode.Variability iterVariability;
  input Option<DAE.Const> constOfForIteratorRange;
  output Env.Env newEnv;
algorithm
  newEnv := Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName), NONE());
  newEnv := Env.extendFrameForIterator(newEnv, iterName, iterType, DAE.UNBOUND(), iterVariability, constOfForIteratorRange);
end addForLoopScope;

protected function addParForLoopScope
"Adds a scope to the environment used in for loops.
 adrpo NOTE:
   The variability of the iterator SHOULD
   be determined by the range constantness!"
  input Env.Env env;
  input Ident iterName;
  input DAE.Type iterType;
  input SCode.Variability iterVariability;
  input Option<DAE.Const> constOfForIteratorRange;
  output Env.Env newEnv;
algorithm
  newEnv := Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.parForScopeName), NONE());
  newEnv := Env.extendFrameForIterator(newEnv, iterName, iterType, DAE.UNBOUND(), iterVariability, constOfForIteratorRange);
end addParForLoopScope;

public function instEqEquation "author: LS, ELN
  Equations follow the same typing rules as equality expressions.
  This function adds the equation to the DAE."
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input DAE.Exp inExp3;
  input DAE.Properties inProperties4;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial5;
  input Boolean inImplicit;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inExp1,inProperties2,inExp3,inProperties4,source,inInitial5,inImplicit)
    local
      DAE.Exp e1_1,e1,e2,e2_1;
      DAE.Type t_1,t1,t2,t;
      DAE.DAElist dae;
      DAE.Properties p1,p2;
      SCode.Initial initial_;
      Boolean impl;
      String e1_str,t1_str,e2_str,t2_str,s1,s2;
      DAE.Const c;
      DAE.TupleConst tp;
      Absyn.Info info;

      /* TODO: Weird hack to make backend happy */
    case (e1 as DAE.CREF(componentRef=_), (p1 as DAE.PROP(type_ = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))),
          e2, (p2 as DAE.PROP(type_ = _, constFlag = c)), _, initial_, _) /* If it fails then this rule is matched. */
      equation
        (e2_1, DAE.PROP(t_1, _)) = Types.matchProp(e2, p2, p1, true);
        (e1,_) = ExpressionSimplify.simplify(e1);
        (e2_1,_) = ExpressionSimplify.simplify(e2_1);
        dae = instEqEquation2(e1, e2_1, t_1, c, source, initial_);
      then
        dae;

    case (e1, (p1 as DAE.PROP(type_ = _)),
          e2, (p2 as DAE.PROP(constFlag = c)), _, initial_, _) /* If e2 is not of e1's type, check if e1 has e2's type instead */
      equation
        (e1_1, DAE.PROP(t_1, _)) = Types.matchProp(e1, p1, p2, false);
        (e1_1,_) = ExpressionSimplify.simplify(e1_1);
        (e2,_) = ExpressionSimplify.simplify(e2);
        dae = instEqEquation2(e1_1, e2, t_1, c, source, initial_);
      then
        dae;

      /* TODO: Make testsuite run properly even if this is the first case... Unknown dimensions are not matched fine here and should possibly be disallowed. */
    case (e1, (p1 as DAE.PROP(type_ = _)),
          e2, (p2 as DAE.PROP(type_ = _, constFlag = c)), _, initial_, _) /* If it fails then this rule is matched. */
      equation
        (e2_1, DAE.PROP(t_1, _)) = Types.matchProp(e2, p2, p1, true);
        (e1,_) = ExpressionSimplify.simplify(e1);
        (e2_1,_) = ExpressionSimplify.simplify(e2_1);
        dae = instEqEquation2(e1, e2_1, t_1, c, source, initial_);
      then dae;

    case (e1, (p1 as DAE.PROP_TUPLE(type_ = _)),
          e2, (p2 as DAE.PROP_TUPLE(type_ = _, tupleConst = tp)), _, initial_, _) /* PR. */
      equation
        (e1_1, DAE.PROP_TUPLE(t_1, _)) = Types.matchProp(e1, p1, p2, false);
        (e1_1,_) = ExpressionSimplify.simplify(e1_1);
        (e2,_) = ExpressionSimplify.simplify(e2);
        c = Types.propTupleAllConst(tp);
        dae = instEqEquation2(e1_1, e2, t_1, c, source, initial_);
      then
        dae;

    case (e1, (p1 as DAE.PROP_TUPLE(type_ = _)),
          e2, (p2 as DAE.PROP_TUPLE(type_ = _, tupleConst = tp)), _, initial_, _) /* PR.
      An assignment to a variable of T_ENUMERATION type is an explicit
      assignment to the value componnent of the enumeration, i.e. having
      a type T_ENUM
   */
      equation
        (e2_1, DAE.PROP_TUPLE(t_1, _)) = Types.matchProp(e2, p2, p1, true);
        (e1,_) = ExpressionSimplify.simplify(e1);
        (e2_1,_) = ExpressionSimplify.simplify(e2_1);
        c = Types.propTupleAllConst(tp);
        dae = instEqEquation2(e1, e2_1, t_1, c, source, initial_);
      then
        dae;

    case ((e1 as DAE.CREF(componentRef = _)),
           DAE.PROP(type_ = DAE.T_ENUMERATION(names = _)),
           e2,
           DAE.PROP(type_ = t as DAE.T_ENUMERATION(names = _), constFlag = c), _, initial_, _)
      equation
        (e1,_) = ExpressionSimplify.simplify(e1);
        (e2,_) = ExpressionSimplify.simplify(e2);
        dae = instEqEquation2(e1, e2, t, c, source, initial_);
      then
        dae;

    // Assignment to a single component with a function returning multiple
    // values.
    case (e1, p1 as DAE.PROP(type_ = _),
          e2, DAE.PROP_TUPLE(type_ = _), _, initial_, _)
      equation
        p2 = Types.propTupleFirstProp(inProperties4);
        DAE.PROP(constFlag = c) = p2;
        (e1, DAE.PROP(type_ = t_1)) = Types.matchProp(e1, p1, p2, false);
        (e1,_) = ExpressionSimplify.simplify(e1);
        e2 = DAE.TSUB(e2, 1, t_1);
        (e2,_) = ExpressionSimplify.simplify(e2);
        dae = instEqEquation2(e1, e2, t_1, c, source, initial_);
      then
        dae;

    case (e1,DAE.PROP(type_ = t1),e2,DAE.PROP(type_ = t2),_,_,_)
      equation
        e1_str = ExpressionDump.printExpStr(e1);
        t1_str = Types.unparseType(t1);
        e2_str = ExpressionDump.printExpStr(e2);
        t2_str = Types.unparseType(t2);
        s1 = stringAppendList({e1_str,"=",e2_str});
        s2 = stringAppendList({t1_str,"=",t2_str});
        info = DAEUtil.getElementSourceFileInfo(source);
        Types.typeErrorSanityCheck(t1_str, t2_str, info);
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2}, info);
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instEqEquation failed with type mismatch in equation: " +& s1 +& " tys: " +& s2);
      then
        fail();
  end matchcontinue;
end instEqEquation;

protected function instEqEquation2
"author: LS, ELN
  This is the second stage of instEqEquation, when the types are checked."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType3;
  input DAE.Const inConst;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial4;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inExp1,inExp2,inType3, inConst, source,inInitial4)
    local
      DAE.DAElist dae; DAE.Exp e1,e2;
      SCode.Initial initial_;
      DAE.ComponentRef cr;
      DAE.Type t;
      list<DAE.Var> vs;
      DAE.Type tt;
      list<DAE.Exp> exps1,exps2;
      list<DAE.Type> tys;

    case (e1,e2,DAE.T_INTEGER(varLst = _),_,_,initial_)
      equation
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_REAL(varLst = _),_,_,initial_)
      equation
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_STRING(varLst = _),_,_,initial_)
      equation
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_BOOL(varLst = _),_,_,initial_)
      equation
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    case (DAE.CREF(componentRef = cr,ty = _),e2,DAE.T_ENUMERATION(names = _),_,_,initial_)
      equation
        dae = makeDaeDefine(cr, e2, source, initial_);
      then
        dae;

    // array equations
    case (e1,e2,tt as DAE.T_ARRAY(ty = _),_,_,initial_)
      equation
        dae = instArrayEquation(e1, e2, tt, inConst, source, initial_);
      then dae;

    // tuples
    case (e1,e2,DAE.T_TUPLE(tupleType = _),_,_,initial_)
      equation
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    // MetaModelica types
    case (e1,e2,DAE.T_METALIST(listType = _),_,_,initial_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_METATUPLE(types = _),_,_,initial_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_METAOPTION(optionType = _),_,_,initial_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,DAE.T_METAUNIONTYPE(paths=_),_,_,initial_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    // --------------

    // Complex types extending basic type
    case (e1,e2,DAE.T_SUBTYPE_BASIC(complexType = tt),_,_,initial_)
      equation
        dae = instEqEquation2(e1, e2, tt, inConst, source, initial_);
      then
        dae;

    // split a complex equation to its elements
    case (e1,e2,DAE.T_COMPLEX(varLst = vs),_,_,initial_)
      equation
        exps1 = Expression.splitRecord(e1,inType3);
        exps2 = Expression.splitRecord(e2,inType3);
        tys = List.map(vs, Types.getVarType);
        dae = instEqEquation2List(exps1, exps2, tys, inConst, source, initial_, {});
      then dae;

   /* all other COMPLEX equations */
   case (e1,e2, tt as DAE.T_COMPLEX(varLst = _),_,_,initial_)
     equation
       dae = instComplexEquation(e1,e2,tt,source,initial_);
     then dae;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instEqEquation2 failed");
      then
        fail();
  end matchcontinue;
end instEqEquation2;

protected function instEqEquation2List
  input list<DAE.Exp> inExps1;
  input list<DAE.Exp> inExps2;
  input list<DAE.Type> inTypes3;
  input DAE.Const const;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial initial_;
  input list<DAE.DAElist> acc;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inExps1,inExps2,inTypes3, const, source, initial_,acc)
    local
      list<DAE.Exp> rest1,rest2;
      list<DAE.Type> rest3;
      DAE.Type ty;
      DAE.Exp exp1,exp2;
      DAE.DAElist res;
    case ({},{},{},_,_,_,_) then DAEUtil.joinDaeLst(listReverse(acc));
    case (exp1::rest1,exp2::rest2,ty::rest3,_,_,_,_)
      equation
        res = instEqEquation2(exp1,exp2,ty,const,source,initial_);
      then instEqEquation2List(rest1,rest2,rest3,const,source,initial_,res::acc);
  end match;
end instEqEquation2List;

protected function assignComplexConstantConstruct "
Author BZ 2010
Function for assigning contrctor calls to variables inside complex var.
Helperfunction for instEqEquation2
ex.
Person p
 Real a[3,3]
 Real b[3]
end p
equation
 p = Person(identity(3),zeros(3))

 this function will flatten this to;
p.a = identity(3);
p.b = zeros(3);
"

input Values.Value constantValue;
input DAE.ComponentRef assigned;
input DAE.ElementSource source;
output list<DAE.Element> eqns;
algorithm
  eqns := matchcontinue(constantValue,assigned,source)
    local
      DAE.ComponentRef cr,cr2;
      Integer i,index;
      Real r;
      String s,n;
      Boolean b;
      Absyn.Path p;
      list<String> names;
      Values.Value v;
      list<Values.Value> vals,arrVals;
      list<DAE.Element> eqnsArray,eqns2;
      DAE.Type tp;
      DAE.Exp lhs;

    case(Values.RECORD(orderd = {},comp = {}),_,_) then {};

    case(Values.RECORD(_, Values.RECORD(comp=_)::_,_::_,_),_,_)
      equation
        print(" implement assignComplexConstantConstruct for records of records\n");
      then fail();

    case(Values.RECORD(p, (v as Values.ARRAY(valueLst = arrVals))::vals, n::names, index),cr,_)
      equation
        tp = ValuesUtil.valueExpType(v);
        cr2 = ComponentReference.crefPrependIdent(cr,n,{},tp);
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqnsArray = assignComplexConstantConstructToArray(arrVals,cr2,source,1);
        eqns = listAppend(eqns,eqnsArray);
      then
        eqns;

    case(Values.RECORD(p, v::vals, n::names, index),cr,_)
      equation
        cr2 = ComponentReference.crefPrependIdent(cr,n,{},DAE.T_INTEGER_DEFAULT);
        eqns2 = assignComplexConstantConstruct(v,cr2,source);
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqns = listAppend(eqns,eqns2);
      then
        eqns;

    // REAL
    case(Values.REAL(r),cr,_)
      equation
        lhs = Expression.crefExp(cr);
      then
        {DAE.EQUATION(lhs,DAE.RCONST(r),source)};

    case(Values.INTEGER(i),cr,_)
      equation
        lhs = Expression.crefExp(cr);
      then
        {DAE.EQUATION(lhs,DAE.ICONST(i),source)};

    case(Values.STRING(s),cr,_)
      equation
        lhs = Expression.crefExp(cr);
      then
        {DAE.EQUATION(lhs,DAE.SCONST(s),source)};

    case(Values.BOOL(b),cr,_)
      equation
        lhs = Expression.crefExp(cr);
      then
        {DAE.EQUATION(lhs,DAE.BCONST(b),source)};

    case(_,cr,_)
      equation
        print(" failure to assign: "  +& ComponentReference.printComponentRefStr(cr) +& " to " +& ValuesUtil.valString(constantValue) +& "\n");
      then
        fail();
  end matchcontinue;
end assignComplexConstantConstruct;

protected function assignComplexConstantConstructToArray "
Helper function for assignComplexConstantConstruct
Does array indexing and assignement "
  input list<Values.Value> iarr;
  input DAE.ComponentRef iassigned;
  input DAE.ElementSource source;
  input Integer subPos;
  output list<DAE.Element> eqns;
algorithm eqns := matchcontinue(iarr,iassigned,source,subPos)
  local
    Values.Value v;
    list<Values.Value> arrVals;
    list<DAE.Element> eqns2;
    list<Values.Value> arr;
    DAE.ComponentRef assigned;

  case({},_,_,_) then {};
  case((Values.ARRAY(valueLst = arrVals))::arr,assigned,_,_)
    equation
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = ComponentReference.subscriptCrefWithInt(assigned, subPos);
      eqns2 = assignComplexConstantConstructToArray(arrVals,assigned,source,1);
      eqns = listAppend(eqns,eqns2);
    then
      eqns;
  case(v::arr,assigned,_,_)
    equation
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = ComponentReference.subscriptCrefWithInt(assigned, subPos);
      eqns2 = assignComplexConstantConstruct(v,assigned,source);
      eqns = listAppend(eqns,eqns2);
      then
        eqns;
end matchcontinue;
end assignComplexConstantConstructToArray;

public function makeDaeEquation
"author: LS, ELN
  Constructs an equation in the DAE, they can be
  either an initial equation or an ordinary equation."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource inSource "the origin of the element";
  input SCode.Initial inInitial3;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inExp1,inExp2,inSource,inInitial3)
    local
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      DAE.Element elt;
    case (e1,e2,source,SCode.NON_INITIAL())
      equation
        elt = DAE.EQUATION(e1,e2,source);
        source = DAEUtil.addSymbolicTransformationFlattenedEqs(source, elt);
      then DAE.DAE({DAE.EQUATION(e1,e2,source)});
    case (e1,e2,source,SCode.INITIAL())
      equation
        elt = DAE.INITIALEQUATION(e1,e2,source);
        source = DAEUtil.addSymbolicTransformationFlattenedEqs(source, elt);
      then DAE.DAE({DAE.INITIALEQUATION(e1,e2,source)});
  end match;
end makeDaeEquation;

protected function makeDaeDefine
"author: LS, ELN "
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inComponentRef,inExp,source,inInitial)
    local DAE.ComponentRef cr; DAE.Exp e2;
    case (cr,e2,_,SCode.NON_INITIAL())
      then DAE.DAE({DAE.DEFINE(cr,e2,source)});
    case (cr,e2,_,SCode.INITIAL())
      then DAE.DAE({DAE.INITIALDEFINE(cr,e2,source)});
  end match;
end makeDaeDefine;

protected function instArrayEquation
  "Instantiates an array equation, i.e. an equation where both sides are arrays."
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type tp;
  input DAE.Const inConst;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(lhs, rhs, tp, inConst, source, initial_)
    local
      Boolean b, b1, b2;
      DAE.Dimensions ds;
      DAE.Dimension dim, lhs_dim, rhs_dim;
      list<DAE.Exp> lhs_idxs, rhs_idxs;
      DAE.Type t;
      String lhs_str, rhs_str, eq_str;
      DAE.Element elt;

    /* Initial array equations with function calls => initial array equations */
    case (_, _, _, _, _, SCode.INITIAL())
      equation
        b1 = Expression.containVectorFunctioncall(lhs);
        b2 = Expression.containVectorFunctioncall(rhs);
        true = boolOr(b1, b2);
        ds = Types.getDimensions(tp);
      then
        DAE.DAE({DAE.INITIAL_ARRAY_EQUATION(ds, lhs, rhs, source)});

    /* Arrays with function calls => array equations */
    case (_, _, _, _, _, SCode.NON_INITIAL())
      equation
        b1 = Expression.containVectorFunctioncall(lhs);
        b2 = Expression.containVectorFunctioncall(rhs);
        true = boolOr(b1, b2);
        ds = Types.getDimensions(tp);
      then
        DAE.DAE({DAE.ARRAY_EQUATION(ds, lhs, rhs, source)});

    // Array equation of any size, non-expanding case
    case (_, _, DAE.T_ARRAY(ty = t, dims = {_}), _, _, _)
      equation
        false = Config.splitArrays();
        // Expand along the first dimensions of the expressions, and generate an
        // equation for each pair of elements.
        DAE.T_ARRAY(dims = lhs_dim :: _) = Expression.typeof(lhs);
        DAE.T_ARRAY(dims = rhs_dim :: _) = Expression.typeof(rhs);
        lhs_idxs = expandArrayDimension(lhs_dim, lhs);
        rhs_idxs = expandArrayDimension(rhs_dim, rhs);
        dae = instArrayElEq(lhs, rhs, t, inConst, lhs_idxs, rhs_idxs, source, initial_);
      then
        dae;

    // Array dimension of known size, expanding case.
    case (_, _, DAE.T_ARRAY(ty = t, dims = {dim}), _, _, _)
      equation
        true = Config.splitArrays();
        true = Expression.dimensionKnown(dim);
        // Expand along the first dimensions of the expressions, and generate an
        // equation for each pair of elements.
        DAE.T_ARRAY(dims = lhs_dim :: _) = Expression.typeof(lhs);
        DAE.T_ARRAY(dims = rhs_dim :: _) = Expression.typeof(rhs);
        lhs_idxs = expandArrayDimension(lhs_dim, lhs);
        rhs_idxs = expandArrayDimension(rhs_dim, rhs);
        dae = instArrayElEq(lhs, rhs, t, inConst, lhs_idxs, rhs_idxs, source, initial_);
      then
        dae;

    case (_, _, DAE.T_ARRAY(ty = _, dims = {dim}), _, _, _)
      equation
        true = Config.splitArrays();
        true = Expression.dimensionKnown(dim);
        true = Expression.isRange(lhs) or Expression.isRange(rhs) or Expression.isReduction(lhs) or Expression.isReduction(rhs);
        ds = Types.getDimensions(tp);
        b = SCode.isInitial(initial_);
        elt = Util.if_(b, DAE.INITIAL_ARRAY_EQUATION(ds, lhs, rhs, source), DAE.ARRAY_EQUATION(ds, lhs, rhs, source));
      then
        DAE.DAE({elt});

    // Array dimension of unknown size, expanding case.
    case (_, _, DAE.T_ARRAY(ty = t, dims = {dim}), _, _, _)
      equation
        true = Config.splitArrays();
        false = Expression.dimensionKnown(dim);
        // It's ok with array equation of unknown size if checkModel is used.
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        // Expand along the first dimensions of the expressions, and generate an
        // equation for each pair of elements.
        DAE.T_ARRAY(dims = lhs_dim :: _) = Expression.typeof(lhs);
        DAE.T_ARRAY(dims = rhs_dim :: _) = Expression.typeof(rhs);
        lhs_idxs = expandArrayDimension(lhs_dim, lhs);
        rhs_idxs = expandArrayDimension(rhs_dim, rhs);
        dae = instArrayElEq(lhs, rhs, t, inConst, lhs_idxs, rhs_idxs, source, initial_);
      then
        dae;

    // Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; (expanding case)
    case (_, _, DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}), _, _, SCode.INITIAL())
      equation
        true = Config.splitArrays();
        // It's ok with array equation of unknown size if checkModel is used.
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        // generate an initial array equation of dim 1
        // Now the dimension can be made DAE.DIM_UNKNOWN(), I just don't want to break anything for now -- alleb
      then
        DAE.DAE({DAE.INITIAL_ARRAY_EQUATION({DAE.DIM_INTEGER(1)}, lhs, rhs, source)});

    // Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; (expanding case)
    case (_, _, DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}), _, _, SCode.NON_INITIAL())
      equation
         true = Config.splitArrays();
        // It's ok with array equation of unknown size if checkModel is used.
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        // generate an array equation of dim 1
        // Now the dimension can be made DAE.DIM_UNKNOWN(), I just don't want to break anything for now -- alleb
      then
        DAE.DAE({DAE.ARRAY_EQUATION({DAE.DIM_INTEGER(1)}, lhs, rhs, source)});

    // Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; (expanding case)
    case (_, _, DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}), _, _, _)
      equation
        true = Config.splitArrays();
        // It's ok with array equation of unknown size if checkModel is used.
        false = Flags.getConfigBool(Flags.CHECK_MODEL);
        lhs_str = ExpressionDump.printExpStr(lhs);
        rhs_str = ExpressionDump.printExpStr(rhs);
        eq_str = stringAppendList({lhs_str, "=", rhs_str});
        Error.addSourceMessage(Error.INST_ARRAY_EQ_UNKNOWN_SIZE, {eq_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instArrayEquation failed");
      then
        fail();
  end matchcontinue;
end instArrayEquation;

protected function instArrayElEq
  "This function loops recursively through all indices in the two arrays and
  generates an equation for each pair of elements."
  input DAE.Exp inLhsExp;
  input DAE.Exp inRhsExp;
  input DAE.Type inType;
  input DAE.Const inConst;
  input list<DAE.Exp> inLhsIndices;
  input list<DAE.Exp> inRhsIndices;
  input DAE.ElementSource inSource;
  input SCode.Initial inInitial;
  output DAE.DAElist outDAE;
algorithm
  outDAE := match(inLhsExp, inRhsExp, inType, inConst, inLhsIndices,
      inRhsIndices, inSource, inInitial)
    local
      DAE.Exp lhs, rhs, lhs_idx, rhs_idx;
      DAE.Type t;
      list<DAE.Exp> lhs_idxs, rhs_idxs;
      DAE.DAElist dae1, dae2;
    case (_, _, _, _, {}, {}, _, _) then DAE.emptyDae;
    case (lhs, rhs, t, _, lhs_idx :: lhs_idxs, rhs_idx :: rhs_idxs, _, _)
      equation
        dae1 = instEqEquation2(lhs_idx, rhs_idx, t, inConst, inSource, inInitial);
        dae2 = instArrayElEq(lhs, rhs, t, inConst, lhs_idxs, rhs_idxs, inSource, inInitial);
        dae1 = DAEUtil.joinDaes(dae1, dae2);
      then
        dae1;
  end match;
end instArrayElEq;

protected function unrollForLoop
"@author: adrpo
 unroll for loops that contains when statements"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input String iterator;
  input Option<Absyn.Exp> range;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) := matchcontinue(inCache,inEnv,inIH,inPrefix,ci_state,iterator,range,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
      Env.Cache cache;
      Env.Env env,env_1;
      Prefix.Prefix pre;
      list<SCode.Statement> sl;
      SCode.Initial initial_;
      Boolean impl;
      DAE.Exp e_1;
      list<DAE.Statement> stmts;
      String i, str;
      Absyn.Exp e;
      DAE.Properties prop;
      Values.Value v;
      DAE.Const cnst;
      DAE.Type id_t;
      InstanceHierarchy ih;

    // only one iterator
    case (cache,env,ih,pre,_,i,SOME(e),sl,_,_,initial_,impl,_)
      equation
        (cache,e_1,prop as DAE.PROP(DAE.T_ARRAY(ty = id_t),cnst),_) = Static.elabExp(cache, env, e, impl,NONE(), true, pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        // we can unroll ONLY if we have a constant/parameter range expression
        true = listMember(cnst, {DAE.C_CONST(), DAE.C_PARAM()});
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,DAE.ATTR(connectorType = SCode.POTENTIAL(), parallelism = SCode.NON_PARALLEL()),_,DAE.UNBOUND(),_,_,_,_,_)
        = Lookup.lookupVar(cache, env_1, ComponentReference.makeCrefIdent(i,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,v,_) = Ceval.ceval(cache, env_1, e_1, impl, NONE(), Absyn.MSG(info), 0) "FIXME: Check bounds";
        (cache,stmts) = loopOverRange(cache, env_1, ih, pre, ci_state, i, v, sl, source, initial_, impl, unrollForLoops);
      then
        (cache,stmts);

    // failure
    case (_,_,_,_,_,_,_,sl,_,_,_,_,_)
      equation
        // only report errors for when in for loops
        // true = containsWhenStatements(sl);
        str = Dump.unparseAlgorithmStr(
               SCode.statementToAlgorithmItem(SCode.ALG_FOR(iterator, range, sl,SCode.noComment,info)));
        Error.addSourceMessage(Error.UNROLL_LOOP_CONTAINING_WHEN, {str}, info);
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.unrollForLoop failed on: " +& str);
      then
        fail();
  end matchcontinue;
end unrollForLoop;

protected function instForStatement
"Helper function for instStatement"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input String iterator;
  input Option<Absyn.Exp> range;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) := matchcontinue(inCache,inEnv,inIH,inPrefix,ci_state,iterator,range,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
      Env.Cache cache;
      Env.Env env;
      Prefix.Prefix pre;
      list<SCode.Statement> sl;
      SCode.Initial initial_;
      Boolean impl;
      list<DAE.Statement> stmts;
      InstanceHierarchy ih;

    // adrpo: unroll ALL for loops containing ALG_WHEN... done
    case (cache,env,ih,pre,_,_,_,sl,_,_,initial_,impl,_)
      equation
        // check here that we have a when loop in the for statement.
        true = containsWhenStatements(sl);
        (cache,stmts) = unrollForLoop(cache,env,ih,pre,ci_state,iterator,range,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);

    // for loops not containing ALG_WHEN
    case (cache,env,ih,pre,_,_,_,sl,_,_,initial_,impl,_)
      equation
        // do not unroll if it doesn't contain a when statement!
        false = containsWhenStatements(sl);
        (cache,stmts) = instForStatement_dispatch(cache,env,ih,pre,ci_state,iterator,range,sl,info,source,initial_,impl,unrollForLoops);
        stmts = replaceLoopDependentCrefs(stmts, iterator, range);
      then
        (cache,stmts);

  end matchcontinue;
end instForStatement;

protected function replaceLoopDependentCrefs
  "Replaces all DAE.CREFs that are dependent on a loop variable with a
  DAE.ASUB."
  input list<DAE.Statement> inStatements;
  input String iterator;
  input Option<Absyn.Exp> range;
  output list<DAE.Statement> outStatements;
algorithm
  (outStatements, _) := DAEUtil.traverseDAEEquationsStmts(inStatements,
      replaceLoopDependentCrefInExp, {Absyn.ITERATOR(iterator,NONE(),range)});
end replaceLoopDependentCrefs;

protected function replaceLoopDependentCrefInExp
  "Helper function for replaceLoopDependentCrefs."
  input tuple<DAE.Exp,Absyn.ForIterators> itpl;
  output tuple<DAE.Exp,Absyn.ForIterators> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp cr_exp,expCref;
      DAE.ComponentRef cr;
      DAE.Type cr_type;
      list<DAE.Subscript> cref_subs;
      list<DAE.Exp> exp_subs;
      Absyn.ForIterators fi;

    case ((DAE.CREF(componentRef = cr), fi))
      equation
        cref_subs = ComponentReference.crefSubs(cr);
        exp_subs = List.map(cref_subs, Expression.subscriptIndexExp);
        true = isSubsLoopDependent(exp_subs, fi);
        cr = ComponentReference.crefStripSubs(cr);
        cr_type = ComponentReference.crefLastType(cr);
        expCref = Expression.makeCrefExp(cr, cr_type);
      then
        ((Expression.makeASUB(expCref, exp_subs), fi));
    case _ then itpl;
  end matchcontinue;
end replaceLoopDependentCrefInExp;

protected function isSubsLoopDependent
  "Checks if a list of subscripts contain any of a list of iterators."
  input list<DAE.Exp> subscripts;
  input Absyn.ForIterators iterators;
  output Boolean loopDependent;
algorithm
  loopDependent := matchcontinue(subscripts, iterators)
    local
      Absyn.Ident iter_name;
      DAE.Exp iter_exp;
      DAE.ComponentRef cref_;
      Absyn.ForIterators rest_iters;
      Boolean res;
    case (_, {}) then false;
    case (_, Absyn.ITERATOR(name = iter_name) :: _)
      equation
        cref_ = ComponentReference.makeCrefIdent(iter_name, DAE.T_INTEGER_DEFAULT, {});
        iter_exp = Expression.makeCrefExp(cref_, DAE.T_INTEGER_DEFAULT);
        true = isSubsLoopDependentHelper(subscripts, iter_exp);
      then
        true;
    case (_, _ :: rest_iters)
      equation
        res = isSubsLoopDependent(subscripts, rest_iters);
      then
        res;
  end matchcontinue;
end isSubsLoopDependent;

protected function isSubsLoopDependentHelper
  "Helper for isLoopDependent.
  Checks if a list of subscripts contains a certain iterator expression."
  input list<DAE.Exp> subscripts;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(subscripts, iteratorExp)
    local
      DAE.Exp subscript;
      list<DAE.Exp> rest;
    case ({}, _) then false;
    case (subscript :: _, _)
      equation
        true = Expression.expContains(subscript, iteratorExp);
      then true;
    case (_ :: rest, _)
      equation
        true = isSubsLoopDependentHelper(rest, iteratorExp);
      then true;
    else false;
  end matchcontinue;
end isSubsLoopDependentHelper;

protected function instForStatement_dispatch
"function for instantiating a for statement"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input String iterator;
  input Option<Absyn.Exp> range;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource inSource;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) :=
  matchcontinue(inCache,inEnv,inIH,inPrefix,ci_state,iterator,range,inForBody,info,inSource,inInitial,inBool,unrollForLoops)
    local
      Env.Cache cache;
      Env.Env env,env_1;
      Prefix.Prefix pre;
      list<SCode.Statement> sl;
      SCode.Initial initial_;
      Boolean impl;
      DAE.Type t;
      DAE.Exp e_1,e_2;
      list<DAE.Statement> sl_1;
      String i;
      Absyn.Exp e;
      DAE.Statement stmt;
      DAE.Properties prop;
      list<tuple<Absyn.ComponentRef,Integer>> lst;
      tuple<Absyn.ComponentRef, Integer> tpl;
      DAE.Const cnst;
      InstanceHierarchy ih;
      DAE.ElementSource source;

    // empty range, i.e. 1:0, return nothing!
    case (cache,env,_,pre,_,_,SOME(e),_,_,_,_,impl,_)
      equation
        (cache,e_1,(prop as DAE.PROP(_,cnst)),_) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl, info);

        // only do this if the range is parameter or constant!
        true = listMember(cnst, {DAE.C_CONST(), DAE.C_PARAM()});
        // is empty range array?
        (cache, Values.ARRAY(valueLst = {}), _) = Ceval.ceval(cache, env, e_1, impl, NONE(), Absyn.MSG(info), 0);
      then
        (cache,{});

    // one iterator
    case (cache,env,ih,pre,_,i,SOME(e),sl,_,source,initial_,impl,_)
      equation
        (cache,e_1,(prop as DAE.PROP(t,cnst)),_) = Static.elabExp(cache, env, e, impl,NONE(), true, pre, info);
        t = getIteratorType(t,i,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache, env_1, ih, pre, ci_state, sl, source, initial_, impl, unrollForLoops, {});
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1, source);
      then
        (cache,{stmt});

    case (cache,env,ih,pre,_,i,NONE(),sl,_,source,initial_,impl,_) //The verison w/o assertions
      equation
        // false = containsWhenStatements(sl);
        (lst as _::_) = SCode.findIteratorInStatements(i,sl);
        tpl=List.first(lst);
        // e = Absyn.RANGE(1,NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP(t,cnst)),_) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        t = getIteratorType(t,i,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache,env_1,ih,pre,ci_state,sl,source,initial_,impl,unrollForLoops,{});
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1, source);
      then
        (cache,{stmt});

  end matchcontinue;
end instForStatement_dispatch;

protected function instComplexEquation "instantiate a comlex equation, i.e. c = Complex(1.0,-1.0) when Complex is a record"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type tp;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial initial_;
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(lhs,rhs,tp,source,initial_)
    local
      String s;
      Absyn.Info info;

    // Records
    case(_,_,_,_,_)
      equation
        true = Types.isRecord(tp);
        dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
      then dae;

    // External objects are treated as ordinary equations
    case (_,_,_,_,_)
      equation
        true = Types.isExternalObject(tp);
        dae = makeDaeEquation(lhs,rhs,source,initial_);
        // adrpo: TODO! FIXME! shouldn't we return the dae here??!!
      // PA: do not know, but at least return the functions.
      then DAE.emptyDae;

    // adrpo 2009-05-15: also T_COMPLEX that is NOT record but TYPE should be allowed
    //                   as is used in Modelica.Mechanics.MultiBody (Orientation type)
    case(_,_,_,_,_) equation
      // adrpo: TODO! check if T_COMPLEX(ClassInf.TYPE)!
      dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
    then dae;

    // complex equation that is not of restriction record is not allowed
    else
      equation
        false = Types.isRecord(tp);
        s = ExpressionDump.printExpStr(lhs) +& " = " +& ExpressionDump.printExpStr(rhs);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.ILLEGAL_EQUATION_TYPE, {s}, info);
      then fail();
  end matchcontinue;
end instComplexEquation;

protected function makeComplexDaeEquation "Creates a DAE.COMPLEX_EQUATION for equations involving records"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial initial_;
  output DAE.DAElist dae;
algorithm
  dae := match(lhs,rhs,source,initial_)
    local
    case(_,_,_,SCode.NON_INITIAL())
      then DAE.DAE({DAE.COMPLEX_EQUATION(lhs,rhs,source)});

    case(_,_,_,SCode.INITIAL())
      then DAE.DAE({DAE.INITIAL_COMPLEX_EQUATION(lhs,rhs,source)});
  end match;
end makeComplexDaeEquation;

public function instAlgorithm
"Algorithms are converted to the representation defined in
  the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.AlgorithmSection inAlgorithm;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,unrollForLoops,inGraph)
    local
      Env.Env env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<SCode.Statement> statements;
      SCode.Statement stmt;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      SCode.AlgorithmSection algSCode;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.DAElist dae;
      String s;
      Absyn.Info info;

    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements),impl,_,graph) /* impl */
      equation
        // set the source of this element
        ci_state = ClassInf.trans(ci_state,ClassInf.FOUND_ALGORITHM());
        source = DAEUtil.createElementSource(Absyn.dummyInfo, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        (cache,statements_1) = instStatements(cache, env, ih, pre, ci_state, statements, source, SCode.NON_INITIAL(), impl, unrollForLoops, {});
        (statements_1,_) = DAEUtil.traverseDAEEquationsStmts(statements_1,Expression.traverseSubexpressionsHelper,(ExpressionSimplify.simplifyWork,ExpressionSimplifyTypes.optionSimplifyOnly));

        dae = DAE.DAE({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    case (_,_,_,_,_,_,ci_state,SCode.ALGORITHM(statements = stmt::_),_,_,_)
      equation
        failure(_ = ClassInf.trans(ci_state,ClassInf.FOUND_ALGORITHM()));
        s = ClassInf.printStateStr(ci_state);
        info = SCode.getStatementInfo(stmt);
        Error.addSourceMessage(Error.ALGORITHM_TRANSITION_FAILURE, {s}, info);
      then fail();

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instAlgorithm;

public function instInitialAlgorithm
"Algorithms are converted to the representation defined
  in the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.AlgorithmSection inAlgorithm;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,unrollForLoops,inGraph)
    local
      Env.Env env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<SCode.Statement> statements;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.DAElist dae;

    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements),impl,_,graph)
      equation
        // set the source of this element
        source = DAEUtil.createElementSource(Absyn.dummyInfo, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        (cache,statements_1) = instStatements(cache, env, ih, pre, ci_state, statements, source, SCode.INITIAL(), impl, unrollForLoops, {});
        (statements_1,_) = DAEUtil.traverseDAEEquationsStmts(statements_1,Expression.traverseSubexpressionsHelper,(ExpressionSimplify.simplifyWork,ExpressionSimplifyTypes.optionSimplifyOnly));

        dae = DAE.DAE({DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instInitialAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instInitialAlgorithm;

public function instConstraint
"Constraints are elaborated and converted to DAE"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input ClassInf.State inState;
  input SCode.ConstraintSection inConstraints;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output DAE.DAElist outDae;
  output ClassInf.State outState;
algorithm
  (outCache,outEnv,outDae,outState) :=
  matchcontinue (inCache,inEnv,inPrefix,inState,inConstraints,inBoolean)
    local
      Env.Env env;
      list<DAE.Exp> constraints_1;
      ClassInf.State ci_state;
      list<Absyn.Exp> constraints;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.ElementSource source "the origin of the element";
      DAE.DAElist dae;

    case (cache,env,pre,ci_state,SCode.CONSTRAINTS(constraints = constraints),impl)
      equation
        // set the source of this element
        ci_state = ClassInf.trans(ci_state,ClassInf.FOUND_ALGORITHM());
        source = DAEUtil.createElementSource(Absyn.dummyInfo, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        (cache,constraints_1,_,_) = Static.elabExpList(cache, env, constraints, impl, NONE(), true /*vect*/, pre, Absyn.dummyInfo);
        // (constraints_1,_) = DAEUtil.traverseDAEEquationsStmts(constraints_1,Expression.traverseSubexpressionsHelper,(ExpressionSimplify.simplifyWork,false));

        dae = DAE.DAE({DAE.CONSTRAINT(DAE.CONSTRAINT_EXPS(constraints_1),source)});
      then
        (cache,env,dae,ci_state);
/*
    case (_,_,_,_,_,_,ci_state,SCode.ALGORITHM(constraints = exp::_),_,_,_)
      equation
        failure(_ = ClassInf.trans(ci_state,ClassInf.FOUND_ALGORITHM()));
        s = ClassInf.printStateStr(ci_state);
        Error.addMessage(Error.ALGORITHM_TRANSITION_FAILURE,{s});
      then fail();
*/
    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instConstraints failed");
      then
        fail();
  end matchcontinue;
end instConstraint;

public function instStatements
"This function converts a list of algorithm statements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input ClassInf.State ci_state;
  input list<SCode.Statement> inAbsynAlgorithmLst;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input list<list<DAE.Statement>> acc;
  output Env.Cache outCache;
  output list<DAE.Statement> outAlgorithmStatementLst;
algorithm
  (outCache,outAlgorithmStatementLst) := match (inCache,inEnv,inIH,inPre,ci_state,inAbsynAlgorithmLst,source,initial_,inBoolean,unrollForLoops,acc)
    local
      Env.Env env;
      Boolean impl;
      list<DAE.Statement> stmts;
      SCode.Statement x;
      list<SCode.Statement> xs;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstanceHierarchy ih;

    // empty case
    case (cache,_,_,_,_,{},_,_,_,_,_)
      equation
        stmts = List.flatten(listReverse(acc));
      then (cache,stmts);

    // general case
    case (cache,env,ih,pre,_,(x :: xs),_,_,impl,_,_)
      equation
        (cache,stmts) = instStatement(cache, env, ih, pre, ci_state, x, source, initial_, impl, unrollForLoops);
        (cache,stmts) = instStatements(cache, env, ih, pre, ci_state, xs, source, initial_, impl, unrollForLoops, stmts::acc);
      then (cache,stmts);
  end match;
end instStatements;

protected function instStatement "
function: instStatement
  This function Looks at an algorithm statement and uses functions
  in the Algorithm module to build a representation of it that can
  be used in the DAE output."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input ClassInf.State ci_state;
  input SCode.Statement inAlgorithm;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "more statements due to loop unrolling";
algorithm
  (outCache,outStatements) := instStatement2(inCache,inEnv,inIH,inPre,ci_state,inAlgorithm,source,initial_,inBoolean,unrollForLoops,Error.getNumErrorMessages());
end instStatement;

protected function instStatement2 "
function: instStatement
  This function Looks at an algorithm statement and uses functions
  in the Algorithm module to build a representation of it that can
  be used in the DAE output."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input ClassInf.State ci_state;
  input SCode.Statement inAlgorithm;
  input DAE.ElementSource inSource;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input Integer numErrorMessages;
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "more statements due to loop unrolling";
algorithm
  (outCache,outStatements) :=
  matchcontinue (inCache,inEnv,inIH,inPre,ci_state,inAlgorithm,inSource,initial_,inBoolean,unrollForLoops,numErrorMessages)
    local
      DAE.Properties cprop,prop,msgprop,varprop,valprop,levelprop;
      DAE.Exp e_1,e_2,cond_1,cond_2,msg_1,msg_2,var_1,var_2,value_1,value_2,level_1,level_2;
      DAE.Statement stmt, stmt1;
      Env.Env env;
      Absyn.Exp e,cond,msg,level,var,value;
      Boolean impl;
      list<DAE.Statement> tb_1,fb_1,sl_1,stmts;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> eib_1;
      list<SCode.Statement> tb,fb,sl;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> eib,elseWhenRest;
      SCode.Statement alg;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstanceHierarchy ih;
      SCode.Comment comment;
      Absyn.Info info;
      list<DAE.Exp> eexpl;
      Absyn.Path ap;
      String str,iter;
      Option<Absyn.Exp> range;
      DAE.CallAttributes attr;
      DAE.ElementSource source;


    // assign
    case (cache,env,ih,pre,_,SCode.ALG_ASSIGN(info = _),source,_,impl,_,_)
      equation
        (cache,stmts) = instAssignment(cache,env,ih,pre,inAlgorithm,source,initial_,impl,unrollForLoops,Error.getNumErrorMessages());
      then (cache,stmts);

    // if statement
    case (cache,env,ih,pre,_,SCode.ALG_IF(boolExpr = e,trueBranch = tb,elseIfBranch = eib,elseBranch = fb,info = info),source,_,impl,_,_)
      equation
        (cache,e_1,prop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,tb_1)= instStatements(cache,env,ih,pre, ci_state, tb, source, initial_,impl,unrollForLoops,{});
        (cache,eib_1) = instElseIfs(cache,env,ih,pre, ci_state, eib, source, initial_,impl,unrollForLoops,info);
        (cache,fb_1) = instStatements(cache,env,ih,pre, ci_state, fb, source, initial_,impl,unrollForLoops,{});
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmts = Algorithm.makeIf(e_2, prop, tb_1, eib_1, fb_1, source);
      then
        (cache,stmts);

    // for loop
    case (cache,env,ih,pre,_,SCode.ALG_FOR(index = iter, range = range,forBody = sl,info = info),source,_,impl,_,_)
      equation
        (cache,stmts) = instForStatement(cache,env,ih,pre,ci_state,iter,range,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);

    // parfor loop
    case (cache,env,ih,pre,_,SCode.ALG_PARFOR(index = iter, range = range,parforBody = sl,info = info),source,_,impl,_,_)
      equation
        (cache,stmts) = instParForStatement(cache,env,ih,pre,ci_state,iter,range,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);

    // while loop
    case (cache,env,ih,pre,_,SCode.ALG_WHILE(boolExpr = e,whileBody = sl, info = info),source,_,impl,_,_)
      equation
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,sl_1) = instStatements(cache,env,ih,pre,ci_state,sl,source,initial_,impl,unrollForLoops,{});
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhile(e_2, prop, sl_1, source);
      then
        (cache,{stmt});

    // when clause without elsewhen
    case (cache,env,ih,pre,_,SCode.ALG_WHEN_A(branches = {(e,sl)}, info = info),source,_,impl,_,_)
      equation
        false = ClassInf.isFunction(ci_state);
        checkWhenAlgorithm(inAlgorithm);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,sl_1) = instStatements(cache, env, ih, pre, ci_state, sl, source, initial_, impl, unrollForLoops, {});
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, NONE(), source);
      then
        (cache,{stmt});

    // when clause with elsewhen branch
    case (cache,env,ih,pre,_,SCode.ALG_WHEN_A(branches = (e,sl)::(elseWhenRest as _::_), comment = comment, info = info),source,_,impl,_,_)
      equation
        false = ClassInf.isFunction(ci_state);
        checkWhenAlgorithm(inAlgorithm);
        (cache,{stmt1}) = instStatement(cache,env,ih,pre,ci_state,SCode.ALG_WHEN_A(elseWhenRest,comment,info),source,initial_,impl,unrollForLoops);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,sl_1) = instStatements(cache, env, ih, pre, ci_state, sl, source, initial_, impl, unrollForLoops, {});
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, SOME(stmt1), source);
      then
        (cache,{stmt});

    // assert(cond,msg)
    case (cache,env,ih,pre,_,SCode.ALG_NORETCALL(exp=Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg},argNames = {})), info = info),source,_,impl,_,_)
      equation
        (cache,cond_1,cprop,_) = Static.elabExp(cache, env, cond, impl,NONE(), true,pre,info);
        (cache,msg_1,msgprop,_) = Static.elabExp(cache, env, msg, impl,NONE(), true,pre,info);
        (cache, cond_1, cprop) = Ceval.cevalIfConstant(cache, env, cond_1, cprop, impl, info);
        (cache, msg_1, msgprop) = Ceval.cevalIfConstant(cache, env, msg_1, msgprop, impl, info);
        (cache,cond_2) = PrefixUtil.prefixExp(cache, env, ih, cond_1, pre);
        (cache,msg_2) = PrefixUtil.prefixExp(cache, env, ih, msg_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmts = Algorithm.makeAssert(cond_2, msg_2, DAE.ASSERTIONLEVEL_ERROR, cprop, msgprop, DAE.PROP(DAE.T_ASSERTIONLEVEL,DAE.C_CONST()), source);
      then
        (cache,stmts);

    // assert(cond,msg,level)
    case (cache,env,ih,pre,_,SCode.ALG_NORETCALL(exp=Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg,level},argNames = {})), info = info),source,_,impl,_,_)
      equation
        (cache,cond_1,cprop,_) = Static.elabExp(cache, env, cond, impl,NONE(), true,pre,info);
        (cache,msg_1,msgprop,_) = Static.elabExp(cache, env, msg, impl,NONE(), true,pre,info);
        (cache,level_1,levelprop,_) = Static.elabExp(cache, env, level, impl,NONE(), true,pre,info);
        (cache, cond_1, cprop) = Ceval.cevalIfConstant(cache, env, cond_1, cprop, impl, info);
        (cache, msg_1, msgprop) = Ceval.cevalIfConstant(cache, env, msg_1, msgprop, impl, info);
        (cache, level_1, levelprop) = Ceval.cevalIfConstant(cache, env, level_1, levelprop, impl, info);
        (cache,cond_2) = PrefixUtil.prefixExp(cache, env, ih, cond_1, pre);
        (cache,msg_2) = PrefixUtil.prefixExp(cache, env, ih, msg_1, pre);
        (cache,level_2) = PrefixUtil.prefixExp(cache, env, ih, level_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmts = Algorithm.makeAssert(cond_2, msg_2, level_2, cprop, msgprop, levelprop, source);
      then
        (cache,stmts);

    // assert(cond,msg,level)
    case (cache,env,ih,pre,_,SCode.ALG_NORETCALL(exp=Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg},argNames = {Absyn.NAMEDARG("level",level)})), comment = comment, info = info),source,_,impl,_,_)
      equation
        (cache,stmts) = instStatement2(cache,env,ih,pre,ci_state,SCode.ALG_NORETCALL(Absyn.CALL(Absyn.CREF_IDENT("assert",{}),Absyn.FUNCTIONARGS({cond,msg,level},{})),comment,info),source,initial_,impl,unrollForLoops,numErrorMessages);
      then
        (cache,stmts);

    // terminate(msg)
    case (cache,env,ih,pre,_,SCode.ALG_NORETCALL(exp=Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "terminate"),
          functionArgs = Absyn.FUNCTIONARGS(args = {msg},argNames = {})), info = info),source,_,impl,_,_)
      equation
        (cache,msg_1,msgprop,_) = Static.elabExp(cache, env, msg, impl,NONE(), true,pre,info);
        (cache, msg_1, msgprop) = Ceval.cevalIfConstant(cache, env, msg_1, msgprop, impl, info);
        (cache,msg_2) = PrefixUtil.prefixExp(cache, env, ih, msg_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeTerminate(msg_2, msgprop, source);
      then
        (cache,{stmt});

    // reinit(variable,value)
    case (cache,env,ih,pre,_,SCode.ALG_NORETCALL(exp=Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "reinit"),
          functionArgs = Absyn.FUNCTIONARGS(args = {var,value},argNames = {})), info = info),source,_,impl,_,_)
      equation
        false = ClassInf.isFunction(ci_state);
        (cache,var_1,varprop,_) = Static.elabExp(cache, env, var, impl,NONE(), true,pre,info);
        (cache, var_1, varprop) = Ceval.cevalIfConstant(cache, env, var_1, varprop, impl, info);
        (cache,var_2) = PrefixUtil.prefixExp(cache, env, ih, var_1, pre);
        (cache,value_1,valprop,_) = Static.elabExp(cache, env, value, impl,NONE(), true,pre,info);
        (cache, value_1, valprop) = Ceval.cevalIfConstant(cache, env, value_1, valprop, impl, info);
        (cache,value_2) = PrefixUtil.prefixExp(cache, env, ih, value_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeReinit(var_2, value_2, varprop, valprop, source);
      then
        (cache,{stmt});

    // generic NORETCALL
    case (cache,env,ih,pre,_,(SCode.ALG_NORETCALL(exp = e, info = info)),source,_,impl,_,_)
      equation
        failure(Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "reinit")) = e);
        failure(Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "assert")) = e);
        failure(Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "terminate")) = e);
        (cache, e_1, _, _) = Static.elabExp(cache, env, e, impl, NONE(), true, pre, info);
        checkValidNoRetcall(e_1,info);
        (cache,e_1) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_NORETCALL(e_1,source);
      then
        (cache,{stmt});

    /// break
    case (cache,_,_,_,_,SCode.ALG_BREAK( info = info),source,_,_,_,_)
      equation
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_BREAK(source);
      then
        (cache,{stmt});

    // return
    case (cache,_,_,_,ClassInf.FUNCTION(path=_),SCode.ALG_RETURN( info = info),source,_,_,_,_)
      equation
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_RETURN(source);
      then
        (cache,{stmt});

    //------------------------------------------
    // part of MetaModelica extension.
    //------------------------------------------
    case (cache,env,ih,pre,_,SCode.ALG_FAILURE(stmts = sl,  info = info),source,_,impl,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,sl_1) = instStatements(cache,env,ih,pre,ci_state,sl,source,initial_,impl,unrollForLoops,{});
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_FAILURE(sl_1,source);
      then
        (cache,{stmt});

    // error handling
    case (_,_,_,_,_,alg,_,_,_,_,_)
      equation
        true = numErrorMessages == Error.getNumErrorMessages();
        str = Dump.unparseAlgorithmStr(SCode.statementToAlgorithmItem(alg));
        Error.addSourceMessage(Error.STATEMENT_GENERIC_FAILURE,{str},SCode.getStatementInfo(alg));
      then
        fail();
  end matchcontinue;
end instStatement2;

protected function makeAssignment
  "Wrapper for Algorithm that calls either makeAssignment or makeTupleAssignment
  depending on whether the right side is a tuple or not. This makes it possible
  to do cref := function_that_returns_tuple(...)."
  input DAE.Exp inLhs;
  input DAE.Properties inLhsProps;
  input DAE.Exp inRhs;
  input DAE.Properties inRhsProps;
  input DAE.Attributes inAttributes;
  input SCode.Initial inInitial;
  input DAE.ElementSource inSource;
  output DAE.Statement outStatement;
algorithm
  outStatement := match (inLhs, inLhsProps, inRhs, inRhsProps, inAttributes, inInitial, inSource)
    local
      list<DAE.Properties> wild_props;
      Integer wild_count;
      list<DAE.Exp> wilds;
      DAE.Exp wildCrefExp;

    // If the RHS is a function that returns a tuple while the LHS is a single
    // value, make a tuple of the LHS and fill in the missing elements with
    // wildcards.
    case (_, DAE.PROP(type_ = _), DAE.CALL(path = _), DAE.PROP_TUPLE(type_ = _), _, _, _)
      equation
        _ :: wild_props = Types.propTuplePropList(inRhsProps);
        wild_count = listLength(wild_props);
        wildCrefExp = Expression.makeCrefExp(DAE.WILD(), DAE.T_UNKNOWN_DEFAULT);
        wilds = List.fill(wildCrefExp, wild_count);
        wild_props = List.fill(DAE.PROP(DAE.T_ANYTYPE_DEFAULT, DAE.C_VAR()), wild_count);
      then
        Algorithm.makeTupleAssignment(inLhs :: wilds, inLhsProps :: wild_props, inRhs, inRhsProps, inInitial, inSource);

    // Otherwise, call Algorithm.makeAssignment as usual.
    else Algorithm.makeAssignment(inLhs, inLhsProps, inRhs, inRhsProps, inAttributes, inInitial, inSource);
  end match;
end makeAssignment;

protected function containsWhenStatements
"@author: adrpo
  this functions returns true if the given
  statement list contains when statements"
  input list<SCode.Statement> statementList;
  output Boolean hasWhenStatements;
algorithm
  hasWhenStatements := matchcontinue(statementList)
    local
      list<SCode.Statement> rest, tb, eb, lst;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> eib;
      Boolean b, b1, b2, b3, b4; list<Boolean> blst;
      list<list<SCode.Statement>> slst;

    // handle nothingness
    case ({}) then false;

    // yeha! we have a when!
    case (SCode.ALG_WHEN_A(branches=_)::_)
      then true;

    // search deeper inside if
    case (SCode.ALG_IF(trueBranch=tb, elseIfBranch=eib, elseBranch=eb)::rest)
      equation
         b1 = containsWhenStatements(tb);
         b2 = containsWhenStatements(eb);
         slst = List.map(eib, Util.tuple22);
         blst = List.map(slst, containsWhenStatements);
         // adrpo: add false to handle the case where list might be empty
         b3 = List.reduce(false::blst, boolOr);
         b4 = containsWhenStatements(rest);
         b = List.reduce({b1, b2, b3, b4}, boolOr);
      then b;

    // search deeper inside for
    case (SCode.ALG_FOR(forBody = lst)::rest)
      equation
         b1 = containsWhenStatements(lst);
         b2 = containsWhenStatements(rest);
         b = boolOr(b1, b2);
      then b;

    // search deeper inside parfor
    case (SCode.ALG_PARFOR(parforBody = lst)::rest)
      equation
         b1 = containsWhenStatements(lst);
         b2 = containsWhenStatements(rest);
         b = boolOr(b1, b2);
      then b;

    // search deeper inside for
    case (SCode.ALG_WHILE(whileBody = lst)::rest)
      equation
         b1 = containsWhenStatements(lst);
         b2 = containsWhenStatements(rest);
         b  = boolOr(b1, b2);
      then b;

    // not a when, move along
    case (_::rest)
      then containsWhenStatements(rest);
  end matchcontinue;
end containsWhenStatements;

protected function loopOverRange
"@author: adrpo
  Unrolling a for loop is explicitly repeating
  the body of the loop once for each iteration."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input Ident inIdent;
  input Values.Value inValue;
  input list<SCode.Statement> inAlgItmLst;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) :=
  matchcontinue (inCache,inEnv,inIH,inPrefix,ci_state,inIdent,inValue,inAlgItmLst,source,inInitial,inBoolean,unrollForLoops)
    local
      Env.Env env_1,env_2,env;
      Prefix.Prefix pre;
      String i;
      Values.Value fst,v;
      list<Values.Value> rest;
      list<SCode.Statement> algs;
      SCode.Initial initial_;
      Boolean impl;
      Env.Cache cache;
      list<Integer> dims;
      Integer dim;
      list<DAE.Statement> stmts, stmts1, stmts2;
      InstanceHierarchy ih;

    // handle empty
    case (cache,_,_,_,_,_,Values.ARRAY(valueLst = {}),_,_,_,_,_)
      then (cache,{});

    // array equation, use instAlgorithms
    case (cache,env,ih,pre,_,i,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),
          algs,_,initial_,impl,_)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(fst, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        /* use instEEquation*/
        (cache,stmts1) = instStatements(cache, env_2, ih, pre, ci_state, algs, source, initial_, impl, unrollForLoops, {});
        (cache,stmts2) = loopOverRange(cache, env, ih, pre, ci_state, i, Values.ARRAY(rest,dims), algs, source, initial_, impl, unrollForLoops);
        stmts = listAppend(stmts1, stmts2);
      then
        (cache,stmts);

    case (_,_,_,_,_,_,v,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.loopOverRange failed to loop over range: " +& ValuesUtil.valString(v));
      then
        fail();
  end matchcontinue;
end loopOverRange;

protected function rangeExpression "
The function takes a tuple of Absyn.ComponentRef (an array variable) and an integer i
and constructs the range expression (Absyn.Exp) for the ith dimension of the variable"
  input tuple<Absyn.ComponentRef, Integer> inTuple;
  output Absyn.Exp outExp;
algorithm
  outExp := match(inTuple)
    local
      Absyn.Exp e;
      Absyn.ComponentRef acref;
      Integer dimNum;
      tuple<Absyn.ComponentRef, Integer> tpl;

    case ((acref,dimNum))
      equation
        e=Absyn.RANGE(Absyn.INTEGER(1),NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
      then e;
  end match;
end rangeExpression;

protected function instIfTrueBranches
"Author: BZ, 2008-09
 Initialise a list of if-equations,
 if, elseif-1 ... elseif-n."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input list<list<SCode.EEquation>> inTypeALst;
  input Boolean IE;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output list<list<DAE.Element>> outDaeLst;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDaeLst,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inTypeALst,IE,inBoolean,inGraph)
    local
      Env.Env env,env_1,env_2;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      Boolean impl;
      list<list<DAE.Element>> llb;
      list<list<SCode.EEquation>> es;
      list<SCode.EEquation> e;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<DAE.Element> elts;

    case (cache,env,ih,_,_,csets,ci_state,{},_,_,graph)
      then
        (cache,env,ih,{},csets,ci_state,graph);
    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),false,impl,graph)
      equation
        (cache,env_1,ih,DAE.DAE(elts),csets_1,ci_state_1,graph) =
           Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEEquation, e, impl, alwaysUnroll, graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) =
           instIfTrueBranches(cache, env_1, ih, mod, pre, csets_1, ci_state_1,  es, false, impl, graph);
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);

    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),true,impl,graph)
      equation
        (cache,env_1,ih,DAE.DAE(elts),csets_1,ci_state_1,graph) =
           Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEInitialEquation, e, impl, alwaysUnroll, graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) =
           instIfTrueBranches(cache, env_1, ih, mod, pre, csets_1, ci_state_1,  es, true, impl, graph);
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);

    case (_,_,_,_,_,_,_,(e :: _),_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "InstSection.instIfTrueBranches failed on equations: " +&
                       stringDelimitList(List.map1(e, SCodeDump.equationStr, SCodeDump.defaultOptions), "\n"));
      then
        fail();
  end matchcontinue;
end instIfTrueBranches;

protected function instElseIfs
"This function helps instStatement to handle elseif parts."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input ClassInf.State ci_state;
  input list<tuple<Absyn.Exp, list<SCode.Statement>>> inElseIfBranches;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> outElseIfBranches;
algorithm
  (outCache,outElseIfBranches) :=
  matchcontinue (inCache,inEnv,inIH,inPre,ci_state,inElseIfBranches,source,initial_,inBoolean,unrollForLoops,info)
    local
      Env.Env env;
      Boolean impl;
      DAE.Exp e_1,e_2;
      DAE.Properties prop;
      list<DAE.Statement> stmts;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> tail_1;
      Absyn.Exp e;
      list<SCode.Statement> l;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> tail;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstanceHierarchy ih;

    case (cache,_,_,_,_,{},_,_,_,_,_) then (cache,{});

    case (cache,env,ih,pre,_,((e,l) :: tail),_,_,impl,_,_)
      equation
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,stmts) = instStatements(cache, env, ih, pre, ci_state, l, source, initial_, impl, unrollForLoops, {});
        (cache,tail_1) = instElseIfs(cache,env,ih,pre,ci_state,tail, source, initial_, impl, unrollForLoops,info);
      then
        (cache,(e_2,prop,stmts) :: tail_1);

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instElseIfs failed");
      then
        fail();
  end matchcontinue;
end instElseIfs;

protected function instConnect "
  Generates connectionsets for connections.
  Parameters and constants in connectors should generate appropriate assert statements.
  Hence, a DAE.Element list is returned as well."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input Boolean inImplicit;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inImplicit,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2;
      DAE.Type t1,t2;
      DAE.Properties prop1,prop2;
      DAE.Attributes attr1,attr2;
      SCode.ConnectorType ct1, ct2;
      Boolean impl;
      DAE.Type ty1,ty2;
      Connect.Face f1,f2;
      Connect.Sets sets;
      DAE.DAElist dae;
      Env.Env env;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Parallelism prl1,prl2;
      SCode.Variability vt1,vt2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<Absyn.Subscript> subs1,subs2;
      list<Absyn.ComponentRef> crefs1,crefs2;
      String s1,s2;

    // adrpo: check for connect(A, A) as we should give a warning and remove it!
    case (cache,env,ih,sets,_,c1,c2,_,graph,_)
      equation
        true = Absyn.crefEqual(c1, c2);
        s1 = Dump.printComponentRefStr(c1);
        s2 = Dump.printComponentRefStr(c1);
        Error.addSourceMessage(Error.SAME_CONNECT_INSTANCE, {s1, s2}, info);
      then
        (cache, env, ih, sets, DAE.emptyDae, graph);

    // Check if either of the components are conditional components with
    // condition = false, in which case we should not instantiate the connection.
    case (cache,env,ih,sets,_,c1,c2,_,graph,_)
      equation
        c1_1 = ComponentReference.toExpCref(c1);
        c2_1 = ComponentReference.toExpCref(c2);
        true = ConnectUtil.connectionContainsDeletedComponents(c1_1, c2_1, sets);
      then
        (cache, env, ih, sets, DAE.emptyDae, graph);

    // adrpo: handle expandable connectors!
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,_)
      equation
        ErrorExt.setCheckpoint("expandableConnectors");
        true = System.getHasExpandableConnectors();
        (cache,env,ih,sets,dae,graph) = connectExpandableConnectors(cache, env, ih, sets, pre, c1, c2, impl, graph, info);
        ErrorExt.rollBack("expandableConnectors");
      then
        (cache,env,ih,sets,dae,graph);

    // handle normal connectors!
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,_)
      equation
        ErrorExt.rollBack("expandableConnectors");
        // Skip collection of dae functions here they can not be present in connector references
        (cache,SOME((DAE.CREF(c1_1,_),_,attr1))) = Static.elabCrefNoEval(cache,env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,_),_,attr2))) = Static.elabCrefNoEval(cache,env, c2, impl, false, pre, info);

        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr1 as DAE.ATTR(ct1,_,vt1,_,io1,_),ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2 as DAE.ATTR(_,_,vt2,_,io2,_),ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        validConnector(ty1, c1_2, info) "Check that the type of the connectors are good." ;
        validConnector(ty2, c2_2, info);
        f1 = ConnectUtil.componentFace(env,ih,c1_2);
        f2 = ConnectUtil.componentFace(env,ih,c2_2);

        ty1 = sortConnectorType(ty1);
        ty2 = sortConnectorType(ty2);

        checkConnectTypes(c1_2, ty1, f1, attr1, c2_2, ty2, f2, attr2, info);
        // print("add connect(");print(ComponentReference.printComponentRefStr(c1_2));print(", ");print(ComponentReference.printComponentRefStr(c2_2));
        // print(") with ");print(Dump.unparseInnerouterStr(io1));print(", ");print(Dump.unparseInnerouterStr(io2));
        // print("\n");
        (cache,_,ih,sets,dae,graph) =
          connectComponents(cache, env, ih, sets, pre, c1_2, f1, ty1, vt1, c2_2, f2, ty2, vt2, ct1, io1, io2, graph, info);
        sets = ConnectUtil.increaseConnectRefCount(c1_2, c2_2, sets);
      then
        (cache,env,ih,sets,dae,graph);

    // Case to display error for non constant subscripts in connectors
    case (cache,env,_,_,pre,c1,c2,_,_,_)
      equation
        subs1 = Absyn.getSubsFromCref(c1,true,true);
        crefs1 = Absyn.getCrefsFromSubs(subs1,true,true);
        subs2 = Absyn.getSubsFromCref(c2,true,true);
        crefs2 = Absyn.getCrefsFromSubs(subs2,true,true);
        //print("Crefs in " +& Dump.printComponentRefStr(c1) +& ": " +& stringDelimitList(List.map(crefs1,Dump.printComponentRefStr),", ") +& "\n");
        //print("Crefs in " +& Dump.printComponentRefStr(c2) +& ": " +& stringDelimitList(List.map(crefs2,Dump.printComponentRefStr),", ") +& "\n");
        s1 = Dump.printComponentRefStr(c1);
        s2 = Dump.printComponentRefStr(c2);
        s1 = "connect("+&s1+&", "+&s2+&")";
        checkConstantVariability(crefs1,cache,env,s1,pre,info);
        checkConstantVariability(crefs2,cache,env,s1,pre,info);
      then
        fail();

    case (_,_,_,_,_,c1,c2,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.instConnect failed for: connect(" +&
          Dump.printComponentRefStr(c1) +& ", " +&
          Dump.printComponentRefStr(c2) +& ")");
      then
        fail();
  end matchcontinue;
end instConnect;

protected function sortConnectorType
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      DAE.Type ty;
      DAE.Dimensions dims;
      DAE.TypeSource source;
      ClassInf.State ci_state;
      list<DAE.Var> vars;
      DAE.EqualityConstraint ec;

    case DAE.T_ARRAY(ty, dims, source)
      equation
        ty = sortConnectorType(ty);
      then
        DAE.T_ARRAY(ty, dims, source);

    case DAE.T_COMPLEX(ci_state, vars, ec, source)
      equation
        vars = List.sort(vars, connectorCompGt);
      then
        DAE.T_COMPLEX(ci_state, vars, ec, source);

    else inType;

  end match;
end sortConnectorType;

protected function connectorCompGt
  input DAE.Var inVar1;
  input DAE.Var inVar2;
  output Boolean outGt;
protected
  DAE.Ident id1, id2;
algorithm
  DAE.TYPES_VAR(name = id1) := inVar1;
  DAE.TYPES_VAR(name = id2) := inVar2;
  outGt := (1 == stringCompare(id1, id2));
end connectorCompGt;

protected function checkConstantVariability "
Author BZ, 2009-09
  Helper function for instConnect, prints error message for the case with non constant(or parameter) subscript(/s)"
  input list<Absyn.ComponentRef> inrefs;
  input Env.Cache cache;
  input Env.Env env;
  input String affectedConnector;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
algorithm
  _ := matchcontinue(inrefs,cache,env,affectedConnector,inPrefix,info)
  local
    Absyn.ComponentRef cr;
    DAE.Properties prop;
    DAE.Const const;
    Prefix.Prefix pre;
    String s1;
    list<Absyn.ComponentRef> refs;

  case({},_,_,_,_,_) then ();
  case(cr::refs,_,_,_,pre,_)
    equation
      (_,SOME((_,prop,_))) = Static.elabCref(cache,env,cr,false,false,pre,info);
      const = Types.propertiesListToConst({prop});
      true = Types.isParameterOrConstant(const);
      checkConstantVariability(refs,cache,env,affectedConnector,pre,info);
    then
      ();
  case(cr::_,_,_,_,pre,_)
    equation
      (_,SOME((_,prop,_))) = Static.elabCref(cache,env,cr,false,false,pre,info);
      const = Types.propertiesListToConst({prop});
      false = Types.isParameterOrConstant(const);
      //print(" error for: " +& affectedConnector +& " subscript: " +& Dump.printComponentRefStr(cr) +& " non constant \n");
      s1 = Dump.printComponentRefStr(cr);
      Error.addSourceMessage(Error.CONNECTOR_ARRAY_NONCONSTANT, {affectedConnector,s1}, info);
    then
      ();
end matchcontinue;
end checkConstantVariability;

protected function stringGte
  input String s1;
  input String s2;
  output Boolean b;
algorithm
  b := stringCompare(s1, s2) >= 0;
end stringGte;

protected function connectExpandableConnectors
"@author: adrpo
  this function handle the connections of expandable connectors"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inBoolean,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2, c1p,c2p;
      DAE.Type t1,t2;
      DAE.Properties prop1,prop2;
      DAE.Attributes attr1,attr2,attr;
      SCode.ConnectorType ct1, ct2;
      Boolean impl;
      DAE.Type ty1,ty2,ty;
      Connect.Sets sets;
      DAE.DAElist dae, daeExpandable;
      Env.Env env, envExpandable, envComponent, env1, env2, envComponentEmpty;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,c1_prefix;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Variability vt1,vt2;
      SCode.Parallelism prl1,prl2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String componentName;
      Absyn.Direction dir1,dir2;
      DAE.Binding binding;
      Option<DAE.Const> cnstForRange;
      InstTypes.SplicedExpData splicedExpData;
      ClassInf.State state;
      list<String> variables1, variables2, variablesUnion;
      DAE.ElementSource source;
      SCode.Visibility vis1, vis2;
      Absyn.ArrayDim arrDims;
      DAE.Dimensions daeDims;

    // both c1 and c2 are expandable
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,_)
      equation
        (cache,SOME((DAE.CREF(c1_1,_),_,attr1))) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,_),_,attr2))) = Static.elabCref(cache, env, c2, impl, false, pre, info);
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache, env, c2_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        DAE.ATTR(connectorType = SCode.POTENTIAL()) = attr1;
        DAE.ATTR(connectorType = SCode.POTENTIAL()) = attr2;
        true = isExpandableConnectorType(ty1);
        true = isExpandableConnectorType(ty2);

        // do the union of the connectors by adding the missing
        // components from one to the other and vice-versa.
        // Debug.fprintln(Flags.EXPANDABLE, ">>>> connect(expandable, expandable)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")" );

        // get the environments of the expandable connectors
        // which contain all the virtual components.
        (_,_,_,_,_,_,_,env1,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,env2,_) = Lookup.lookupVar(cache, env, c2_2);

        // Debug.fprintln(Flags.EXPANDABLE, "1 connect(expandable, expandable)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")" );

        // Debug.fprintln(Flags.EXPANDABLE, "env ===>\n" +& Env.printEnvStr(env));
        // Debug.fprintln(Flags.EXPANDABLE, "env(c1) ===>\n" +& Env.printEnvStr(env1));
        // Debug.fprintln(Flags.EXPANDABLE, "env(c2) ===>\n" +& Env.printEnvStr(env2));

        // get the virtual components
        variables1 = Env.getVariablesFromEnv(env1);
        // Debug.fprintln(Flags.EXPANDABLE, "Variables1: " +& stringDelimitList(variables1, ", "));
        variables2 = Env.getVariablesFromEnv(env2);
        // Debug.fprintln(Flags.EXPANDABLE, "Variables2: " +& stringDelimitList(variables2, ", "));
        variablesUnion = List.union(variables1, variables2);
        // sort so we have them in order
        variablesUnion = List.sort(variablesUnion, stringGte);
        // Debug.fprintln(Flags.EXPANDABLE, "Union of expandable connector variables: " +& stringDelimitList(variablesUnion, ", "));

        // Debug.fprintln(Flags.EXPANDABLE, "2 connect(expandable, expandable)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // then connect each of the components normally.
        (cache,env,ih,sets,dae,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,variablesUnion,impl,graph,info);

        // Debug.fprintln(Flags.EXPANDABLE, "<<<< connect(expandable, expandable)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

      then
        (cache,env,ih,sets,dae,graph);

    // c2 is expandable, forward to c1 expandable by switching arguments.
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,_)
      equation
        // c2 is expandable
        (cache,NONE()) = Static.elabCref(cache, env, c2, impl, false, pre, info);
        (cache,SOME((DAE.CREF(_,_),_,_))) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        // Debug.fprintln(Flags.EXPANDABLE, "connect(existing, expandable)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");
        (cache,env,ih,sets,dae,graph) = connectExpandableConnectors(cache,env,ih,sets,pre,c2,c1,impl,graph,info);
      then
        (cache,env,ih,sets,dae,graph);

    // c1 is expandable, catch error that c1 is an IDENT! it should be at least a.x
    case (cache,env,_,_,pre,c1 as Absyn.CREF_IDENT(name=_),c2,impl,_,_)
      equation
        // c1 is expandable
        (cache,NONE()) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        // adrpo: TODO! FIXME! add this as an Error not as a print!
        print("Error: The marked virtual expandable component reference in connect([" +&
         PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Absyn.printComponentRefStr(c1) +& "], " +&
         PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Absyn.printComponentRefStr(c2) +& "); should be qualified, i.e. expandableConnectorName.virtualName!\n");
      then
        fail();

    // c1 is expandable and c2 is existing BUT contains MORE THAN 1 component
    // c1 is expandable and SHOULD be qualified!
    case (cache,env,ih,sets,pre,c1 as Absyn.CREF_QUAL(name=_),c2,impl,graph,_)
      equation
        // c1 is expandable
        (cache,NONE()) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,_),_,attr2))) = Static.elabCref(cache, env, c2, impl, false, pre, info);

        // Debug.fprintln(Flags.EXPANDABLE, ">>>> connect(expandable, existing)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // lookup the existing connector
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        // bind the attributes
        DAE.ATTR(ct2,prl2,vt2,_,io2,vis2) = attr2;

        // Debug.fprintln(Flags.EXPANDABLE, "1 connect(expandable, existing)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // strip the last prefix!
        c1_prefix = Absyn.crefStripLast(c1);
        // elab expandable connector
        (cache,SOME((DAE.CREF(c1_1,_),_,_))) = Static.elabCref(cache,env,c1_prefix,impl,false,pre,info);
        // lookup the expandable connector
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,_,ty1) = Lookup.lookupConnectorVar(cache, env, c1_2);
        // make sure is expandable!
        true = isExpandableConnectorType(ty1);
        // strip last subs to get the full type!
        c1_2 = ComponentReference.crefStripLastSubs(c1_2);
        (_,attr,ty,binding,cnstForRange,_,_,envExpandable,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,envComponent,_) = Lookup.lookupVar(cache, env, c2_2);

        // we have more than 1 variables in the envComponent, we need to add an empty environment for c1
        // and dive into!
        variablesUnion = Env.getVariablesFromEnv(envComponent);
        // print("VARS MULTIPLE:" +& stringDelimitList(variablesUnion, ", ") +& "\n");
        // more than 1 variables
        true = listLength(variablesUnion) > 1;

        // Debug.fprintln(Flags.EXPANDABLE, "2 connect(expandable, existing[MULTIPLE])(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // get the virtual component name
        Absyn.CREF_IDENT(componentName, _) = Absyn.crefGetLastIdent(c1);

        envComponentEmpty = Env.removeComponentsFromFrameV(envComponent);

        // get the dimensions from the type!
        daeDims = Types.getDimensions(ty2);
        arrDims = List.map(daeDims,Expression.unelabDimension);
        // add to the environment of the expandable
        // connector the new virtual variable.
        envExpandable = Env.extendFrameV(
                          envExpandable,
                          DAE.TYPES_VAR(componentName,
                                        DAE.ATTR(ct2,prl2,vt2,Absyn.BIDIR(),io2,vis2),
                                        ty2,DAE.UNBOUND(),
                                        NONE()),
                          SCode.COMPONENT(
                            componentName,
                            SCode.defaultPrefixes,
                            SCode.ATTR(arrDims, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR()),
                            Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                            SCode.noComment, NONE(), Absyn.dummyInfo),
                          DAE.NOMOD(),
                          Env.VAR_TYPED(),
          // add empty here to connect individual components!
          envComponentEmpty);
        // ******************************************************************************
        // here we need to update the correct environment.
        // walk the cref: c1_2 and update all the corresponding environments on the path:
        // Example: c1_2 = a.b.c -> update env c, update env b with c, update env a with b!
        env = updateEnvComponentsOnQualPath(
                    cache,
                    env,
                    c1_2,
                    attr,
                    ty,
                    binding,
                    cnstForRange,
                    envExpandable);
        // ******************************************************************************

        // c1 = Absyn.joinCrefs(ComponentReference.unelabCref(c1_2), Absyn.CREF_IDENT(componentName, {}));
        // then connect each of the components normally.
        (cache,env,ih,sets,dae,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,variablesUnion,impl,graph,info);
      then
        (cache,env,ih,sets,dae,graph);

    // c1 is expandable and SHOULD be qualified!
    case (cache,env,ih,sets,pre,c1 as Absyn.CREF_QUAL(name=_),c2,impl,graph,_)
      equation
        // c1 is expandable
        (cache,NONE()) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,_),_,attr2))) = Static.elabCref(cache, env, c2, impl, false, pre, info);

        // Debug.fprintln(Flags.EXPANDABLE, ">>>> connect(expandable, existing)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // lookup the existing connector
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        // bind the attributes
        DAE.ATTR(ct2,prl2,vt2,_,io2,vis2) = attr2;

        // Debug.fprintln(Flags.EXPANDABLE, "1 connect(expandable, existing)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // strip the last prefix!
        c1_prefix = Absyn.crefStripLast(c1);
        // elab expandable connector
        (cache,SOME((DAE.CREF(c1_1,_),_,_))) = Static.elabCref(cache, env, c1_prefix, impl, false, pre, info);
        // lookup the expandable connector
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache, env, c1_2);
        // make sure is expandable!
        true = isExpandableConnectorType(ty1);
        // strip last subs to get the full type!
        c1_2 = ComponentReference.crefStripLastSubs(c1_2);
        (_,attr,ty,binding,cnstForRange,_,_,envExpandable,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,envComponent,_) = Lookup.lookupVar(cache, env, c2_2);

        // we have more than 1 variables in the envComponent, we need to add an empty environment for c1
        // and dive into!
        variablesUnion = Env.getVariablesFromEnv(envComponent);
        // print("VARS SINGLE:" +& stringDelimitList(variablesUnion, ", ") +& "\n");
        // max 1 variable, should check for empty!
        false = listLength(variablesUnion) > 1;

        // Debug.fprintln(Flags.EXPANDABLE, "2 connect(expandable, existing[SINGLE])(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        // get the virtual component name
        Absyn.CREF_IDENT(componentName, _) = Absyn.crefGetLastIdent(c1);

        // get the dimensions from the type!
        daeDims = Types.getDimensions(ty2);
        arrDims = List.map(daeDims,Expression.unelabDimension);
        // add to the environment of the expandable
        // connector the new virtual variable.
        envExpandable = Env.extendFrameV(
                          envExpandable,
                          DAE.TYPES_VAR(
                            componentName,
                            DAE.ATTR(ct2,prl2,vt2,Absyn.BIDIR(),io2,vis2),
                            ty2,DAE.UNBOUND(),NONE()),
                          SCode.COMPONENT(
                            componentName,
                            SCode.defaultPrefixes,
                            SCode.ATTR(arrDims, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR()),
                            Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                            SCode.noComment, NONE(), Absyn.dummyInfo),
                          DAE.NOMOD(),
                          Env.VAR_TYPED(),
                          envComponent);
        // ******************************************************************************
        // here we need to update the correct environment.
        // walk the cref: c1_2 and update all the corresponding environments on the path:
        // Example: c1_2 = a.b.c -> update env c, update env b with c, update env a with b!
        env = updateEnvComponentsOnQualPath(
                    cache,
                    env,
                    c1_2,
                    attr,
                    ty,
                    binding,
                    cnstForRange,
                    envExpandable);
        // ******************************************************************************

        // Debug.fprintln(Flags.EXPANDABLE, "3 connect(expandable, existing[SINGLE])(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")");

        //Debug.fprintln(Flags.EXPANDABLE, "env expandable: " +& Env.printEnvStr(envExpandable));
        //Debug.fprintln(Flags.EXPANDABLE, "env component: " +& Env.printEnvStr(envComponent));
        //Debug.fprintln(Flags.EXPANDABLE, "env: " +& Env.printEnvStr(env));

        // use the cannon cref here as we will NOT find [i] in this environment!!!!
        // c1 = Absyn.joinCrefs(ComponentReference.unelabCref(c1_2), Absyn.CREF_IDENT(componentName, {}));
        // now it should be in the Env, fetch the info!
        (cache,SOME((DAE.CREF(c1_1,_),_,_))) = Static.elabCref(cache, env, c1, impl, false, pre,info);
        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        // bind the attributes
        DAE.ATTR(ct1,prl1,vt1,_,io1,vis1) = attr1;

        // then connect the components normally.
        (cache,env,ih,sets,dae,graph) = instConnect(cache,env,ih,sets,pre,c1,c2,impl,graph,info);

        // adrpo: TODO! FIXME! check if is OK
        state = ClassInf.CONNECTOR(Absyn.IDENT("expandable connector"), true);
        (cache,c1p) = PrefixUtil.prefixCref(cache, env, ih, pre, c1_2);
        (cache,c2p) = PrefixUtil.prefixCref(cache, env, ih, pre, c2_2);
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1p,c2p)), NONE());
        // declare the added component in the DAE!
        (cache,c1_2) = PrefixUtil.prefixCref(cache, env, ih, pre, c1_2);

        // get the dimensions from the ty1 type!
        daeDims = Types.getDimensions(ty1);
        arrDims = List.map(daeDims,Expression.unelabDimension);
        daeExpandable = generateExpandableDAE(
          c1_2,
          state,
          ty1,
          SCode.ATTR(arrDims, ct1, prl1, vt1, Absyn.BIDIR()),
          vis1,
          io1,
          source);

        dae = DAEUtil.joinDaes(dae, daeExpandable);
        // Debug.fprintln(Flags.EXPANDABLE, "<<<< connect(expandable, existing)(" +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c1) +& ", " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "." +& Dump.printComponentRefStr(c2) +& ")\nDAE:" +&DAEDump.dump2str(daeExpandable));
      then
        (cache,env,ih,sets,dae,graph);

    // both c1 and c2 are non expandable!
    case (cache,env,_,_,pre,c1,c2,impl,_,_)
      equation
        // both of these are OK
        (cache,SOME((DAE.CREF(c1_1,_),_,_))) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,_),_,_))) = Static.elabCref(cache, env, c2, impl, false, pre, info);

        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,_,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,_,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);

        // non-expandable
        false = isExpandableConnectorType(ty1);
        false = isExpandableConnectorType(ty2);

        // Debug.fprintln(Flags.EXPANDABLE,
        //   "connect(non-expandable, non-expandable)(" +&
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        // then connect the components normally.
      then
        fail(); // fail to enter connect normally
  end matchcontinue;
end connectExpandableConnectors;

protected function generateExpandableDAE
"@author: adrpo
 connect(expandable, non-expandable)
 should generate a DAE for the expandable part.
 Expand the array if needed."
 input DAE.ComponentRef cref;
 input ClassInf.State state;
 input DAE.Type ty;
 input SCode.Attributes attrs;
 input SCode.Visibility vis;
 input Absyn.InnerOuter io;
 input DAE.ElementSource source;
 output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(cref, state, ty, attrs, vis, io, source)
    local
      Absyn.ArrayDim arrDims;
      DAE.Dimensions daeDims;
      DAE.DAElist daeExpandable;
      list<DAE.ComponentRef> crefs;

    // scalars!
    case (_, _, _, _, _, _, _)
      equation
        // get the dimensions from the type!
        (daeDims as {}) = Types.getDimensions(ty);
        _ = List.map(daeDims,Expression.unelabDimension);
        daeExpandable = InstDAE.daeDeclare(cref, state, ty,
           attrs,
           vis, NONE(), {}, NONE(), NONE(),
           SOME(SCode.COMMENT(NONE(), SOME("virtual variable in expandable connector"))),
           io, SCode.NOT_FINAL(), source, true);
      then
        daeExpandable;

    // arrays
    case (_, _, _, _, _, _, _)
      equation
        // get the dimensions from the type!
        (daeDims as _::_) = Types.getDimensions(ty);
        _ = List.map(daeDims,Expression.unelabDimension);
        crefs = ComponentReference.expandCref(cref, false);
        // print(" crefs: " +& stringDelimitList(List.map(crefs, ComponentReference.printComponentRefStr),", ") +& "\n");
        daeExpandable = daeDeclareList(listReverse(crefs), state, ty, attrs, vis, io, source, DAE.emptyDae);
      then
        daeExpandable;

  end matchcontinue;
end generateExpandableDAE;

protected function daeDeclareList
"declare a list of crefs, one for each array element"
 input list<DAE.ComponentRef> crefs;
 input ClassInf.State state;
 input DAE.Type ty;
 input SCode.Attributes attrs;
 input SCode.Visibility vis;
 input Absyn.InnerOuter io;
 input DAE.ElementSource source;
 input DAE.DAElist acc;
 output DAE.DAElist outDAE;
algorithm
  outDAE := match(crefs, state, ty, attrs, vis, io, source, acc)
    local
      Absyn.ArrayDim arrDims;
      DAE.Dimensions daeDims;
      DAE.DAElist daeExpandable;
      list<DAE.ComponentRef> lst;
      DAE.ComponentRef cref;

    case ({}, _, _, _, _, _, _, _) then acc;

    case (cref::lst, _, _, _, _, _, _, _)
      equation
        daeExpandable = InstDAE.daeDeclare(cref, state, ty,
           attrs,
           vis, NONE(), {}, NONE(), NONE(),
           SOME(SCode.COMMENT(NONE(), SOME("virtual variable in expandable connector"))),
           io, SCode.NOT_FINAL(), source, true);
        daeExpandable = DAEUtil.joinDaes(daeExpandable, acc);
        daeExpandable = daeDeclareList(lst, state, ty, attrs, vis, io, source, daeExpandable);
      then
        daeExpandable;
  end match;
end daeDeclareList;

protected function updateEnvComponentsOnQualPath
"@author: adrpo 2010-10-05
  This function will fetch the environments on the
  cref path and update the last one with the given input,
  then update all the environment back to the root.
  Example:
    input: env[a], a.b.c.d, env[d]
    update env[c] with env[d]
    update env[b] with env[c]
    update env[a] with env[b]"
  input Env.Cache inCache "cache";
  input Env.Env inEnv "the environment we should update!";
  input DAE.ComponentRef virtualExpandableCref;
  input DAE.Attributes virtualExpandableAttr;
  input DAE.Type virtualExpandableTy;
  input DAE.Binding virtualExpandableBinding;
  input Option<DAE.Const> virtualExpandableCnstForRange;
  input Env.Env virtualExpandableEnv "the virtual component environment!";
  output Env.Env outEnv "the returned updated environment";
algorithm
  outEnv :=
  match(inCache, inEnv, virtualExpandableCref, virtualExpandableAttr, virtualExpandableTy,
                virtualExpandableBinding, virtualExpandableCnstForRange, virtualExpandableEnv)
    local
      Env.Cache cache;
      Env.Env topEnv "the environment we should update!";
      DAE.ComponentRef veCref, qualCref;
      DAE.Attributes veAttr,currentAttr;
      DAE.Type veTy,currentTy;
      DAE.Binding veBinding,currentBinding;
      Option<DAE.Const> veCnstForRange,currentCnstForRange;
      Env.Env veEnv "the virtual component environment!";
      Env.Env updatedEnv "the returned updated environment";
      Env.Env currentEnv, forLoopEnv, realEnv;
      String currentName;

    // we have reached the top, update and return!
    case (_, topEnv, DAE.CREF_IDENT(ident = currentName), veAttr, veTy, veBinding, veCnstForRange, veEnv)
      equation
        (realEnv, forLoopEnv) = Lookup.splitEnv(topEnv);
        // update the topEnv
        updatedEnv = Env.updateFrameV(
                       realEnv,
                       DAE.TYPES_VAR(currentName, veAttr, veTy, veBinding, veCnstForRange),
                       Env.VAR_TYPED(),
                       veEnv);
        updatedEnv = listAppend(forLoopEnv, updatedEnv);
      then
        updatedEnv;

    // if we have a.b.x, update b with x and call us recursively with a.b
    case (cache, topEnv, veCref as DAE.CREF_QUAL(componentRef = _), veAttr, veTy, veBinding, veCnstForRange, veEnv)
      equation
        // get the last one
        currentName = ComponentReference.crefLastIdent(veCref);
        // strip the last one
        qualCref = ComponentReference.crefStripLastIdent(veCref);
        // strip the last subs
        qualCref = ComponentReference.crefStripLastSubs(qualCref);
        // find the correct environment to update
        (_,currentAttr,currentTy,currentBinding,currentCnstForRange,_,_,currentEnv,_) = Lookup.lookupVar(cache, topEnv, qualCref);

        (realEnv, forLoopEnv) = Lookup.splitEnv(currentEnv);
        // update the current environment!
        currentEnv = Env.updateFrameV(
                       realEnv,
                       DAE.TYPES_VAR(currentName, veAttr, veTy, veBinding, veCnstForRange),
                       Env.VAR_TYPED(),
                       veEnv);
        currentEnv = listAppend(forLoopEnv, currentEnv);

        // call us recursively to reach the top!
        updatedEnv = updateEnvComponentsOnQualPath(
                      cache,
                      topEnv,
                      qualCref,
                      currentAttr,
                      currentTy,
                      currentBinding,
                      currentCnstForRange,
                      currentEnv);
      then updatedEnv;
  end match;
end updateEnvComponentsOnQualPath;

protected function connectExpandableVariables
"@author: adrpo
  this function handle the connections of expandable connectors
  that contain components"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input list<String> inVariablesUnion;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  match (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inVariablesUnion,inBoolean,inGraph,info)
    local
      Boolean impl;
      Connect.Sets sets;
      DAE.DAElist dae, dae1, dae2;
      Env.Env env;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,c1_full,c2_full;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<String> names;
      String name;

    // handle empty case
    case (cache,env,ih,sets,_,_,_,{},_,graph,_)
      then (cache,env,ih,sets,DAE.emptyDae,graph);

    // handle recursive call
    case (cache,env,ih,sets,pre,c1,c2,name::names,impl,graph,_)
      equation
        // add name to both c1 and c2, then connect normally
        c1_full = Absyn.joinCrefs(c1, Absyn.CREF_IDENT(name, {}));
        c2_full = Absyn.joinCrefs(c2, Absyn.CREF_IDENT(name, {}));
        // Debug.fprintln(Flags.EXPANDABLE,
        //   "connect(full_expandable, full_expandable)(" +&
        //      Dump.printComponentRefStr(c1_full) +& ", " +&
        //      Dump.printComponentRefStr(c2_full) +& ")");
        (cache,env,ih,sets,dae1,graph) = instConnect(cache,env,ih,sets,pre,c1_full,c2_full,impl,graph,info);

        (cache,env,ih,sets,dae2,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,names,impl,graph,info);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env,ih,sets,dae,graph);
  end match;
end connectExpandableVariables;

public function isExpandableConnectorType
"@author: adrpo
  this function checks if the given type is an expandable connector"
  input DAE.Type ty;
  output Boolean isExpandable;
algorithm
  isExpandable := match (ty)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_,true))) then true;
    // TODO! check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(_,true))) then true;
    else false;
  end match;
end isExpandableConnectorType;

protected function getStateFromType
"@author: adrpo
  this function gets the ClassInf.State from the given type.
  it will fail if the type is not a complex type."
  input DAE.Type ty;
  output ClassInf.State outState;
algorithm
  outState := match (ty)
    local
      ClassInf.State state;
    case (DAE.T_COMPLEX(complexClassType = state)) then state;
    // TODO! check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = state)) then state;
    // adpo: TODO! FIXME! add a debug print here!
    else fail();
  end match;
end getStateFromType;

protected function isConnectorType
"@author: adrpo
  this function checks if the given type is an expandable connector"
  input DAE.Type ty;
  output Boolean isConnector;
algorithm
  isConnector := match (ty)
    case (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_,false))) then true;
    // TODO! check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(_,false))) then true;
    else false;
  end match;
end isConnectorType;

protected function flipDirection
"@author: adrpo
  this function will flip direction:
  input  -> output
  output -> input
  bidir  -> bidir"
  input  Absyn.Direction inDir;
  output Absyn.Direction outDir;
algorithm
  outDir := match(inDir)
    case (Absyn.INPUT()) then Absyn.OUTPUT();
    case (Absyn.OUTPUT()) then Absyn.INPUT();
    case (Absyn.BIDIR()) then Absyn.BIDIR();
  end match;
end flipDirection;

protected function validConnector
"This function tests whether a type is a eligible to be used in connections."
  input DAE.Type inType;
  input DAE.ComponentRef inCref;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue (inType, inCref, inInfo)
    local
      ClassInf.State state;
      DAE.Type tp;
      String str;

    case (DAE.T_REAL(varLst = _), _, _) then ();
    case (DAE.T_INTEGER(varLst = _), _, _) then ();
    case (DAE.T_STRING(varLst = _), _, _) then ();
    case (DAE.T_BOOL(varLst = _), _, _) then ();
    case (DAE.T_ENUMERATION(index = _), _, _) then ();

    case (DAE.T_COMPLEX(complexClassType = state), _, _)
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(false));
      then
        ();

    case (DAE.T_COMPLEX(complexClassType = state), _, _)
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(true));
      then
        ();

    // TODO, check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = state), _, _)
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(false));
      then
        ();

    // TODO, check if subtype is needed here
    case (DAE.T_SUBTYPE_BASIC(complexClassType = state), _, _)
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(true));
      then
        ();

    case (DAE.T_ARRAY(ty = tp), _, _)
      equation
        validConnector(tp, inCref, inInfo);
      then
        ();

    // everything in expandable is a connector!
    case (_, _, _)
      equation
        true = ConnectUtil.isExpandable(inCref);
      then
        ();

    else
      equation
        str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.INVALID_CONNECTOR_TYPE, {str}, inInfo);
      then
        fail();
  end matchcontinue;
end validConnector;

protected function checkConnectTypes
  input DAE.ComponentRef inLhsCref;
  input DAE.Type inLhsType;
  input Connect.Face inLhsFace;
  input DAE.Attributes inLhsAttributes;
  input DAE.ComponentRef inRhsCref;
  input DAE.Type inRhsType;
  input Connect.Face inRhsFace;
  input DAE.Attributes inRhsAttributes;
  input Absyn.Info inInfo;
protected
  SCode.ConnectorType lhs_ct, rhs_ct;
  Absyn.Direction lhs_dir, rhs_dir;
  Absyn.InnerOuter lhs_io, rhs_io;
  SCode.Visibility lhs_vis, rhs_vis;
algorithm
  DAE.ATTR(connectorType = lhs_ct, direction = lhs_dir, innerOuter = lhs_io,
    visibility = lhs_vis) := inLhsAttributes;
  DAE.ATTR(connectorType = rhs_ct, direction = rhs_dir, innerOuter = rhs_io,
    visibility = rhs_vis) := inRhsAttributes;
  checkConnectTypesType(inLhsType, inRhsType, inLhsCref, inRhsCref, inInfo);
  checkConnectTypesFlowStream(lhs_ct, rhs_ct, inLhsCref, inRhsCref, inInfo);
  checkConnectTypesDirection(lhs_dir, inLhsFace, lhs_vis, rhs_dir, inRhsFace,
    rhs_vis, inLhsCref, inRhsCref, inInfo);
  checkConnectTypesInnerOuter(lhs_io, rhs_io, inLhsCref, inRhsCref, inInfo);
end checkConnectTypes;

protected function checkConnectTypesType
  input DAE.Type inLhsType;
  input DAE.Type inRhsType;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLhsType, inRhsType, inLhsCref, inRhsCref, inInfo)
    local
      DAE.Type t1, t2;
      String cs1, cs2, cref_str1, cref_str2, str1, str2;
      list<Integer> dims1, dims2;

    case (_, _, _, _, _)
      equation
        true = Types.equivtypesOrRecordSubtypeOf(inLhsType, inRhsType);
      then
        ();

    // The type is not identical hence error.
    case (_, _, _, _, _)
      equation
        (t1, _) = Types.flattenArrayType(inLhsType);
        (t2, _) = Types.flattenArrayType(inRhsType);
        false = Types.equivtypesOrRecordSubtypeOf(t1, t2);
        (_, cs1) = Types.printConnectorTypeStr(t1);
        (_, cs2) = Types.printConnectorTypeStr(t2);
        cref_str1 = ComponentReference.printComponentRefStr(inLhsCref);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsCref);
        Error.addSourceMessage(Error.CONNECT_INCOMPATIBLE_TYPES,
          {cref_str1, cref_str2, cref_str1, cs1, cref_str2, cs2}, inInfo);
      then
        fail();

    // Different dimensionality.
    case (_, _, _, _, _)
      equation
        (_, dims1) = Types.flattenArrayType(inLhsType);
        (_, dims2) = Types.flattenArrayType(inRhsType);
        false = List.isEqualOnTrue(dims1, dims2, intEq);
        false = (listLength(dims1) + listLength(dims2)) == 0;
        cref_str1 = ComponentReference.printComponentRefStr(inLhsCref);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsCref);
        str1 = stringDelimitList(List.map(dims1, intString), ", ");
        str1 = "[" +& str1 +& "]";
        str2 = stringDelimitList(List.map(dims2, intString), ", ");
        str2 = "[" +& str2 +& "]";
        Error.addSourceMessage(Error.CONNECTOR_ARRAY_DIFFERENT,
          {cref_str1, cref_str2, str1, str2}, inInfo);
      then
        fail();

  end matchcontinue;
end checkConnectTypesType;

protected function checkConnectTypesFlowStream
  input SCode.ConnectorType inLhsConnectorType;
  input SCode.ConnectorType inRhsConnectorType;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLhsConnectorType, inRhsConnectorType, inLhsCref,
      inRhsCref, inInfo)
    local
      String cref_str1, cref_str2, pre_str1, pre_str2;
      list<String> err_strl;

    case (_, _, _, _, _)
      equation
        true = SCode.connectorTypeEqual(inLhsConnectorType, inRhsConnectorType);
      then
        ();

    else
      equation
        cref_str1 = ComponentReference.printComponentRefStr(inLhsCref);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsCref);
        pre_str1 = SCodeDump.connectorTypeStr(inLhsConnectorType);
        pre_str2 = SCodeDump.connectorTypeStr(inRhsConnectorType);
        err_strl = Util.if_(SCode.potentialBool(inLhsConnectorType),
          {pre_str2, cref_str2, cref_str1}, {pre_str1, cref_str1, cref_str2});
        Error.addSourceMessage(Error.CONNECT_PREFIX_MISMATCH, err_strl, inInfo);
      then
        fail();

  end matchcontinue;
end checkConnectTypesFlowStream;

protected function checkConnectTypesDirection
  input Absyn.Direction inLhsDirection;
  input Connect.Face inLhsFace;
  input SCode.Visibility inLhsVisibility;
  input Absyn.Direction inRhsDirection;
  input Connect.Face inRhsFace;
  input SCode.Visibility inRhsVisibility;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLhsDirection, inLhsFace, inLhsVisibility, inRhsDirection,
      inRhsFace, inRhsVisibility, inLhsCref, inRhsCref, inInfo)
    local
      String cref_str1, cref_str2;

    // Two connectors with the same directions but different faces or different
    // directions may be connected.
    case (_, _, _, _, _, _, _, _, _)
      equation
        false = isSignalSource(inLhsDirection, inLhsFace, inLhsVisibility) and
                isSignalSource(inRhsDirection, inRhsFace, inRhsVisibility);
      then
        ();

    else
      equation
        cref_str1 = ComponentReference.printComponentRefStr(inLhsCref);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsCref);
        Error.addSourceMessage(Error.CONNECT_TWO_SOURCES,
          {cref_str1, cref_str2}, inInfo);
      then
        ();

  end matchcontinue;
end checkConnectTypesDirection;

protected function isSignalSource
  input Absyn.Direction inDirection;
  input Connect.Face inFace;
  input SCode.Visibility inVisibility;
  output Boolean outIsSignal;
algorithm
  outIsSignal := match(inDirection, inFace, inVisibility)
    case (Absyn.OUTPUT(), Connect.INSIDE(), _) then true;
    case (Absyn.INPUT(), Connect.OUTSIDE(), SCode.PUBLIC()) then true;
    else false;
  end match;
end isSignalSource;

protected function checkConnectTypesInnerOuter
  input Absyn.InnerOuter inLhsIO;
  input Absyn.InnerOuter inRhsIO;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input Absyn.Info inInfo;
algorithm
  _ := match(inLhsIO, inRhsIO, inLhsCref, inRhsCref, inInfo)
    local
      String cref_str1, cref_str2;

    case (Absyn.OUTER(), Absyn.OUTER(), _, _, _)
      equation
        cref_str1 = ComponentReference.printComponentRefStr(inLhsCref);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsCref);
        Error.addSourceMessage(Error.CONNECT_OUTER_OUTER,
          {cref_str1, cref_str2}, inInfo);
      then
        fail();

    else ();

  end match;
end checkConnectTypesInnerOuter;

public function connectComponents "
  This function connects two components and generates connection
  sets along the way.  For simple components (of type Real) it
  adds the components to the set, and for complex types it traverses
  the subcomponents and recursively connects them to each other.
  A DAE.Element list is returned for assert statements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix3;
  input DAE.ComponentRef cr1;
  input Connect.Face inFace5;
  input DAE.Type inType6;
  input SCode.Variability vt1;
  input DAE.ComponentRef cr2;
  input Connect.Face inFace8;
  input DAE.Type inType9;
  input SCode.Variability vt2;
  input SCode.ConnectorType inConnectorType;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,cr1,inFace5,inType6,vt1,cr2,inFace8,inType9,vt2,inConnectorType,io1,io2,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1,c2,c1p,c2p;
      Connect.Sets sets_1,sets;
      Env.Env env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      DAE.Type t1, t2, bc_tp1, bc_tp2, equalityConstraintFunctionReturnType;
      DAE.Dimension dim1,dim2;
      DAE.DAElist dae;
      list<DAE.Var> l1,l2;
      SCode.ConnectorType ct;
      String c1_str,t1_str,t2_str,c2_str;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.InlineType inlineType1, inlineType2;
      Absyn.Path fpath1, fpath2;
      Integer idim1,idim2,dim_int;
      DAE.Exp zeroVector, crefExp1, crefExp2, exp;
      list<DAE.Element>  breakDAEElements, elts;
      SCode.Element equalityConstraintFunction;
      DAE.Dimensions dims,dims2;
      list<DAE.ComponentRef> crefs1, crefs2;
      DAE.Const const1,const2;
      list<DAE.Exp> lhsl, rhsl;

    // connections to outer components
    case(cache,env,ih,sets,pre,c1,f1,_,_,c2,f2,_,_,ct,_,_,graph,_)
      equation
        false = SCode.streamBool(ct);
        // print("Connecting components: " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "/" +&
        //    ComponentReference.printComponentRefStr(c1) +& "[" +& Dump.unparseInnerouterStr(io1) +& "]" +& " = " +&
        //    ComponentReference.printComponentRefStr(c2) +& "[" +& Dump.unparseInnerouterStr(io2) +& "]\n");
        true = InnerOuter.outerConnection(io1,io2);


        // prefix outer with the prefix of the inner directly!
        (cache, DAE.CREF(c1_1, _)) =
           PrefixUtil.prefixExp(cache, env, ih, Expression.crefExp(c1), pre);
        (cache, DAE.CREF(c2_1, _)) =
           PrefixUtil.prefixExp(cache, env, ih, Expression.crefExp(c2), pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        // print("CONNECT: " +& PrefixUtil.printPrefixStrIgnoreNoPre(pre) +& "/" +&
        //    ComponentReference.printComponentRefStr(c1_1) +& "[" +& Dump.unparseInnerouterStr(io1) +& "]" +& " = " +&
        //    ComponentReference.printComponentRefStr(c2_1) +& "[" +& Dump.unparseInnerouterStr(io2) +& "]\n");

        sets = ConnectUtil.addOuterConnection(pre,sets,c1_1,c2_1,io1,io2,f1,f2,source);
      then
        (cache,env,ih,sets,DAE.emptyDae,graph);

    // Non-flow and Non-stream type Parameters and constants generate assert statements
    case (cache,env,ih,sets,pre,c1,_,t1,_,c2,_,t2,_,SCode.POTENTIAL(),_,_,graph,_)
      equation
        true = SCode.isParameterOrConst(vt1) and SCode.isParameterOrConst(vt2) ;
        true = Types.basicType(Types.arrayElementType(t1));
        true = Types.basicType(Types.arrayElementType(t2));

        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        crefExp1 = Expression.crefExp(c1_1);
        crefExp2 = Expression.crefExp(c2_1);
        // Evaluate constant crefs away
        const1 = NFInstUtil.toConst(vt1);
        const2 = NFInstUtil.toConst(vt2);
        (cache, crefExp1, _) = Ceval.cevalIfConstant(cache, env, crefExp1, DAE.PROP(t1,const1), true, info);
        (cache, crefExp2, _) = Ceval.cevalIfConstant(cache, env, crefExp2, DAE.PROP(t2,const2), true, info);

        lhsl = Expression.arrayElements(crefExp1);
        rhsl = Expression.arrayElements(crefExp2);
        elts = List.threadMap1(lhsl, rhsl, generateConnectAssert, source);
      then
        (cache,env,ih,sets,DAE.DAE(elts),graph);

    // Connection of two components of basic type.
    case (cache, env, ih, sets, pre, c1, f1, t1, _, c2, f2, t2, _, _, _, _, graph, _)
      equation
        true = Types.basicType(t1);
        true = Types.basicType(t2);

        // TODO: FIXME!
        // adrpo 2012-10-14: should we not prefix here??!!
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addConnection(sets, c1, f1, c2, f2, inConnectorType, source);
      then
        (cache,env,ih,sets_1,DAE.emptyDae,graph);

    // Connection of arrays of complex types
    case (cache,env,ih,sets,pre,
        c1,f1,DAE.T_ARRAY(dims = {dim1}, ty = t1),_,
        c2,f2,DAE.T_ARRAY(dims = {dim2}, ty = t2),_,
        ct as SCode.POTENTIAL(),_,_,graph,_)
      equation
        DAE.T_COMPLEX(complexClassType=_) = Types.arrayElementType(t1);
        DAE.T_COMPLEX(complexClassType=_) = Types.arrayElementType(t2);

        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
        _ = Expression.dimensionSize(dim1);

        crefs1 = ComponentReference.expandCref(c1,false);
        crefs2 = ComponentReference.expandCref(c2,false);
        (cache, _, ih, sets_1, dae, graph) = connectArrayComponents(cache, env,
          ih, sets, pre, crefs1, f1, t1, vt1, io1, crefs2, f2, t2, vt2, io2, ct,
          graph, info);
      then
        (cache,env,ih,sets_1,dae,graph);

    // Connection of arrays
    case (cache,env,ih,sets,pre,
        c1, f1, t1 as DAE.T_ARRAY(ty = _), _,
        c2, f2, t2 as DAE.T_ARRAY(ty = _), _,
        ct,_,_,graph,_)
      equation
        dims = Types.getDimensions(t1);
        dims2 = Types.getDimensions(t2);
        true = List.isEqualOnTrue(dims, dims2, Expression.dimensionsKnownAndEqual);

        // set the source of this element
        (cache,c1p) = PrefixUtil.prefixCref(cache, env, ih, pre, c1);
        (cache,c2p) = PrefixUtil.prefixCref(cache, env, ih, pre, c2);
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1p,c2p)), NONE());

        sets_1 = ConnectUtil.addArrayConnection(sets, c1, f1, c2, f2, source, ct);
      then
        (cache,env,ih,sets_1,DAE.emptyDae,graph);

    // Connection of connectors with an equality constraint.
    case (cache,env,ih,sets,pre,c1,f1,t1 as DAE.T_COMPLEX(equalityConstraint=SOME((fpath1,idim1,inlineType1))),_,
                                c2,f2,t2 as DAE.T_COMPLEX(equalityConstraint=SOME((_,_,_))),_,
                                ct as SCode.POTENTIAL(),_,_,
        (graph as ConnectionGraph.GRAPH(updateGraph = true)),_)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        // Connect components ignoring equality constraints
        (cache,env,ih,sets_1,dae,_) =
        connectComponents(cache, env, ih, sets, pre, c1, f1, t1, vt1, c2, f2,
          t2, vt2, ct, io1, io2, ConnectionGraph.NOUPDATE_EMPTY, info);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        // Add an edge to connection graph. The edge contains the
        // dae to be added in the case where the edge is broken.
        zeroVector = Expression.makeRealArrayOfZeros(idim1);
        crefExp1 = Expression.crefExp(c1_1);
        crefExp2 = Expression.crefExp(c2_1);
        equalityConstraintFunctionReturnType =
          DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(idim1)},DAE.emptyTypeSource);

        source = DAEUtil.addAdditionalComment(source, " equation generated by overconstrained connection graph breaking");

        breakDAEElements =
          {DAE.ARRAY_EQUATION({DAE.DIM_INTEGER(idim1)}, zeroVector,
                        DAE.CALL(fpath1,{crefExp1, crefExp2},
                                 DAE.CALL_ATTR(
                                   equalityConstraintFunctionReturnType,
                                   false, false, false, inlineType1, DAE.NO_TAIL())), // use the inline type
                        source // set the origin of the element
                        )};
        graph = ConnectionGraph.addConnection(graph, c1_1, c2_1, breakDAEElements);

        // deal with equalityConstraint function!
        // instantiate and add the equalityConstraint function to the dae function tree!
        (cache,equalityConstraintFunction,env) = Lookup.lookupClass(cache,env,fpath1,false);
        (cache,fpath1) = Inst.makeFullyQualified(cache,env,fpath1);
        cache = Env.addCachedInstFuncGuard(cache,fpath1);
        (cache,env,ih) =
          InstFunction.implicitFunctionInstantiation(cache,env,ih,DAE.NOMOD(),Prefix.NOPRE(),equalityConstraintFunction,{});
      then
        (cache,env,ih,sets_1,dae,graph);

    // Complex types t1 extending basetype
    case (cache,env,ih,sets,pre,c1,f1,DAE.T_SUBTYPE_BASIC(complexType = bc_tp1),_,c2,f2,t2,_, ct,_,_,graph,_)
      equation
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache, env, ih, sets,
            pre, c1, f1, bc_tp1, vt1, c2, f2, t2, vt2, ct, io1, io2, graph, info);
      then
        (cache,env,ih,sets_1,dae,graph);

    // Complex types t2 extending basetype
    case (cache,env,ih,sets,pre,c1,f1,t1,_,c2,f2,DAE.T_SUBTYPE_BASIC(complexType = bc_tp2),_,ct,_,_,graph,_)
      equation
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache, env, ih, sets,
            pre, c1, f1, t1, vt1, c2, f2, bc_tp2, vt2, ct, io1, io2, graph, info);
      then
        (cache,env,ih,sets_1,dae,graph);

    // Connection of complex connector, e.g. Pin
    case (cache,env,ih,sets,pre,c1,f1,DAE.T_COMPLEX(varLst = l1),_,c2,f2,DAE.T_COMPLEX(varLst = l2),_,ct,_,_,graph,_)
      equation
        (cache,_,ih,sets_1,dae,graph) = connectVars(cache, env, ih, sets, pre,
            c1, f1, l1, vt1, c2, f2, l2, vt2, ct, io1, io2, graph, info);
      then
        (cache,env,ih,sets_1,dae,graph);

    // Error
    case (cache,env,ih,_,pre,c1,_,t1,_,c2,_,t2,_,_,_,_,_,_)
      equation
        (cache,_) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,_) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        c1_str = ComponentReference.printComponentRefStr(c1);
        t1_str = Types.unparseType(t1);
        c2_str = ComponentReference.printComponentRefStr(c2);
        t2_str = Types.unparseType(t2);
        c1_str = stringAppendList({c1_str," and ",c2_str});
        t1_str = stringAppendList({t1_str," and ",t2_str});
        Error.addSourceMessage(Error.INVALID_CONNECTOR_VARIABLE, {c1_str,t1_str},info);
      then
        fail();

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.connectComponents failed\n");
      then
        fail();
  end matchcontinue;
end connectComponents;

protected function generateConnectAssert
  input DAE.Exp inLhsExp;
  input DAE.Exp inRhsExp;
  input DAE.ElementSource inSource;
  output DAE.Element outAssert;
protected
  DAE.Exp exp;
algorithm
  exp := DAE.RELATION(inLhsExp, DAE.EQUAL(DAE.T_BOOL_DEFAULT), inRhsExp, -1, NONE());
  (exp, _) := ExpressionSimplify.simplify(exp);
  outAssert := DAE.ASSERT(exp, DAE.SCONST("automatically generated from connect"),
    DAE.ASSERTIONLEVEL_ERROR, inSource);
end generateConnectAssert;

protected function connectArrayComponents
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix;
  input list<DAE.ComponentRef> inLhsCrefs;
  input Connect.Face inLhsFace;
  input DAE.Type inLhsType;
  input SCode.Variability inLhsVar;
  input Absyn.InnerOuter inLhsIO;
  input list<DAE.ComponentRef> inRhsCrefs;
  input Connect.Face inRhsFace;
  input DAE.Type inRhsType;
  input SCode.Variability inRhsVar;
  input Absyn.InnerOuter inRhsIO;
  input SCode.ConnectorType inConnectorType;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache, outEnv, outIH, outSets, outDae, outGraph) :=
  match(inCache, inEnv, inIH, inSets, inPrefix,
      inLhsCrefs, inLhsFace, inLhsType, inLhsVar, inLhsIO,
      inRhsCrefs, inRhsFace, inRhsType, inRhsVar, inRhsIO,
      inConnectorType, inGraph, inInfo)
    local
      DAE.ComponentRef lhs, rhs;
      list<DAE.ComponentRef> rest_lhs, rest_rhs;
      Env.Cache cache;
      Env.Env env;
      InstanceHierarchy ih;
      Connect.Sets sets;
      DAE.DAElist dae1, dae2;
      ConnectionGraph.ConnectionGraph graph;

    case (_, _, _, _, _, lhs :: rest_lhs, _, _, _, _, rhs :: rest_rhs, _, _, _,
        _, _, _, _)
      equation
        (cache, env, ih, sets, dae1, graph) = connectComponents(inCache, inEnv,
          inIH, inSets, inPrefix, lhs, inLhsFace, inLhsType, inLhsVar, rhs,
          inRhsFace, inRhsType, inRhsVar, inConnectorType, inLhsIO, inRhsIO,
          inGraph, inInfo);
        (cache, env, ih, sets, dae2, graph) = connectArrayComponents(cache,
          env, ih, sets, inPrefix, rest_lhs, inLhsFace, inLhsType, inLhsVar,
          inLhsIO, rest_rhs, inRhsFace, inRhsType, inRhsVar, inRhsIO,
          inConnectorType, graph, inInfo);
        dae1 = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache, env, ih, sets, dae1, graph);

    else (inCache, inEnv, inIH, inSets, DAE.emptyDae, inGraph);

  end match;
end connectArrayComponents;

protected function connectVars
"This function connects two subcomponents by adding the component
  name to the current path and recursively connecting the components
  using the function connectComponents."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix.Prefix inPrefix;
  input DAE.ComponentRef inComponentRef3;
  input Connect.Face inFace4;
  input list<DAE.Var> inTypesVarLst5;
  input SCode.Variability vt1;
  input DAE.ComponentRef inComponentRef6;
  input Connect.Face inFace7;
  input list<DAE.Var> inTypesVarLst8;
  input SCode.Variability vt2;
  input SCode.ConnectorType inConnectorType;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output InnerOuter.InstHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  match (inCache,inEnv,inIH,inSets,inPrefix,inComponentRef3,inFace4,inTypesVarLst5,vt1,inComponentRef6,inFace7,inTypesVarLst8,vt2,inConnectorType,io1,io2,inGraph,info)
    local
      Connect.Sets sets,sets_1,sets_2;
      Env.Env env;
      DAE.ComponentRef c1_1,c2_1,c1,c2;
      DAE.DAElist dae,dae2,dae_1;
      Connect.Face f1,f2;
      String n;
      DAE.Attributes attr1,attr2;
      SCode.ConnectorType ct;
      DAE.Type ty1,ty2;
      list<DAE.Var> xs1,xs2;
      SCode.Variability vta,vtb;
      DAE.Type ty_2;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,sets,_,_,_,{},_,_,_,{},_,_,_,_,graph,_)
      then (cache,env,ih,sets,DAE.emptyDae,graph);
    case (cache,env,ih,sets,_,c1,f1,
        (DAE.TYPES_VAR(name = n,attributes =(attr1 as DAE.ATTR(connectorType = ct,variability = vta)),ty = ty1) :: xs1),_,c2,f2,
        (DAE.TYPES_VAR(attributes = (attr2 as DAE.ATTR(variability = vtb)),ty = ty2) :: xs2),_,_,_,_,graph,_)
      equation
        ty_2 = Types.simplifyType(ty1);
        ct = propagateConnectorType(inConnectorType, ct);
        c1_1 = ComponentReference.crefPrependIdent(c1, n, {}, ty_2);
        c2_1 = ComponentReference.crefPrependIdent(c2, n, {}, ty_2);
        checkConnectTypes(c1_1, ty1, f1, attr1, c2_1, ty2, f2, attr2, info);
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih,sets, inPrefix, c1_1, f1, ty1, vta, c2_1, f2, ty2, vtb, ct, io1, io2, graph, info);
        (cache,_,ih,sets_2,dae2,graph) = connectVars(cache,env,ih,sets_1, inPrefix, c1, f1, xs1,vt1, c2, f2, xs2, vt2, inConnectorType, io1, io2, graph, info);
        dae_1 = DAEUtil.joinDaes(dae, dae2);
      then
        (cache,env,ih,sets_2,dae_1,graph);
  end match;
end connectVars;

protected function propagateConnectorType
  input SCode.ConnectorType inConnectorType;
  input SCode.ConnectorType inSubConnectorType;
  output SCode.ConnectorType outSubConnectorType;
algorithm
  outSubConnectorType := match(inConnectorType, inSubConnectorType)
    case (SCode.POTENTIAL(), _) then inSubConnectorType;
    else inConnectorType;
  end match;
end propagateConnectorType;

protected function expandArrayDimension
  "Expands an array into elements given a dimension, i.e.
    (3, x) => {x[1], x[2], x[3]}"
  input DAE.Dimension inDim;
  input DAE.Exp inArray;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := matchcontinue(inDim, inArray)
    local
      list<DAE.Exp> expl;
      Integer sz;
      list<Integer> ints;
      Absyn.Path name;
      list<String> ls;

    // Empty integer list. List.intRange is not defined for size < 1,
    // so we need to handle empty lists here.
    case (DAE.DIM_INTEGER(integer = 0), _) then {};
    case (DAE.DIM_INTEGER(integer = sz), _)
      equation
        ints = List.intRange(sz);
        expl = List.map1(ints, makeAsubIndex, inArray);
      then
        expl;
    case (DAE.DIM_BOOLEAN(), _)
      equation
        expl = DAE.BCONST(false)::DAE.BCONST(true)::{};
      then
        expl;
    case (DAE.DIM_ENUM(enumTypeName = name, literals = ls), _)
      equation
        expl = makeEnumLiteralIndices(name, ls, 1, inArray);
      then
        expl;
    /* adrpo: these are completly wrong!
              will result in equations 1 = 1!
    case (DAE.DIM_EXP(exp = _), _) then {DAE.ICONST(1)};
    case (DAE.DIM_UNKNOWN(), _) then {DAE.ICONST(1)};
    */
    case (DAE.DIM_UNKNOWN(), _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        ints = List.intRange(1); // try to make an array index of 1 when we don't know the dimension
        expl = List.map1(ints, makeAsubIndex, inArray);
      then
        expl;
  end matchcontinue;
end expandArrayDimension;

protected function makeAsubIndex
  "Creates an ASUB expression given an expression and an integer index."
  input Integer index;
  input DAE.Exp expr;
  output DAE.Exp asub;
algorithm
  (asub,_) := ExpressionSimplify.simplify1(Expression.makeASUB(expr, {DAE.ICONST(index)}));
end makeAsubIndex;

protected function makeEnumLiteralIndices
  "Creates a list of enumeration literal expressions from an enumeration."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  input Integer enumIndex;
  input DAE.Exp expr;
  output list<DAE.Exp> enumIndices;
algorithm
  enumIndices := match(enumTypeName, enumLiterals, enumIndex, expr)
    local
      String l;
      list<String> ls;
      DAE.Exp e;
      list<DAE.Exp> expl;
      Absyn.Path enum_type_name;
      Integer index;
    case (_, {}, _, _) then {};
    case (_, l :: ls, _, _)
      equation
        enum_type_name = Absyn.joinPaths(enumTypeName, Absyn.IDENT(l));
        e = DAE.ENUM_LITERAL(enum_type_name, enumIndex);
        (e,_) = ExpressionSimplify.simplify1(Expression.makeASUB(expr, {e}));
        e = Debug.bcallret1(Expression.isCref(e), Expression.unliftExp, e, e);
        index = enumIndex + 1;
        expl = makeEnumLiteralIndices(enumTypeName, ls, index, expr);
      then
        e :: expl;
  end match;
end makeEnumLiteralIndices;

protected function getVectorizedCref
"for a vectorized cref, return the originial cref without vector subscripts"
input DAE.Exp crefOrArray;
output DAE.Exp cref;
algorithm
   cref := match(crefOrArray)
     local
       DAE.ComponentRef cr;
       DAE.Type t;
       DAE.Exp crefExp;

     case (cref as DAE.CREF(_,_)) then cref;

     case (DAE.ARRAY(_,_,DAE.CREF(cr,t)::_))
       equation
         cr = ComponentReference.crefStripLastSubs(cr);
         crefExp = Expression.makeCrefExp(cr, t);
       then crefExp;
   end match;
end getVectorizedCref;


protected function checkWhenAlgorithm
"@author: adrpo
 checks when equation for:
 - when alg in when alg is not allowed
 - reinit in when with initial condition is not allowed
   when (initial()) then
     reinit(x, y);
   end when;
"
  input SCode.Statement inWhenAlgorithm;
algorithm
  checkForReinitInWhenInitialAlg(inWhenAlgorithm);
  checkForNestedWhenInStatements(inWhenAlgorithm);
end checkWhenAlgorithm;

protected function checkForReinitInWhenInitialAlg
"Fails if a when (initial()) alg contains
 reinit which is not allowed in Modelica."
  input SCode.Statement inWhenAlgorithm;
algorithm
  _ := matchcontinue(inWhenAlgorithm)
    local
      Boolean b1, b2;
      Absyn.Exp exp;
      Absyn.Info info;
      list<SCode.Statement> algs;

    // do not add an error
    case SCode.ALG_WHEN_A(branches = (exp, algs)::_ )
      equation
        b1 = Absyn.expContainsInitial(exp);
        b2 = SCode.algorithmsContainReinit(algs);
        false = boolAnd(b1, b2);
      then
        ();

    // add an error
    case SCode.ALG_WHEN_A(branches = (exp, algs)::_ , info = info)
      equation
        true = Absyn.expContainsInitial(exp);
        true = SCode.algorithmsContainReinit(algs);
        Error.addSourceMessage(Error.REINIT_IN_WHEN_INITIAL, {}, info);
      then
        fail();

  end matchcontinue;
end checkForReinitInWhenInitialAlg;

protected function checkForNestedWhenInStatements
  "Fails if a when alg contains nested when
   alg, which are not allowed in Modelica.
   An error message is added when failing."
  input SCode.Statement inWhenAlgorithm;
algorithm
  _ := matchcontinue(inWhenAlgorithm)
    local
      Absyn.Info info;
      list<SCode.Statement> algs;

    // continue if when equations are not nested
    case (SCode.ALG_WHEN_A(branches = (_,algs)::_))
      equation
        false = containsWhenStatements(algs);
      then
        ();

    // add an error message for nested when
    case (SCode.ALG_WHEN_A(branches = (_,algs)::_, info = info))
      equation
        true = containsWhenStatements(algs);
        Error.addSourceMessage(Error.NESTED_WHEN, {}, info);
      then
        fail();

  end matchcontinue;
end checkForNestedWhenInStatements;

protected function checkWhenEquation
"@author: adrpo
 checks when equation for:
 - when equation in when equation is not allowed
 - reinit in when with initial condition is not allowed
   when (initial()) then
     reinit(x, y);
   end when;"
  input SCode.EEquation inWhenEq;
algorithm
  checkForReinitInWhenInitialEq(inWhenEq);
  checkForNestedWhenInEquation(inWhenEq);
end checkWhenEquation;

protected function checkForReinitInWhenInitialEq
"Fails if a when (initial()) equation contains
 reinit which is not allowed in Modelica."
  input SCode.EEquation inWhenEq;
algorithm
  _ := matchcontinue(inWhenEq)
    local
      Boolean b1, b2;
      Absyn.Exp exp;
      Absyn.Info info;
      list<SCode.EEquation> el;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> tpl_el;

    // add an error for when initial() then reinit()
    case SCode.EQ_WHEN(condition = exp, eEquationLst = el, elseBranches = _)
      equation
        b1 = Absyn.expContainsInitial(exp);
        b2 = SCode.equationsContainReinit(el);
        false = boolAnd(b1, b2);
      then
        ();

    // add an error for when initial() then reinit()
    case SCode.EQ_WHEN(condition = exp, eEquationLst = el, elseBranches = _, info = info)
      equation
        true = Absyn.expContainsInitial(exp);
        true = SCode.equationsContainReinit(el);
        Error.addSourceMessage(Error.REINIT_IN_WHEN_INITIAL, {}, info);
      then
        fail();

  end matchcontinue;
end checkForReinitInWhenInitialEq;

protected function checkForNestedWhenInEquation
  "Fails if a when equation contains nested when
   equations, which are not allowed in Modelica.
   An error message is added when failing."
  input SCode.EEquation inWhenEq;
algorithm
  _ := matchcontinue(inWhenEq)
    local
      Absyn.Info info;
      list<SCode.EEquation> eqs;
      list<list<SCode.EEquation>> eqs_lst;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> tpl_el;

    // continue if when equations are not nested
    case SCode.EQ_WHEN(eEquationLst = eqs, elseBranches = tpl_el)
      equation
        checkForNestedWhenInEqList(eqs);
        eqs_lst = List.map(tpl_el, Util.tuple22);
        List.map_0(eqs_lst, checkForNestedWhenInEqList);
      then
        ();

    // print error if when equations are nested.
    case (SCode.EQ_WHEN(info = info))
      equation
        Error.addSourceMessage(Error.NESTED_WHEN, {}, info);
      then
        fail();

  end matchcontinue;
end checkForNestedWhenInEquation;

protected function checkForNestedWhenInEqList
  "Helper function to checkForNestedWhen. Searches for nested when equations in
  a list of equations."
  input list<SCode.EEquation> inEqs;
algorithm
  List.map_0(inEqs, checkForNestedWhenInEq);
end checkForNestedWhenInEqList;

protected function checkForNestedWhenInEq
  "Helper function to checkForNestedWhen. Searches for nested when equations in
  an equation."
  input SCode.EEquation inEq;
algorithm
  _ := matchcontinue(inEq)
    local
      list<SCode.EEquation> eqs;
      list<list<SCode.EEquation>> eqs_lst;

    case SCode.EQ_WHEN(info = _) then fail();

    case SCode.EQ_IF(thenBranch = eqs_lst, elseBranch = eqs)
      equation
        List.map_0(eqs_lst, checkForNestedWhenInEqList);
        checkForNestedWhenInEqList(eqs);
      then
        ();

    case SCode.EQ_FOR(eEquationLst = eqs)
      equation
        checkForNestedWhenInEqList(eqs);
      then
        ();

    case SCode.EQ_EQUALS(info = _) then ();
    case SCode.EQ_CONNECT(info = _) then ();
    case SCode.EQ_ASSERT(info = _) then ();
    case SCode.EQ_TERMINATE(info = _) then ();
    case SCode.EQ_REINIT(info = _) then ();
    case SCode.EQ_NORETCALL(info = _) then ();

    case _
      equation
        Debug.fprintln(Flags.FAILTRACE, "- InstSection.checkForNestedWhenInEq failed.");
      then
        fail();

  end matchcontinue;
end checkForNestedWhenInEq;

protected function instAssignment
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy ih;
  input Prefix.Prefix inPre;
  input SCode.Statement alg;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean impl;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input Integer numError;
  output Env.Cache outCache;
  output list<DAE.Statement> stmts "more statements due to loop unrolling";
algorithm
  (outCache,stmts) := matchcontinue (inCache,inEnv,ih,inPre,alg,source,initial_,impl,unrollForLoops,numError)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.Exp e_1;
      DAE.Properties eprop;
      Prefix.Prefix pre;
      Absyn.Exp var;
      Absyn.Exp value;
      Absyn.Info info;
      String str;
      DAE.Type t;

    case (cache,env,_,pre,SCode.ALG_ASSIGN(assignComponent=var,value=value,info=info),_,_,_,_,_)
      equation
        (cache,e_1,eprop,_) = Static.elabExp(cache,env,value,impl,NONE(),true,pre,info);
        (cache,stmts) = instAssignment2(cache,env,ih,pre,var,e_1,eprop,info,source,initial_,impl,unrollForLoops,numError);
      then (cache,stmts);

    case (cache,env,_,pre,SCode.ALG_ASSIGN(assignComponent=_,value=value,info=info),_,_,_,_,_)
      equation
        true = numError == Error.getNumErrorMessages();
        failure((_,_,_,_) = Static.elabExp(cache,env,value,impl,NONE(),true,pre,info));
        str = Dump.unparseAlgorithmStr(SCode.statementToAlgorithmItem(alg));
        Error.addSourceMessage(Error.ASSIGN_RHS_ELABORATION,{str},info);
      then fail();
  end matchcontinue;
end instAssignment;

protected function instAssignment2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPre;
  input Absyn.Exp var;
  input DAE.Exp value;
  input DAE.Properties props;
  input Absyn.Info info;
  input DAE.ElementSource inSource;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input Integer numError;
  output Env.Cache outCache;
  output list<DAE.Statement> stmts "more statements due to loop unrolling";
algorithm
  (outCache,stmts) := matchcontinue (inCache,inEnv,inIH,inPre,var,value,props,info,inSource,initial_,inBoolean,unrollForLoops,numError)
    local
      DAE.ComponentRef ce,ce_1;
      DAE.Properties cprop,eprop,prop,prop1,prop2;
      DAE.Exp e_1, e_2, cre, cre2, e2_2, e2_2_2, lhs, rhs;
      DAE.Statement stmt;
      Env.Env env;
      Absyn.ComponentRef cr;
      Absyn.Exp e,e1,e2, left;
      Boolean impl;
      list<Absyn.Exp> expl;
      list<DAE.Exp> expl_1,expl_2;
      list<DAE.Properties> cprops, eprops;
      list<DAE.Attributes> attrs;
      DAE.Type lt,rt,ty,t;
      String s,lhs_str,rhs_str,lt_str,rt_str,s1,s2;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstanceHierarchy ih;
      DAE.Pattern pattern;
      DAE.Attributes attr;
      DAE.ElementSource source;
      DAE.Dimension dim, lhs_dim, rhs_dim;
      list<DAE.Exp> lhs_idxs, rhs_idxs;

    // v := expr; where v or expr are size 0
    case (cache,env,_,pre,Absyn.CREF(cr),e_1,_,_,_,_,impl,_,_)
      equation
        (cache,SOME((lhs as DAE.CREF(_,t),_,attr))) = Static.elabCrefNoEval(cache, env, cr, impl, false, pre, info);
        DAE.T_ARRAY( dims = {_}) = t;
        rhs = e_1;
        Static.checkAssignmentToInput(var, attr, env, false, info);
        DAE.T_ARRAY(dims = lhs_dim :: _) = Expression.typeof(lhs);
        DAE.T_ARRAY(dims = rhs_dim :: _) = Expression.typeof(rhs);
        {} = expandArrayDimension(lhs_dim, lhs);
        {} = expandArrayDimension(rhs_dim, rhs);
      then
        (cache,{});

    // v := expr;
    case (cache,env,ih,pre,Absyn.CREF(cr),e_1,eprop,_,source,_,impl,_,_)
      equation
        (cache,SOME((DAE.CREF(ce,t),cprop,attr))) = Static.elabCrefNoEval(cache, env, cr, impl, false, pre, info);
        Static.checkAssignmentToInput(var, attr, env, false, info);
        (cache, ce_1) = Static.canonCref(cache, env, ce, impl);
        (cache, ce_1) = PrefixUtil.prefixCref(cache, env, ih, pre, ce_1);

        (cache, t) = PrefixUtil.prefixExpressionsInType(cache, env, ih, pre, t);

        lt = Types.getPropType(cprop);
        (cache, lt) = PrefixUtil.prefixExpressionsInType(cache, env, ih, pre, lt);
        cprop = Types.setPropType(cprop, lt);

        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache, e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);

        rt = Types.getPropType(eprop);
        (cache, rt) = PrefixUtil.prefixExpressionsInType(cache, env, ih, pre, rt);
        eprop = Types.setPropType(eprop, rt);

        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = makeAssignment(Expression.makeCrefExp(ce_1,t), cprop, e_2, eprop, attr, initial_, source);
      then
        (cache,{stmt});

    // der(x) := ...
    case (cache,env,ih,pre,e2 as Absyn.CALL(function_ = Absyn.CREF_IDENT(name="der"),functionArgs=(Absyn.FUNCTIONARGS(args={Absyn.CREF(cr)})) ),e_1,eprop,_,source,_,impl,_,_)
      equation
        (cache,SOME((_,cprop,attr))) = Static.elabCrefNoEval(cache,env, cr, impl,false,pre,info);
        (cache,(e2_2 as DAE.CALL(path=_)),_,_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache,e2_2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_2, pre);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = makeAssignment(e2_2_2, cprop, e_2, eprop, attr /*SCode.RW()*/, initial_, source);
      then
        (cache,{stmt});

    // v[i] := expr (in e.g. for loops)
    case (cache,env,ih,pre,Absyn.CREF(cr),e_1,eprop,_,source,_,impl,_,_)
      equation
        (cache,SOME((cre,cprop,attr))) = Static.elabCrefNoEval(cache,env, cr, impl,false,pre,info);
        Static.checkAssignmentToInput(var, attr, env, false, info);
        (cache,cre2) = PrefixUtil.prefixExp(cache, env, ih, cre, pre);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = makeAssignment(cre2, cprop, e_2, eprop, attr, initial_, source);
      then
        (cache,{stmt});

    // (v1,v2,..,vn) := func(...)
    case (cache,env,ih,pre,Absyn.TUPLE(expressions = expl),e_1,eprop,_,source,_,impl,_,_)
      equation
        true = MetaUtil.onlyCrefExpressions(expl);
        (cache, e_1 as DAE.CALL(path=_), eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,expl_1,cprops,attrs,_) = Static.elabExpCrefNoEvalList(cache, env, expl, impl, NONE(), false, pre, info, Error.getNumErrorMessages());
        Static.checkAssignmentToInputs(expl, attrs, env, info);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache, env, ih, expl_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeTupleAssignment(expl_2, cprops, e_2, eprop, initial_, source);
      then
        (cache,{stmt});

    // (v1,v2,..,vn) := match...
    case (cache,env,ih,pre,Absyn.TUPLE(expressions = expl),e_1,eprop,_,source,_,impl,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        true = MetaUtil.onlyCrefExpressions(expl);
        true = Types.isTuple(Types.getPropType(eprop));
        (cache, e_1 as DAE.MATCHEXPRESSION(matchType=_), eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,expl_1,cprops,attrs,_) = Static.elabExpCrefNoEvalList(cache, env, expl, impl, NONE(), false, pre, info, Error.getNumErrorMessages());
        Static.checkAssignmentToInputs(expl, attrs, env, info);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache, env, ih, expl_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeTupleAssignment(expl_2, cprops, e_2, eprop, initial_, source);
      then
        (cache,{stmt});

    case (cache,env,_,_,left,e_1,prop,_,source,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        ty = Types.getPropType(prop);
        (e_1,ty) = Types.convertTupleToMetaTuple(e_1,ty);
        (cache,pattern) = Patternm.elabPattern(cache,env,left,ty,info);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Util.if_(Types.isEmptyOrNoRetcall(ty),DAE.STMT_NORETCALL(e_1,source),DAE.STMT_ASSIGN(DAE.T_UNKNOWN_DEFAULT,DAE.PATTERN(pattern),e_1,source));
      then (cache,{stmt});

    /* Tuple with rhs constant */
    case (cache,env,ih,pre,Absyn.TUPLE(expressions = expl),e_1,eprop,_,source,_,impl,_,_)
      equation
        (cache, e_1 as DAE.TUPLE(PR = expl_1), eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl, info);
        (cache,expl_2,cprops,attrs,_) = Static.elabExpCrefNoEvalList(cache,env, expl, impl,NONE(),false,pre,info, Error.getNumErrorMessages());
        Static.checkAssignmentToInputs(expl, attrs, env, info);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache, env, ih, expl_2, pre);
        eprops = Types.propTuplePropList(eprop);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmts = Algorithm.makeAssignmentsList(expl_2, cprops, expl_1, eprops, /* SCode.RW() */ DAE.dummyAttrVar, initial_, source);
      then
        (cache,stmts);

    /* Tuple with lhs being a tuple NOT of crefs => Error */
    case (_,_,_,_,e as Absyn.TUPLE(expressions = expl),_,_,_,_,_,_,_,_)
      equation
        failure(_ = List.map(expl,Absyn.expCref));
        s = Dump.printExpStr(e);
        Error.addSourceMessage(Error.TUPLE_ASSIGN_CREFS_ONLY, {s}, info);
      then
        fail();

    case (cache,env,_,pre,e1 as Absyn.TUPLE(expressions = expl),e_2,prop2,_,_,_,impl,_,_)
      equation
        DAE.CALL(path = _) = e_2;
        _ = List.map(expl,Absyn.expCref);
        (cache,e_1,prop1,_) = Static.elabExp(cache,env,e1,impl,NONE(),false,pre,info);
        lt = Types.getPropType(prop1);
        rt = Types.getPropType(prop2);
        false = Types.subtype(lt, rt);
        lhs_str = ExpressionDump.printExpStr(e_1);
        rhs_str = ExpressionDump.printExpStr(e_2);
        lt_str = Types.unparseType(lt);
        rt_str = Types.unparseType(rt);
        Types.typeErrorSanityCheck(lt_str, rt_str, info);
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,{lhs_str,rhs_str,lt_str,rt_str}, info);
      then
        fail();

    /* Tuple with rhs not CALL or CONSTANT => Error */
    case (_,_,_,_,Absyn.TUPLE(expressions = expl),e_1,_,_,_,_,_,_,_)
      equation
        _ = List.map(expl,Absyn.expCref);
        failure(DAE.CALL(path = _) = e_1);
        s = ExpressionDump.printExpStr(e_1);
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY, {s}, info);
      then
        fail();

    case (_,_,_,_,_,e_1,_,_,_,_,_,_,_)
      equation
        true = numError == Error.getNumErrorMessages();
        s1 = Dump.printExpStr(var);
        s2 = ExpressionDump.printExpStr(e_1);
        Error.addSourceMessage(Error.ASSIGN_UNKNOWN_ERROR, {s1,s2}, info);
      then
        fail();
  end matchcontinue;
end instAssignment2;

protected function generateNoConstantBindingError
  input Option<Values.Value> emptyValueOpt;
  input Absyn.Info info;
algorithm
  _ := match(emptyValueOpt, info)
    local
      String scope "the scope where we could not find the binding";
      String name "the name of the variable";
      Values.Value ty "the DAE.Type translated to Value using defaults";
      String tyStr "the type of the variable";

    case (NONE(), _) then ();
    case (SOME(Values.EMPTY(scope, name, _, _)), _)
      equation
         Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {name, scope}, info);
      then
        fail();

  end match;
end generateNoConstantBindingError;

protected function getIteratorType
  input DAE.Type ty;
  input String id;
  input Absyn.Info info;
  output DAE.Type oty;
algorithm
  oty := match (ty,id,info)
    local
      String str;
    case (DAE.T_ARRAY(ty = oty),_,_) then oty;
    else
      equation
        str = Types.unparseType(ty);
        Error.addSourceMessage(Error.ITERATOR_NON_ARRAY,{id,str},info);
      then fail();
  end match;
end getIteratorType;



protected function instParForStatement
"Helper function for instStatement"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input String iterator;
  input Option<Absyn.Exp> range;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) := matchcontinue(inCache,inEnv,inIH,inPrefix,ci_state,iterator,range,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
      Env.Cache cache;
      Env.Env env;
      Prefix.Prefix pre;
      list<SCode.Statement> sl;
      SCode.Initial initial_;
      Boolean impl;
      list<DAE.Statement> stmts;
      InstanceHierarchy ih;

    // adrpo: unroll ALL for loops containing ALG_WHEN... done
    case (cache,env,ih,pre,_,_,_,sl,_,_,initial_,impl,_)
      equation
        // check here that we have a when loop in the for statement.
        true = containsWhenStatements(sl);
        (cache,stmts) = unrollForLoop(cache,env,ih,pre,ci_state,iterator,range,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);

    // for loops not containing ALG_WHEN
    case (cache,env,ih,pre,_,_,_,sl,_,_,initial_,impl,_)
      equation
        // do not unroll if it doesn't contain a when statement!
        false = containsWhenStatements(sl);
        (cache,stmts) = instParForStatement_dispatch(cache,env,ih,pre,ci_state,iterator,range,sl,info,source,initial_,impl,unrollForLoops);
        stmts = replaceLoopDependentCrefs(stmts, iterator, range);
      then
        (cache,stmts);

  end matchcontinue;
end instParForStatement;

protected function instParForStatement_dispatch
"function for instantiating a for statement"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input ClassInf.State ci_state;
  input String iterator;
  input Option<Absyn.Exp> range;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource inSource;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatements) :=
  matchcontinue(inCache,inEnv,inIH,inPrefix,ci_state,iterator,range,inForBody,info,inSource,inInitial,inBool,unrollForLoops)
    local
      Env.Cache cache;
      Env.Env env,env_1;
      Prefix.Prefix pre;
      list<SCode.Statement> sl;
      SCode.Initial initial_;
      Boolean impl;
      DAE.Type t;
      DAE.Exp e_1,e_2;
      list<DAE.Statement> sl_1;
      String i;
      Absyn.Exp e;
      DAE.Statement stmt;
      DAE.Properties prop;
      list<tuple<Absyn.ComponentRef,Integer>> lst;
      tuple<Absyn.ComponentRef, Integer> tpl;
      DAE.Const cnst;
      InstanceHierarchy ih;
      DAE.ElementSource source;
      list<tuple<DAE.ComponentRef,Absyn.Info>> loopPrlVars;
      DAE.ComponentRef parforIter;

    // one iterator
    case (cache,env,ih,pre,_,i,SOME(e),sl,_,source,initial_,impl,_)
      equation
        (cache,e_1,(prop as DAE.PROP(t,cnst)),_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        t = getIteratorType(t,i,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, ih, e_1, pre);
        env_1 = addParForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache, env_1, ih, pre, ci_state, sl, source, initial_, impl, unrollForLoops, {});

        // this is where we check the parfor loop for data parallel specific
        // situations. Start with empty list and collect all variables cref'ed
        // in the loop body.
        loopPrlVars = collectParallelVariables({},sl_1);

        // Remove the parfor loop iterator from the list(implicitly declared).
        parforIter = DAE.CREF_IDENT(i, t,{});
        (loopPrlVars,_) = List.deleteMemberOnTrue(parforIter,loopPrlVars,crefInfoListCrefsEqual);

        // Check the cref's in the list one by one to make
        // sure that they are parallel variables.
        // checkParallelVariables(cache,env_1,loopPrlVars);
        List.map2_0(loopPrlVars, isCrefParGlobalOrForIterator, cache, env_1);

        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeParFor(i, e_2, prop, sl_1, loopPrlVars, source);
      then
        (cache,{stmt});

    case (cache,env,ih,pre,_,i,NONE(),sl,_,source,initial_,impl,_) //The verison w/o assertions
      equation
        // false = containsWhenStatements(sl);
        (lst as _::_) = SCode.findIteratorInStatements(i,sl);
        tpl=List.first(lst);
        // e = Absyn.RANGE(1,NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP(t,cnst)),_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        t = getIteratorType(t,i,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        env_1 = addParForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache,env_1,ih,pre,ci_state,sl,source,initial_,impl,unrollForLoops,{});
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1, source);
      then
        (cache,{stmt});

    case (_,_,_,_,_,i,NONE(),sl,_,_,_,_,_)
      equation
        // false = containsWhenStatements(sl);
        {} = SCode.findIteratorInStatements(i,sl);
        Error.addSourceMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i},info);
      then fail();

    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"instParForStatement_dispatch failed."}, info);
      then fail();

  end matchcontinue;
end instParForStatement_dispatch;


protected function isCrefParGlobalOrForIterator
"Checks if a component reference is referencing a parglobal
variable or the loop iterator(implicitly declared is OK).
All other references are errors."
  input tuple<DAE.ComponentRef,Absyn.Info> inCrefInfo;
  input Env.Cache inCache;
  input Env.Env inEnv;
algorithm
  _ := matchcontinue(inCrefInfo,inCache,inEnv)
    local
      String errorString;
      DAE.ComponentRef cref;
      Absyn.Info info;
      SCode.Parallelism prl;
      Boolean isParglobal;
      Option<DAE.Const> cnstForRange;

    case((cref,_),_,_)
      equation
        // Look up the variable
        (_, DAE.ATTR(parallelism = prl),_,_,_,_,_,_,_) = Lookup.lookupVar(inCache, inEnv, cref);

        // is it parglobal var?
        isParglobal = SCode.parallelismEqual(prl, SCode.PARGLOBAL());

        // Now the iterator is already removed. No need for this.
        // is it the iterator of the parfor loop(implicitly declared)?
        // isForiterator = Util.isSome(cnstForRange);

        //is it either a parglobal var or for iterator
        //true = isParglobal or isForiterator;

        true = isParglobal;

      then ();

    case((cref,info),_,_)
      equation
        errorString = "\n" +&
        "- Component '" +& Absyn.pathString(ComponentReference.crefToPath(cref)) +&
        "' is used in a parallel for loop." +& "\n" +&
        "- Parallel for loops can only contain references to parglobal variables."
        ;
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, info);
      then fail();

  end matchcontinue;
end isCrefParGlobalOrForIterator;


protected function crefInfoListCrefsEqual
"Compares if two <DAE.ComponentRef,Absyn.Info> tuples have
are the same in the sense that they have the same cref (which
means they are references to the same component).
The info is
just for error messages."
  input DAE.ComponentRef inFoundCref;
  input tuple<DAE.ComponentRef,Absyn.Info> inCrefInfos;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inFoundCref,inCrefInfos)
  local
    DAE.ComponentRef cref1;

    case(_,(cref1,_)) then ComponentReference.crefEqualWithoutSubs(cref1,inFoundCref);
  end match;
end crefInfoListCrefsEqual;


protected function collectParallelVariables
"Traverses the body of a parallel for loop and collects
all variable references. the list should not include implictly
declared variables like loop iterators. Only references to
components declared to outside of the parfor loop need to be
collected.
We need the list of referenced variables for Code generation in the backend.
EXPENSIVE operation but needs to be done."
  input list<tuple<DAE.ComponentRef,Absyn.Info>> inCrefInfos;
  input list<DAE.Statement> inStatments;
  output list<tuple<DAE.ComponentRef,Absyn.Info>> outCrefInfos;

algorithm
  outCrefInfos := matchcontinue(inCrefInfos,inStatments)
    local
      list<DAE.Statement> restStmts, stmtList;
      list<tuple<DAE.ComponentRef,Absyn.Info>> crefInfoList;
      DAE.ComponentRef foundCref;
      DAE.Exp exp1,exp2;
      Absyn.Info info;
      DAE.Ident iter;
      DAE.Type iterType;
      DAE.Statement debugStmt;

    case(_,{}) then inCrefInfos;

    case(crefInfoList,DAE.STMT_ASSIGN(_, exp1, exp2, DAE.SOURCE(info = info))::restStmts)
      equation
        //check the lhs and rhs.
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1,exp2},info);

        //check the rest
        crefInfoList = collectParallelVariables(crefInfoList,restStmts);
      then crefInfoList;

    // for statment
    case(crefInfoList, DAE.STMT_FOR(type_=iterType, iter=iter, range=exp1, statementLst=stmtList, source=DAE.SOURCE(info = info))::restStmts)
      equation
        //check the range exp.
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},info);

        // check the body of the loop.
//        crefInfoList_tmp = collectParallelVariables(crefInfoList,stmtList);
        crefInfoList = collectParallelVariables(crefInfoList,stmtList);
        // We need to remove the iterator from
        // the list generated for the loop bofy. For iterators are implicitly declared.
        // This should be done here since the iterator is in scope only as long as we
        // are in the loop body.
        foundCref = DAE.CREF_IDENT(iter, iterType,{});
        // (crefInfoList_tmp,_) = List.deleteMemberOnTrue(foundCref,crefInfoList_tmp,crefInfoListCrefsEqual);
        (crefInfoList,_) = List.deleteMemberOnTrue(foundCref,crefInfoList,crefInfoListCrefsEqual);

        // Now that the iterator is removed cocatenate the two lists
        // crefInfoList = List.appendNoCopy(crefInfoList_tmp,crefInfoList);

        //check the rest
        crefInfoList = collectParallelVariables(crefInfoList,restStmts);
      then crefInfoList;

    // If statment
    // mahge TODO: Fix else Exps.
    case(crefInfoList, DAE.STMT_IF(exp1, stmtList, _, DAE.SOURCE(info = info))::restStmts)
      equation
        //check the condition exp.
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},info);
        //check the body of the if statment
        crefInfoList = collectParallelVariables(crefInfoList,stmtList);

        //check the rest
        crefInfoList = collectParallelVariables(crefInfoList,restStmts);
      then crefInfoList;

    case(crefInfoList, DAE.STMT_WHILE(exp1, stmtList, DAE.SOURCE(info = info))::restStmts)
      equation
        //check the condition exp.
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},info);
        //check the body of the while loop
        crefInfoList = collectParallelVariables(crefInfoList,stmtList);

        //check the rest
        crefInfoList = collectParallelVariables(crefInfoList,restStmts);
      then crefInfoList;

    case(crefInfoList,_::restStmts)
      then collectParallelVariables(crefInfoList,restStmts);

  end matchcontinue;
end collectParallelVariables;



protected function collectParallelVariablesinExps
  input list<tuple<DAE.ComponentRef,Absyn.Info>> inCrefInfos;
  input list<DAE.Exp> inExps;
  input Absyn.Info inInfo;
  output list<tuple<DAE.ComponentRef,Absyn.Info>> outCrefInfos;

algorithm
  outCrefInfos := matchcontinue(inCrefInfos,inExps,inInfo)
    local
      list<DAE.Exp> restExps;
      list<tuple<DAE.ComponentRef,Absyn.Info>> crefInfoList;
      DAE.ComponentRef foundCref;
      DAE.Exp exp1,exp2,exp3;
      list<DAE.Exp> expLst1;
      list<DAE.Subscript> subscriptLst;
      Boolean alreadyInList;
      DAE.Exp debugExp;


    case(_,{},_) then inCrefInfos;

    case(crefInfoList,DAE.CREF(foundCref, _)::restExps,_)
      equation
        // Check if the cref is already added to the list
        // avoid repeated lookup.
        // and we don't care about subscript differences.

        alreadyInList = List.isMemberOnTrue(foundCref,crefInfoList,crefInfoListCrefsEqual);

        // add it to the list if it is not in there
        crefInfoList = Util.if_(alreadyInList, crefInfoList, (foundCref,inInfo)::crefInfoList);

        //check the subscripts (that is: if they are crefs)
        DAE.CREF_IDENT(_,_,subscriptLst) = foundCref;
        crefInfoList = collectParallelVariablesInSubscriptList(crefInfoList,subscriptLst,inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // Array subscripting
    case(crefInfoList, DAE.ASUB(exp1,expLst1)::restExps,_)
      equation
        //check the ASUB specific expressions
        crefInfoList = collectParallelVariablesinExps(crefInfoList,exp1::expLst1,inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // Binary Operations
    case(crefInfoList, DAE.BINARY(exp1,_, exp2)::restExps,_)
      equation
        //check the lhs and rhs
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1,exp2},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // Unary Operations
    case(crefInfoList, DAE.UNARY(_, exp1)::restExps,_)
      equation
        //check the exp
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // Logical Binary Operations
    case(crefInfoList, DAE.LBINARY(exp1,_, exp2)::restExps,_)
      equation
        //check the lhs and rhs
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1,exp2},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // Logical Unary Operations
    case(crefInfoList, DAE.LUNARY(_, exp1)::restExps,_)
      equation
        //check the exp
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // range with step value.
    case(crefInfoList, DAE.RANGE(_, exp1, SOME(exp2), exp3)::restExps,_)
      equation
        //check the range specific expressions
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1,exp2,exp3},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // range withOUT step value.
    case(crefInfoList, DAE.RANGE(_, exp1, NONE(), exp3)::restExps,_)
      equation
        //check the range specific expressions
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1,exp3},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;

    // cast stmt
    case(crefInfoList, DAE.CAST(_, exp1)::restExps,_)
      equation
        //check the range specific expressions
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},inInfo);

        // check the rest
        crefInfoList = collectParallelVariablesinExps(crefInfoList,restExps,inInfo);
      then crefInfoList;



    // ICONST, RCONST, SCONST, BCONST, ENUM_LITERAL
    //
    case(crefInfoList,_::restExps,_)
      then collectParallelVariablesinExps(crefInfoList,restExps,inInfo);

  end matchcontinue;
end collectParallelVariablesinExps;


protected function collectParallelVariablesInSubscriptList
  input list<tuple<DAE.ComponentRef,Absyn.Info>> inCrefInfos;
  input list<DAE.Subscript> inSubscriptLst;
  input Absyn.Info inInfo;
  output list<tuple<DAE.ComponentRef,Absyn.Info>> outCrefInfos;

algorithm
  outCrefInfos := matchcontinue(inCrefInfos,inSubscriptLst,inInfo)
    local
      list<DAE.Subscript> restSubs;
      list<tuple<DAE.ComponentRef,Absyn.Info>> crefInfoList;
      DAE.Exp exp1;


    case(_,{},_) then inCrefInfos;

    case(crefInfoList, DAE.INDEX(exp1)::restSubs,_)
      equation
        //check the sub exp.
        crefInfoList = collectParallelVariablesinExps(crefInfoList,{exp1},inInfo);

        //check the rest
        crefInfoList = collectParallelVariablesInSubscriptList(crefInfoList,restSubs,inInfo);
      then crefInfoList;

    case(crefInfoList,_::restSubs,_)
      then collectParallelVariablesInSubscriptList(crefInfoList,restSubs,inInfo);

  end matchcontinue;
end collectParallelVariablesInSubscriptList;

protected function checkValidNoRetcall
  input DAE.Exp exp;
  input Absyn.Info info;
algorithm
  _ := match (exp,info)
    local
      String str;
    case (DAE.CALL(path=_),_) then ();
    case (DAE.REDUCTION(expr=_),_) then ();
    else
      equation
        str = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.NORETCALL_INVALID_EXP,{str},info);
      then fail();
  end match;
end checkValidNoRetcall;

end InstSection;
