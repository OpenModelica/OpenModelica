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

package InstSection
" file:        InstSection.mo
  package:     InstSection
  description: Model instantiation

  RCS: $Id: InstSection.mo 6158 2010-09-21 10:13:14Z sjoelund.se $

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
public import RTOpts;
public import SCode;

protected import Algorithm;
protected import Ceval;
protected import ConnectUtil;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Exp;
protected import Inst;
protected import Interactive;
protected import Lookup;
protected import MetaUtil;
protected import ModUtil;
protected import OptManager;
protected import Patternm;
protected import PrefixUtil;
protected import SCodeUtil;
protected import Static;
protected import Types;
protected import Util;
protected import UnitAbsyn;
protected import Values;
protected import ValuesUtil;
protected import System;
protected import ErrorExt;

public
type Prefix = Prefix.Prefix "a prefix";

public
type Mod = DAE.Mod "a modification";

public
type Ident = DAE.Ident "an identifier";

public
type Env = Env.Env "an environment";
  
public
type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

public function instEquation 
"function instEquation
  author: LS, ELN
   
  Instantiates an equation by calling 
  instEquationCommon with Inital set 
  to NON_INITIAL."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) := 
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,unrollForLoops,inGraph)
    local
      list<Env.Frame> env_1,env;
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
      
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq),impl,unrollForLoops,graph) /* impl */ 
      equation
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl,graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
    case (_,_,_,_,_,_,_,SCode.EQUATION(eEquation = eqn),impl,unrollForLoops,graph)
      local SCode.EEquation eqn; String str;
      equation 
        true = RTOpts.debugFlag("failtrace");
        str= SCode.equationStr(eqn);
        Debug.fprint("failtrace", "- instEquation failed eqn:");
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instEquation;

protected function instEEquation 
"function: instEEquation 
  Instantiation of EEquation, used in for loops and if-equations."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache cache;
  output Env outEnv;
  output InstanceHierarchy outIH;  
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState, outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,unrollForLoops,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,unrollForLoops,graph) /* impl */ 
      equation 
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = 
        instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.NON_INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
    // failure
    case(cache,env,ih,mods,pre,csets,ci_state,eq,impl,unrollForLoops,graph) 
      equation
        Debug.fprint("failtrace","Inst.instEEquation failed for "+&SCode.equationStr(eq)+&"\n");
    then fail(); 
  end matchcontinue;
end instEEquation;

public function instInitialEquation 
"function: instInitialEquation
  author: LS, ELN 
  Instantiates initial equation by calling inst_equation_common with Inital 
  set to INITIAL."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.Equation inEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDAe;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEquation,inBoolean,unrollForLoops,inGraph)
    local
      list<Env.Frame> env_1,env;
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
      
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQUATION(eEquation = eq),impl,unrollForLoops,graph) 
      equation 
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache, env, ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
    case (_,_,ih,_,_,_,_,_,impl,_,_)
      equation 
        Debug.fprint("failtrace", "- instInitialEquation failed\n");
      then
        fail();
  end matchcontinue;
end instInitialEquation;

protected function instEInitialEquation 
"function: instEInitialEquation 
  Instantiates initial EEquation used in for loops and if equations "
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inBoolean,unrollForLoops,inGraph)
    local
      DAE.DAElist dae;
      Connect.Sets csets_1,csets;
      ClassInf.State ci_state_1,ci_state;
      list<Env.Frame> env;
      DAE.Mod mods;
      Prefix.Prefix pre;
      SCode.EEquation eq;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      
    case (cache,env,ih,mods,pre,csets,ci_state,eq,impl,unrollForLoops,graph) /* impl */ 
      equation 
        (cache,env,ih,dae,csets_1,ci_state_1,graph) = instEquationCommon(cache,env,ih, mods, pre, csets, ci_state, eq, SCode.INITIAL(), impl, graph);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
  end matchcontinue;
end instEInitialEquation;

protected function instEquationCommon
"function: instEquationCommon 
  The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.
 
  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  instEquationCommon2(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,Error.getNumErrorMessages());
end instEquationCommon;

protected function instEquationCommon2
"function: instEquationCommon 
  The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.
 
  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Integer errorCount;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,errorCount)
    local
      String s;
    case (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph,_)
      equation
        (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) = instEquationCommonWork(inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph);
      then (outCache,outEnv,outIH,outDae,outSets,outState,outGraph);
        // We only want to print a generic error message if no other error message was printed
        // Providing two error messages for the same error is confusing (but better than none) 
    case (_,_,_,_,_,_,_,inEEquation,_,_,_,errorCount)
      equation
        true = errorCount == Error.getNumErrorMessages();
        s = SCode.equationStr(inEEquation);
        Error.addSourceMessage(Error.EQUATION_GENERIC_FAILURE, {s}, SCode.equationFileInfo(inEEquation));
      then
        fail();
  end matchcontinue;
end instEquationCommon2;

protected function instEquationCommonWork
"function: instEquationCommon 
  The DAE output of the translation contains equations which
  in most cases directly corresponds to equations in the source.
  Some of them are also generated from `connect\' clauses.
 
  This function takes an equation from the source and generates DAE
  equations and connection sets."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.EEquation inEEquation;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inEEquation,inInitial,inBoolean,inGraph)
    local
      list<DAE.Properties> props;
      Connect.Sets csets_1,csets;
      DAE.DAElist dae,dae1,dae2,dae3;
      list<DAE.DAElist> dael;
      ClassInf.State ci_state_1,ci_state,ci_state_2;
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mods,mod;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,cr;
      SCode.Initial initial_;
      Boolean impl,cond;
      String n,i,s;
      Absyn.Exp e2,e1,e,ee;
      list<Absyn.Exp> conditions,crs;
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e_1,e_2;
      DAE.Properties prop1,prop2;
      list<SCode.EEquation> b,tb1,fb,el,eel;
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
      Absyn.ComponentRef arrName;
      list<Absyn.Ident> idList;
      Absyn.Exp itExp;
      Absyn.ForIterators rangeIdList;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      list<tuple<Absyn.ComponentRef, Integer>> lst;
      tuple<Absyn.ComponentRef, Integer> tpl;
      DAE.ElementSource source "the origin of the element";
      list<DAE.Element> daeElts1,daeElts2;
      list<list<DAE.Element>> daeLLst;
      DAE.DAElist fdae,fdae1,fdae11,fdae2,fdae3,dae2;
      DAE.FunctionTree funcs,funcs1;
      DAE.Const cnst;
      Boolean unrollForLoops;
      Absyn.Info info;

    /* connect statements */
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_CONNECT(crefLeft = c1,crefRight = c2,info = info),initial_,impl,graph) 
      equation 
        (cache,env,ih,csets_1,dae,graph) = instConnect(cache,env,ih, csets,  pre, c1, c2, impl, graph, info);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
        
        //------------------------------------------------------
        // Part of the MetaModelica extension
        /* equality equations cref = array(...) */
        // Should be removed??
        // case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_EQUALS(e1 as Absyn.CREF(cr),Absyn.ARRAY(expList)),initial_,impl)
        //   local Option<Interactive.InteractiveSymbolTable> c1,c2;
        //     list<Absyn.Exp> expList;
        //    Absyn.ComponentRef cr;
        //     DAE.Properties cprop;
        //   equation
        //     true = RTOpts.acceptMetaModelicaGrammar();
        // If this is a list assignment, then the Absyn.ARRAY expression should
        // be evaluated to DAE.LIST
        //   (cache,_,cprop,_) = Static.elabCref(cache,env, cr, impl,false);
        //   true = MetaUtil.isList(cprop);
        // Do static analysis and constant evaluation of expressions.
        // Gives expression and properties
        // (Type  bool | (Type  Const as (bool | Const list))).
        // For a function, it checks the funtion name.
        // Also the function call\'s in parameters are type checked with
        // the functions definition\'s inparameters. This is done with
        // regard to the position of the input arguments.
        // Returns the output parameters from the function.
        // (cache,e1_1,prop1,c1) = Static.elabExp(cache,env, e1, impl,NONE(),true /*do vectorization*/);
        // (cache,e2_1,prop2,c2) = Static.elabListExp(cache,env, expList, cprop, impl,NONE(),true/* do vectorization*/);
        // (cache,e1_1,e2_1) = condenseArrayEquation(cache,env,e1,e2,e1_1,e2_1,prop1,impl);
        //  (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);
        //  (cache,e2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_1, pre);
        // Check that the lefthandside and the righthandside get along.
        // dae = instEqEquation(e1_2, prop1, e2_2, prop2, initial_, impl);
        // ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        // then
        // (cache,env,ih,dae,csets,ci_state_1);
        //------------------------------------------------------

    /* equality equations e1 = e2 */
    case (cache,env,ih,mods,pre,csets,ci_state,SCode.EQ_EQUALS(expLeft = e1,expRight = e2,info = info),initial_,impl,graph)
      local
        Option<Interactive.InteractiveSymbolTable> c1,c2;
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
        (cache,e1_1,prop1,c1) = Static.elabExp(cache,env, e1, impl,NONE(),true /*do vectorization*/,pre,info); 
        (cache,e2_1,prop2,c2) = Static.elabExp(cache,env, e2, impl,NONE(),true/* do vectorization*/,pre,info);
        (cache, e1_1, prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl);
        (cache, e2_1, prop2) = Ceval.cevalIfConstant(cache, env, e2_1, prop2, impl);
         
        (cache,e1_1,e2_1,prop1) = condenseArrayEquation(cache,env,e1,e2,e1_1,e2_1,prop1,prop2,impl,pre,info);
        (cache,e1_2) = PrefixUtil.prefixExp(cache,env, ih, e1_1, pre);
        (cache,e2_2) = PrefixUtil.prefixExp(cache,env, ih, e2_1, pre);
        
        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        //Check that the lefthandside and the righthandside get along.
        dae = instEqEquation(e1_2, prop1, e2_2, prop2, source, initial_, impl);
                          
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets,ci_state_1,graph);
        
    
/*    case (cache,env,ih,mods,pre,csets,ci_state,eqn as SCode.EQ_EQUALS(expLeft = e1,expRight = e2,info = info),initial_,impl,graph)
      equation 
        failure(checkTupleCallEquation(e1,e2));
        s = SCode.equationStr(eqn);
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY,{s},info);
      then fail();*/

    /* if-equation         
       If the condition is constant this case will select the correct branch and remove the if-equation*/ 
     
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.NON_INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        (DAE.PROP((DAE.T_BOOL(_),_),cnst)) = Types.propsAnd(props);
        true = Types.isParameterOrConstant(cnst);
        (cache,valList) = Ceval.cevalList(cache,env, expl1, impl,NONE(), Ceval.NO_MSG());
        blist = Util.listMap(valList,ValuesUtil.valueBool);
        b = Util.selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, b, impl, Inst.alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);
        
    // if-equation
    // If we are doing checkModel we might get an if-equation whose condition is
    // a parameter without a binding, and which DAEUtil.ifEqToExpr can't handle.
    // If the model would have been instantiated one of the branches would have
    // been chosen, so this case therefore chooses one of the branches.
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.NON_INITIAL(),impl,graph)
      equation
        true = OptManager.getOption("checkModel"); 
        (cache, _,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        (DAE.PROP((DAE.T_BOOL(_),_),DAE.C_PARAM)) = Types.propsAnd(props);
        b = Util.selectList({true}, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, b, impl, Inst.alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

    /* initial if-equation 
    If the condition is constant this case will select the correct branch and remove the initial if-equation */ 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info=info),SCode.INITIAL(),impl,graph) 
      equation 
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        (DAE.PROP((DAE.T_BOOL(_),_),_)) = Types.propsAnd(props);
        (cache,valList) = Ceval.cevalList(cache,env, expl1, impl,NONE(), Ceval.NO_MSG());
        blist = Util.listMap(valList,ValuesUtil.valueBool);
        b = Util.selectList(blist, tb, fb);
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEInitialEquation, b, impl, Inst.alwaysUnroll, graph);
      then
        (cache,env_1,ih,dae,csets_1,ci_state_1,graph);

        // IF_EQUATION when condition is not constant 
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb,info = info),SCode.NON_INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        (DAE.PROP((DAE.T_BOOL(_),_),DAE.C_VAR)) = Types.propsAnd(props); 
        (cache,expl1) = PrefixUtil.prefixExpList(cache, env, ih, expl1, pre);
        
        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache,env,ih, mod, pre, csets, ci_state,tb, false, impl, graph);
        (cache,env_2,ih,DAE.DAE(daeElts2),_,ci_state_2,graph) = Inst.instList(cache,env_1,ih, mod, pre, csets, ci_state, instEEquation, fb, impl, Inst.alwaysUnroll, graph) "There are no connections inside if-clauses." ;
        dae = DAE.DAE({DAE.IF_EQUATION(expl1,daeLLst,daeElts2,source)}); 
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

        // Initial IF_EQUATION  when condition is not constant
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_IF(condition = conditions,thenBranch = tb,elseBranch = fb, info = info),SCode.INITIAL(),impl,graph)
      equation 
        (cache, expl1,props,_) = Static.elabExpList(cache,env, conditions, impl,NONE(),true,pre,info);
        (DAE.PROP((DAE.T_BOOL(_),_),DAE.C_VAR())) = Types.propsAnd(props);
        (cache,expl1) = PrefixUtil.prefixExpList(cache, env, ih, expl1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,daeLLst,_,ci_state_1,graph) = instIfTrueBranches(cache,env,ih, mod, pre, csets, ci_state, tb, true, impl, graph);
        (cache,env_2,ih,DAE.DAE(daeElts2),_,ci_state_2,graph) = Inst.instList(cache,env_1,ih, mod, pre, csets, ci_state, instEInitialEquation, fb, impl, Inst.alwaysUnroll, graph) "There are no connections inside if-clauses." ;
        dae = DAE.DAE({DAE.INITIAL_IF_EQUATION(expl1,daeLLst,daeElts2,source)});
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);

        /* `when equation\' statement, modelica 1.1 
         When statements are instantiated by evaluating the
         conditional expression.
         */ 
    case (cache,env,ih,mod,pre,csets,ci_state, eq as SCode.EQ_WHEN(condition = e,eEquationLst = el,tplAbsynExpEEquationLstLst = ((ee,eel) :: eex),info=info),(initial_ as SCode.NON_INITIAL()),impl,graph) 
      local DAE.Element daeElt2; list<DAE.ComponentRef> lhsCrefs,lhsCrefsRec; Integer i1; list<DAE.Element> daeElts3;
      equation 
        checkForNestedWhen(eq);
        (cache,e_1,prop1,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, prop1) = Ceval.cevalIfConstant(cache, env, e_1, prop1, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,DAE.DAE(daeElts1),_,_,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, el, impl, Inst.alwaysUnroll, graph);
        lhsCrefs = DAEUtil.verifyWhenEquation(daeElts1);
        (cache,env_2,ih,DAE.DAE(daeElts3 as (daeElt2 :: _)),_,ci_state_1,graph) = instEquationCommon(cache,env_1,ih, mod, pre, csets, ci_state, 
          SCode.EQ_WHEN(ee,eel,eex,NONE(),info), initial_, impl, graph);
        lhsCrefsRec = DAEUtil.verifyWhenEquation(daeElts3);
        i1 = listLength(lhsCrefs);
        lhsCrefs = Util.listUnionOnTrue(lhsCrefs,lhsCrefsRec,Exp.crefEqual);
        //TODO: fix error reporting print(" listLength pre:" +& intString(i1) +& " post: " +& intString(listLength(lhsCrefs)) +& "\n");
        true = intEq(listLength(lhsCrefs),i1);
        ci_state_2 = instEquationCommonCiTrans(ci_state_1, initial_);
        dae = DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,SOME(daeElt2),source)});
      then
        (cache,env_2,ih,dae,csets,ci_state_2,graph);
                        
    case (cache,env,ih,mod,pre,csets,ci_state, eq as SCode.EQ_WHEN(condition = e,eEquationLst = el,tplAbsynExpEEquationLstLst = {}, info = info),(initial_ as SCode.NON_INITIAL()),impl,graph)
      local list<DAE.ComponentRef> lhsCrefs; 
      equation 
        checkForNestedWhen(eq);
        (cache,e_1,prop1,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, prop1) = Ceval.cevalIfConstant(cache, env, e_1, prop1, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        
        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,env_1,ih,DAE.DAE(daeElts1),_,_,graph) = Inst.instList(cache,env,ih, mod, pre, csets, ci_state, instEEquation, el, impl, Inst.alwaysUnroll, graph);
        lhsCrefs = DAEUtil.verifyWhenEquation(daeElts1);
        // TODO: fix error reporting, print(" exps: " +& Util.stringDelimitList(Util.listMap(lhsCrefs,Exp.printComponentRefStr),", ") +& "\n");
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
        dae = DAE.DAE({DAE.WHEN_EQUATION(e_2,daeElts1,NONE(),source)});
      then
        (cache,env_1,ih,dae,csets,ci_state_1,graph);
    
    // Print error if when equations are nested.
    case (_, env, _, _, _, _, _, eq as SCode.EQ_WHEN(info = info), _, _, _)
      local
        String scope_str, eq_str;
      equation
        failure(checkForNestedWhen(eq));
        scope_str = Env.printEnvPathStr(env);
        eq_str = SCode.equationStr(eq);
        Error.addSourceMessage(Error.NESTED_WHEN, {scope_str, eq_str}, info);
      then
        fail();
        
    // seems unnecessary to handle when equations that are initial `for\' loops
    // The loop expression is evaluated to a constant array of integers, and then the loop is unrolled.   

    // Implicit range
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.END(),eEquationLst = el,info=info),initial_,impl,graph)  
      equation 
        (lst as {}) = SCode.findIteratorInEEquationLst(i,el);
        Error.addSourceMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i},info);
      then
        fail();
        
     // for i loop ... end for; NOTE: This construct is encoded as range being Absyn.END()
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = Absyn.END(),eEquationLst = el, info=info),initial_,impl,graph) 
      equation 
        (lst as _::_)=SCode.findIteratorInEEquationLst(i,el);
        tpl=Util.listFirst(lst);
        e=rangeExpression(tpl);
        (cache,e_1,DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = id_t),_), constFlag = cnst),_) = 
          Static.elabExp(cache,env, e, impl,NONE(),true, pre, info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl,NONE(), NONE, Ceval.MSG()) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache,env_1, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);

    /* for i in <expr> loop .. end for; */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = e,eEquationLst = el,info=info),initial_,impl,graph) 
      equation 
        (cache,e_1,DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = id_t), _), constFlag = cnst),_) = Static.elabExp(cache,env, e, impl,NONE(),true, pre, info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,v,_) = Ceval.ceval(cache,env, e_1, impl,NONE(), NONE, Ceval.NO_MSG()) "FIXME: Check bounds" ;
        (cache,dae,csets_1,graph) = unroll(cache, env_1, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl,graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache,env,ih,dae,csets_1,ci_state_1,graph);
      
        // A for-equation with a parameter range without binding, which is ok when
        // doing checkModel. Use a range {1} to check that the loop can be
        // instantiated.
    case (cache, env, ih, mod, pre, csets, ci_state, SCode.EQ_FOR(index = i, range = e, eEquationLst = el,info=info), initial_, impl, graph)
      equation
        true = OptManager.getOption("checkModel");
        (cache, e_1, DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = id_t), _), constFlag = cnst as DAE.C_PARAM), _) =
          Static.elabExp(cache, env, e, impl,NONE(), true, pre,info);
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        v = Values.ARRAY({Values.INTEGER(1)}, {1});
        (cache, dae, csets_1, graph) = unroll(cache, env_1, mod, pre, csets, ci_state, i, id_t, v, el, initial_, impl, graph);
        ci_state_1 = instEquationCommonCiTrans(ci_state, initial_);
      then
        (cache, env, ih, dae, csets_1, ci_state_1, graph);

      /* for i in <expr> loop .. end for; 
      where <expr> is not constant or parameter expression */  
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_FOR(index = i,range = e,eEquationLst = el,info=info),initial_,impl,graph)
      equation 
        (cache,e_1,DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = _),_), constFlag = DAE.C_VAR()),_)
          = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        // adrpo: the iterator is not in the environment, this would fail!
        // (cache,DAE.ATTR(false,false,SCode.RW(),_,_,_),(DAE.T_INTEGER(_),_),DAE.UNBOUND(),_,_,_) 
        //  = Lookup.lookupVar(cache,env, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{})) "for loops with non-constant iteration bounds" ;
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"Non-constant iteration bounds", "No suggestion"}, info);
      then
        fail();
    /* assert statements*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_ASSERT(condition = e1,message = e2,info = info),initial_,impl,graph)
      equation 
        (cache,e1_1,prop1 as DAE.PROP((DAE.T_BOOL(_),_),_),_) = Static.elabExp(cache,env, e1, impl,NONE(),true,pre,info) "assert statement" ;
        (cache, e1_1, prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl);
        (cache,e2_1,prop2 as DAE.PROP((DAE.T_STRING(_),_),_),_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache, e2_1, prop2) = Ceval.cevalIfConstant(cache, env, e2_1, prop2, impl);
        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);                
        (cache,e2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_1, pre); 

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = DAE.DAE({DAE.ASSERT(e1_2,e2_2,source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    /* terminate statements */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_TERMINATE(message= e1, info=info),initial_,impl,graph)
      equation 
        (cache,e1_1,prop1 as DAE.PROP((DAE.T_STRING(_),_),_),_) = Static.elabExp(cache,env, e1, impl,NONE(),true,pre,info);
        (cache, e1_1, prop1) = Ceval.cevalIfConstant(cache, env, e1_1, prop1, impl);
        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = DAE.DAE({DAE.TERMINATE(e1_2,source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    /* reinit statement */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_REINIT(cref = cr,expReinit = e2,info = info),initial_,impl,graph)
      local  DAE.DAElist trDae; list<DAE.Element> daeElts; 
        DAE.ComponentRef cr_2; DAE.ExpType t; DAE.Properties tprop1,tprop2;
      equation 
        (cache,SOME((e1_1 as DAE.CREF(cr_1,t),tprop1,_))) = Static.elabCref(cache,env, cr, impl,false,pre,info) "reinit statement" ;
        (cache, e1_1, tprop1) = Ceval.cevalIfConstant(cache, env, e1_1, tprop1, impl);
        (cache,e2_1,tprop2,_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache, e2_1, tprop2) = Ceval.cevalIfConstant(cache, env, e2_1, tprop2, impl);
        (e2_1,_) = Types.matchProp(e2_1,tprop2,tprop1,true);
        (cache,e1_1,e2_1,tprop1) = condenseArrayEquation(cache,env,Absyn.CREF(cr),e2,e1_1,e2_1,tprop1,tprop2,impl,pre,info);
        (cache,e2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_1, pre);
        (cache,e1_2) = PrefixUtil.prefixExp(cache, env, ih, e1_1, pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        DAE.DAE(daeElts) = instEqEquation(e1_2, tprop1, e2_2, tprop2, source, initial_, impl);
        daeElts = Util.listMap(daeElts,makeDAEArrayEqToReinitForm);
        dae = DAE.DAE(daeElts);
      then
        (cache,env,ih,dae,csets,ci_state,graph);
      
      /* Connections.root(cr) */  
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("root", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {})),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; 
      equation 
        (cache,SOME((DAE.CREF(cr_,t),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addDefiniteRoot(graph, cr_);
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);    
            
      /* Connections.potentialRoot(cr) 
      TODO: Merge all cases for potentialRoot below using standard way of handling named/positional arguments and type conversion Integer->Real
      */     
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {})),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; 
      equation 
        (cache,SOME((DAE.CREF(cr_,t),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, 0.0);
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);        
         
         /* Connections.potentialRoot(cr,priority =prio ) - priority as named argument */
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr)}, {Absyn.NAMEDARG("priority", Absyn.REAL(priority))})),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Real priority;
      equation 
        (cache,SOME((DAE.CREF(cr_,t),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, priority);
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);             

        /* Connections.potentialRoot(cr,priority) - priority as positional argument*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr),Absyn.REAL(priority)}, {})),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Real priority;
      equation 
        (cache,SOME((DAE.CREF(cr_,t),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, priority);
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);

        /* Connections.potentialRoot(cr,priority) - priority as Integer positinal argument*/
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("potentialRoot", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr),Absyn.INTEGER(priority)}, {})),initial_,impl,graph)
      local Absyn.ComponentRef cr; DAE.ComponentRef cr_; DAE.ExpType t; Integer priority;
      equation 
        (cache,SOME((DAE.CREF(cr_,t),_,_))) = Static.elabCref(cache,env, cr, false /* ??? */,false,pre,info);
        (cache,cr_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr_);
        graph = ConnectionGraph.addPotentialRoot(graph, cr_, intReal(priority));
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);

        /*Connections.branch(cr1,cr2) */        
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(info=info,
              functionName = Absyn.CREF_QUAL("Connections", {}, Absyn.CREF_IDENT("branch", {})),
              functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF(cr1), Absyn.CREF(cr2)}, {})),initial_,impl,graph)
      local Absyn.ComponentRef cr1, cr2; DAE.ComponentRef cr1_, cr2_; DAE.ExpType t; 
      equation 
        (cache,SOME((DAE.CREF(cr1_,t),_,_))) = Static.elabCref(cache,env, cr1, false /* ??? */,false,pre,info);
        (cache,SOME((DAE.CREF(cr2_,t),_,_))) = Static.elabCref(cache,env, cr2, false /* ??? */,false,pre,info);
        (cache,cr1_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr1_);
        (cache,cr2_) = PrefixUtil.prefixCref(cache,env,ih,pre, cr2_);
        graph = ConnectionGraph.addBranch(graph, cr1_, cr2_);
      then
        (cache,env,ih,DAEUtil.emptyDae,csets,ci_state,graph);
        
    case (cache,env,ih,mod,pre,csets,ci_state,SCode.EQ_NORETCALL(functionName = cr, functionArgs = fargs, info = info),initial_,impl,graph)
      local DAE.ComponentRef cr_2; DAE.ExpType t; Absyn.Path path; list<DAE.Exp> expl; Absyn.FunctionArgs fargs;
        DAE.Exp exp;
      equation 
        (cache,exp,prop1,_) = Static.elabExp(cache,env,Absyn.CALL(cr,fargs),impl,NONE(),false,pre,info);
        (cache, exp, prop1) = Ceval.cevalIfConstant(cache, env, exp, prop1, impl);
        (cache,exp) = PrefixUtil.prefixExp(cache,env,ih,exp,pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        dae = instEquationNoRetCallVectorization(exp,source);
      then
        (cache,env,ih,dae,csets,ci_state,graph);
               
    case (_,env,ih,_,_,_,_,eqn,_,impl,graph)
      equation
        true = RTOpts.debugFlag("failtrace");
        s = SCode.equationStr(eqn);
        Debug.fprint("failtrace", "- instEquationCommonWork failed for eqn: ");        
        Debug.fprint("failtrace", s +& " in scope:" +& Env.getScopeName(env) +& "\n");
      then
        fail();
  end matchcontinue;
end instEquationCommonWork;

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
        _ = Util.listMap(crs,Absyn.expCref);
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
        _ = Util.listMap(crs,Absyn.expCref);
      then ();
    case (left,_,_)
      equation
        failure(Absyn.TUPLE(_) = left);
      then ();
    case (left as Absyn.TUPLE(crs),right,info)
      equation
        s1 = Dump.printExpStr(left);
        s2 = Dump.printExpStr(right);
        s = System.stringAppendList({s1," = ",s2,";"});
        Error.addSourceMessage(Error.TUPLE_ASSIGN_CREFS_ONLY,{s},info);
      then fail();
    case (left as Absyn.TUPLE(crs),right,info)
      equation
        failure(Absyn.CALL(_,_) = right);
        s1 = Dump.printExpStr(left);
        s2 = Dump.printExpStr(right);
        s = System.stringAppendList({s1," = ",s2,";"});
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY,{s},info);
      then fail();
  end matchcontinue;
end checkTupleCallEquationMessage;

protected function instEquationNoRetCallVectorization "creates DAE for NORETCALLs and also performs vectorization if needed"
  input DAE.Exp expCall;
  input DAE.ElementSource source "the origin of the element";
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(expCall,source)
  local Absyn.Path fn; list<DAE.Exp> expl; DAE.ExpType ty; Boolean s; DAE.Exp e;
    DAE.DAElist dae1,dae2; 
    DAE.FunctionTree funcs;
    case(expCall as DAE.CALL(path=fn,expLst=expl),source) equation
      then DAE.DAE({DAE.NORETCALL(fn,expl,source)});
    case(DAE.ARRAY(ty,s,e::expl),source)
      equation
        dae1 = instEquationNoRetCallVectorization(DAE.ARRAY(ty,s,expl),source);
        dae2 = instEquationNoRetCallVectorization(e,source);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then dae;
    case(DAE.ARRAY(ty,s,{}),source) equation
      then DAEUtil.emptyDae;
  end matchcontinue;
end instEquationNoRetCallVectorization;

protected function makeDAEArrayEqToReinitForm "
Author: BZ, 2009-02 
Function for transforming DAE equations into DAE.REINIT form, used by instEquationCommon   "
  input DAE.Element inEq;
  output DAE.Element outEqn;
algorithm outEqn := matchcontinue(inEq)
  local
    DAE.ComponentRef cr,cr2; 
    DAE.Exp e1,e2,e;
    DAE.ExpType t;
    DAE.ElementSource source "the origin of the element";
    
  case(DAE.EQUATION(DAE.CREF(cr,_),e,source)) then DAE.REINIT(cr,e,source);
  case(DAE.DEFINE(cr,e,source)) then DAE.REINIT(cr,e,source);
  case(DAE.EQUEQUATION(cr,cr2,source))
    equation
      t = Exp.crefLastType(cr2);
      then DAE.REINIT(cr,DAE.CREF(cr2,t),source);
  case(_) equation print("Failure in: makeDAEArrayEqToReinitForm\n"); then fail();
end matchcontinue;
end makeDAEArrayEqToReinitForm;

protected function condenseArrayEquation "This function transforms makes the two sides of an array equation
into its condensed form. By default, most array variables are vectorized,
i.e. v becomes {v[1],v[2],..,v[n]}. But for array equations containing function calls this is not wanted.
This function detect this case and elaborates expressions without vectorization."
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Exp e1;
  input Absyn.Exp e2;
  input DAE.Exp elabedE1;
  input DAE.Exp elabedE2;
  input DAE.Properties prop "To determine if array equation";
  input DAE.Properties prop2 "To determine if array equation";
  input Boolean impl;
  input Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outE1;
  output DAE.Exp outE2;
  output DAE.Properties oprop "If we have an expandable tuple";
algorithm
  (outCache,outE1,outE2,oprop) := matchcontinue(inCache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl,inPrefix,info)
    local Env.Cache cache;
      Boolean b1,b2,b3,b4; 
      DAE.DAElist fdae1,fdae2,dae;
      DAE.Exp elabedE1_2, elabedE2_2;
      DAE.Properties prop1, prop2;
      Prefix pre;
    case(cache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl,pre,info) equation
      b3 = Types.isPropTupleArray(prop);
      b4 = Types.isPropTupleArray(prop2);
      true = boolOr(b3,b4);
      true = Exp.containFunctioncall(elabedE2);
      (e1,prop) = expandTupleEquationWithWild(e1,prop2,prop);
      (cache,elabedE1_2,prop1,_) = Static.elabExp(cache,env, e1, impl,NONE(),false,pre,info);
      (cache, elabedE1_2, prop1) = Ceval.cevalIfConstant(cache, env, elabedE1_2, prop1, impl);
      (cache,elabedE2_2,prop2,_) = Static.elabExp(cache,env, e2, impl,NONE(),false,pre,info);
      (cache, elabedE2_2, prop2) = Ceval.cevalIfConstant(cache, env, elabedE2_2, prop2, impl);
      then
        (cache,elabedE1_2,elabedE2_2,prop);
    case(cache,env,e1,e2,elabedE1,elabedE2,prop,prop2,impl,_,_)
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
    Option<Absyn.Path> op;
    list<DAE.TupleConst> tupleConst,tupleConst2;
    DAE.Const tconst;
  case(Absyn.TUPLE(aexpl), 
    DAE.PROP_TUPLE( (DAE.T_TUPLE(typeList),_) , _),
    (propTuple as DAE.PROP_TUPLE((DAE.T_TUPLE(lst),op),DAE.TUPLE_CONST(tupleConst)
    )))
    equation
      fillValue = (listLength(typeList)-listLength(aexpl));
      lst2 = Util.listFill((DAE.T_ANYTYPE(NONE),NONE()),fillValue) "types"; 
      aexpl2 = Util.listFill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions"; 
      tupleConst2 = Util.listFill(DAE.SINGLE_CONST(DAE.C_VAR),fillValue) "TupleConst's"; 
      aexpl = listAppend(aexpl,aexpl2);      
      lst = listAppend(lst,lst2);
      tupleConst = listAppend(tupleConst,tupleConst2);
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE((DAE.T_TUPLE(lst),op),DAE.TUPLE_CONST(tupleConst)));
  case(inExp, DAE.PROP_TUPLE(  (DAE.T_TUPLE(typeList),_) , _),DAE.PROP(propType,tconst))
    equation
      fillValue = (listLength(typeList)-1);
      aexpl2 = Util.listFill(Absyn.CREF(Absyn.WILD()),fillValue) "epxressions"; 
      lst2 = Util.listFill((DAE.T_ANYTYPE(NONE),NONE()),fillValue) "types";  
      tupleConst2 = Util.listFill(DAE.SINGLE_CONST(DAE.C_VAR),fillValue) "TupleConst's"; 
      aexpl = listAppend({inExp},aexpl2);
      lst = listAppend({propType},lst2); 
      tupleConst = listAppend({DAE.SINGLE_CONST(tconst)},tupleConst2);
    then
      (Absyn.TUPLE(aexpl),DAE.PROP_TUPLE((DAE.T_TUPLE(lst),NONE()),DAE.TUPLE_CONST(tupleConst)));
  case(inExp,propCall,propTuple)
    equation
      false = Types.isPropTuple(propCall);
      then (inExp,propTuple);
      case(_,_,_) equation print("expand_Tuple_Equation_With_Wild failed \n");then fail();
  end matchcontinue;
end expandTupleEquationWithWild;


protected function instEquationCommonCiTrans 
"function: instEquationCommonCiTrans  
  updats The ClassInf state machine when an equation is instantiated."
  input ClassInf.State inState;
  input SCode.Initial inInitial;
  output ClassInf.State outState;
algorithm 
  outState := matchcontinue (inState,inInitial)
    local ClassInf.State ci_state_1,ci_state;
    case (ci_state,SCode.NON_INITIAL())
      equation 
        ci_state_1 = ClassInf.trans(ci_state, ClassInf.FOUND_EQUATION());
      then
        ci_state_1;
    case (ci_state,SCode.INITIAL()) then ci_state; 
  end matchcontinue;
end instEquationCommonCiTrans;

protected function unroll "function: unroll
  Unrolling a loop is a way of removing the non-linear structure of
  the FOR clause by explicitly repeating the body of the loop once
  for each iteration."
  input Env.Cache inCache;
  input Env inEnv;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input Ident inIdent;
  input DAE.Type inIteratorType;
  input Values.Value inValue;
  input list<SCode.EEquation> inSCodeEEquationLst;
  input SCode.Initial inInitial;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outDae,outSets,outGraph):=
  matchcontinue (inCache,inEnv,inMod,inPrefix,inSets,inState,inIdent,inIteratorType,inValue,inSCodeEEquationLst,inInitial,inBoolean,inGraph)
    local
      Connect.Sets csets,csets_1,csets_2;
      list<Env.Frame> env_1,env_2,env_3,env;
      DAE.DAElist dae1,dae2,dae;
      ClassInf.State ci_state_1,ci_state;
      DAE.Mod mods;
      Prefix.Prefix pre;
      String i;
      Values.Value fst,v;
      list<Values.Value> rest;
      list<SCode.EEquation> eqs;
      SCode.Initial initial_;
      Boolean impl;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      list<Integer> dims;
      Integer dim;
      DAE.Type ty;
    case (cache,_,_,_,csets,_,_,_,Values.ARRAY(valueLst = {}),_,_,_,graph) 
    then (cache,DAEUtil.emptyDae,csets,graph);  /* impl */ 
    
    /* array equation, use instEEquation */
    case (cache,env,mods,pre,csets,ci_state,i,ty,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.NON_INITIAL()),impl,graph)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, false, SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, ty, DAE.VALBOUND(fst,DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        /* use instEEquation*/ 
        (cache,env_3,_,dae1,csets_1,ci_state_1,graph) = 
          Inst.instList(cache, env_2, InnerOuter.emptyInstHierarchy, mods, pre, csets, ci_state, instEEquation, eqs, impl, Inst.alwaysUnroll, graph);
        (cache,dae2,csets_2,graph) = unroll(cache,env, mods, pre, csets_1, ci_state_1, i, ty, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);
        
     /* initial array equation, use instEInitialEquation */
    case (cache,env,mods,pre,csets,ci_state,i,ty,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),eqs,(initial_ as SCode.INITIAL()),impl,graph)
      equation 
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, false, SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, ty, DAE.VALBOUND(fst,DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        /* Use instEInitialEquation*/
        (cache,env_3,_,dae1,csets_1,ci_state_1,graph) = 
          Inst.instList(cache, env_2, InnerOuter.emptyInstHierarchy, mods, pre, csets, ci_state, instEInitialEquation, eqs, impl, Inst.alwaysUnroll, graph);
        (cache,dae2,csets_2,graph) = unroll(cache,env, mods, pre, csets_1, ci_state_1, i, ty, Values.ARRAY(rest,dims), eqs, initial_, impl,graph);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,dae,csets_2,graph);
    case (_,_,_,_,_,_,_,_,v,_,_,_,_)
      equation 
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- InstSection.unroll failed: " +& ValuesUtil.valString(v));
      then
        fail();
  end matchcontinue;
end unroll;

protected function addForLoopScope
"Adds a scope to the environment used in for loops.
 adrpo NOTE: 
   The variability of the iterator SHOULD 
   be determined by the range constantness!"
  input Env env;
  input Ident iterName;
  input DAE.Type iterType;
  input SCode.Variability iterVariability;
  input Option<DAE.Const> constOfForIteratorRange; 
  output Env newEnv;
algorithm
  newEnv := Env.openScope(env, false, SOME(Env.forScopeName),NONE());
  newEnv := Env.extendFrameForIterator(newEnv, iterName, iterType, DAE.UNBOUND(), iterVariability, constOfForIteratorRange); 
end addForLoopScope;

public function instEqEquation "function: instEqEquation
  author: LS, ELN 
  Equations follow the same typing rules as equality expressions.
  This function adds the equation to the DAE."
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input DAE.Exp inExp3;
  input DAE.Properties inProperties4;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial5;
  input Boolean inBoolean6;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inProperties2,inExp3,inProperties4,source,inInitial5,inBoolean6)
    local
      DAE.Exp e1_1,e1,e2,e2_1;
      tuple<DAE.TType, Option<Absyn.Path>> t_1,t1,t2,t;
      DAE.DAElist dae;
      DAE.Properties p1,p2;
      SCode.Initial initial_;
      Boolean impl;
      String e1_str,t1_str,e2_str,t2_str,s1,s2;
    case (e1,(p1 as DAE.PROP(type_ = t1)),e2,(p2 as DAE.PROP(type_ = t2)),source,initial_,impl) /* impl PR. e1= lefthandside, e2=righthandside
   This seem to be a strange function. 
   wich rule is matched? or is both rules matched?
   LS: Static.type_convert in Static.match_prop can probably fail,
    then the first rule will not match. Question if whether the second
    rule can match in that case.
   This rule is matched first, if it fail the next rule is matched.
   If it fails then this rule is matched. 
   BZ(2007-05-30): Not so strange it checks for eihter exp1 or exp2 to be from expected type.*/ 
      equation 
        (e1_1,DAE.PROP(t_1,_)) = Types.matchProp(e1, p1, p2, false);
        dae = instEqEquation2(e1_1, e2, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP(type_ = t1)),e2,(p2 as DAE.PROP(type_ = t2)),source,initial_,impl) /* If it fails then this rule is matched. */ 
      equation 
        (e2_1,DAE.PROP(t_1,_)) = Types.matchProp(e2, p2, p1, true);
        dae = instEqEquation2(e1, e2_1, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP_TUPLE(type_ = t1)),e2,(p2 as DAE.PROP_TUPLE(type_ = t2)),source,initial_,impl) /* PR. */ 
      equation 
        (e1_1,DAE.PROP_TUPLE(t_1,_)) = Types.matchProp(e1, p1, p2, false);
        dae = instEqEquation2(e1_1, e2, t_1, source, initial_);
      then
        dae;
    case (e1,(p1 as DAE.PROP_TUPLE(type_ = t1)),e2,(p2 as DAE.PROP_TUPLE(type_ = t2)),source,initial_,impl) /* PR. 
      An assignment to a varaible of T_ENUMERATION type is an explicit 
      assignment to the value componnent of the enumeration, i.e. having 
      a type T_ENUM
   */ 
      equation 
        (e2_1,DAE.PROP_TUPLE(t_1,_)) = Types.matchProp(e2, p2, p1, true);
        dae = instEqEquation2(e1, e2_1, t_1, source, initial_);
      then
        dae;

    case ((e1 as DAE.CREF(componentRef = _)),DAE.PROP(type_ = (DAE.T_ENUMERATION(names = _),_)),
           e2,DAE.PROP(type_ = (t as (DAE.T_ENUMERATION(names = _),_))),source,initial_,impl)
      equation 
        dae = instEqEquation2(e1, e2, t, source, initial_);
      then
        dae;
    case (e1,DAE.PROP(type_ = t1),e2,DAE.PROP(type_ = t2),source,initial_,impl)
      equation
        e1_str = Exp.printExpStr(e1);
        t1_str = Types.unparseType(t1);
        e2_str = Exp.printExpStr(e2);
        t2_str = Types.unparseType(t2);
        s1 = System.stringAppendList({e1_str,"=",e2_str});
        s2 = System.stringAppendList({t1_str,"=",t2_str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2}, DAEUtil.getElementSourceFileInfo(source));
        Debug.fprintln("failtrace", "- InstSection.instEqEquation failed with type mismatch in equation: " +& s1 +& " tys: " +& s2);
      then
        fail();        
  end matchcontinue;
end instEqEquation;

protected function instEqEquation2 
"function: instEqEquation2
  author: LS, ELN
  This is the second stage of instEqEquation, when the types are checked."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType3;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial4;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inExp2,inType3,source,inInitial4)
    local
      DAE.DAElist dae; DAE.Exp e1,e2;
      SCode.Initial initial_;
      DAE.ComponentRef cr,c1_1,c2_1,c1,c2,assignedCr;
      DAE.ExpType t,t1,t2,tp,ty,lsty,elabedType;
      list<Integer> ds;
      tuple<DAE.TType, Option<Absyn.Path>> bc;
      DAE.DAElist dae1,dae2,decl;
      ClassInf.State cs;
      String n; list<DAE.Var> vs; 
      Option<Absyn.Path> p;
      DAE.Type tt;
      Values.Value value;
      list<DAE.Element> dael;
      DAE.FunctionTree funcs;

    case (e1,e2,(DAE.T_INTEGER(varLstInt = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_REAL(varLstReal = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_STRING(varLstString = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_BOOL(varLstBool = _),_),source,initial_)
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    case (DAE.CREF(componentRef = cr,ty = t),e2,(DAE.T_ENUMERATION(names = _),_),source,initial_)
      equation 
        dae = makeDaeDefine(cr, e2, source, initial_);
      then
        dae;

		/* array equations */
		case (e1,e2,(t as (DAE.T_ARRAY(arrayDim = _),_)),source,initial_)
				local DAE.Type t;
			equation
				dae = instArrayEquation(e1, e2, t, source, initial_);
			then dae;

    /* tuples */
    case (e1,e2,(DAE.T_TUPLE(tupleType = _),_),source,initial_) 
      equation 
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;

    /* MetaModelica types */
    case (e1,e2,(DAE.T_LIST(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_METATUPLE(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_METAOPTION(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    case (e1,e2,(DAE.T_UNIONTYPE(_),_),source,initial_)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        dae = makeDaeEquation(e1, e2, source, initial_);
      then
        dae;
    /* -------------- */
    /* Complex types extending basic type */
    case (e1,e2,(DAE.T_COMPLEX(complexTypeOption = SOME(bc)),_),source,initial_) 
      equation 
        dae = instEqEquation2(e1, e2, bc, source, initial_);
      then
       dae;
  
  /* Complex equation for records on form e1 = e2, expand to equality over record elements*/
    case (DAE.CREF(componentRef=_),DAE.CREF(componentRef=_),(DAE.T_COMPLEX(complexVarLst = {}),_),source,initial_) 
      then DAEUtil.emptyDae; 
    case (DAE.CREF(componentRef = c1,ty = t1),DAE.CREF(componentRef = c2,ty = t2),
          (DAE.T_COMPLEX(complexClassType = cs,complexVarLst = (DAE.TYPES_VAR(name = n,type_ = t) :: vs),
          complexTypeOption = bc, equalityConstraint = ec),p),source,initial_)
      local
        tuple<DAE.TType, Option<Absyn.Path>> t;
        Option<tuple<DAE.TType, Option<Absyn.Path>>> bc;
        DAE.ExpType ty22,ty2;
        DAE.EqualityConstraint ec;
      equation 
        ty2 = Types.elabType(t);
        c1_1 = Exp.extendCref(c1,ty2, n, {});
        c2_1 = Exp.extendCref(c2,ty2, n, {});
        dae1 = instEqEquation2(DAE.CREF(c1_1,ty2), DAE.CREF(c2_1,ty2), t, source, initial_);
        dae2 = instEqEquation2(DAE.CREF(c1,t1), DAE.CREF(c2,t2), (DAE.T_COMPLEX(cs,vs,bc,ec),p), source, initial_);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae; 
        
        // split a constant complex equation to its elements 
    case ((e1 as DAE.CREF(assignedCr,_)),(e2 as DAE.CALL(path=_,ty=ty)),tt as (DAE.T_COMPLEX(complexVarLst = _),_),source,initial_)
      local DAE.AvlTree dav; 
      equation
        elabedType = Types.elabType(tt);
        true = Exp.equalTypes(elabedType,ty);        
        // adrpo: 2010-02-18, bug: https://openmodelica.org:8443/cb/issue/1175?navigation=true
        // DO NOT USE Ceval.MSG() here to generate messages 
        // as it will print error messages such as:
        //   Error: Variable body.sequence_start[1] not found in scope <global scope>
        //   Error: No constant value for variable body.sequence_start[1] in scope <global scope>.
        //   Error: Variable body.sequence_angleStates[1] not found in scope <global scope>
        //   Error: No constant value for variable body.sequence_angleStates[1] in scope <global scope>.
        // These errors happen because WE HAVE NO ENVIRONMENT, so we cannot lookup or ceval any cref!
        (_,value,_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e2, false,NONE(), NONE, Ceval.NO_MSG());
        dael = assignComplexConstantConstruct(value,assignedCr,source);
        //print(" SplitComplex \n ");DAEUtil.printDAE(DAE.DAE(dael,dav)); 
      then DAE.DAE(dael); 
        
   /* all other COMPLEX equations */
   case (e1,e2, t as (DAE.T_COMPLEX(complexVarLst = _),_),source,initial_)
     local DAE.Type t;     
      equation        
     dae = instComplexEquation(e1,e2,t,source,initial_);
    then dae;
   
    case (e1,e2,t,source,initial_)
      local tuple<DAE.TType, Option<Absyn.Path>> t;
      equation 
        Debug.fprintln("failtrace", "- InstSection.instEqEquation2 failed");
      then
        fail();
  end matchcontinue;
end instEqEquation2; 

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
    DAE.ComponentRef cr,cr2,cr3;
    Integer i,index;
    Real r;
    String s,n;
    Boolean b; 
    Absyn.Path p;    
    list<String> names;
    Values.Value v; 
    list<Values.Value> vals,arrVals;
    list<DAE.Element> eqnsArray,eqns2;
    case(Values.RECORD(orderd = {},comp = {}),cr,source) then {};
    case(Values.RECORD(p, Values.RECORD(comp=_)::vals,n::names,index),cr,source)
      equation
        print(" implement assignComplexConstantConstruct for records of records\n");
      then fail();

    case(Values.RECORD(p, (v as Values.ARRAY(valueLst = arrVals))::vals, n::names, index),cr,source)
      local DAE.ExpType tp;
      equation
        tp = ValuesUtil.valueExpType(v);
        cr2 = Exp.crefAppend(cr,DAE.CREF_IDENT(n,tp,{}));
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqnsArray = assignComplexConstantConstructToArray(arrVals,cr2,source,1);
        eqns = listAppend(eqns,eqnsArray);
      then
        eqns;
    case(Values.RECORD(p, v::vals, n::names, index),cr,source)
      equation
        cr2 = Exp.crefAppend(cr,DAE.CREF_IDENT(n,DAE.ET_INT,{}));
        eqns2 = assignComplexConstantConstruct(v,cr2,source);
        eqns = assignComplexConstantConstruct(Values.RECORD(p,vals,names,index),cr,source);
        eqns = listAppend(eqns,eqns2);
      then
        eqns;
          
        // REAL
    case(Values.REAL(r),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_REAL),DAE.RCONST(r),source)};
      
    case(Values.INTEGER(i),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_INT),DAE.ICONST(i),source)};
        
    case(Values.STRING(s),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_STRING),DAE.SCONST(s),source)};
        
    case(Values.BOOL(b),cr,source)
    then {DAE.EQUATION(DAE.CREF(cr,DAE.ET_BOOL),DAE.BCONST(b),source)};

    case(constantValue,cr,source)
      equation
        print(" failure to assign: "  +& Exp.printComponentRefStr(cr) +& " to " +& ValuesUtil.valString(constantValue) +& "\n");
      then
        fail();
  end matchcontinue;
end assignComplexConstantConstruct;

protected function assignComplexConstantConstructToArray "
Helper function for assignComplexConstantConstruct
Does array indexing and assignement 
"
input list<Values.Value> arr;
input DAE.ComponentRef assigned;
input DAE.ElementSource source;
input Integer subPos;
output list<DAE.Element> eqns;
algorithm eqns := matchcontinue(arr,assigned,source,subPos)
  local
    Values.Value v;
    list<Values.Value> arrVals; 
    list<DAE.Element> eqns2;
  case({},_,_,_) then {};
  case((v  as Values.ARRAY(valueLst = arrVals))::arr,assigned,source,subPos)
    equation      
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = Exp.addSubscriptsLast(assigned,subPos);
      eqns2 = assignComplexConstantConstructToArray(arrVals,assigned,source,1);
      eqns = listAppend(eqns,eqns2);
    then 
      eqns;
  case(v::arr,assigned,source,subPos)
    equation      
      eqns = assignComplexConstantConstructToArray(arr,assigned,source,subPos+1);
      assigned = Exp.addSubscriptsLast(assigned,subPos);
      eqns2 = assignComplexConstantConstruct(v,assigned,source);
      eqns = listAppend(eqns,eqns2);
      then 
        eqns;
end matchcontinue;
end assignComplexConstantConstructToArray;

public function makeDaeEquation 
"function: makeDaeEquation
  author: LS, ELN  
  Constructs an equation in the DAE, they can be 
  either an initial equation or an ordinary equation."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource source "the origin of the element";  
  input SCode.Initial inInitial3;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inExp1,inExp2,source,inInitial3)
    local DAE.Exp e1,e2;
      DAE.FunctionTree funcs;
    case (e1,e2,source,SCode.NON_INITIAL())
      then DAE.DAE({DAE.EQUATION(e1,e2,source)});
    case (e1,e2,source,SCode.INITIAL())
      then DAE.DAE({DAE.INITIALEQUATION(e1,e2,source)});
  end matchcontinue;
end makeDaeEquation;

protected function makeDaeDefine 
"function: makeDaeDefine
  author: LS, ELN "
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input DAE.ElementSource source "the origin of the element";
  input SCode.Initial inInitial;
  output DAE.DAElist outDae;
algorithm 
  outDae := matchcontinue (inComponentRef,inExp,source,inInitial)
    local DAE.ComponentRef cr; DAE.Exp e2;
      DAE.FunctionTree funcs;
    case (cr,e2,source,SCode.NON_INITIAL())
      then DAE.DAE({DAE.DEFINE(cr,e2,source)});
    case (cr,e2,source,SCode.INITIAL())
      then DAE.DAE({DAE.INITIALDEFINE(cr,e2,source)});
  end matchcontinue;
end makeDaeDefine;

protected function instArrayEquation
	"Instantiates an array equation, i.e. an equation where both sides are arrays."
	input DAE.Exp lhs;
	input DAE.Exp rhs;
	input DAE.Type tp;
	input DAE.ElementSource source;
	input SCode.Initial initial_;
	output DAE.DAElist dae;
algorithm 
	dae := matchcontinue(lhs, rhs, tp, source, initial_)
		local
			Boolean b1, b2;
			list<Integer> ds;
			DAE.FunctionTree funcs;
			DAE.Dimension dim;
			
		/* Initial array equations with function calls => initial array equations */
		case (lhs, rhs, tp, source, SCode.INITIAL())
			equation
				b1 = Exp.containVectorFunctioncall(lhs);
				b2 = Exp.containVectorFunctioncall(rhs);
				true = boolOr(b1, b2);
				ds = Types.getDimensionSizes(tp);
				lhs = Exp.simplify(lhs);
				rhs = Exp.simplify(rhs);
			then
				DAE.DAE({DAE.INITIAL_ARRAY_EQUATION(ds, lhs, rhs, source)});

		/* Arrays with function calls => array equations */
		case (lhs, rhs, tp, source, SCode.NON_INITIAL())
			equation
				b1 = Exp.containVectorFunctioncall(lhs);
				b2 = Exp.containVectorFunctioncall(rhs);
				true = boolOr(b1, b2);
				ds = Types.getDimensionSizes(tp);
				lhs = Exp.simplify(lhs);
				rhs = Exp.simplify(rhs);
			then
				DAE.DAE({DAE.ARRAY_EQUATION(ds, lhs, rhs, source)});
				
    // Array dimension of known size.
    case (lhs, rhs, (DAE.T_ARRAY(arrayType = t, arrayDim = dim), _), source, initial_)
      local
        DAE.Dimension lhs_dim, rhs_dim;
        list<DAE.Exp> lhs_idxs, rhs_idxs;
        DAE.Type t;
      equation
        failure(equality(dim = DAE.DIM_UNKNOWN())); // adrpo: make sure the dimensions are known!
        // Expand along the first dimensions of the expressions, and generate an
        // equation for each pair of elements.
        DAE.ET_ARRAY(arrayDimensions = lhs_dim :: _) = Exp.typeof(lhs);
        DAE.ET_ARRAY(arrayDimensions = rhs_dim :: _) = Exp.typeof(rhs);
        lhs_idxs = expandArrayDimension(lhs_dim, lhs);
        rhs_idxs = expandArrayDimension(rhs_dim, rhs);
        dae = instArrayElEq(lhs, rhs, t, lhs_idxs, rhs_idxs, source, initial_);
      then
        dae;
				
    // Array dimension of known size.
    case (lhs, rhs, (DAE.T_ARRAY(arrayType = t, arrayDim = dim), _), source, initial_)
      local
        DAE.Dimension lhs_dim, rhs_dim;
        list<DAE.Exp> lhs_idxs, rhs_idxs;
        DAE.Type t;
      equation
        equality(dim = DAE.DIM_UNKNOWN()); // adrpo: make sure the dimensions are known!
        // It's ok with array equation of unknown size if checkModel is used.
			  true = OptManager.getOption("checkModel");
        // Expand along the first dimensions of the expressions, and generate an
        // equation for each pair of elements.
        DAE.ET_ARRAY(arrayDimensions = lhs_dim :: _) = Exp.typeof(lhs);
        DAE.ET_ARRAY(arrayDimensions = rhs_dim :: _) = Exp.typeof(rhs);
        lhs_idxs = expandArrayDimension(lhs_dim, lhs);
        rhs_idxs = expandArrayDimension(rhs_dim, rhs);
        dae = instArrayElEq(lhs, rhs, t, lhs_idxs, rhs_idxs, source, initial_);
      then
        dae;
				
		/* Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; */
		case (lhs, rhs, (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN), _), source, SCode.INITIAL())
			local
				String lhs_str, rhs_str, eq_str;
			equation
        // It's ok with array equation of unknown size if checkModel is used.
			  true = OptManager.getOption("checkModel");
			  // generate an initial array equation of dim 1
			then 
				DAE.DAE({DAE.INITIAL_ARRAY_EQUATION({1}, lhs, rhs, source)});

		/* Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; */
		case (lhs, rhs, (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN), _), source, SCode.NON_INITIAL())
			local
				String lhs_str, rhs_str, eq_str;
			equation
        // It's ok with array equation of unknown size if checkModel is used.
			  true = OptManager.getOption("checkModel");
			  // generate an array equation of dim 1
			then 
				DAE.DAE({DAE.ARRAY_EQUATION({1}, lhs, rhs, source)});
				
		/* Array equation of unknown size, e.g. Real x[:], y[:]; equation x = y; */
		case (lhs, rhs, (DAE.T_ARRAY(arrayDim = DAE.DIM_UNKNOWN), _), _, _)
			local
				String lhs_str, rhs_str, eq_str;
			equation
        // It's ok with array equation of unknown size if checkModel is used.
			  false = OptManager.getOption("checkModel");
				lhs_str = Exp.printExpStr(lhs);
				rhs_str = Exp.printExpStr(rhs);
				eq_str = System.stringAppendList({lhs_str, "=", rhs_str});
				Error.addMessage(Error.INST_ARRAY_EQ_UNKNOWN_SIZE, {eq_str});
			then 
				fail();

		case (_, _, _, _, _)
			equation
				Debug.fprintln("failtrace", "- InstSection.instArrayEquation failed");
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
  input list<DAE.Exp> inLhsIndices;
  input list<DAE.Exp> inRhsIndices;
  input DAE.ElementSource inSource;
  input SCode.Initial inInitial;
  output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(inLhsExp, inRhsExp, inType, inLhsIndices,
      inRhsIndices, inSource, inInitial)
    local
      DAE.Exp lhs, rhs, lhs_idx, rhs_idx;
      DAE.Type t;
      String l;
      list<String> l_rest;
      list<DAE.Exp> lhs_idxs, rhs_idxs;
      DAE.DAElist dae1, dae2;
    case (_, _, _, {}, {}, _, _) then DAEUtil.emptyDae;
    case (lhs, rhs, t, lhs_idx :: lhs_idxs, rhs_idx :: rhs_idxs, _, _)
      equation
        dae1 = instEqEquation2(lhs_idx, rhs_idx, t, inSource, inInitial);
        dae2 = instArrayElEq(lhs, rhs, t, lhs_idxs, rhs_idxs, inSource, inInitial);
        dae1 = DAEUtil.joinDaes(dae1, dae2);
      then
        dae1;
  end matchcontinue;
end instArrayElEq;

protected function unrollForLoop
"@author: adrpo
 unroll for loops that contains when statements"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPrefix;
  input Absyn.ForIterators inIterators;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatement) := matchcontinue(inCache,inEnv,inIH,inPrefix,inIterators,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
	    Env.Cache cache;
	    list<Env.Frame> env,env_1;
	    Prefix pre;
	    list<Absyn.ForIterator> restIterators, iterators;
	    list<SCode.Statement> sl;
	    SCode.Initial initial_;
	    Boolean impl;
	    tuple<DAE.TType, Option<Absyn.Path>> t;
	    DAE.Exp e_1,e_2;
	    list<DAE.Statement> sl_1,stmts,stmts1,stmts2;
	    String i, str;
	    Absyn.Exp e;
	    DAE.Statement stmt;
	    DAE.Properties prop;
	    list<tuple<Absyn.ComponentRef,Integer>> lst;
	    DAE.DAElist dae,dae1,dae2,fdae;
	    tuple<Absyn.ComponentRef, Integer> tpl;
	    DAE.ComponentRef index;
	    Absyn.ComponentRef cr;
	    Absyn.Path typePath;
	    Integer len;
	    list<SCode.Element> elementLst;
	    list<Values.Value> vals;
	    Values.Value v;
	    DAE.Const cnst;
	    DAE.Type id_t;
	    InstanceHierarchy ih;
	  
	  // only one iterator  
    case (cache,env,ih,pre,{(i,SOME(e))},sl,info,source,initial_,impl,unrollForLoops)
      equation
        (cache,e_1,prop as DAE.PROP((DAE.T_ARRAY(arrayType = id_t),_),cnst),_) = Static.elabExp(cache, env, e, impl,NONE(), true, pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        // we can unroll ONLY if we have a constant/parameter range expression
        true = listMember(cnst, {DAE.C_CONST(), DAE.C_PARAM()});        
        env_1 = addForLoopScope(env, i, id_t, SCode.VAR(), SOME(cnst));
        (cache,DAE.ATTR(false,false,SCode.RW(),_,_,_),(_,_),DAE.UNBOUND(),_,_,_,_,_) 
        = Lookup.lookupVar(cache, env_1, DAE.CREF_IDENT(i,DAE.ET_OTHER(),{}));
        (cache,v,_) = Ceval.ceval(cache, env_1, e_1, impl,NONE(), NONE, Ceval.MSG()) "FIXME: Check bounds";
        (cache,stmts) = loopOverRange(cache, env_1, ih, pre, i, v, sl, source, initial_, impl, unrollForLoops);
      then
        (cache,stmts);
	  
    // multiple for iterators 
    //  for (i in a, j in b, k in c) loop 
    //      stmts; 
    //  end for;
    // are translated to equivalent:
    //  for (i in a) loop 
    //   for (j in b) loop 
    //    for (k in c) loop 
    //      stmts;
    //    end for;
    //   end for;
    //  end for;
    case (cache,env,ih,pre,(i,SOME(e))::(restIterators as _::_),sl,info,source,initial_,impl,unrollForLoops)
      equation
        (cache,stmts) = 
           unrollForLoop(cache, env, ih, pre, {(i, SOME(e))},
              {SCode.ALG_FOR(restIterators, sl,NONE(),info)},
              info,source,initial_, impl,unrollForLoops);
      then
        (cache,stmts);
    // failure
    case (cache,env,ih,pre,inIterators,sl,info,source,initial_,impl,unrollForLoops)
      equation
        // only report errors for when in for loops
        // true = containsWhenStatements(sl);
        str = Dump.unparseAlgorithmStr(0, 
               SCode.statementToAlgorithmItem(SCode.ALG_FOR(inIterators, sl,NONE(),info)));
        Error.addSourceMessage(Error.UNROLL_LOOP_CONTAINING_WHEN(), {str}, info);
        Debug.fprintln("failtrace", "- InstSection.unrollForLoop failed on: " +& str);
      then
        fail();
  end matchcontinue;
end unrollForLoop;

protected function instForStatement 
"Helper function for instStatement"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPrefix;
  input Absyn.ForIterators inIterators;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model"; 
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatement) := matchcontinue(inCache,inEnv,inIH,inPrefix,inIterators,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
	    Env.Cache cache;
	    list<Env.Frame> env,env_1;
	    Prefix pre;
	    list<Absyn.ForIterator> restIterators, iterators;
	    list<SCode.Statement> sl;
	    SCode.Initial initial_;
	    Boolean impl;
	    tuple<DAE.TType, Option<Absyn.Path>> t;
	    DAE.Exp e_1,e_2;
	    list<DAE.Statement> sl_1,stmts;
	    String i;
	    Absyn.Exp e;
	    DAE.Statement stmt,stmt_1;
	    DAE.Properties prop;
	    list<tuple<Absyn.ComponentRef,Integer>> lst;
	    DAE.DAElist dae,dae1,dae2;
	    tuple<Absyn.ComponentRef, Integer> tpl;
	    DAE.ComponentRef index;
	    Absyn.ComponentRef cr;
	    Absyn.Path typePath;
	    Integer len;
	    list<SCode.Element> elementLst;
	    list<Values.Value> vals;
	    DAE.Const cnst;
	    InstanceHierarchy ih;

    // adrpo: unroll ALL for loops containing ALG_WHEN... done
    case (cache,env,ih,pre,inIterators,sl,info,source,initial_,impl,unrollForLoops)
      equation
        // check here that we have a when loop in the for statement.
        true = containsWhenStatements(sl);
        (cache,stmts) = unrollForLoop(cache,env,ih,pre,inIterators,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);
        
    // for loops not containing ALG_WHEN
    case (cache,env,ih,pre,inIterators,sl,info,source,initial_,impl,unrollForLoops)
      equation
        // do not unroll if it doesn't contain a when statement!
        false = containsWhenStatements(sl);
        (cache,stmts) = instForStatement_dispatch(cache,env,ih,pre,inIterators,sl,info,source,initial_,impl,unrollForLoops);
        stmts = replaceLoopDependentCrefs(stmts, inIterators);
      then
        (cache,stmts);

  end matchcontinue;
end instForStatement;

protected function replaceLoopDependentCrefs
  "Replaces all DAE.CREFs that are dependent on a loop variable with a
  DAE.ASUB."
  input list<Algorithm.Statement> inStatements;
  input Absyn.ForIterators forIterators;
  output list<Algorithm.Statement> outStatements;
algorithm
  (outStatements, _) := DAEUtil.traverseDAEEquationsStmts(inStatements,
      replaceLoopDependentCrefInExp, forIterators);
end replaceLoopDependentCrefs;

protected function replaceLoopDependentCrefInExp
  "Helper function for replaceLoopDependentCrefs."
  input DAE.Exp inExpr;
  input Absyn.ForIterators inForIterators;
  output DAE.Exp outExpr;
  output Absyn.ForIterators outForIterators;
algorithm
  (outExpr, outForIterators) := matchcontinue(inExpr, inForIterators)
    case (cr_exp as DAE.CREF(componentRef = cr), _)
      local
        DAE.Exp cr_exp;
        DAE.ComponentRef cr;
        DAE.ExpType cr_type;
        list<DAE.Subscript> cref_subs;
        list<DAE.Exp> exp_subs;
      equation
        cref_subs = Exp.crefSubs(cr);
        exp_subs = Util.listMap(cref_subs, Exp.subscriptExp);
        true = isSubsLoopDependent(exp_subs, inForIterators);
        cr = Exp.crefStripSubs(cr);
        cr_type = Exp.crefType(cr);
      then
        (DAE.ASUB(DAE.CREF(cr, cr_type), exp_subs), inForIterators);
    case (_, _) then (inExpr, inForIterators);
  end matchcontinue;
end replaceLoopDependentCrefInExp;

protected function isSubsLoopDependent
  "Checks if a list of subscripts contain any of a list of iterators."
  input list<DAE.Exp> subscripts;
  input Absyn.ForIterators iterators;
  output Boolean loopDependent;
algorithm
  loopDependent := matchcontinue(subscripts, iterators)
    case (_, {}) then false;
    case (_, (iter_name, _) :: _)
      local
        Absyn.Ident iter_name;
        DAE.Exp iter_exp;
      equation
        iter_exp = DAE.CREF(DAE.CREF_IDENT(iter_name, DAE.ET_INT(), {}), DAE.ET_INT()); 
        true = isSubsLoopDependentHelper(subscripts, iter_exp);
      then
        true;
    case (_, _ :: rest_iters)
      local
        Absyn.ForIterators rest_iters;
        Boolean res;
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
    case (subscript :: rest, _)
      equation
        true = Exp.expContains(subscript, iteratorExp);
      then true;
    case (subscript :: rest, _)
      equation
        true = isSubsLoopDependentHelper(rest, iteratorExp);
      then true;
    case (_, _) then false;
  end matchcontinue;
end isSubsLoopDependentHelper;

protected function instForStatement_dispatch 
"function for instantiating a for statement"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPrefix;
  input Absyn.ForIterators inIterators;
  input list<SCode.Statement> inForBody;
  input Absyn.Info info;
  input DAE.ElementSource source;
  input SCode.Initial inInitial;
  input Boolean inBool;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model"; 
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "for statements can produce more statements than one by unrolling";
algorithm
  (outCache,outStatement) := matchcontinue(inCache,inEnv,inIH,inPrefix,inIterators,inForBody,info,source,inInitial,inBool,unrollForLoops)
    local
	    Env.Cache cache;
	    list<Env.Frame> env,env_1;
	    Prefix pre;
	    list<Absyn.ForIterator> restIterators, iterators;
	    list<SCode.Statement> sl;
	    SCode.Initial initial_;
	    Boolean impl;
	    DAE.Type t;
	    DAE.Exp e_1,e_2;
	    list<DAE.Statement> sl_1,stmts;
	    String i;
	    Absyn.Exp e;
	    DAE.Statement stmt,stmt_1;
	    DAE.Properties prop;
	    list<tuple<Absyn.ComponentRef,Integer>> lst;
	    DAE.DAElist dae,dae1,dae2;
	    tuple<Absyn.ComponentRef, Integer> tpl;
	    DAE.ComponentRef index;
	    Absyn.ComponentRef cr;
	    Absyn.Path typePath;
	    Integer len;
	    list<SCode.Element> elementLst;
	    list<Values.Value> vals;
	    DAE.Const cnst;
	    InstanceHierarchy ih;

    // one iterator
    case (cache,env,ih,pre,{(i,SOME(e))},sl,info,source,initial_,impl,unrollForLoops)
      equation
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),cnst)),_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache,env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache, env_1, ih, pre, sl, source, initial_, impl, unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1, source);
      then
        (cache,{stmt});

    // multiple iterators
    case (cache,env,ih,pre,(i,SOME(e))::restIterators,sl,info,source,initial_,impl,unrollForLoops)
      equation        
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),cnst)),_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,stmts) = instForStatement_dispatch(cache,env_1,ih,pre,restIterators,sl,info,source,initial_,impl,unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, stmts, source);
      then
        (cache,{stmt});
    //  case (cache,env,pre,{(i,NONE())},sl,initial_,impl,unrollForLoops)
    //    equation       
    //      lst=Absyn.findIteratorInAlgorithmItemLst(i,sl);
    //      len=listLength(lst);
    //      zero=0;
    //      equality(zero=len);
    //      equality(lst={});
    //      Error.addMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i});        
    //    then
    //     fail();
    
    case (cache,env,ih,pre,(i,NONE())::restIterators,sl,info,source,initial_,impl,unrollForLoops)
      equation
        // false = containsWhenStatements(sl); 
        {} = SCode.findIteratorInStatements(i,sl);
        Error.addSourceMessage(Error.IMPLICIT_ITERATOR_NOT_FOUND_IN_LOOP_BODY,{i},info);
      then
        fail();
        
    case (cache,env,ih,pre,{(i,NONE())},sl,info,source,initial_,impl,unrollForLoops) //The verison w/o assertions
      equation
        // false = containsWhenStatements(sl);
        (lst as _::_) = SCode.findIteratorInStatements(i,sl);
        tpl=Util.listFirst(lst);
        // e = Absyn.RANGE(1,NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),cnst)),_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instStatements(cache,env_1,ih,pre,sl,source,initial_,impl,unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source,info);
        stmt = Algorithm.makeFor(i, e_2, prop, sl_1, source);
      then
        (cache,{stmt});
    case (cache,env,ih,pre,(i,NONE())::restIterators,sl,info,source,initial_,impl,unrollForLoops) //The verison w/o assertions
      equation
        // false = containsWhenStatements(sl); 
        (lst as _::_) = SCode.findIteratorInStatements(i,sl);
        tpl=Util.listFirst(lst);
        // e = Absyn.RANGE(1,NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
        e=rangeExpression(tpl);
        (cache,e_1,(prop as DAE.PROP((DAE.T_ARRAY(_,t),_),cnst)),_) = Static.elabExp(cache,env, e, impl,NONE(), true,pre,info);
        (cache, e_1) = Ceval.cevalRangeIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        env_1 = addForLoopScope(env, i, t, SCode.VAR(), SOME(cnst));
        (cache,sl_1) = instForStatement_dispatch(cache,env_1,ih,pre,restIterators,sl,info,source,initial_,impl,unrollForLoops);
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
    local DAE.Element daeEl; String s;
    // Records
    case(lhs,rhs,tp,source,initial_)
      equation
        true = Types.isRecord(tp);
        dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
      then dae;

    // External objects are treated as ordinary equations
    case (lhs,rhs,tp,source,initial_)
      equation
        true = Types.isExternalObject(tp);
        dae = makeDaeEquation(lhs,rhs,source,initial_);
        // adrpo: TODO! FIXME! shouldn't we return the dae here??!!
      // PA: do not know, but at least return the functions.
      then DAEUtil.emptyDae; 

    // adrpo 2009-05-15: also T_COMPLEX that is NOT record but TYPE should be allowed
    //                   as is used in Modelica.Mechanics.MultiBody (Orientation type)
    case(lhs,rhs,tp,source,initial_) equation
      // adrpo: TODO! check if T_COMPLEX(ClassInf.TYPE)!
      dae = makeComplexDaeEquation(lhs,rhs,source,initial_);
    then dae;

    // complex equation that is not of restriction record is not allowed
    case(lhs,rhs,tp,source,initial_)
      equation
        false = Types.isRecord(tp);
        s = Exp.printExpStr(lhs) +& " = " +& Exp.printExpStr(rhs);
        Error.addMessage(Error.ILLEGAL_EQUATION_TYPE,{s});
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
  dae := matchcontinue(lhs,rhs,source,initial_)
  local DAE.FunctionTree funcs;
    case(lhs,rhs,source,SCode.NON_INITIAL())
      then DAE.DAE({DAE.COMPLEX_EQUATION(lhs,rhs,source)});

    case(lhs,rhs,source,SCode.INITIAL())
      then DAE.DAE({DAE.INITIAL_COMPLEX_EQUATION(lhs,rhs,source)});
  end matchcontinue;
end makeComplexDaeEquation;

public function instAlgorithm 
"function: instAlgorithm 
  Algorithms are converted to the representation defined in 
  the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.AlgorithmSection inAlgorithm;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph) := 
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,unrollForLoops,inGraph)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<SCode.Statement> statements;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      SCode.AlgorithmSection algSCode;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      DAE.DAElist dae,fdae;
      
    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements),impl,unrollForLoops,graph) /* impl */ 
      equation 
        // set the source of this element
        source = DAEUtil.createElementSource(Absyn.dummyInfo, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());

        (cache,statements_1) = instStatements(cache, env, ih, pre, statements, source, SCode.NON_INITIAL(), impl, unrollForLoops);        
        
        dae = DAE.DAE({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    case (_,_,_,_,_,_,_,algSCode,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- InstSection.instAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instAlgorithm;

public function instInitialAlgorithm 
"function: instInitialAlgorithm 
  Algorithms are converted to the representation defined 
  in the module Algorithm, and the added to the DAE result.
  This function converts an algorithm section."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input SCode.AlgorithmSection inAlgorithm;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output DAE.DAElist outDae;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (outCache,outEnv,outIH,outDae,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inAlgorithm,inBoolean,unrollForLoops,inGraph)
    local
      list<Env.Frame> env_1,env;
      list<DAE.Statement> statements_1;
      Connect.Sets csets;
      ClassInf.State ci_state;
      list<SCode.Statement> statements;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.DAElist fdae,dae;
      
    case (cache,env,ih,_,pre,csets,ci_state,SCode.ALGORITHM(statements = statements),impl,unrollForLoops,graph)
      equation 
        // set the source of this element
        source = DAEUtil.createElementSource(Absyn.dummyInfo, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), NONE(), NONE());
        
        (cache,statements_1) = instStatements(cache, env, ih, pre, statements, source, SCode.INITIAL(), impl, unrollForLoops);
        
        dae = DAE.DAE({DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(statements_1),source)});
      then
        (cache,env,ih,dae,csets,ci_state,graph);

    case (_,_,_,_,_,_,_,_,_,_,_)
      equation 
        Debug.fprintln("failtrace", "- InstSection.instInitialAlgorithm failed");
      then
        fail();
  end matchcontinue;
end instInitialAlgorithm;

public function instStatements 
"function: instStatements 
  This function converts a list of algorithm statements."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPre;
  input list<SCode.Statement> inAbsynAlgorithmLst;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  output Env.Cache outCache;
  output list<DAE.Statement> outAlgorithmStatementLst;
algorithm 
  (outCache,outAlgorithmStatementLst) := matchcontinue (inCache,inEnv,inIH,inPre,inAbsynAlgorithmLst,source,initial_,inBoolean,unrollForLoops)
    local
      list<Env.Frame> env;
      Boolean impl;
      list<DAE.Statement> stmts1,stmts2,stmts;
      SCode.Statement x;
      list<SCode.Statement> xs;
      Env.Cache cache;
      Prefix pre;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;

    // empty case 
    case (cache,env,ih,pre,{},source,initial_,impl,unrollForLoops) then (cache,{});

    // general case       
    case (cache,env,ih,pre,(x :: xs),source,initial_,impl,unrollForLoops)
      equation 
        (cache,stmts1) = instStatement(cache, env, ih, pre, x, source, initial_, impl, unrollForLoops);
        (cache,stmts2) = instStatements(cache, env, ih, pre, xs, source, initial_, impl, unrollForLoops);
        stmts = listAppend(stmts1, stmts2);
      then
        (cache,stmts);
  end matchcontinue;
end instStatements;

protected function instStatement "
function: instStatement 
  This function Looks at an algorithm statement and uses functions
  in the Algorithm module to build a representation of it that can
  be used in the DAE output."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPre;
  input SCode.Statement inAlgorithm;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";  
  output Env.Cache outCache;
  output list<DAE.Statement> outStatements "more statements due to loop unrolling";
algorithm 
  (outCache,outStatements) := matchcontinue (inCache,inEnv,inIH,inPre,inAlgorithm,source,initial_,inBoolean,unrollForLoops)
    local
      DAE.ComponentRef ce,ce_1;
      DAE.ExpType t;
      DAE.Properties cprop,eprop,prop,prop1,prop2,msgprop,varprop,valprop;
      SCode.Accessibility acc;
      DAE.Exp e_1,e_2,cond_1,cond_2,msg_1,msg_2,var_1,var_2,value_1,value_2,cre,cre2;
      DAE.Statement stmt, stmt1;
      list<Env.Frame> env,env_1;
      Absyn.ComponentRef cr;
      Absyn.Exp e,e1,e2,cond,msg, assignComp,var,value,elseWhenC,vb,matchExp;
      Boolean impl,onlyCref,tupleExp;
      list<Absyn.Exp> absynExpList,inputExps,expl;
      list<DAE.Exp> expl_1,expl_2,inputExpsDAE;
      Absyn.MatchType matchType;
      list<DAE.Properties> cprops, eprops;
      DAE.Type lt,rt;
      String s,i,lhs_str,rhs_str,lt_str,rt_str;
      list<DAE.Statement> tb_1,fb_1,sl_1,stmts;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> eib_1;
      list<SCode.Statement> tb,fb,sl,elseWhenSt;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> eib,el,elseWhenRest;
      SCode.Statement alg;
      Env.Cache cache;
      Prefix pre; 
      Absyn.ForIterators forIterators;
      DAE.DAElist dae,dae1,dae2,dae3,dae4;
      InstanceHierarchy ih;
      Option<SCode.Comment> comment;
      Absyn.Info info;
      Absyn.Case case_;

    //------------------------------------------
    // Part of MetaModelica list extension. KS
    //------------------------------------------
    /* v := Array(...); */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = Absyn.ARRAY(expList),info = info),source,initial_,impl,unrollForLoops)
      local
        list<Absyn.Exp> expList;
        DAE.Type t2;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();

        // If this is a list assignment, then the Array(...) expression should
        // be evaluated to DAE.LIST

        (cache,SOME((cre,cprop,acc))) = Static.elabCref(cache,env, cr, impl,false,pre,info);
        true = MetaUtil.isList(cprop);

        (cache,DAE.CREF(ce,t)) = PrefixUtil.prefixExp(cache, env, ih, cre, pre);
        (cache,ce_1) = Static.canonCref(cache,env, ce, impl);

        // In case we have a nested list expression
        expList = MetaUtil.transformArrayNodesToListNodes(expList,{});

        (cache,e_1,eprop,_) = Static.elabListExp(cache,env, expList, cprop, impl,NONE(),true,pre,info);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);

        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeAssignment(DAE.CREF(ce_1,t), cprop, e_2, eprop, acc, initial_, source);
      then 
        (cache,{stmt});
    //-----------------------------------------//

    /* v := array(for-iterator); */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(c),
      // Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(e1,id,e2))),impl)
         value = Absyn.CALL(Absyn.CREF_IDENT("array",{}),Absyn.FOR_ITER_FARG(e1,rangeList)),info=info),source,initial_,impl,unrollForLoops)
      local
        Absyn.Exp e1,vb;
        Absyn.ForIterators rangeList;
        Absyn.ComponentRef c;
        list<Absyn.Ident> tempLoopVarNames;
        list<Absyn.AlgorithmItem> vb_body,tempLoopVarsInit;
        list<Absyn.ElementItem> tempLoopVars;
        DAE.Exp vb2;
      equation
        // rangeList = {(id,e2)};
        (tempLoopVarNames,tempLoopVars,tempLoopVarsInit) = createTempLoopVars(rangeList,{},{},{},1);

        //Transform this function call into a number of nested for-loops
        (vb_body) = createForIteratorAlgorithm(e1,rangeList,tempLoopVarNames,tempLoopVarNames,c);

        vb_body = listAppend(tempLoopVarsInit,vb_body);
        vb = Absyn.VALUEBLOCK(tempLoopVars,Absyn.VALUEBLOCKALGORITHMS(vb_body),Absyn.BOOL(true));
        (cache,vb2,_,_) = Static.elabExp(cache,env,vb,impl,NONE(),true,pre,info);

        // _ := { ... }, this will be handled in Codegen.algorithmStatement
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_ASSIGN(DAE.ET_BOOL(),
                                DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                                vb2,source);
      then
        (cache,{stmt});

    /* v := Function(for-iterator); */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(c1),
      // Absyn.CALL(c2,Absyn.FOR_ITER_FARG(e1,id,e2))),impl)
         value = Absyn.CALL(c2,Absyn.FOR_ITER_FARG(e1,rangeList)),comment = comment, info = info),source,initial_,impl,unrollForLoops)
      local
        Absyn.Exp e1,vb;
        Absyn.ForIterators rangeList;
        SCode.Statement absynStmt;
        list<Absyn.Ident> tempLoopVarNames;
        Absyn.ComponentRef c1,c2;
        list<Absyn.ElementItem> declList,tempLoopVars;
        list<Absyn.AlgorithmItem> vb_body,tempLoopVarsInit;
      equation
        // rangeList = {(id,e2)};
        (tempLoopVarNames,tempLoopVars,tempLoopVarsInit) = createTempLoopVars(rangeList,{},{},{},1);

        // Create temporary array to store the result from the for-iterator construct
        (cache,declList) = createForIteratorArray(cache,env,e1,rangeList,impl,pre,info);

        declList = listAppend(declList,tempLoopVars);

        // Create for-statements
        vb_body = createForIteratorAlgorithm(e1,rangeList,tempLoopVarNames,tempLoopVarNames,Absyn.CREF_IDENT("VEC__",{}));

        vb_body = listAppend(tempLoopVarsInit,vb_body);
        vb = Absyn.VALUEBLOCK(declList,Absyn.VALUEBLOCKALGORITHMS(vb_body),
        Absyn.CALL(c2,Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT("VEC__",{}))},{})));
        absynStmt = SCode.ALG_ASSIGN(Absyn.CREF(c1),vb,comment,info);

        (cache,stmts) = instStatement(cache,env,ih,pre,absynStmt,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);

    /* v := expr; */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = e,info = info),source,initial_,impl,unrollForLoops) 
      equation     
        (cache,SOME((cre,cprop,acc))) = Static.elabCref(cache, env, cr, impl, false,pre,info);
        (cache,DAE.CREF(ce,t)) = PrefixUtil.prefixExp(cache, env, ih, cre, pre);
        (cache,ce_1) = Static.canonCref(cache, env, ce, impl);
        (cache,e_1,eprop,_) = Static.elabExp(cache, env, e, impl,NONE(),true,pre,info);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = makeAssignment(DAE.CREF(ce_1,t), cprop, e_2, eprop, acc, initial_, source);
      then
        (cache,{stmt});

        /* der(x) := ... */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = 
          (e2 as Absyn.CALL(function_ = Absyn.CREF_IDENT(name="der"),functionArgs=(Absyn.FUNCTIONARGS(args={Absyn.CREF(cr)})) )),value = e,info = info),
          source,initial_,impl,unrollForLoops)
      local
        Absyn.Exp e2;
        DAE.Exp e2_2,e2_2_2; 
      equation 
        (cache,SOME((_,cprop,acc))) = Static.elabCref(cache,env, cr, impl,false,pre,info);
        (cache,(e2_2 as DAE.CALL(path=_)),_,_) = Static.elabExp(cache,env, e2, impl,NONE(),true,pre,info);
        (cache,e2_2_2) = PrefixUtil.prefixExp(cache, env, ih, e2_2, pre);
        (cache,e_1,eprop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeAssignment(e2_2_2, cprop, e_2, eprop, SCode.RW() ,initial_, source);
      then
        (cache,{stmt});

    // v[i] := expr (in e.g. for loops)
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = e, info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,SOME((cre,cprop,acc))) = Static.elabCref(cache,env, cr, impl,false,pre,info);
        (cache,cre2) = PrefixUtil.prefixExp(cache, env, ih, cre, pre);
        (cache,e_1,eprop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeAssignment(cre2, cprop, e_2, eprop, acc,initial_,source);
      then
        (cache,{stmt});

    // (v1,v2,..,vn) := func(...)
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e,info = info),source,initial_,impl,unrollForLoops)
      equation
        true = MetaUtil.onlyCrefExpressions(expl);
        (cache,e_1,eprop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1 as DAE.CALL(path=_), eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,expl_1,cprops,_) = Static.elabExpList(cache, env, expl, impl,NONE(),false,pre,info);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache, env, ih, expl_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeTupleAssignment(expl_2, cprops, e_2, eprop, initial_, source);
      then
        (cache,{stmt});

      // MetaModelica Matchcontinue - should come before the error message about tuple assignment
    case (cache,env,ih,pre,alg as SCode.ALG_ASSIGN(value = Absyn.MATCHEXP(matchTy=_)),source,initial_,impl,unrollForLoops)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,stmt) = createMatchStatement(cache,env,ih,pre,alg,impl,Error.getNumErrorMessages());
      then (cache,{stmt});
        
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = left, value = right, comment = comment, info = info),source,initial_,impl,unrollForLoops)
      local
        list<Absyn.ElementItem> elemList;
        list<Absyn.Exp> varList;
        Absyn.Exp left,right,lhsExp;
        DAE.Type ty;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        // Prevent infinite recursion
        failure(Absyn.MATCHEXP(matchTy=_) = right);
        failure(Absyn.VALUEBLOCK(result=_) = right);
        expl = MetaUtil.extractListFromTuple(left,0);
        onlyCref = MetaUtil.onlyCrefExpressions(expl);
        tupleExp = MetaUtil.isTupleExp(right);

        (cache,e_1,prop,_) = Static.elabExp(cache,env,right,impl,NONE(),true,pre,info);
        ty = Util.if_(tupleExp,MetaUtil.fixMetaTuple(prop),Types.getPropType(prop));
        (elemList,varList) = MetaUtil.extractOutputVarsType({ty},1,{},{});

        true = (not onlyCref) or (listLength(varList)<>listLength(expl));
        /*
          lhs := rhs; is translated into (vars=list of temporary variables with types of rhs):
          _ := matchcontinue ()
            local vars
            case ()
              equation
                vars = rhs;
                _ := matchcontinue vars
                case lhs then ();
              then ();
        */
        
        lhsExp = MetaUtil.createLhsExp(varList);
        matchExp = Absyn.MATCHEXP(Absyn.MATCH(),Absyn.TUPLE(varList),{},{Absyn.CASE(left,info,{},{},Absyn.TUPLE({}),NONE())},NONE());
        vb = Absyn.VALUEBLOCK(elemList,Absyn.VALUEBLOCKALGORITHMS(
          {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(lhsExp,right),NONE(),info),Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.WILD),matchExp),NONE(),info)}),
          Absyn.BOOL(true));
        // Debug.traceln("vb:" +& Dump.printExpStr(vb) +& "\n");
        alg = SCode.ALG_ASSIGN(Absyn.CREF(Absyn.WILD()),vb,NONE(),info);
        (cache,stmts) = instStatement(cache,env,ih,pre,alg,source,initial_,impl,unrollForLoops);
      then (cache,stmts);
        
    /* Tuple with rhs constant */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e,info=info),source,initial_,impl,unrollForLoops)
      local
        DAE.Exp unvectorisedExpl;
      equation 
        (cache,e_1,eprop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1 as DAE.TUPLE(PR = expl_1), eprop) = Ceval.cevalIfConstant(cache, env, e_1, eprop, impl);
        (_,_,_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e_1, false,NONE(), NONE, Ceval.MSG());
        (cache,expl_2,cprops,_) = Static.elabExpList(cache,env, expl, impl,NONE(),false,pre,info);
        (cache,expl_2) = PrefixUtil.prefixExpList(cache, env, ih, expl_2, pre);
        eprops = Types.propTuplePropList(eprop);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmts = Algorithm.makeAssignmentsList(expl_2, cprops, expl_1, eprops, SCode.RW(), initial_, source);
      then
        (cache,stmts);

    /* Tuple with lhs being a tuple NOT of crefs => Error */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = e as Absyn.TUPLE(expressions = expl)),source,initial_,impl,unrollForLoops)
      equation 
        failure(_ = Util.listMap(expl,Absyn.expCref));
        s = Dump.printExpStr(e);
        Error.addMessage(Error.TUPLE_ASSIGN_CREFS_ONLY, {s});
      then
        fail();
        
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = e1 as Absyn.TUPLE(expressions = expl),value = e2,info=info),source,initial_,impl,unrollForLoops)
      equation
        Absyn.CALL(functionArgs = _) = e2;
        _ = Util.listMap(expl,Absyn.expCref);
        (cache,e_1,prop1,_) = Static.elabExp(cache,env,e1,impl,NONE(),false,pre,info);
        (cache,e_2,prop2,_) = Static.elabExp(cache,env,e2,impl,NONE(),false,pre,info);
        lt = Types.getPropType(prop1);
        rt = Types.getPropType(prop2);
        false = Types.subtype(lt, rt);
        lhs_str = Exp.printExpStr(e_1);
        rhs_str = Exp.printExpStr(e_2);
        lt_str = Types.unparseType(lt);
        rt_str = Types.unparseType(rt);
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,{lhs_str,rhs_str,lt_str,rt_str}, info);
      then
        fail();

    /* Tuple with rhs not CALL or CONSTANT => Error */
    case (cache,env,ih,pre,SCode.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl),value = e,info=info),source,initial_,impl,unrollForLoops)
      equation
        // failure(Absyn.CALL(functionArgs = _) = e);
        _ = Util.listMap(expl,Absyn.expCref);
        s = Dump.printExpStr(e);
        Error.addSourceMessage(Error.TUPLE_ASSIGN_FUNCALL_ONLY, {s}, info);
      then
        fail();
        
    /* If statement*/
    case (cache,env,ih,pre,SCode.ALG_IF(boolExpr = e,trueBranch = tb,elseIfBranch = eib,elseBranch = fb,info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,e_1,prop,_) = Static.elabExp(cache,env, e, impl,NONE(),true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);        
        (cache,tb_1)= instStatements(cache,env,ih,pre, tb, source, initial_,impl,unrollForLoops);
        (cache,eib_1) = instElseIfs(cache,env,ih,pre, eib, source, initial_,impl,unrollForLoops,info);
        (cache,fb_1) = instStatements(cache,env,ih,pre, fb, source, initial_,impl,unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeIf(e_2, prop, tb_1, eib_1, fb_1, source);
      then
        (cache,{stmt});
        
    /* For loop */
    case (cache,env,ih,pre,SCode.ALG_FOR(iterators = forIterators,forBody = sl,info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,stmts) = instForStatement(cache,env,ih,pre,forIterators,sl,info,source,initial_,impl,unrollForLoops);
      then
        (cache,stmts);
        
    /* While loop */
    case (cache,env,ih,pre,SCode.ALG_WHILE(boolExpr = e,whileBody = sl, info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);        
        (cache,sl_1) = instStatements(cache,env,ih,pre,sl,source,initial_,impl,unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhile(e_2, prop, sl_1, source);
      then
        (cache,{stmt});

    /* When clause without elsewhen */
    case (cache,env,ih,pre,SCode.ALG_WHEN_A(branches = {(e,sl)}, info = info),source,initial_,impl,unrollForLoops)
      equation 
        false = containsWhenStatements(sl);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,sl_1) = instStatements(cache, env, ih, pre, sl, source, initial_, impl, unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, NONE(), source);
      then
        (cache,{stmt});
        
    /* When clause with elsewhen branch */
    case (cache,env,ih,pre,SCode.ALG_WHEN_A(branches = (e,sl)::(elseWhenRest as _::_), comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation 
        false = containsWhenStatements(sl);
        (cache,{stmt1}) = instStatement(cache,env,ih,pre,SCode.ALG_WHEN_A(elseWhenRest,comment,info),source,initial_,impl,unrollForLoops);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);        
        (cache,sl_1) = instStatements(cache, env, ih, pre, sl, source, initial_, impl, unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeWhenA(e_2, prop, sl_1, SOME(stmt1), source);
      then
        (cache,{stmt});

    // Check for nested when clauses, which are invalid.
    case (_,env,ih,_,alg as SCode.ALG_WHEN_A(branches = (_,sl)::_, info = info),_,_,_,_)
      local
        String alg_str, scope_str;
      equation
        true = containsWhenStatements(sl);
        alg_str = Dump.unparseAlgorithmStr(0,SCode.statementToAlgorithmItem(alg));
        scope_str = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.NESTED_WHEN, {scope_str, alg_str}, info);
      then fail();

    /* assert(cond,msg) */
    case (cache,env,ih,pre,SCode.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg},argNames = {}), info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,cond_1,cprop,_) = Static.elabExp(cache, env, cond, impl,NONE(), true,pre,info);
        (cache, cond_1, cprop) = Ceval.cevalIfConstant(cache, env, cond_1, cprop, impl);
        (cache,cond_2) = PrefixUtil.prefixExp(cache, env, ih, cond_1, pre);        
        (cache,msg_1,msgprop,_) = Static.elabExp(cache, env, msg, impl,NONE(), true,pre,info);
        (cache, msg_1, msgprop) = Ceval.cevalIfConstant(cache, env, msg_1, msgprop, impl);
        (cache,msg_2) = PrefixUtil.prefixExp(cache, env, ih, msg_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeAssert(cond_2, msg_2, cprop, msgprop, source);
      then
        (cache,{stmt});
        
    /* terminate(msg) */
    case (cache,env,ih,pre,SCode.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "terminate"),
          functionArgs = Absyn.FUNCTIONARGS(args = {msg},argNames = {}), info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,msg_1,msgprop,_) = Static.elabExp(cache, env, msg, impl,NONE(), true,pre,info);
        (cache, msg_1, msgprop) = Ceval.cevalIfConstant(cache, env, msg_1, msgprop, impl);
        (cache,msg_2) = PrefixUtil.prefixExp(cache, env, ih, msg_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeTerminate(msg_2, msgprop, source);
      then
        (cache,{stmt});
        
    /* reinit(variable,value) */
    case (cache,env,ih,pre,SCode.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "reinit"),
          functionArgs = Absyn.FUNCTIONARGS(args = {var,value},argNames = {}), info = info),source,initial_,impl,unrollForLoops)
      equation 
        (cache,var_1,varprop,_) = Static.elabExp(cache, env, var, impl,NONE(), true,pre,info);
        (cache, var_1, varprop) = Ceval.cevalIfConstant(cache, env, var_1, varprop, impl);
        (cache,var_2) = PrefixUtil.prefixExp(cache, env, ih, var_1, pre);
        (cache,value_1,valprop,_) = Static.elabExp(cache, env, value, impl,NONE(), true,pre,info);
        (cache, value_1, valprop) = Ceval.cevalIfConstant(cache, env, value_1, valprop, impl);
        (cache,value_2) = PrefixUtil.prefixExp(cache, env, ih, value_1, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = Algorithm.makeReinit(var_2, value_2, varprop, valprop, source);
      then
        (cache,{stmt});
        
    /* generic NORETCALL */
    case (cache,env,ih,pre,(SCode.ALG_NORETCALL(functionCall = callFunc, functionArgs = callArgs, info = info)),source,initial_,impl,unrollForLoops)
      local 
        Absyn.ComponentRef callFunc;
        Absyn.FunctionArgs callArgs;
        Absyn.Exp aea;
        list<DAE.Exp> eexpl;
        Absyn.Path ap;
        Boolean tuple_, builtin;
        DAE.InlineType inline;
        DAE.ExpType tp;
      equation
        (cache, DAE.CALL(ap, eexpl, tuple_, builtin, tp, inline), varprop, _) = 
          Static.elabExp(cache, env, Absyn.CALL(callFunc, callArgs), impl,NONE(), true,pre,info); 
        ap = PrefixUtil.prefixPath(ap,pre);
        (cache,eexpl) = PrefixUtil.prefixExpList(cache, env, ih, eexpl, pre);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_NORETCALL(DAE.CALL(ap,eexpl,tuple_,builtin,tp,inline),source);
      then
        (cache,{stmt});
         
    /* break */
    case (cache,env,ih,pre,SCode.ALG_BREAK(comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation 
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_BREAK(source);
      then
        (cache,{stmt});
        
    /* return */
    case (cache,env,ih,pre,SCode.ALG_RETURN(comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation 
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_RETURN(source);
      then
        (cache,{stmt});
        
        //------------------------------------------
    // Part of MetaModelica extension. KS
    //------------------------------------------
    /* try */
    case (cache,env,ih,pre,SCode.ALG_TRY(tryBody = sl, comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,sl_1) = instStatements(cache, env, ih, pre, sl, source, initial_, impl, unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_TRY(sl_1,source);
      then
        (cache,{stmt});
        
    /* catch */
    case (cache,env,ih,pre,SCode.ALG_CATCH(catchBody = sl, comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,sl_1) = instStatements(cache, env, ih, pre, sl, source, initial_, impl, unrollForLoops);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_CATCH(sl_1,source);
      then
        (cache,{stmt});

    /* throw */
    case (cache,env,ih,pre,SCode.ALG_THROW(comment = comment, info = info),source,initial_,impl,unrollForLoops)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_THROW(source);
      then
        (cache,{stmt});

    /* GOTO */
    case (cache,env,ih,pre,SCode.ALG_GOTO(labelName = s, comment = comment, info = info),source,initial_,impl,unrollForLoops)
      local
        String s;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_GOTO(s,source);
      then
        (cache,{stmt});

    case (cache,env,ih,pre,SCode.ALG_LABEL(labelName = s, comment = comment, info = info),source,initial_,impl,unrollForLoops)
      local
        String s;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_LABEL(s,source);
      then
        (cache,{stmt});
    
      // Helper statement for matchcontinue
    case (cache,env,ih,pre,SCode.ALG_MATCHCASES(matchType = matchType, inputExps = inputExps, switchCases = expl, comment = comment, info = info),source,_,impl,unrollForLoops)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,expl_1,_,_) = Static.elabExpList(cache,env, expl, impl,NONE(),true,pre,info);
        (cache,inputExpsDAE,_,_) = Static.elabExpList(cache,env, inputExps, impl,NONE(),true,pre,info);
        source = DAEUtil.addElementSourceFileInfo(source, info);
        stmt = DAE.STMT_MATCHCASES(matchType,inputExpsDAE,expl_1,source);
      then (cache,{stmt});

    //------------------------------------------
        
    case (cache,env,ih,pre,alg,_,initial_,impl,unrollForLoops)
      local String str;
      equation 
        true = RTOpts.debugFlag("failtrace");
        str = Dump.unparseAlgorithmStr(0,SCode.statementToAlgorithmItem(alg));
        Debug.fprintln("failtrace", "- InstSection.instStatement failed: " +& str);
        //Debug.fcall("failtrace", Dump.printAlgorithm, alg);
        //Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end instStatement;

protected function makeAssignment
  "Wrapper for Algorithm that calls either makeAssignment or makeTupleAssignment
  depending on whether the right side is a tuple or not. This makes it possible
  to do cref := function_that_returns_tuple(...)."
  input DAE.Exp inLhs;
  input DAE.Properties inLhsProps;
  input DAE.Exp inRhs;
  input DAE.Properties inRhsProps;
  input SCode.Accessibility inAccessibility;
  input SCode.Initial inInitial;
  input DAE.ElementSource inSource;
  output Algorithm.Statement outStatement;
algorithm
  outStatement := matchcontinue(inLhs, inLhsProps, inRhs, inRhsProps,
      inAccessibility, inInitial, inSource)
    local
      list<DAE.Properties> wild_props;
      Integer wild_count;
      list<DAE.Exp> wilds;
    // If the RHS is a function that returns a tuple while the LHS is a single
    // value, make a tuple of the LHS and fill in the missing elements with
    // wildcards.
    case (_, DAE.PROP(type_ = _), DAE.CALL(path = _), DAE.PROP_TUPLE(type_ = _), _, _, _)
      equation
        _ :: wild_props = Types.propTuplePropList(inRhsProps);
        wild_count = listLength(wild_props);
        wilds = Util.listFill(DAE.CREF(DAE.WILD, DAE.ET_OTHER), wild_count);
        wild_props = Util.listFill(DAE.PROP((DAE.T_ANYTYPE(NONE),NONE()), DAE.C_VAR), wild_count);
     then Algorithm.makeTupleAssignment(inLhs :: wilds, inLhsProps :: wild_props, inRhs, inRhsProps, inInitial, inSource);
    // Otherwise, call Algorithm.makeAssignment as usual.
    case (_, _, _, _, _, _, _)
      then Algorithm.makeAssignment(inLhs, inLhsProps, inRhs, inRhsProps,
        inAccessibility, inInitial, inSource);
  end matchcontinue;
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
         slst = Util.listMap(eib, Util.tuple22);
         blst = Util.listMap(slst, containsWhenStatements);
         // adrpo: add false to handle the case where list might be empty
         b3 = Util.listReduce(false::blst, boolOr);
         b4 = containsWhenStatements(rest);
         b = Util.listReduce({b1, b2, b3, b4}, boolOr);
      then b;

    // search deeper inside for
    case (SCode.ALG_FOR(forBody = lst)::rest)
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

    // search deeper inside catch
    case (SCode.ALG_CATCH(catchBody = lst)::rest)
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
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPrefix;
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
  matchcontinue (inCache,inEnv,inIH,inPrefix,inIdent,inValue,inAlgItmLst,source,inInitial,inBoolean,unrollForLoops)
    local
      list<Env.Frame> env_1,env_2,env_3,env;
      DAE.DAElist dae1,dae2,dae;
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
    case (cache,_,_,_,_,Values.ARRAY(valueLst = {}),_,source,_,_,_) 
      then (cache,{}); 
    
    /* array equation, use instAlgorithms */
    case (cache,env,ih,pre,i,Values.ARRAY(valueLst = (fst :: rest), dimLst = dim :: dims),
          algs,source,initial_,impl,unrollForLoops)
      equation
        dim = dim-1;
        dims = dim::dims;
        env_1 = Env.openScope(env, false, SOME(Env.forScopeName),NONE());
        // the iterator is not constant but the range is constant
        env_2 = Env.extendFrameForIterator(env_1, i, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(fst,DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.CONST(), SOME(DAE.C_CONST()));
        /* use instEEquation*/ 
        (cache,stmts1) = instStatements(cache, env_2, ih, pre, algs, source, initial_, impl, unrollForLoops);
        (cache,stmts2) = loopOverRange(cache, env, ih, pre, i, Values.ARRAY(rest,dims), algs, source, initial_, impl, unrollForLoops);
        stmts = listAppend(stmts1, stmts2);
      then
        (cache,stmts);
        
    case (_,_,_,_,_,v,_,_,_,_,_)
      equation 
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- InstSection.loopOverRange failed to loop over range: " +& ValuesUtil.valString(v));
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
  outExp := matchcontinue(inTuple)
    local
      Absyn.Exp e;
      Absyn.ComponentRef acref;
      Integer dimNum;           
      tuple<Absyn.ComponentRef, Integer> tpl;

    case (tpl as (acref,dimNum))
      equation
        e=Absyn.RANGE(Absyn.INTEGER(1),NONE(),Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({Absyn.CREF(acref),Absyn.INTEGER(dimNum)},{})));
      then e;
  end matchcontinue;
end rangeExpression;

/* MetaModelica Language Extension */
protected function createMatchStatement
"function: createMatchStatement
  Author: KS
  Function called by instStatement"
  input Env.Cache cache;
  input Env.Env env;
  input InstanceHierarchy ih;
  input Prefix pre;
  input SCode.Statement alg;
  input Boolean inBoolean;
  input Integer numError;
  output Env.Cache outCache;
  output DAE.Statement outStmt;
algorithm
  (outCache,outStmt,dae) := matchcontinue (cache,env,ih,pre,alg,inBoolean,numError)
    local
      DAE.Properties cprop,eprop;
      DAE.Statement stmt;
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix localPre;
      Absyn.Exp exp,e;
      DAE.ComponentRef ce;
      DAE.Exp cre,e_1,e_2;
      Boolean impl;
      SCode.Accessibility acc;
      Absyn.ComponentRef cr;
      DAE.ExpType t;
      list<Absyn.Exp> expl;
      Absyn.Info info;
      DAE.ElementSource source;
      String str1,str2;
      
    // (v1,v2,..,vn)|v|_ := matchcontinue(...). Part of MetaModelica extension. KS
    case (localCache,localEnv,ih,localPre,SCode.ALG_ASSIGN(assignComponent = exp, value = e as Absyn.MATCHEXP(matchTy=_), info = info),impl,numError)
      equation
        expl = MetaUtil.extractListFromTuple(exp, 0);
        (localCache,e) = Patternm.matchMain(e,expl,localCache,localEnv,info);
        (localCache,e_1,eprop,_) = Static.elabExp(localCache,localEnv, e, impl,NONE(),true,pre,info);
        (localCache,e_2) = PrefixUtil.prefixExp(localCache, localEnv, ih, e_1, localPre);
        source = DAEUtil.createElementSource(info,NONE(),NONE(),NONE(),NONE());
        stmt = DAE.STMT_ASSIGN(
                 DAE.ET_OTHER(),
                 DAE.CREF(DAE.WILD,DAE.ET_OTHER()),
                 e_2,source);
      then
        (localCache,stmt);

    case (_,_,_,_,SCode.ALG_ASSIGN(assignComponent = exp, value = e as Absyn.MATCHEXP(matchTy=_), info = info),_,numError)
      equation
        true = numError == Error.getNumErrorMessages();
        str1 = Dump.printExpStr(exp);
        str2 = Dump.printExpStr(e);
        Error.addSourceMessage(Error.META_MATCH_GENERAL_FAILURE, {str1,str2}, info);
      then fail();

  end matchcontinue;
end createMatchStatement;

protected function instIfTrueBranches
"Author: BZ, 2008-09
 Initialise a list of if-equations,
 if, elseif-1 ... elseif-n."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Mod inMod;
  input Prefix inPrefix;
  input Connect.Sets inSets;
  input ClassInf.State inState;
  input list<list<SCode.EEquation>> inTypeALst;
  input Boolean IE;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output list<list<DAE.Element>> outDaeLst;
  output Connect.Sets outSets;
  output ClassInf.State outState;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outDaeLst,funcs,outSets,outState,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inMod,inPrefix,inSets,inState,inTypeALst,IE,inBoolean,inGraph)
    local
      list<Env.Frame> env,env_1,env_2;
      DAE.Mod mod;
      Prefix.Prefix pre;
      Connect.Sets csets,csets_1,csets_2;
      ClassInf.State ci_state,ci_state_1,ci_state_2;
      Boolean impl;
      list<list<DAE.Element>> llb;
      list<list<SCode.EEquation>> es;
      list<SCode.EEquation> la,e;
      DAE.DAElist lb;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      SCode.EEquation eee;
      list<DAE.Element> elts;
      DAE.FunctionTree funcs1,funcs2;

    case (cache,env,ih,mod,pre,csets,ci_state,{},_,impl,graph)
      then
        (cache,env,ih,{},csets,ci_state,graph);
    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),false,impl,graph)
      equation
        (cache,env_1,ih,DAE.DAE(elts),csets_1,ci_state_1,graph) = 
           Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEEquation, e, impl, Inst.alwaysUnroll, graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) = 
           instIfTrueBranches(cache, env_1, ih, mod, pre, csets_1, ci_state_1,  es, false, impl, graph);
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);

    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),true,impl,graph)
      equation
        (cache,env_1,ih,DAE.DAE(elts),csets_1,ci_state_1,graph) = 
           Inst.instList(cache, env, ih, mod, pre, csets, ci_state, instEInitialEquation, e, impl, Inst.alwaysUnroll, graph);
        (cache,env_2,ih,llb,csets_2,ci_state_2,graph) = 
           instIfTrueBranches(cache, env_1, ih, mod, pre, csets_1, ci_state_1,  es, true, impl, graph);         
      then
        (cache,env_2,ih,elts::llb,csets_2,ci_state_2,graph);

    case (cache,env,ih,mod,pre,csets,ci_state,(e :: es),_,impl,graph)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "InstSection.instIfTrueBranches failed on equations: " +&
                       Util.stringDelimitList(Util.listMap(e, SCode.equationStr), "\n"));
      then
        fail();
  end matchcontinue;
end instIfTrueBranches;

protected function instElseIfs
"function: instElseIfs
  This function helps instStatement to handle elseif parts."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix inPre;
  input list<tuple<Absyn.Exp, list<SCode.Statement>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input DAE.ElementSource source;
  input SCode.Initial initial_;
  input Boolean inBoolean;
  input Boolean unrollForLoops "we should unroll for loops if they are part of an algorithm in a model";
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> outTplExpExpTypesPropertiesAlgorithmStatementLstLst;
algorithm
  (outCache,outTplExpExpTypesPropertiesAlgorithmStatementLstLst) :=
  matchcontinue (inCache,inEnv,inIH,inPre,inTplAbsynExpAbsynAlgorithmItemLstLst,source,initial_,inBoolean,unrollForLoops,info)
    local
      list<Env.Frame> env;
      Boolean impl;
      DAE.Exp e_1,e_2;
      DAE.Properties prop;
      list<DAE.Statement> stmts;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> tail_1;
      Absyn.Exp e;
      list<SCode.Statement> l;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> tail;
      Env.Cache cache;
      Prefix pre;
      DAE.DAElist dae,dae1,dae2,dae3;
      InstanceHierarchy ih;
      
    case (cache,env,ih,pre,{},source,initial_,impl,unrollForLoops,info) then (cache,{});

    case (cache,env,ih,pre,((e,l) :: tail),source,initial_,impl,unrollForLoops,info)
      equation
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        (cache,stmts) = instStatements(cache, env, ih, pre, l, source, initial_, impl, unrollForLoops);
        (cache,tail_1) = instElseIfs(cache,env,ih,pre,tail, source, initial_, impl, unrollForLoops,info);
      then
        (cache,(e_2,prop,stmts) :: tail_1);

    case (_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- InstSection.instElseIfs failed");
      then
        fail();
  end matchcontinue;
end instElseIfs;

protected function instConnect "
  Generates connectionsets for connections.
  Parameters and constants in connectors should generate appropriate assert statements.
  Hence, a DAE.Element list is returned as well."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;  
  input Connect.Sets inSets;
  input Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inBoolean,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2;
      DAE.ExpType t1,t2;
      DAE.Properties prop1,prop2;
      SCode.Accessibility acc;
      DAE.Attributes attr1,attr2;
      Boolean flowPrefix1,flowPrefix2,streamPrefix1,streamPrefix2,impl;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2;
      Connect.Face f1,f2;
      Connect.Sets sets_1,sets,sets_2,sets_3;
      DAE.DAElist dae;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Variability vt1,vt2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    // Check if either of the components are conditional components with
    // condition = false, in which case we should not instantiate the connection.
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation
        c1_1 = Exp.toExpCref(c1);
        (cache, c1_1) = PrefixUtil.prefixCref(cache, env, ih, pre, c1_1);
        c2_1 = Exp.toExpCref(c2);
        (cache, c2_1) = PrefixUtil.prefixCref(cache, env, ih, pre, c2_1);
        true = ConnectUtil.connectionContainsDeletedComponents(c1_1, c2_1, sets);
      then
        (cache, env, ih, sets, DAEUtil.emptyDae, graph);

    // adrpo: handle expandable connectors!
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation
        ErrorExt.setCheckpoint("expandableConnectors");        
        true = System.getHasExpandableConnectors();
        (cache,env,ih,sets,dae,graph) = connectExpandableConnectors(cache, env, ih, sets, pre, c1, c2, impl, graph, info);
        ErrorExt.rollBack("expandableConnectors");
      then
        (cache,env,ih,sets,dae,graph);
    
    // handle normal connectors!
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation
        ErrorExt.rollBack("expandableConnectors");        
        // Skip collection of dae functions here they can not be present in connector references
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,acc))) = Static.elabCref(cache,env, c1, impl, false,pre,info);
        (cache,SOME((DAE.CREF(c2_1,t2),prop2,acc))) = Static.elabCref(cache,env, c2, impl, false,pre,info);

        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr1 as DAE.ATTR(flowPrefix1,streamPrefix1,_,vt1,_,io1),ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2 as DAE.ATTR(flowPrefix2,streamPrefix2,_,vt2,_,io2),ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        validConnector(ty1) "Check that the type of the connectors are good." ;
        validConnector(ty2);
        checkConnectTypes(env, ih, c1_2, ty1, attr1, c2_2, ty2, attr2, io1, io2, info);
        f1 = ConnectUtil.componentFace(env,ih,c1_2);
        f2 = ConnectUtil.componentFace(env,ih,c2_2);
        sets_1 = ConnectUtil.updateConnectionSetTypes(sets,c1_1);
        sets_2 = ConnectUtil.updateConnectionSetTypes(sets_1,c2_1);
        // print("add connect(");print(Exp.printComponentRefStr(c1_2));print(", ");print(Exp.printComponentRefStr(c2_2));
        // print(") with ");print(Dump.unparseInnerouterStr(io1));print(", ");print(Dump.unparseInnerouterStr(io2));
        // print("\n");
        (cache,_,ih,sets_3,dae,graph) =
        connectComponents(cache, env, ih, sets_2, pre, c1_2, f1, ty1, vt1, c2_2, f2, ty2, vt2, flowPrefix1, streamPrefix1, io1, io2, graph, info);
      then
        (cache,env,ih,sets_3,dae,graph);    

    // Case to display error for non constant subscripts in connectors
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      local
        list<Absyn.Subscript> subs1,subs2;
        list<Absyn.ComponentRef> crefs1,crefs2;
        list<DAE.Properties> props1,props2;
        DAE.Const const;
        Boolean b1,b2;
        String s1,s2,s3,s4;
      equation
        subs1 = Absyn.getSubsFromCref(c1);
        crefs1 = Absyn.getCrefsFromSubs(subs1);
        subs2 = Absyn.getSubsFromCref(c2);
        crefs2 = Absyn.getCrefsFromSubs(subs2);
        //print("Crefs in " +& Dump.printComponentRefStr(c1) +& ": " +& Util.stringDelimitList(Util.listMap(crefs1,Dump.printComponentRefStr),", ") +& "\n");
        //print("Crefs in " +& Dump.printComponentRefStr(c2) +& ": " +& Util.stringDelimitList(Util.listMap(crefs2,Dump.printComponentRefStr),", ") +& "\n");
        s1 = Dump.printComponentRefStr(c1);
        s2 = Dump.printComponentRefStr(c2);
        s1 = "connect("+&s1+&", "+&s2+&")";
        checkConstantVariability(crefs1,cache,env,s1,pre,info);
        checkConstantVariability(crefs2,cache,env,s1,pre,info);
      then
        fail();

    case (cache,env,ih,sets,pre,c1,c2,impl,_,_)
      equation
        Debug.fprintln("failtrace", "- InstSection.instConnect failed for: connect(" +& 
          Dump.printComponentRefStr(c1) +& ", " +&
          Dump.printComponentRefStr(c2) +& ")");
      then
        fail();
  end matchcontinue;
end instConnect;

protected function checkConstantVariability "
Author BZ, 2009-09
  Helper function for instConnect, prints error message for the case with non constant(or parameter) subscript(/s)"
  input list<Absyn.ComponentRef> inrefs;
  input Env.Cache cache;
  input Env.Env env;
  input String affectedConnector;
  input Prefix inPrefix;
  input Absyn.Info info;
algorithm props := matchcontinue(inrefs,cache,env,affectedConnector,inPrefix,info)
  local
    Absyn.ComponentRef cr;
    Boolean b2;
    DAE.Properties prop;
    DAE.Const const;
    Prefix pre;
  case({},_,_,_,_,_) then ();
  case(cr::inrefs,cache,env,affectedConnector,pre,info)
    equation
      (_,SOME((_,prop,_))) = Static.elabCref(cache,env,cr,false,false,pre,info);
      const = Types.elabTypePropToConst({prop});
      true = Types.isParameterOrConstant(const);
      checkConstantVariability(inrefs,cache,env,affectedConnector,pre,info);
    then
      ();
  case(cr::inrefs,cache,env,affectedConnector,pre,info)
    local String s1;
    equation
      (_,SOME((_,prop,_))) = Static.elabCref(cache,env,cr,false,false,pre,info);
      const = Types.elabTypePropToConst({prop});
      false = Types.isParameterOrConstant(const);
      //print(" error for: " +& affectedConnector +& " subscript: " +& Dump.printComponentRefStr(cr) +& " non constant \n");
      s1 = Dump.printComponentRefStr(cr);
      Error.addSourceMessage(Error.CONNECTOR_ARRAY_NONCONSTANT, {affectedConnector,s1}, info);
    then
      ();
end matchcontinue;
end checkConstantVariability;

protected function connectExpandableConnectors
"@author: adrpo
  this function handle the connections of expandable connectors"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;  
  input Connect.Sets inSets;
  input Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inBoolean,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2;
      DAE.ExpType t1,t2;
      DAE.Properties prop1,prop2;
      SCode.Accessibility acc1,acc2,acc;
      DAE.Attributes attr1,attr2,attr;
      Boolean flowPrefix1,flowPrefix2,flowPrefix,streamPrefix1,streamPrefix2,streamPrefix,impl;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2,ty;
      Connect.Face f1,f2;
      Connect.Sets sets_1,sets,sets_2,sets_3;
      DAE.DAElist dae, daeExpandable;
      list<Env.Frame> env, envExpandable, envComponent, env1, env2, envComponentEmpty;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,c1_prefix,c2_prefix;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Variability vt1,vt2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String componentName, expandableConnectorName;
      Absyn.Direction dir1,dir2,dir,dirFlipped;
      DAE.Binding binding;
      Option<DAE.Const> cnstForRange;
      Lookup.SplicedExpData splicedExpData;
      ClassInf.State state;
      list<String> variables1, variables2, variablesUnion;
      DAE.ElementSource source;

    // both c1 and c2 are expandable
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,acc))) = Static.elabCref(cache, env, c1, impl, false,pre,info);
        (cache,SOME((DAE.CREF(c2_1,t2),prop2,acc))) = Static.elabCref(cache, env, c2, impl, false,pre,info);
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache, env, c2_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        DAE.ATTR(false,false,_,vt1,_,io1) = attr1;
        DAE.ATTR(false,false,_,vt2,_,io2) = attr2;
        true = isExpandableConnectorType(ty1);
        true = isExpandableConnectorType(ty2);

        // do the union of the connectors by adding the missing 
        // components from one to the other and vice-versa.
        // Debug.fprintln("expandable", 
        //  ">>>> connect(expandable, expandable)(" +& 
        //     Dump.printComponentRefStr(c1) +& ", " +&
        //     Dump.printComponentRefStr(c2) +& ")"
        //     );
        
        // get the environments of the expandable connectors
        // which contain all the virtual components.
        (_,_,_,_,_,_,_,env1,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,env2,_) = Lookup.lookupVar(cache, env, c2_2);
        
        // Debug.fprintln("expandable", 
        //   "1 connect(expandable, expandable)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")" 
        //      );
             
        //Debug.fprintln("expandable", "env ===>\n" +& Env.printEnvStr(env));
        //Debug.fprintln("expandable", "env(c1) ===>\n" +& Env.printEnvStr(env1));
        //Debug.fprintln("expandable", "env(c2) ===>\n" +& Env.printEnvStr(env2));
             
        // get the virtual components
        variables1 = Env.getVariablesFromEnv(env1);
        // Debug.fprintln("expandable", "Variables1: " +& Util.stringDelimitList(variables1, ", "));
        variables2 = Env.getVariablesFromEnv(env2);
        // Debug.fprintln("expandable", "Variables2: " +& Util.stringDelimitList(variables2, ", "));
        variablesUnion = Util.listUnion(variables1, variables2);
        // Debug.fprintln("expandable", "Union of expandable connector variables: " +& Util.stringDelimitList(variablesUnion, ", "));
        
        // Debug.fprintln("expandable", 
        //   "2 connect(expandable, expandable)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
        // then connect each of the components normally.
        (cache,env,ih,sets,dae,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,variablesUnion,impl,graph,info);
        
        // Debug.fprintln("expandable", 
        //   "<<<< connect(expandable, expandable)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
      then
        (cache,env,ih,sets,dae,graph);

    // c2 is expandable, forward to c1 expandable by switching arguments. 
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation
        // c2 is expandable
        (cache,NONE()) = Static.elabCref(cache, env, c2, impl, false,pre,info);
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,acc))) = Static.elabCref(cache,env,c1,impl,false,pre,info);
        // Debug.fprintln("expandable", 
        //   "connect(existing, expandable)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        (cache,env,ih,sets,dae,graph) = connectExpandableConnectors(cache,env,ih,sets,pre,c2,c1,impl,graph,info);
      then
        (cache,env,ih,sets,dae,graph);

    // c1 is expandable, catch error that c1 is an IDENT! it should be at least a.x 
    case (cache,env,ih,sets,pre,c1 as Absyn.CREF_IDENT(name=_),c2,impl,graph,info)
      equation
        // c1 is expandable        
        (cache,NONE()) = Static.elabCref(cache,env,c1,impl,false,pre,info);
        // adrpo: TODO! FIXME! add this as an Error not as a print!
        print("Error: The marked virtual expandable component reference in connect([" +& 
          Absyn.printComponentRefStr(c1) +& "], " +&
          Absyn.printComponentRefStr(c2) +& "); should be qualified, i.e. expandableConnectorName.virtualName!\n"); 
      then
        fail();

    // c1 is expandable and c2 is existing BUT contains MORE THAN 1 component
    // c1 is expandable and SHOULD be qualified!
    case (cache,env,ih,sets,pre,c1 as Absyn.CREF_QUAL(name=_),c2,impl,graph,info)
      equation
        // c1 is expandable        
        (cache,NONE()) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,t2),prop2,acc2))) = Static.elabCref(cache, env, c2, impl, false, pre, info);        

        // Debug.fprintln("expandable", 
        //   ">>>> connect(expandable, existing)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
        // lookup the existing connector
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        // bind the attributes
        DAE.ATTR(flowPrefix2,streamPrefix2,acc2,vt2,dir2,io2) = attr2;
        
        // Debug.fprintln("expandable", 
        //   "1 connect(expandable, existing)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );

        // strip the last prefix!
        c1_prefix = Absyn.crefStripLast(c1);
        // elab expandable connector
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,_))) = Static.elabCref(cache,env,c1_prefix,impl,false,pre,info);
        // lookup the expandable connector
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache, env, c1_2);
        // make sure is expandable!
        true = isExpandableConnectorType(ty1);
        (_,attr,ty,binding,cnstForRange,splicedExpData,_,envExpandable,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,envComponent,_) = Lookup.lookupVar(cache, env, c2_2);
        
        // we have more than 1 variables in the envComponent, we need to add an empty environment for c1
        // and dive into!
        variablesUnion = Env.getVariablesFromEnv(envComponent);
        // print("VARS MULTIPLE:" +& Util.stringDelimitList(variablesUnion, ", ") +& "\n");        
        // more than 1 variables
        true = listLength(variablesUnion) > 1;
        
        // Debug.fprintln("expandable", 
        //   "2 connect(expandable, existing[MULTIPLE])(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );        

        // get the virtual component name
        Absyn.CREF_IDENT(componentName, _) = Absyn.crefGetLastIdent(c1);
        // add the component c2 to the environment and IH as c1 with reversed input/output
        // flip direction
        dirFlipped = flipDirection(dir2);
        
        envComponentEmpty = Env.removeComponentsFromFrameV(envComponent);
        
        // add to the environment of the expandable 
        // connector the new virtual variable.
        envExpandable = Env.extendFrameV(envExpandable,
          DAE.TYPES_VAR(componentName,DAE.ATTR(flowPrefix2,streamPrefix2,acc2,vt2,dirFlipped,io2),false,
          ty2,DAE.UNBOUND(),NONE()), NONE(), Env.VAR_TYPED(), 
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

        // then connect each of the components normally.
        (cache,env,ih,sets,dae,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,variablesUnion,impl,graph,info);
      then
        (cache,env,ih,sets,dae,graph);     

    // c1 is expandable and SHOULD be qualified!
    case (cache,env,ih,sets,pre,c1 as Absyn.CREF_QUAL(name=_),c2,impl,graph,info)
      equation
        // c1 is expandable        
        (cache,NONE()) = Static.elabCref(cache, env, c1, impl, false, pre, info);
        (cache,SOME((DAE.CREF(c2_1,t2),prop2,acc2))) = Static.elabCref(cache, env, c2, impl, false, pre, info);
        
        // Debug.fprintln("expandable", 
        //   ">>>> connect(expandable, existing)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
        // lookup the existing connector
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        // bind the attributes
        DAE.ATTR(flowPrefix2,streamPrefix2,acc2,vt2,dir2,io2) = attr2;
        
        // Debug.fprintln("expandable", 
        //   "1 connect(expandable, existing)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
        // strip the last prefix!
        c1_prefix = Absyn.crefStripLast(c1);
        // elab expandable connector
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,_))) = Static.elabCref(cache, env, c1_prefix, impl, false, pre, info);
        // lookup the expandable connector
        (cache,c1_2) = Static.canonCref(cache, env, c1_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache, env, c1_2);
        // make sure is expandable!
        true = isExpandableConnectorType(ty1);
        (_,attr,ty,binding,cnstForRange,splicedExpData,_,envExpandable,_) = Lookup.lookupVar(cache, env, c1_2);
        (_,_,_,_,_,_,_,envComponent,_) = Lookup.lookupVar(cache, env, c2_2);
        
        // we have more than 1 variables in the envComponent, we need to add an empty environment for c1
        // and dive into!
        variablesUnion = Env.getVariablesFromEnv(envComponent);
        // print("VARS SINGLE:" +& Util.stringDelimitList(variablesUnion, ", ") +& "\n");
        // max 1 variable, should check for empty!
        false = listLength(variablesUnion) > 1;        
        
        // Debug.fprintln("expandable", 
        //   "2 connect(expandable, existing[SINGLE])(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        
        // get the virtual component name
        Absyn.CREF_IDENT(componentName, _) = Absyn.crefGetLastIdent(c1);
        // add the component c2 to the environment and IH as c1 with reversed input/output
        // flip direction
        dirFlipped = flipDirection(dir2);
        
        // add to the environment of the expandable 
        // connector the new virtual variable.
        envExpandable = Env.extendFrameV(envExpandable,
          DAE.TYPES_VAR(componentName,DAE.ATTR(flowPrefix2,streamPrefix2,acc2,vt2,dirFlipped,io2),false,
          ty2,DAE.UNBOUND(),NONE()), NONE(), Env.VAR_TYPED(),
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
        
        // Debug.fprintln("expandable", 
        //   "3 connect(expandable, existing[SINGLE])(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")" 
        //      );        

        //Debug.fprintln("expandable", "env expandable: " +& Env.printEnvStr(envExpandable));
        //Debug.fprintln("expandable", "env component: " +& Env.printEnvStr(envComponent));
        //Debug.fprintln("expandable", "env: " +& Env.printEnvStr(env));
        
        // now it should be in the Env, fetch the info!
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,_))) = Static.elabCref(cache, env, c1, impl, false,pre,info);
        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        // bind the attributes
        DAE.ATTR(flowPrefix1,streamPrefix1,acc1,vt1,dir1,io1) = attr1;
        
        // then connect the components normally.
        (cache,env,ih,sets,dae,graph) = instConnect(cache,env,ih,sets,pre,c1,c2,impl,graph,info);

        // adrpo: TODO! FIXME! check if is OK
        state = ClassInf.UNKNOWN(Absyn.IDENT("expandable connector"));
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());
        // declare the added component in the DAE!
        (cache,c1_2) = PrefixUtil.prefixCref(cache, env, ih, pre, c1_2);
        daeExpandable = Inst.daeDeclare(c1_2, state, ty1, 
           SCode.ATTR({}, flowPrefix1, streamPrefix1, acc1, vt1, dir1), 
           false,NONE(), {},NONE(), NONE(), 
           SOME(SCode.COMMENT(NONE(), SOME("virtual variable in expandable connector"))), 
           io1, false, source, true);
        
        dae = DAEUtil.joinDaes(dae, daeExpandable);
        
        // Debug.fprintln("expandable", 
        //   "<<<< connect(expandable, existing)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")\nDAE:\n" +&
        //      DAEDump.dump2str(daeExpandable)
        //      );
      then
        (cache,env,ih,sets,dae,graph);
    
    // both c1 and c2 are non expandable! 
    case (cache,env,ih,sets,pre,c1,c2,impl,graph,info)
      equation        
        // both of these are OK
        (cache,SOME((DAE.CREF(c1_1,t1),prop1,acc))) = Static.elabCref(cache,env, c1, impl, false,pre,info);
        (cache,SOME((DAE.CREF(c2_1,t2),prop2,acc))) = Static.elabCref(cache,env, c2, impl, false,pre,info);

        (cache,c1_2) = Static.canonCref(cache,env, c1_1, impl);
        (cache,c2_2) = Static.canonCref(cache,env, c2_1, impl);
        (cache,attr1,ty1) = Lookup.lookupConnectorVar(cache,env,c1_2);
        (cache,attr2,ty2) = Lookup.lookupConnectorVar(cache,env,c2_2);
        
        // non-expandable
        false = isExpandableConnectorType(ty1);
        false = isExpandableConnectorType(ty2);

        // Debug.fprintln("expandable", 
        //   "connect(non-expandable, non-expandable)(" +& 
        //      Dump.printComponentRefStr(c1) +& ", " +&
        //      Dump.printComponentRefStr(c2) +& ")"
        //      );
        // then connect the components normally.
      then
        fail(); // fail to enter connect normally
  end matchcontinue;
end connectExpandableConnectors;

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
  input tuple<DAE.TType, Option<Absyn.Path>> virtualExpandableTy;
  input DAE.Binding virtualExpandableBinding; 
  input Option<DAE.Const> virtualExpandableCnstForRange;
  input Env.Env virtualExpandableEnv "the virtual component environment!";
  output Env.Env outEnv "the returned updated environment";  
algorithm
  outEnv := 
  matchcontinue(inCache, inEnv, virtualExpandableCref, virtualExpandableAttr, virtualExpandableTy, 
                virtualExpandableBinding, virtualExpandableCnstForRange, virtualExpandableEnv)
    local
      Env.Cache cache;
      Env.Env topEnv "the environment we should update!";
      DAE.ComponentRef veCref, qualCref;
      DAE.Attributes veAttr,currentAttr;
      tuple<DAE.TType, Option<Absyn.Path>> veTy,currentTy;
      DAE.Binding veBinding,currentBinding; 
      Option<DAE.Const> veCnstForRange,currentCnstForRange;
      Env.Env veEnv "the virtual component environment!";
      Env.Env updatedEnv "the returned updated environment";
      Env.Env currentEnv;
      String currentName;

    // we have reached the top, update and return! 
    case (cache, topEnv, veCref as DAE.CREF_IDENT(ident = currentName), veAttr, veTy, veBinding, veCnstForRange, veEnv)
      equation
        // update the topEnv
        updatedEnv = Env.updateFrameV(
                       topEnv, 
                       DAE.TYPES_VAR(currentName, veAttr, false, veTy, veBinding, veCnstForRange), 
                       Env.VAR_TYPED(),
                       veEnv);
      then
        updatedEnv;
    
    // if we have a.b.x, update b with x and call us recursively with a.b
    case (cache, topEnv, veCref as DAE.CREF_QUAL(componentRef = _), veAttr, veTy, veBinding, veCnstForRange, veEnv)
      equation
        // get the last one 
        currentName = Exp.crefLastIdent(veCref);
        // strip the last one
        qualCref = Exp.crefStripLastIdent(veCref);
        // strip the last subs
        qualCref = Exp.crefStripLastSubs(qualCref);
        // find the correct environment to update
        (_,currentAttr,currentTy,currentBinding,currentCnstForRange,_,_,currentEnv,_) = Lookup.lookupVar(cache, topEnv, qualCref);        
        
        // update the current environment!
        currentEnv = Env.updateFrameV(
                       currentEnv, 
                       DAE.TYPES_VAR(currentName, veAttr, false, veTy, veBinding, veCnstForRange), 
                       Env.VAR_TYPED(),
                       veEnv);
                 
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
  end matchcontinue;
end updateEnvComponentsOnQualPath; 

protected function connectExpandableVariables
"@author: adrpo
  this function handle the connections of expandable connectors
  that contain components"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;  
  input Connect.Sets inSets;
  input Prefix inPrefix;
  input Absyn.ComponentRef inComponentRefLeft;
  input Absyn.ComponentRef inComponentRefRight;
  input list<String> inVariablesUnion;
  input Boolean inBoolean;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix,inComponentRefLeft,inComponentRefRight,inVariablesUnion,inBoolean,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1_2,c2_2;
      DAE.ExpType t1,t2;
      DAE.Properties prop1,prop2;
      SCode.Accessibility acc1,acc2,acc;
      DAE.Attributes attr1,attr2,attr;
      Boolean flowPrefix1,flowPrefix2,flowPrefix,streamPrefix1,streamPrefix2,streamPrefix,impl;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2,ty;
      Connect.Face f1,f2;
      Connect.Sets sets_1,sets,sets_2,sets_3;
      DAE.DAElist dae, dae1, dae2;
      list<Env.Frame> env, envExpandable, envComponent, env1, env2;
      Prefix.Prefix pre;
      Absyn.ComponentRef c1,c2,c1_full,c2_full;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      SCode.Variability vt1,vt2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      String componentName, expandableConnectorName;
      Absyn.Direction dir1,dir2,dir,dirFlipped;
      DAE.Binding binding;
      Option<DAE.Const> cnstForRange;
      Lookup.SplicedExpData splicedExpData;
      ClassInf.State state;
      list<String> names;
      String name;    

    // handle empty case
    case (cache,env,ih,sets,pre,c1,c2,{},impl,graph,info)
      then (cache,env,ih,sets,DAEUtil.emptyDae,graph);
      
    // handle recursive call
    case (cache,env,ih,sets,pre,c1,c2,name::names,impl,graph,info)
      equation
        // add name to both c1 and c2, then connect normally
        c1_full = Absyn.joinCrefs(c1, Absyn.CREF_IDENT(name, {}));
        c2_full = Absyn.joinCrefs(c2, Absyn.CREF_IDENT(name, {}));
        // Debug.fprintln("expandable", 
        //   "connect(full_expandable, full_expandable)(" +& 
        //      Dump.printComponentRefStr(c1_full) +& ", " +&
        //      Dump.printComponentRefStr(c2_full) +& ")");
        (cache,env,ih,sets,dae1,graph) = instConnect(cache,env,ih,sets,pre,c1_full,c2_full,impl,graph,info);
        
        (cache,env,ih,sets,dae2,graph) = connectExpandableVariables(cache,env,ih,sets,pre,c1,c2,names,impl,graph,info);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache,env,ih,sets,dae,graph);
  end matchcontinue;
end connectExpandableVariables;

protected function isExpandableConnectorType
"@author: adrpo
  this function checks if the given type is an expandable connector"
  input DAE.Type ty;
  output Boolean isExpandable;
algorithm
  isExpandable := matchcontinue(ty)
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_,true)),_)) then true;
    case (_) then false;
  end matchcontinue;
end isExpandableConnectorType;

protected function getStateFromType
"@author: adrpo
  this function gets the ClassInf.State from the given type.
  it will fail if the type is not a complex type."
  input DAE.Type ty;
  output ClassInf.State outState;
algorithm
  outState := matchcontinue(ty)
    local
      ClassInf.State state;
    case ((DAE.T_COMPLEX(complexClassType = state),_)) then state;
    // adpo: TODO! FIXME! add a debug print here!
    case (_) then fail();
  end matchcontinue;
end getStateFromType;

protected function isConnectorType
"@author: adrpo
  this function checks if the given type is an expandable connector"
  input DAE.Type ty;
  output Boolean isConnector;
algorithm
  isConnector := matchcontinue(ty)
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(_,false)),_)) then true;
    case (_) then false;
  end matchcontinue;
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
  outDir := matchcontinue(inDir)
    case (Absyn.INPUT()) then Absyn.OUTPUT();
    case (Absyn.OUTPUT()) then Absyn.INPUT();
    case (Absyn.BIDIR()) then Absyn.BIDIR();
  end matchcontinue;
end flipDirection;

function handleStreamConnectors
"@author: adrpo
 this function evaluates the inStream and actualStream builtin operators"
  input Prefix.Prefix pre "prefix required for checking deleted components";  
  input Connect.Sets sets;
  input DAE.DAElist inDAE;
  output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(pre, sets, inDAE)
    local
      DAE.DAElist dae;
      list<DAE.Element> elems;
      DAE.FunctionTree functions "set of functions";     

    case (pre, sets, dae)
      equation
        (dae,_,_) = DAEUtil.traverseDAE(dae, DAEUtil.emptyFuncTree, evalActualStream, sets);
        (dae,_,_) = DAEUtil.traverseDAE(dae, DAEUtil.emptyFuncTree, evalInStream, sets);        
      then
        dae;
  end matchcontinue;
end handleStreamConnectors;

protected function evalActualStream
"@author: adrpo
 this function evaluates the builtin operator actualStream.
 See Modelica Specification 3.2, page 177"
  input DAE.Exp inExp;
  input Connect.Sets inSets;
  output DAE.Exp outExp;
  output Connect.Sets outSets;
algorithm
  (outExp,outSets) := matchcontinue(inExp,inSets)
    local
      DAE.Exp exp;
      Connect.Sets sets;
      DAE.ComponentRef cref;
      Boolean result;

    // deal with actualStream
    case (DAE.CALL(path=Absyn.IDENT("actualStream"),
          expLst={DAE.CREF(componentRef = cref)}), sets)
      equation
        // Modelica Specification 3.2, page 177, Section: 15.3 Stream Operator actualStream
        // actualStream(port.h_outflow) = if port.m_flow > 0 then inStream(port.h_outflow)
        //                                                   else port.h_outflow;
        // we need to retrieve the flow variable associated with the stream variable here
        // so that we can build the expression
        exp = inExp;
      then (exp, sets);
    // no replacement needed
    case (exp, sets)
      then (exp, sets);
  end matchcontinue;
end evalActualStream;

protected function evalInStream
"@author: adrpo
 this function evaluates the builtin operator inStream.
 See Modelica Specification 3.2, page 176"
  input DAE.Exp inExp;
  input Connect.Sets inSets;
  output DAE.Exp outExp;
  output Connect.Sets outSets;
algorithm
  (outExp,outSets) := matchcontinue(inExp,inSets)
    local
      DAE.Exp exp;
      Connect.Sets sets;
      DAE.ComponentRef cref;
      Boolean result;

    // deal with inStream
    case (DAE.CALL(path=Absyn.IDENT("inStream"),
          expLst={DAE.CREF(componentRef = cref)}), sets)
      equation
        // Modelica Specification 3.2, page 176, Section: 15.2 Stream Operator inStream and Connection Equations
        // N = 1, M = 0: unconnected stream
        // inStream(m1.c.h_outflow) = m1.c.h_outflow;
        // N = 2, M = 0: two connected inside streams
        // inStream(m1.c.h_outflow) = m2.c.h_outflow;
        // inStream(m2.c.h_outflow) = m1.c.h_outflow;
        // N = 1, M = 1: one inside stream connected to one outside stream
        // inStream(m1.c.h_outflow) = inStream(c1.h_outflow);
        // // Additional equation to be generated
        // c1.h_outflow = m1.c.h_outflow;        
        exp = inExp;
      then (exp, sets);
    // no replacement needed
    case (exp, sets)
      then (exp, sets);
  end matchcontinue;
end evalInStream;

protected function validConnector
"function: validConnector
  This function tests whether a type is a eligible to be used in connections."
  input DAE.Type inType;
algorithm
  _ := matchcontinue (inType)
    local
      ClassInf.State state;
      tuple<DAE.TType, Option<Absyn.Path>> tp,t;
      String str;
    case ((DAE.T_REAL(varLstReal = _),_)) then ();
    case ((DAE.T_INTEGER(_),_)) then ();
    case ((DAE.T_STRING(_),_)) then ();
    case ((DAE.T_BOOL(_),_)) then ();
    case ((DAE.T_ENUMERATION(index = _), _)) then ();
    case ((DAE.T_COMPLEX(complexClassType = state),_))
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(false));
      then
        ();
    case ((DAE.T_COMPLEX(complexClassType = state),_))
      equation
        ClassInf.valid(state, SCode.R_CONNECTOR(true));
      then
        ();
    case ((DAE.T_ARRAY(arrayType = tp),_))
      equation
        validConnector(tp);
      then
        ();
    case t
      equation
        str = Types.unparseType(t);
        Error.addMessage(Error.INVALID_CONNECTOR_TYPE, {str});
      then
        fail();
  end matchcontinue;
end validConnector;

protected function checkConnectTypes
"function: checkConnectTypes
  Check that the type and type attributes of two
  connectors match, so that they really may be connected."
  input Env.Env env;
  input InstanceHierarchy inIH;
  input DAE.ComponentRef inComponentRef1;
  input DAE.Type inType2;
  input DAE.Attributes inAttributes3;
  input DAE.ComponentRef inComponentRef4;
  input DAE.Type inType5;
  input DAE.Attributes inAttributes6;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Absyn.Info info;
algorithm
  _ := matchcontinue (env,inIH,inComponentRef1,inType2,inAttributes3,inComponentRef4,inType5,inAttributes6,io1,io2,info)
    local
      String c1_str,c2_str;
      DAE.ComponentRef c1,c2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2;
      Boolean flow1,flow2,stream1,stream2,outer1,outer2;
      InstanceHierarchy ih;
    /* If two input connectors are connected they must have different faces */
    case (env,ih,c1,_,DAE.ATTR(direction = Absyn.INPUT()),c2,_,DAE.ATTR(direction = Absyn.INPUT()),io1,io2,info)
      equation
        InnerOuter.assertDifferentFaces(env, ih, c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_TWO_INPUTS, {c1_str,c2_str}, info);
      then
        fail();

    /* If two output connectors are connected they must have different faces */
    case (env,ih,c1,_,DAE.ATTR(direction = Absyn.OUTPUT()),c2,_,DAE.ATTR(direction = Absyn.OUTPUT()),io1,io2,info)
      equation
        InnerOuter.assertDifferentFaces(env, ih, c1, c2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_TWO_OUTPUTS, {c1_str,c2_str}, info);
      then
        fail();

    /* The type must be identical and flow of connected variables must be same */
    case (env,ih,_,t1,DAE.ATTR(flowPrefix = flow1),_,t2,DAE.ATTR(flowPrefix = flow2),io1,io2,info)
      equation
        equality(flow1 = flow2);
        true = Types.equivtypes(t1, t2) "we do not check arrays here";
        outer1 = ModUtil.isPureOuter(io1);
        outer2 = ModUtil.isPureOuter(io2);
        false = boolAnd(outer2,outer1) "outer to outer illegal";
      then
        ();

    case (_,_,c1,_,_,c2,_,_,io1,io2,info)
      equation
        true = ModUtil.isPureOuter(io1);
        true = ModUtil.isPureOuter(io2);
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_OUTER_OUTER, {c1_str,c2_str}, info);
      then
        fail();

    case (env,ih,c1,_,DAE.ATTR(flowPrefix = true),c2,_,DAE.ATTR(flowPrefix = false),io1,io2,info)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c1_str,c2_str}, info);
      then
        fail();

    case (env,ih,c1,_,DAE.ATTR(flowPrefix = false),c2,_,DAE.ATTR(flowPrefix = true),io1,io2,info)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_FLOW_TO_NONFLOW, {c2_str,c1_str}, info);
      then
        fail();

    case (env,ih,_,t1,DAE.ATTR(streamPrefix = stream1, flowPrefix = false),_,t2,DAE.ATTR(streamPrefix = stream2, flowPrefix = false),io1,io2,info)
      equation
        equality(stream1 = stream2);
        true = Types.equivtypes(t1, t2);
      then
        ();

    case (env,ih,c1,_,DAE.ATTR(streamPrefix = true, flowPrefix = false),c2,_,DAE.ATTR(streamPrefix = false, flowPrefix = false),io1,io2,info)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_STREAM_TO_NONSTREAM, {c1_str,c2_str}, info);
      then
        fail();

    case (env,ih,c1,_,DAE.ATTR(streamPrefix = false, flowPrefix = false),c2,_,DAE.ATTR(streamPrefix = true, flowPrefix = false),io1,io2,info)
      equation
        c1_str = Exp.printComponentRefStr(c1);
        c2_str = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_STREAM_TO_NONSTREAM, {c2_str,c1_str}, info);
      then
        fail();
    /* The type is not identical hence error */
    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2,info)
      local String s1,s2,s3,s4,s1_1,s2_2;
      equation
        (t1,_) = Types.flattenArrayType(t1);
        (t2,_) = Types.flattenArrayType(t2);
        false = Types.equivtypes(t1, t2) "we do not check arrays here";
        (s1,s1_1) = Types.printConnectorTypeStr(t1);
        (s2,s2_2) = Types.printConnectorTypeStr(t2);
        s3 = Exp.printComponentRefStr(c1);
        s4 = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECT_INCOMPATIBLE_TYPES, {s3,s4,s3,s1_1,s4,s2_2}, info);
      then
        fail();

    /* Different dimensionality */
    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2,info)
      local
        String s1,s2,s3,s4,s1_1,s2_2;
        list<Integer> iLst1,iLst2;
      equation
        (t1,iLst1) = Types.flattenArrayType(t1);
        (t2,iLst2) = Types.flattenArrayType(t2);
        false = Util.isListEqualWithCompareFunc(iLst1,iLst2,intEq);
        false = (listLength(iLst1)+listLength(iLst2) ==0);
        s1 = Exp.printComponentRefStr(c1);
        s2 = Exp.printComponentRefStr(c2);
        Error.addSourceMessage(Error.CONNECTOR_ARRAY_DIFFERENT, {s1,s2}, info);
      then
        fail();

    case (env,_,c1,_,_,c2,_,_,io1,io2,info)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- InstSection.checkConnectTypes(" +&
          Exp.printComponentRefStr(c1) +& " <-> " +&
          Exp.printComponentRefStr(c2) +& " failed");
      then
        fail();

    case (env,ih,c1,t1,DAE.ATTR(flowPrefix = flow1),c2,t2,DAE.ATTR(flowPrefix = flow2),io1,io2,info)
      local DAE.Type t1,t2; Boolean flow1,flow2,b0; String s0,s1,s2;
      equation
        true = RTOpts.debugFlag("failtrace");
        b0 = Types.equivtypes(t1, t2);
        s0 = Util.if_(b0,"types equivalent;","types NOT equivalent");
        s1 = Util.if_(flow1,"flow "," ");
        s2 = Util.if_(flow2,"flow "," ");
        Debug.trace("- InstSection.checkConnectTypes(");
        Debug.trace(s0);
        Debug.trace(Exp.printComponentRefStr(c1));
        Debug.trace(" : ");
        Debug.trace(s1);
        Debug.trace(Types.unparseType(t1));

        Debug.trace(Exp.printComponentRefStr(c1));
        Debug.trace(" <-> ");
        Debug.trace(Exp.printComponentRefStr(c2));
        Debug.trace(" : ");
        Debug.trace(s2);
        Debug.trace(Types.unparseType(t2));
        Debug.traceln(") failed");
      then
        fail();
  end matchcontinue;
end checkConnectTypes;

public function connectComponents "
  This function connects two components and generates connection
  sets along the way.  For simple components (of type Real) it
  adds the components to the set, and for complex types it traverses
  the subcomponents and recursively connects them to each other.
  A DAE.Element list is returned for assert statements."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix inPrefix3;
  input DAE.ComponentRef cr1;
  input Connect.Face inFace5;
  input DAE.Type inType6;
  input SCode.Variability vt1;
  input DAE.ComponentRef cr2;
  input Connect.Face inFace8;
  input DAE.Type inType9;
  input SCode.Variability vt2;
  input Boolean inFlowPrefix;
  input Boolean inStreamPrefix;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph) :=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,cr1,inFace5,inType6,vt1,cr2,inFace8,inType9,vt2,inFlowPrefix,inStreamPrefix,io1,io2,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1,c2;
      list<DAE.ComponentRef> dc;
      Connect.Sets sets_1,sets;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,bc_tp1,bc_tp2;
      SCode.Variability vr;
      DAE.Dimension dim1,dim2;
      Integer dim_int;
      DAE.DAElist dae, dae2;
      list<DAE.Var> l1,l2;
      Boolean flowPrefix, streamPrefix;
      String c1_str,t1_str,t2_str,c2_str;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      Boolean c1outer,c2outer;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      DAE.InlineType inlineType1, inlineType2;

    /* connections to outer components */
    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,false,io1,io2,graph,info)
      equation
        // print("Connecting components: " +& PrefixUtil.printPrefixStr(pre) +& "/" +&
        //    Exp.printComponentRefStr(c1) +& "[" +& Dump.unparseInnerouterStr(io1) +& "]" +& " = " +& 
        //    Exp.printComponentRefStr(c2) +& "[" +& Dump.unparseInnerouterStr(io2) +& "]\n");
        true = InnerOuter.outerConnection(io1,io2);
        
        // The cref that is outer should not be prefixed
        (c1outer,c2outer) = InnerOuter.referOuter(io1,io2);

        //c1_1 = PrefixUtil.prefixCref(pre, c1);
        //c2_1 = PrefixUtil.prefixCref(pre, c2);
        //c1_1 = Util.if_(c1outer,c1,c1_1);
        //c2_1 = Util.if_(c2outer,c2,c2_1);

        // prefix outer with the prefix of the inner directly! 
        (cache, DAE.CREF(c1_1, _)) = 
           PrefixUtil.prefixExp(cache, env, ih, DAE.CREF(c1, DAE.ET_OTHER()), pre);
        (cache, DAE.CREF(c2_1, _)) = 
           PrefixUtil.prefixExp(cache, env, ih, DAE.CREF(c2, DAE.ET_OTHER()), pre);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        // print("CONNECT: " +& PrefixUtil.printPrefixStr(pre) +& "/" +&
        //    Exp.printComponentRefStr(c1_1) +& "[" +& Dump.unparseInnerouterStr(io1) +& "]" +& " = " +& 
        //    Exp.printComponentRefStr(c2_1) +& "[" +& Dump.unparseInnerouterStr(io2) +& "]\n");
        
        sets = ConnectUtil.addOuterConnection(pre,sets,c1_1,c2_1,io1,io2,f1,f2,source);
      then 
        (cache,env,ih,sets,DAEUtil.emptyDae,graph);
        
    /* flow - with a subtype of Real */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_REAL(varLstReal = _),_),vt1,c2,f2,(DAE.T_REAL(varLstReal = _),_),vt2,true,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addFlow(sets, c1_1, f1, c2_1, f2, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* flow - with arrays */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),vt1,c2,f2,
                                      (DAE.T_ARRAY(arrayType = t2),_),vt2,true,false,io1,io2,graph,info)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t1);
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t2);
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        dim_int = Exp.dimensionSize(dim1);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addArrayFlow(sets, c1_1, f1, c2_1, f2, dim_int, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Non-flow and Non-stream type Parameters and constants generate assert statements */
    case (cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,false,false,io1,io2,graph,info)
      local list<Boolean> bolist,bolist2;
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        true = SCode.isParameterOrConst(vt1) and SCode.isParameterOrConst(vt2) ;
        true = Types.basicType(t1);
        true = Types.basicType(t2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

      then
        (cache,env,ih,sets,DAE.DAE({
          DAE.ASSERT(
            DAE.RELATION(DAE.CREF(c1_1,DAE.ET_REAL()),DAE.EQUAL(DAE.ET_BOOL()),DAE.CREF(c2_1,DAE.ET_REAL())),
            DAE.SCONST("automatically generated from connect"),
            source) // set the origin of the element
          }),graph);

    /* Same as above, but returns empty (removed conditional var) */
    case (cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        true = SCode.isParameterOrConst(vt1) and SCode.isParameterOrConst(vt2) ;
        true = Types.basicType(t1);
        true = Types.basicType(t2);
        //print("  Same as above, but returns empty (removed conditional var)\n");
      then
        (cache,env,ih,sets,DAEUtil.emptyDae,graph);

    /* connection of two Reals */        
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_REAL(varLstReal = _),_),vt1,c2,_,(DAE.T_REAL(varLstReal = _),_),vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* connection of two Integers */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_INTEGER(varLstInt = _),_),vt1,c2,_,(DAE.T_INTEGER(varLstInt = _),_),vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* connection of two Booleans */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_BOOL(_),_),vt1,c2,_,(DAE.T_BOOL(_),_),vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Connection of two Strings */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_STRING(_),_),vt1,c2,_,(DAE.T_STRING(_),_),vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Connection of two enumeration variables */
    case (cache,env,ih,sets,pre,c1,_,(DAE.T_ENUMERATION(index = NONE),_),vt1,c2,_,(DAE.T_ENUMERATION(index = NONE),_),vt2,false,false,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache, env, ih, pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache, env, ih, pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addEqu(sets, c1_1, c2_1, source);
      then
        (cache, env, ih, sets_1, DAEUtil.emptyDae, graph);

    /* Connection of arrays of complex types */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),vt1,
                                c2,f2,(DAE.T_ARRAY(arrayDim = dim2,arrayType = t2),_),vt2,
                                flowPrefix as false, streamPrefix as false,io1,io2,graph,info)
      equation
        ((DAE.T_COMPLEX(complexClassType=_),_)) = Types.arrayElementType(t1);
        ((DAE.T_COMPLEX(complexClassType=_),_)) = Types.arrayElementType(t2);

        true = Exp.dimensionsKnownAndEqual(dim1, dim2);
        dim_int = Exp.dimensionSize(dim1);

        (cache,_,ih,sets_1,dae,graph) = connectArrayComponents(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,dim_int,1,graph,info);
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Connection of arrays */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),vt1,
                                c2,f2,(DAE.T_ARRAY(arrayDim = dim2,arrayType = t2),_),vt2,
                                flowPrefix as false,streamPrefix as false,io1,io2,graph,info)
      local
        list<DAE.Dimension> dims,dims2;
        list<Integer> idims,idims2;
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        DAE.ET_ARRAY(_,dims) = Types.elabType(inType6);
        DAE.ET_ARRAY(_,dims2) = Types.elabType(inType9);
        true = Util.isListEqualWithCompareFunc(dims, dims2, Exp.dimensionsKnownAndEqual);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addMultiArrayEqu(sets, c1_1, c2_1, dims, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);

    /* Connection of connectors with an equality constraint.*/
    case (cache,env,ih,sets,pre,c1,f1,t1 as (DAE.T_COMPLEX(equalityConstraint=SOME((fpath1,dim1,inlineType1))),_),vt1,
                                c2,f2,t2 as (DAE.T_COMPLEX(equalityConstraint=SOME((fpath2,dim2,inlineType2))),_),vt2,
                                flowPrefix as false, streamPrefix as false,io1,io2,
        (graph as ConnectionGraph.GRAPH(updateGraph = true)),info)
      local
        Absyn.Path fpath1, fpath2;
        Integer dim1, dim2;
        DAE.Exp zeroVector;
        list<DAE.Element> elements, breakDAEElements;
        DAE.FunctionTree functions, equalityConstraintFunctions;
        DAE.DAElist equalityConstraintDAE;
        SCode.Class equalityConstraintFunction;
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        // Connect components ignoring equality constraints
        (cache,env,ih,sets_1,dae,_) =
        connectComponents(
          cache, env, ih, sets, pre,
          c1, f1, t1, vt1,
          c2, f2, t2, vt2,
          flowPrefix, streamPrefix, 
          io1, io2, ConnectionGraph.NOUPDATE_EMPTY, info);

        /* We can form the daes from connection set already at this point
           because there must not be flow components in types having equalityConstraint.
           TODO Is this correct if inner/outer has been used? */
        //(dae2,graph) = ConnectUtil.equations(sets_1,pre,false,graph);
        //dae = listAppend(dae, dae2);
        //DAE.printDAE(DAE.DAE(dae));

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        // Add an edge to connection graph. The edge contains the 
        // dae to be added in the case where the edge is broken.
        zeroVector = Exp.makeRealArrayOfZeros(dim1);
        breakDAEElements = 
          {DAE.ARRAY_EQUATION({dim1}, zeroVector,
                        DAE.CALL(fpath1,{DAE.CREF(c1_1, DAE.ET_OTHER()), DAE.CREF(c2_1, DAE.ET_OTHER())},
                                 false, false, DAE.ET_REAL(), inlineType1), // use the inline type
                        source // set the origin of the element
                        )};
        graph = ConnectionGraph.addConnection(graph, c1_1, c2_1, breakDAEElements);
 
        // deal with equalityConstraint function!
        // instantiate and add the equalityConstraint function to the dae function tree!
        (cache,equalityConstraintFunction,env) = Lookup.lookupClass(cache,env,fpath1,false);
        (cache,fpath1) = Inst.makeFullyQualified(cache,env,fpath1);
        cache = Env.addCachedInstFuncGuard(cache,fpath1);
        (cache,env,ih) = 
            Inst.implicitFunctionInstantiation(cache,env,ih,DAE.NOMOD(),pre,sets_1,equalityConstraintFunction,{});
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Complex types t1 extending basetype */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_COMPLEX(complexVarLst = l1,complexTypeOption = SOME(bc_tp1)),_),vt1,c2,f2,t2,vt2,
           flowPrefix,streamPrefix,io1,io2,graph,info)
      equation
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache, env, ih, sets, pre, c1, f1, bc_tp1,vt1, c2, f2, t2,vt2, flowPrefix,streamPrefix,io1,io2, graph,info);
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Complex types t2 extending basetype */
    case (cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,(DAE.T_COMPLEX(complexVarLst = l1,complexTypeOption = SOME(bc_tp2)),_),vt2,flowPrefix,streamPrefix,io1,io2,graph,info)
      equation
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih, sets, pre, c1, f1, t1, vt1,c2, f2, bc_tp2,vt2, flowPrefix,streamPrefix,io1,io2,graph,info);
      then
        (cache,env,ih,sets_1,dae,graph);

    /* Connection of complex connector, e.g. Pin */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_COMPLEX(complexVarLst = l1),_),vt1,c2,f2,(DAE.T_COMPLEX(complexVarLst = l2),_),vt2,_,_,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        (cache,_,ih,sets_1,dae,graph) = connectVars(cache,env,ih, sets, c1_1, f1, l1, vt1, c2_1, f2, l2, vt2, io1, io2, graph, info);
      then
        (cache,env,ih,sets_1,dae,graph);

    // stream connector variables with subtype real    
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_REAL(varLstReal = _),_),vt1,c2,f2,(DAE.T_REAL(varLstReal = _),_),vt2,false,true,io1,io2,graph,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addStream(sets, c1_1, f1, c2_1, f2, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);
        
    /* stream - with arrays */
    case (cache,env,ih,sets,pre,c1,f1,(DAE.T_ARRAY(arrayDim = dim1,arrayType = t1),_),vt1,c2,
                                   f2,(DAE.T_ARRAY(arrayType = t2),_),vt2,false,true,io1,io2,graph,info)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t1);
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(t2);
        dim_int = Exp.dimensionSize(dim1);
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);

        // set the source of this element
        source = DAEUtil.createElementSource(info, Env.getEnvPath(env), PrefixUtil.prefixToCrefOpt(pre), SOME((c1_1,c2_1)), NONE());

        sets_1 = ConnectUtil.addArrayStream(sets, c1_1, f1, c2_1, f2, dim_int, source);
      then
        (cache,env,ih,sets_1,DAEUtil.emptyDae,graph);        

    /* Error */
    case (cache,env,ih,_,pre,c1,_,t1,vt1,c2,_,t2,vt2,_,_,io1,io2,_,info)
      equation
        (cache,c1_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c1);
        (cache,c2_1) = PrefixUtil.prefixCref(cache,env,ih,pre, c2);
        c1_str = Exp.printComponentRefStr(c1);
        t1_str = Types.unparseType(t1);
        c2_str = Exp.printComponentRefStr(c2);
        t2_str = Types.unparseType(t2);
        c1_str = System.stringAppendList({c1_str," and ",c2_str});
        t1_str = System.stringAppendList({t1_str," and ",t2_str});
        Error.addSourceMessage(Error.INVALID_CONNECTOR_VARIABLE, {c1_str,t1_str},info);
      then
        fail();

    case (cache,env,ih,_,pre,c1,_,t1,vt1,c2,_,t2,vt2,_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- InstSection.connectComponents failed\n");
      then
        fail();
  end matchcontinue;
end connectComponents;

protected function connectArrayComponents "
 Help functino to connectComponents
Traverses arrays of complex connectors and calls connectComponents for each index
"
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Connect.Sets inSets;
  input Prefix inPrefix3;
  input DAE.ComponentRef cr1;
  input Connect.Face inFace5;
  input DAE.Type inType6;
  input SCode.Variability vt1;
  input DAE.ComponentRef cr2;
  input Connect.Face inFace8;
  input DAE.Type inType9;
  input SCode.Variability vt2;
  input Boolean inFlowPrefix;
  input Boolean inStreamPrefix;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Integer dim1;
  input Integer i "current index";
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inPrefix3,cr1,inFace5,inType6,vt1,cr2,inFace8,inType9,vt2,inFlowPrefix,inStreamPrefix,io1,io2,dim1,i,inGraph,info)
    local
      DAE.ComponentRef c1_1,c2_1,c1,c2,c21,c11;
      Connect.Sets sets_1,sets;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Connect.Face f1,f2;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,bc_tp1,bc_tp2;
      SCode.Variability vr;
      Integer dim1,dim2;
      DAE.DAElist dae,dae1,dae2;
      list<DAE.Var> l1,l2;
      Boolean flowPrefix,streamPrefix;
      String c1_str,t1_str,t2_str,c2_str;
      Env.Cache cache;
      Absyn.InnerOuter io1,io2;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,dim1,i,graph,info)
      equation
        true = (dim1 == i);
        c1 = Exp.replaceCrefSliceSub(c1,{DAE.INDEX(DAE.ICONST(i))});
        c2 = Exp.replaceCrefSliceSub(c2,{DAE.INDEX(DAE.ICONST(i))});
        (cache,_,ih,sets_1,dae,graph)= connectComponents(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,graph,info);
      then (cache,env,ih,sets_1,dae,graph);

    case(cache,env,ih,sets,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,dim1,i,graph,info)
      equation
        c11 = Exp.replaceCrefSliceSub(c1,{DAE.INDEX(DAE.ICONST(i))});
        c21 = Exp.replaceCrefSliceSub(c2,{DAE.INDEX(DAE.ICONST(i))});
        (cache,_,ih,sets_1,dae1,graph)= connectComponents(cache,env,ih,sets,pre,c11,f1,t1,vt1,c21,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,graph,info);
        (cache,_,ih,sets_1,dae2,graph) = connectArrayComponents(cache,env,ih,sets_1,pre,c1,f1,t1,vt1,c2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,dim1,i+1,graph,info);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then (cache,env,ih,sets_1,dae,graph);
  end matchcontinue;
end connectArrayComponents;

protected function connectVars
"function: connectVars
  This function connects two subcomponents by adding the component
  name to the current path and recursively connecting the components
  using the function connectComponents."
  input Env.Cache inCache;
  input Env inEnv;
  input InstanceHierarchy inIH;
  input Connect.Sets inSets;
  input DAE.ComponentRef inComponentRef3;
  input Connect.Face inFace4;
  input list<DAE.Var> inTypesVarLst5;
  input SCode.Variability vt1;
  input DAE.ComponentRef inComponentRef6;
  input Connect.Face inFace7;
  input list<DAE.Var> inTypesVarLst8;
  input SCode.Variability vt2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input ConnectionGraph.ConnectionGraph inGraph;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env outEnv;
  output InstanceHierarchy outIH;
  output Connect.Sets outSets;
  output DAE.DAElist outDae;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (outCache,outEnv,outIH,outSets,outDae,outGraph):=
  matchcontinue (inCache,inEnv,inIH,inSets,inComponentRef3,inFace4,inTypesVarLst5,vt1,inComponentRef6,inFace7,inTypesVarLst8,vt2,io1,io2,inGraph,info)
    local
      Connect.Sets sets,sets_1,sets_2;
      list<Env.Frame> env;
      DAE.ComponentRef c1_1,c2_1,c1,c2;
      DAE.DAElist dae,dae2,dae_1;
      Connect.Face f1,f2;
      String n;
      DAE.Attributes attr1,attr2;
      Boolean flow1,flow2,stream1,stream2;
      SCode.Variability vt1,vt2;
      tuple<DAE.TType, Option<Absyn.Path>> ty1,ty2;
      list<DAE.Var> xs1,xs2;
      SCode.Variability vta,vtb;
      DAE.ExpType ty_2,ty_22;
      Env.Cache cache;
      ConnectionGraph.ConnectionGraph graph;
      InstanceHierarchy ih;

    case (cache,env,ih,sets,_,_,{},vt1,_,_,{},vt2,io1,io2,graph,info)
      then (cache,env,ih,sets,DAEUtil.emptyDae,graph);
    case (cache,env,ih,sets,c1,f1,(DAE.TYPES_VAR(name = n,attributes = (attr1 as DAE.ATTR(flowPrefix = flow1,streamPrefix = stream1,parameter_ = vta)),type_ = ty1) :: xs1),vt1,
                         c2,f2,(DAE.TYPES_VAR(attributes = (attr2 as DAE.ATTR(flowPrefix = flow2,streamPrefix=stream2,parameter_ = vtb)),type_ = ty2) :: xs2),vt2,io1,io2,graph,info)
      equation
        ty_2 = Types.elabType(ty1);
        c1_1 = Exp.extendCref(c1, ty_2, n, {});
        c2_1 = Exp.extendCref(c2, ty_2, n, {});
        checkConnectTypes(env,ih, c1_1, ty1, attr1, c2_1, ty2, attr2, io1, io2, info);
        (cache,_,ih,sets_1,dae,graph) = connectComponents(cache,env,ih,sets, Prefix.NOPRE(), c1_1, f1, ty1, vta, c2_1, f2, ty2, vtb, flow1, stream1, io1, io2, graph, info);
        (cache,_,ih,sets_2,dae2,graph) = connectVars(cache,env,ih,sets_1, c1, f1, xs1,vt1, c2, f2, xs2, vt2, io1, io2, graph, info);
        dae_1 = DAEUtil.joinDaes(dae, dae2);
      then
        (cache,env,ih,sets_2,dae_1,graph);
  end matchcontinue;
end connectVars;

protected function createTempLoopVars
"function: createTempLoopVars
  author: KS
  Function used for creating loop variables, used in the for iterator constructs."
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> accTempLoopVars1;
  input list<Absyn.ElementItem> accTempLoopVars2;
  input list<Absyn.AlgorithmItem> accTempLoopInit;
  input Integer count;
  output list<Absyn.Ident> outList1;
  output list<Absyn.ElementItem> outList2;
  output list<Absyn.AlgorithmItem> outList3;
algorithm
  (outList1,outList2,outList3) := matchcontinue (rangeIdList,accTempLoopVars1,accTempLoopVars2,accTempLoopInit,count)
    local
      list<Absyn.Ident> localAccVars1;
      list<Absyn.ElementItem> localAccVars2;
      list<Absyn.AlgorithmItem> localAccTempLoopInit;
    case ({},localAccVars1,localAccVars2,localAccTempLoopInit,_)
      then (localAccVars1,localAccVars2,localAccTempLoopInit);
    case (_ :: restIdRange,localAccVars1,localAccVars2,localAccTempLoopInit,n)
      local
        Absyn.ForIterators restIdRange;
        Absyn.Ident id2;
        Integer n;
        list<Absyn.ElementItem> elem;
        list<Absyn.AlgorithmItem> elem2;
      equation
        id2 = stringAppend("LOOPVAR__",intString(n));
        localAccVars1 = listAppend(localAccVars1,{id2});
        elem = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(id2,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        localAccVars2 = listAppend(localAccVars2,elem);
        elem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(id2,{})),Absyn.INTEGER(0)),NONE(),Absyn.dummyInfo)};
        localAccTempLoopInit = listAppend(localAccTempLoopInit,elem2);
        n = n+1;
        (localAccVars1,localAccVars2,localAccTempLoopInit) = createTempLoopVars(restIdRange,localAccVars1,localAccVars2,localAccTempLoopInit,n);
      then (localAccVars1,localAccVars2,localAccTempLoopInit);
  end matchcontinue;
end createTempLoopVars;

protected function createForIteratorAlgorithm
"function: createForIteratorAlgorithm
  author: KS
  Function that creates for algorithm statements to be used in the for iterator constructor assignment."
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> idList;
  input list<Absyn.Ident> tempLoopVars;
  input Absyn.ComponentRef arrayId;
  output list<Absyn.AlgorithmItem> outAlg;
algorithm
  (outAlg) := matchcontinue (iterExp,rangeIdList,idList,tempLoopVars,arrayId)
    local
      list<Absyn.AlgorithmItem> stmt1,stmt2,stmt3;
      Absyn.Ident id,tempLoopVar;
      Absyn.Exp rangeExp,localIterExp;
      list<Absyn.Ident> localIdList,restTempLoopVars;
      Absyn.ComponentRef localArrayId;
      DAE.DAElist dae,dae1,dae2;
    case (localIterExp,(id,SOME(rangeExp)) :: {},localIdList,tempLoopVar :: _,localArrayId)
      local
        list<Absyn.Subscript> subList;
        Absyn.Exp arrayRef;
      equation
        subList = createArrayIndexing(localIdList,{});
        arrayRef = createArrayReference(localArrayId,subList);
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),Absyn.ADD(),Absyn.INTEGER(1))),NONE(),Absyn.dummyInfo)};
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(arrayRef,localIterExp),NONE(),Absyn.dummyInfo)};
        stmt1 = listAppend(stmt1,stmt2);
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_FOR({(id,SOME(rangeExp))},stmt1),NONE(),Absyn.dummyInfo)};
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.INTEGER(0)),NONE(),Absyn.dummyInfo)};
        stmt3 = listAppend(stmt2,stmt1);
      then (stmt3);

    case (localIterExp,(id,SOME(rangeExp)) :: rest,localIdList,tempLoopVar :: restTempLoopVars,localArrayId)
      local
        Absyn.ForIterators rest;
      equation
        (stmt2) = createForIteratorAlgorithm(localIterExp,rest,localIdList,restTempLoopVars,localArrayId);
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.BINARY(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),Absyn.ADD(),Absyn.INTEGER(1))),NONE(),Absyn.dummyInfo)};
        stmt1 = listAppend(stmt1,stmt2);
        stmt2 = {Absyn.ALGORITHMITEM(Absyn.ALG_FOR({(id,SOME(rangeExp))},stmt1),NONE(),Absyn.dummyInfo)};
        stmt1 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(tempLoopVar,{})),
          Absyn.INTEGER(0)),NONE(),Absyn.dummyInfo)};
        stmt3 = listAppend(stmt2,stmt1);
      then (stmt3);
  end matchcontinue;
end createForIteratorAlgorithm;


protected function createForIteratorArray
"function: createForIteratorArray
  author: KS
  Creates an array that will be used for storing temporary results in the for-iterator construct. "
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input Boolean b;
  input Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.ElementItem> outDecls;
algorithm
  (outCache,outDecls,outDae) := matchcontinue (cache,env,iterExp,rangeIdList,b,inPrefix,info)
    case (localCache,localEnv,localIterExp,localRangeIdList,impl,pre,info)
      local
        Env.Env env2,localEnv;
        Env.Cache localCache,cache2;
        Absyn.ForIterators localRangeIdList;
        list<Absyn.Subscript> subscriptList;
        DAE.Type t;
        Absyn.Path t2;
        list<Absyn.ElementItem> ld;
        list<SCode.Element> ld2;
        list<tuple<SCode.Element, DAE.Mod>> ld_mod;
        list<Absyn.ElementItem> decls;
        Boolean impl;
        Integer i;
        Absyn.Exp localIterExp;
        InstanceHierarchy ih;
        DAE.DAElist dae,dae1,dae2;
        Prefix pre;

      equation
        (localCache,subscriptList,ld) = deriveArrayDimAndTempVars(localCache,localEnv,localRangeIdList,impl,{},{},pre,info);

        // Temporarily add the loop variables to the environment so that we can later
        // elaborate the main for-iterator construct expression, in order to get the array type
        env2 = Env.openScope(localEnv, false, NONE(),NONE());
        ld2 = SCodeUtil.translateEitemlist(ld,false);
        ld2 = Inst.componentElts(ld2);
        ld_mod = Inst.addNomod(ld2);
        (localCache,env2,ih) = Inst.addComponentsToEnv(localCache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
        Connect.SETS({},{},{},{}), ClassInf.UNKNOWN(Absyn.IDENT("temp")), ld_mod, {}, {}, {}, impl);
       (cache2,env2,ih,_,_,_,_,_,_) = Inst.instElementList(localCache,env2,ih,UnitAbsyn.noStore,
        DAE.NOMOD(), Prefix.NOPRE(), Connect.SETS({},{},{},{}), ClassInf.UNKNOWN(Absyn.IDENT("temp")),
        ld_mod,{},impl,Inst.INNER_CALL,ConnectionGraph.EMPTY);

        (cache2,_,DAE.PROP(t,_),_) = Static.elabExp(cache2,env2,localIterExp,impl,NONE(),false,pre,info);

        t2 = convertType(t);

        decls = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(t2,NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("VEC__",subscriptList,NONE()),NONE(),NONE())}),
            info,NONE()))};
      then (localCache,decls);
  end matchcontinue;
end createForIteratorArray;

protected function deriveArrayDimAndTempVars
"function: deriveArrayDimAndTempVars.
  author: KS
  Given a list of range-expressions (tagged with loop variable identifiers), we derive the dimension of each range."
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.ForIterators rangeList;
  input Boolean impl;
  input list<Absyn.Subscript> accList;
  input list<Absyn.ElementItem> accTempVars;
  input Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache cache;
  output list<Absyn.Subscript> outList1;
  output list<Absyn.ElementItem> outList2;
algorithm
  (cache,outList1,outList2) := matchcontinue (cache,env,rangeList,impl,accList,accTempVars,inPrefix,info)
    local
      list<Absyn.Subscript> localAccList;
      list<Absyn.ElementItem> localAccTempVars;
      Env.Env localEnv;
      Env.Cache localCache;
      Prefix pre;
    case (localCache,_,{},_,localAccList,localAccTempVars,_,info) then (localCache,localAccList,localAccTempVars);
    case (localCache,localEnv,(id,SOME(e)) :: restList,localImpl,localAccList,localAccTempVars,pre,info)
      local
        Absyn.Exp e;
        Absyn.ForIterators restList;
        Boolean localImpl;
        list<Absyn.Subscript> elem;
        list<Absyn.ElementItem> elem2;
        Integer i;
        Absyn.Ident id;
        DAE.Type t;
        Absyn.Path t2;
        DAE.DAElist dae,dae1,dae2;

      equation
        (localCache,_,DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(i),t),NONE()),_),_) = Static.elabExp(localCache,localEnv,e,localImpl,NONE(),false,pre,info);
        elem = {Absyn.SUBSCRIPT(Absyn.INTEGER(i))};
        localAccList = listAppend(localAccList,elem);
        t2 = convertType(t);
        elem2 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(t2,NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(id,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        localAccTempVars = listAppend(localAccTempVars,elem2);
        (localCache,localAccList,localAccTempVars) =
        deriveArrayDimAndTempVars(localCache,localEnv,restList,localImpl,localAccList,localAccTempVars,pre,info);
      then (localCache,localAccList,localAccTempVars);
  end matchcontinue;
end deriveArrayDimAndTempVars;

protected function convertType
"function: convertType
  author: KS"
  input DAE.Type t;
  output Absyn.Path t2;
algorithm
  t2 := matchcontinue (t)
    local
      String s;
      Absyn.Path extObj;
    case ((DAE.T_INTEGER(_),_)) then Absyn.IDENT("Integer");
    case ((DAE.T_REAL(_),_)) then Absyn.IDENT("Real");
    case ((DAE.T_STRING(_),_)) then Absyn.IDENT("String");
    case ((DAE.T_BOOL(_),_)) then Absyn.IDENT("Boolean");
//    case ((DAE.T_ENUM(),_)) then Absyn.IDENT("Enum");
    /*
    case ((DAE.T_COMPLEX(ClassInf.MODEL(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.RECORD(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.BLOCK(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.CONNECTOR(s),_,_),_)) then Absyn.IDENT(s);
    case ((DAE.T_COMPLEX(ClassInf.EXTERNAL_OBJ(extObj),_,_),_)) then extObj;
    */
 end matchcontinue;
end convertType;

// The following functions are used in the instantiation of
// array iterator constructors. For instance,
// v := { 3*i*j for i in 1:5, j in 1:n }
protected function createForIteratorEquations
"function: createForIteratorEquations
  author: KS
  Function that creates for equations to be used in the for iterator construct assignment."
  input Absyn.Exp iterExp;
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> idList;
  input Absyn.ComponentRef arrayId;
  input Absyn.Info info;
  output SCode.EEquation outEq;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outEq,outDae) :=
  matchcontinue (iterExp,rangeIdList,idList,arrayId,info)
    local
      Absyn.Ident id;
      Absyn.Exp rangeExp,localIterExp;
      list<Absyn.Ident> localIdList;
      Absyn.ComponentRef localArrayId;
    case (localIterExp,(id,SOME(rangeExp)) :: {},localIdList,localArrayId,info)
      local
        list<Absyn.Subscript> subList;
        Absyn.Exp arrayRef;
        list<SCode.EEquation> eqList;
        SCode.EEquation eq1,eq2;
      equation
        subList = createArrayIndexing(localIdList,{});
        arrayRef = createArrayReference(localArrayId,subList);
        eq1 = SCode.EQ_EQUALS(arrayRef,localIterExp,NONE(),info);
        eqList = {eq1};
        eq2 = SCode.EQ_FOR(id,rangeExp,eqList,NONE(),info);
      then (eq2,DAEUtil.emptyDae);
    case (localIterExp,(id,SOME(rangeExp)) :: rest,localIdList,localArrayId,info)
      local
        Absyn.ForIterators rest;
        list<SCode.EEquation> eqList;
        SCode.EEquation eq1,eq2;
      equation
        (eq1,_) = createForIteratorEquations(localIterExp,rest,localIdList,localArrayId,info);
        eqList = {eq1};
        eq2 = SCode.EQ_FOR(id,rangeExp,eqList,NONE(),info);
      then (eq2,DAEUtil.emptyDae);
  end matchcontinue;
end createForIteratorEquations;

protected function extractLoopVars
"function: extractLoopVars
  author: KS"
  input Absyn.ForIterators rangeIdList;
  input list<Absyn.Ident> accList;
  output list<Absyn.Ident> outList;
algorithm
  outList :=
  matchcontinue (rangeIdList,accList)
    local
      list<Absyn.Ident> localAccList;
      list<Absyn.ElementItem> localAccVars2;
    case ({},localAccList)
      then localAccList;
    case ((id,_) :: restIdRange,localAccList)
      local
        Absyn.ForIterators restIdRange;
        Absyn.Ident id;
      equation
        localAccList = listAppend(localAccList,{id});
        localAccList = extractLoopVars(restIdRange,localAccList);
      then localAccList;
  end matchcontinue;
end extractLoopVars;

protected function createArrayIndexing
"function: createArrayIndexing
  author: KS
  Function that creates a list of subscripts to be used when indexing an array."
  input list<Absyn.Ident> idList;
  input list<Absyn.Subscript> accList;
  output list<Absyn.Subscript> outSubList;
algorithm
  outSubList :=
  matchcontinue (idList,accList)
    local
      list<Absyn.Subscript> localAccList;
    case ({},localAccList) then localAccList;
    case (firstId :: restId,localAccList)
      local
        Absyn.Ident firstId;
        Absyn.Subscript subExp;
        list<Absyn.Ident> restId;
      equation
        subExp = Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT(firstId,{})));
        localAccList = listAppend(localAccList,Util.listCreate(subExp));
        localAccList = createArrayIndexing(restId,localAccList);
      then localAccList;
  end matchcontinue;
end createArrayIndexing;

protected function createArrayReference
"function: createArrayReference
  author: KS"
  input Absyn.ComponentRef c;
  input list<Absyn.Subscript> subList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (c,subList)
    case (Absyn.CREF_IDENT(id,sl),localSubList)
      local
        Absyn.Ident id;
        list<Absyn.Subscript> sl,localSubList;
        Absyn.Exp c2;
      equation
        sl = listAppend(sl,localSubList);
        c2 = Absyn.CREF(Absyn.CREF_IDENT(id,sl));
      then c2;
    case (Absyn.CREF_QUAL(id,sl,c),localSubList)
      local
        Absyn.Ident id;
        list<Absyn.Subscript> sl,localSubList;
        Absyn.ComponentRef c;
        Absyn.Exp c2;
      equation
        sl = listAppend(sl,localSubList);
        c2 = Absyn.CREF(Absyn.CREF_QUAL(id,sl,c));
      then c2;
  end matchcontinue;
end createArrayReference;

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
      
    // Empty integer list. Util.listIntRange is not defined for size < 1, 
    // so we need to handle empty lists here.
    case (DAE.DIM_INTEGER(integer = 0), _) then {};
    case (DAE.DIM_INTEGER(integer = sz), _)
      equation
        ints = Util.listIntRange(sz);
        expl = Util.listMap1(ints, makeAsubIndex, inArray);
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
    case (DAE.DIM_UNKNOWN, _) then {DAE.ICONST(1)};
    */
    case (DAE.DIM_UNKNOWN, _)
      equation
        true = OptManager.getOption("checkModel");
        ints = Util.listIntRange(1); // try to make an array index of 1 when we don't know the dimension
        expl = Util.listMap1(ints, makeAsubIndex, inArray);
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
  asub := Exp.simplify(DAE.ASUB(expr, {DAE.ICONST(index)}));
  asub := Debug.bcallret1(Exp.isCrefScalar(asub), Exp.unliftExp, asub, asub);
end makeAsubIndex;

protected function makeEnumLiteralIndices
  "Creates a list of enumeration literal expressions from an enumeration."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  input Integer enumIndex;
  input DAE.Exp expr;
  output list<DAE.Exp> enumIndices;
algorithm
  enumIndices := matchcontinue(enumTypeName, enumLiterals, enumIndex, expr)
    case (_, {}, _, _) then {};
    case (_, l :: ls, _, _)
      local
        String l;
        list<String> ls;
        DAE.Exp e;
        list<DAE.Exp> expl;
        Absyn.Path enum_type_name;
        Integer index;
      equation
        enum_type_name = Absyn.joinPaths(enumTypeName, Absyn.IDENT(l));
        e = DAE.ENUM_LITERAL(enum_type_name, enumIndex);
        e = Exp.simplify(DAE.ASUB(expr, {e}));
        e = Debug.bcallret1(Exp.isCref(e), Exp.unliftExp, e, e);
        index = enumIndex + 1;
        expl = makeEnumLiteralIndices(enumTypeName, ls, index, expr);
      then
        e :: expl;
  end matchcontinue;
end makeEnumLiteralIndices;

protected function getVectorizedCref
"for a vectorized cref, return the originial cref without vector subscripts"
input DAE.Exp crefOrArray;
output DAE.Exp cref;
algorithm
   cref := matchcontinue(crefOrArray)
   local
     DAE.ComponentRef cr;
     DAE.ExpType t;
     case (cref as DAE.CREF(_,_)) then cref;
     case (DAE.ARRAY(_,_,DAE.CREF(cr,t)::_)) equation
       cr = Exp.crefStripLastSubs(cr);
       then DAE.CREF(cr,t);
   end matchcontinue;
end getVectorizedCref;

protected function checkForNestedWhen
  "Fails if a when equation contains nested when equations, which are not
  allowed in Modelica."
  input SCode.EEquation inWhenEq;
algorithm
  _ := matchcontinue(inWhenEq)
    case SCode.EQ_WHEN(eEquationLst = el, tplAbsynExpEEquationLstLst = tpl_el)
      local
        list<SCode.EEquation> el;
        list<list<SCode.EEquation>> el2;
        list<tuple<Absyn.Exp, list<SCode.EEquation>>> tpl_el;
      equation
        checkForNestedWhenInEqList(el);
        el2 = Util.listMap(tpl_el, Util.tuple22);
        Util.listMap0(el2, checkForNestedWhenInEqList);
      then
        ();
    case _
      equation
        Debug.fprintln("failtrace", "- InstSection.checkForNestedWhen failed.");
      then
        fail();
  end matchcontinue;
end checkForNestedWhen;

protected function checkForNestedWhenInEqList
  "Helper function to checkForNestedWhen. Searches for nested when equations in
  a list of equations."
  input list<SCode.EEquation> inEqs;
algorithm
  Util.listMap0(inEqs, checkForNestedWhenInEq);
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
        Util.listMap0(eqs_lst, checkForNestedWhenInEqList);
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
        Debug.fprintln("failtrace", "- InstSection.checkForNestedWhenInEq failed.");
      then
        fail();
  end matchcontinue;
end checkForNestedWhenInEq;

end InstSection;
