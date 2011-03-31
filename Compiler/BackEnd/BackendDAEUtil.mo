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

encapsulated package BackendDAEUtil
" file:         BackendDAEUtil.mo
  package:     BackendDAEUtil 
  description: BackendDAEUtil comprised functions for BackendDAE data types.

  RCS: $Id$

  This module is a lowered form of a DAE including equations
  and simple equations in
  two separate lists. The variables are split into known variables
  parameters and constants, and unknown variables,
  states and algebraic variables.
  The module includes the BLT sorting algorithm which sorts the
  equations into blocks, and the index reduction algorithm using
  dummy derivatives for solving higher index problems.
  It also includes the tarjan algorithm to detect strong components
  in the BLT sorting."

public import BackendDAE;
public import DAE;
public import Env;

protected import Absyn;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashTable;
protected import ComponentReference;
protected import Ceval;
protected import ClassInf;
protected import DAEUtil;
protected import Derive; 
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import HashTable2;
protected import HashTable4;
protected import OptManager;
protected import RTOpts;
protected import SCode;
protected import Util;
protected import Values;
protected import VarTransform;

/*************************************************
 * checkBackendDAE and stuff 
 ************************************************/

public function checkBackendDAEWithErrorMsg"function: checkBackendDAEWithErrorMsg
  author: Frenkel TUD
  run checkDEALow and prints all errors"
  input BackendDAE.BackendDAE inBackendDAE;
protected
  list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expCrefs;
  list<BackendDAE.Equation> wrongEqns;
algorithm  
  _ := matchcontinue (inBackendDAE)
    local BackendDAE.BackendDAE bdae;  
    case (bdae)
      equation
        false = RTOpts.debugFlag("checkBackendDAE");
      then
        ();  
    case (bdae)
      equation
        true = RTOpts.debugFlag("checkBackendDAE");
        (expCrefs,wrongEqns) = checkBackendDAE(inBackendDAE);
        printcheckBackendDAEWithErrorMsg(expCrefs,wrongEqns);
      then
        ();  
     end matchcontinue;
end checkBackendDAEWithErrorMsg;
 
public function printcheckBackendDAEWithErrorMsg"function: printcheckBackendDAEWithErrorMsg
  author: Frenkel TUD
  helper for checkDEALowWithErrorMsg"
  input list<tuple<DAE.Exp,list<DAE.ComponentRef>>> inExpCrefs;  
  input list<BackendDAE.Equation> inWrongEqns;
algorithm   
  _ := matchcontinue (inExpCrefs,inWrongEqns)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> res;
      list<String> strcrefs;
      String crefstring, expstr,scopestr;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> wrongEqns;
      DAE.ElementSource source;
    
    case ({},{})  then ();    
    
    case ({},eqn::wrongEqns)
      equation
        printEqnSizeError(eqn);
        printcheckBackendDAEWithErrorMsg({},wrongEqns);
      then ();
    
    case (((e,crefs))::res,wrongEqns)
      equation
        strcrefs = Util.listMap(crefs,ComponentReference.crefStr);
        crefstring = Util.stringDelimitList(strcrefs,", ");
        expstr = ExpressionDump.printExpStr(e);
        scopestr = stringAppendList({crefstring," from Expression: ",expstr});
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {scopestr,"BackendDAE object"});
        printcheckBackendDAEWithErrorMsg(res,wrongEqns);
      then
        ();
  end matchcontinue;
end printcheckBackendDAEWithErrorMsg;      

protected function printEqnSizeError"function: printEqnSizeError
  author: Frenkel TUD 2010-12"
    input BackendDAE.Equation inEqn;
algorithm
  _ := matchcontinue(inEqn)
  local 
    BackendDAE.Equation eqn;
    DAE.Exp e1, e2;
    DAE.ComponentRef cr;
    DAE.ExpType t1,t2;
    String eqnstr, t1str, t2str, tstr;
    DAE.ElementSource source;
    case (eqn as BackendDAE.EQUATION(exp=e1,scalar=e2,source=source))
      equation
        eqnstr = BackendDump.equationStr(eqn);
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);   
        t1str = ExpressionDump.typeString(t1);     
        t2str = ExpressionDump.typeString(t2);   
        tstr = stringAppendList({t1str," != ", t2str});  
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {eqnstr,tstr}, DAEUtil.getElementSourceFileInfo(source));
      then ();
    case (eqn as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e1,source=source))
      equation
        eqnstr = BackendDump.equationStr(eqn);
        t1 = Expression.typeof(e1);
        t2 = ComponentReference.crefLastType(cr);
        t1str = ExpressionDump.typeString(t1);     
        t2str = ExpressionDump.typeString(t2);   
        tstr = stringAppendList({t1str," != ", t2str});  
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {eqnstr,tstr}, DAEUtil.getElementSourceFileInfo(source));
      then ();
    case (eqn as BackendDAE.COMPLEX_EQUATION(lhs=e1,rhs=e2,source=source))
      equation
        eqnstr = BackendDump.equationStr(eqn);
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);   
        t1str = ExpressionDump.typeString(t1);     
        t2str = ExpressionDump.typeString(t2);   
        tstr = stringAppendList({t1str," != ", t2str});  
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {eqnstr,tstr}, DAEUtil.getElementSourceFileInfo(source));
      then ();                
      //
    case eqn then ();
  end matchcontinue;
end printEqnSizeError;
      
public function checkBackendDAE "function: checkBackendDAE
  author: Frenkel TUD
  This function checks the BackendDAE object if
  -  all component refercences used in the expressions are 
     part of the BackendDAE object.
  -  all variables that are reinit are states
  Returns all component references which not part of the BackendDAE object."
  input BackendDAE.BackendDAE inBackendDAE;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
  output list<BackendDAE.Equation> outWrongEqns;
algorithm
  (outExpCrefs,outWrongEqns) := matchcontinue (inBackendDAE)
    local
      BackendDAE.Variables vars1,vars2,allvars;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
      list<BackendDAE.Var> varlst1,varlst2,allvarslst;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcrefs,expcrefs1,expcrefs2,expcrefs3,expcrefs4,expcrefs5;
      list<BackendDAE.Equation> wrongEqns,wrongEqns1,wrongEqns2;
    
    case (BackendDAE.DAE(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs))
      equation
        varlst1 = varList(vars1);
        varlst2 = varList(vars2);
        allvarslst = listAppend(varlst1,varlst2);
        allvars = listVar(allvarslst);
        ((_,expcrefs)) = traverseBackendDAEExpsVars(vars1,checkBackendDAEExp,(allvars,{}));
        ((_,expcrefs1)) = traverseBackendDAEExpsVars(vars2,checkBackendDAEExp,(allvars,expcrefs));
        ((_,expcrefs2)) = traverseBackendDAEExpsEqns(eqns,checkBackendDAEExp,(allvars,expcrefs1));
        ((_,expcrefs3)) = traverseBackendDAEExpsEqns(reqns,checkBackendDAEExp,(allvars,expcrefs2));
        ((_,expcrefs4)) = traverseBackendDAEExpsEqns(ieqns,checkBackendDAEExp,(allvars,expcrefs3));
        ((_,expcrefs5)) = traverseBackendDAEArrayNoCopy(ae,checkBackendDAEExp,traverseBackendDAEExpsArrayEqn,1,arrayLength(ae),(allvars,expcrefs4));
        //((_,expcrefs6)) = traverseBackendDAEArrayNoCopy(algs,checkBackendDAEExp,traverseAlgorithmExps,1,arrayLength(algs),(allvars,expcrefs5));
        
        wrongEqns = BackendEquation.traverseBackendDAEEqns(eqns,checkEquationSize,{});
        wrongEqns1 = BackendEquation.traverseBackendDAEEqns(reqns,checkEquationSize,wrongEqns);
        wrongEqns2 = BackendEquation.traverseBackendDAEEqns(ieqns,checkEquationSize,wrongEqns1);
      then
        (expcrefs5,wrongEqns2);
    
    case (_)
      equation
        Debug.fprintln("failtrace", "- BackendDAEUtil.checkBackendDAE failed");
      then
        fail();
  end matchcontinue;
end checkBackendDAE;

protected function checkBackendDAEExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<tuple<DAE.Exp,list<DAE.ComponentRef>>>>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<tuple<DAE.Exp,list<DAE.ComponentRef>>>>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> lstExpCrefs,lstExpCrefs1;
    case ((exp,(vars,lstExpCrefs)))
      equation
        ((_,(_,crefs))) = Expression.traverseExp(exp,traversecheckBackendDAEExp,(vars,{}));
        lstExpCrefs1 = Util.if_(listLength(crefs)>0,(exp,crefs)::lstExpCrefs,lstExpCrefs);
       then
        ((exp,(vars,lstExpCrefs1)));
    case inTpl then inTpl;
  end matchcontinue;      
end checkBackendDAEExp;

protected function traversecheckBackendDAEExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs,crefs1;
      list<DAE.Exp> expl;
      list<DAE.ExpVar> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,crefs)))
      then ((e, (vars,crefs)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.ET_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,crefs)))
      equation
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars1,crefs1))) = Expression.traverseExpList(expl,traversecheckBackendDAEExp,(vars,crefs));
      then
        ((e, (vars1,crefs1)));  

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.ET_ARRAY(ty=_)),(vars,crefs)))
      equation
        ((e1,_)) = extendArrExp((e,NONE()));
        ((_,(vars1,crefs1))) = Expression.traverseExp(e1,traversecheckBackendDAEExp,(vars,crefs));
      then
        ((e, (vars1,crefs1)));      
    
    // case for Reductions    
    case ((e as DAE.REDUCTION(iterators = riters),(vars,crefs)))
      equation
        // add idents to vars
        backendVars = Util.listMap(riters,makeIterVariable);
        vars = BackendVariable.addVars(backendVars,vars);
      then
        ((e, (vars,crefs)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,crefs)))
      then
        ((e, (vars,crefs)));        
    
    case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((e, (vars,crefs)));
    
    case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
      equation
         failure((_,_) = BackendVariable.getVar(cr, vars));
      then
        ((e, (vars,cr::crefs)));
    
    case inTuple then inTuple;
  end matchcontinue;
end traversecheckBackendDAEExp;

protected function makeIterVariable
  input DAE.ReductionIterator iter;
  output BackendDAE.Var backendVar;
protected
  String name;
  DAE.ComponentRef cr;
algorithm
  name := Expression.reductionIterName(iter);
  cr := ComponentReference.makeCrefIdent(name,DAE.ET_INT(),{});
  backendVar := BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.INT(),NONE(),NONE(),{},0,
                     DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
end makeIterVariable;

protected function checkEquationSize"function: checkEquationSize
  author: Frenkel TUD 2010-12

  - check if the left hand site and thr rigth hand site have equal types.
"
    input tuple<BackendDAE.Equation, list<BackendDAE.Equation>> inTpl;
    output tuple<BackendDAE.Equation, list<BackendDAE.Equation>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local 
    BackendDAE.Equation e;
    list<BackendDAE.Equation> wrongEqns,wrongEqns1;
    DAE.Exp e1, e2;
    DAE.ComponentRef cr;
    DAE.ExpType t1,t2;
    Boolean b;
    case ((e as BackendDAE.EQUATION(exp=e1,scalar=e2),wrongEqns))
      equation
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);
        b = Expression.equalTypes(t1,t2);
        wrongEqns1 = Util.listConsOnTrue(not b,e,wrongEqns);
      then ((e,wrongEqns1));

    case ((e as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e1),wrongEqns))
      equation
        t1 = Expression.typeof(e1);
        t2 = ComponentReference.crefLastType(cr);
        b = Expression.equalTypes(t1,t2);
        wrongEqns1 = Util.listConsOnTrue(not b,e,wrongEqns);
      then ((e,wrongEqns1));

    case ((e as BackendDAE.COMPLEX_EQUATION(lhs=e1,rhs=e2),wrongEqns))
      equation
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);
        b = Expression.equalTypes(t1,t2);
        wrongEqns1 = Util.listConsOnTrue(not b,e,wrongEqns);
      then ((e,wrongEqns1));        
        
      //
    case inTpl then inTpl;
  end matchcontinue;
end checkEquationSize;


/*************************************************
 * Initialisation and stuff 
 ************************************************/

public function checkInitialSystem"function: checkInitialSystem
  author: Frenkel TUD 2010-12

  - check if the inital conditions full specified and fix it 
  if not.
"

  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree funcs;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue (inDAE,funcs)
    local
      BackendDAE.Variables variables,knvars,exObj,aliasVars;
      BackendDAE.EquationArray orderedEqs,removedEqs,initialEqs;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;      
      Integer nie,nie1,nie2,unfixed,unfixed1,unfixed2,sizealias;
      BackendDAE.BackendDAE dae,dae1;
      list<BackendDAE.WhenClause> whenClauseLst;
      list<DAE.ComponentRef> vars,varsws,states,statesws;
      BackendDAE.AliasVariables av;
   
    case (dae as BackendDAE.DAE(orderedVars=variables,knownVars=knvars,externalObjects=exObj,aliasVars=av,orderedEqs=orderedEqs,removedEqs=removedEqs,
           initialEqs=initialEqs,arrayEqs=arrayEqs,algorithms=algs,eventInfo=eventInfo,extObjClasses=extObjClasses),funcs)
      equation
        /* count the unfixed variables */
        // vars
        ((vars,varsws,states,statesws,unfixed)) = BackendVariable.traverseBackendDAEVars(variables,countInitialVars,({},{},{},{},0));
        // kvars
        ((vars,varsws,states,statesws,unfixed1)) = BackendVariable.traverseBackendDAEVars(knvars,countInitialVars,(vars,varsws,states,statesws,unfixed));
        //BackendDAE.ALIASVARS(aliasVars = aliasVars) = av;
        //sizealias = BackendVariable.varsSize(aliasVars);   
        //unfixed2 = unfixed1 - sizealias;     
        /* count the equations */
        nie = equationSize(initialEqs);
        BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst) = eventInfo;
        ((nie1,_)) = BackendEquation.traverseBackendDAEEqns(orderedEqs,countInitialEqns,(nie,whenClauseLst));
        ((nie2,_)) = BackendEquation.traverseBackendDAEEqns(removedEqs,countInitialEqns,(nie1,whenClauseLst));
        dae1 = checkInitialSystem1(unfixed1,nie2,dae,funcs,vars,varsws,states,statesws);
      then
        dae;   
    
    case (dae,_)
      equation
        print("- BackendDAEUtil.checkInitialSystem failed\n");
      then
        dae;
  end matchcontinue;
end checkInitialSystem;

protected function checkInitialSystem1"function: checkInitialSystem
  author: Frenkel TUD 2010-12"
  input Integer inUnfixed;
  input Integer inInitialEqns;
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree funcs;
  input list<DAE.ComponentRef> inVars;
  input list<DAE.ComponentRef> inVarsWS;
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStatesWS;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue (inUnfixed,inInitialEqns,inDAE,funcs,inVars,inVarsWS,inStates,inStatesWS)
    local
      BackendDAE.Variables vars,knvars,exObj,vars1,knvars1;
      BackendDAE.EquationArray orderedEqs,removedEqs,initialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      array<DAE.Algorithm> algs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.AliasVariables alisvars;
      BackendDAE.BackendDAE dae1;
   
    // unfixed equal equations
    case (inUnfixed,inInitialEqns,inDAE,_,_,_,_,_)
      equation
        true = intEq(inUnfixed,inInitialEqns);
      then 
        inDAE;
  
    // unfixed less than equations
    case (inUnfixed,inInitialEqns,inDAE,_,_,_,_,_)
      equation
        true = intLt(inUnfixed,inInitialEqns);
      then 
        inDAE;  
   
    // unfixed greater than equations
    case (inUnfixed,inInitialEqns,inDAE as BackendDAE.DAE(orderedVars=vars,knownVars=knvars,externalObjects=exObj,aliasVars=alisvars,orderedEqs=orderedEqs,removedEqs=removedEqs,
           initialEqs=initialEqs,arrayEqs=arrayEqs,algorithms=algs,eventInfo=eventInfo,extObjClasses=extObjClasses),funcs,inVars,inVarsWS,inStates,inStatesWS)
      equation
        true = RTOpts.debugFlag("dumpInit");
        print("Warning initial conditions not fully specified.\n"); 
        print("Variables with fixed=false: ");print(intString(inUnfixed)); print("\n");
        print("Number of equations for initialisation: ");print(intString(inInitialEqns)); print("\n");
        true = intGt(inUnfixed,inInitialEqns);
        // change fixed to true until equal equations
        (vars1,knvars1) = fixInitalVars(inUnfixed,inInitialEqns,vars,knvars,inVars,inVarsWS,inStates,inStatesWS);        
        dae1 = BackendDAE.DAE(vars1,knvars1,exObj,alisvars,orderedEqs,removedEqs,initialEqs,arrayEqs,algs,eventInfo,extObjClasses);
      then 
        dae1;    
   
    // unfixed greater than equations
    case (inUnfixed,inInitialEqns,inDAE as BackendDAE.DAE(orderedVars=vars,knownVars=knvars,externalObjects=exObj,aliasVars=alisvars,orderedEqs=orderedEqs,removedEqs=removedEqs,
           initialEqs=initialEqs,arrayEqs=arrayEqs,algorithms=algs,eventInfo=eventInfo,extObjClasses=extObjClasses),funcs,inVars,inVarsWS,inStates,inStatesWS)
      equation
        true = intGt(inUnfixed,inInitialEqns);
        // change fixed to true until equal equations
        (vars1,knvars1) = fixInitalVars(inUnfixed,inInitialEqns,vars,knvars,inVars,inVarsWS,inStates,inStatesWS);        
        dae1 = BackendDAE.DAE(vars1,knvars1,exObj,alisvars,orderedEqs,removedEqs,initialEqs,arrayEqs,algs,eventInfo,extObjClasses);
      then 
        dae1;     

    case (_,_,inDAE,_,_,_,_,_)
      equation
        print("- BackendDAEUtil.checkInitialSystem1 failed\n");
      then
        inDAE;
  end matchcontinue;
end checkInitialSystem1;

protected function countInitialVars
" function countInitialVars
 autor: Frenkel TUD 2010-12"
 input tuple<BackendDAE.Var, tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef>,Integer>> inTpl;
 output tuple<BackendDAE.Var, tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef>,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)  
    local
      BackendDAE.Var var;
      list<DAE.ComponentRef> vars,varsws,states,statesws;
      Integer unfixed;
      BackendDAE.VarKind kind;
      DAE.ComponentRef cr;
      String s,scr;

    // constants
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isConst(var);
      then 
        ((var,(vars,varsws,states,statesws,unfixed)));
    // parameters with fixed=false : become variable
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isParam(var);
        false = BackendVariable.varFixed(var);
      then
        ((var,(vars,varsws,states,statesws,unfixed+1)));
    // parameters with fixed=true
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isParam(var);
      then
        ((var,(vars,varsws,states,statesws,unfixed)));

    // states with fixed=true    
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isStateVar(var);
        true = BackendVariable.varFixed(var);
      then
        ((var,(vars,varsws,states,statesws,unfixed+1 /*for derivative*/)));
    // states with fixed=false and start value
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isStateVar(var);
        false = BackendVariable.varFixed(var);
        _ = BackendVariable.varStartValueFail(var);
        cr = BackendVariable.varCref(var);
      then
        ((var,(vars,varsws,states,cr::statesws,unfixed+2/*+1 for derivative*/)));
    // states with fixed=false and without start value
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.isStateVar(var);
        false = BackendVariable.varFixed(var);
        cr = BackendVariable.varCref(var);
      then
        ((var,(vars,varsws,cr::states,statesws,unfixed+2/*+1 for derivative*/)));

    // vars with fixed=true    
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = BackendVariable.varFixed(var);
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind);
      then
        ((var,(vars,varsws,states,statesws,unfixed)));
  
    // vars with fixed=false and bound expression    
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        false = BackendVariable.varFixed(var);
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind);
        _ = BackendVariable.varBindExp(var);
      then
        ((var,(vars,varsws,states,statesws,unfixed)));  
        
    // vars with fixed=false and start value
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        false = BackendVariable.varFixed(var);
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind);
        _ = BackendVariable.varStartValueFail(var);
        cr = BackendVariable.varCref(var);
      then
        ((var,(vars,cr::varsws,states,statesws,unfixed+1)));
    // vars with fixed=false and without start value
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        false = BackendVariable.varFixed(var);
        kind = BackendVariable.varKind(var);
        BackendVariable.isVarKindVariable(kind);
        cr = BackendVariable.varCref(var);
      then
        ((var,(cr::vars,varsws,states,statesws,unfixed+1)));            

    // vars with no case print
    case ((var,(vars,varsws,states,statesws,unfixed)))
      equation
        true = RTOpts.debugFlag("dumpInit");
        cr = BackendVariable.varCref(var);
        scr = ComponentReference.printComponentRefStr(cr);
        s = stringAppendList({"countInitialVars: No case for  ",scr,"\n"});
        print(s);        
      then
        ((var,(vars,varsws,states,statesws,unfixed))); 

    case (inTpl) then inTpl; 

  end matchcontinue;
end countInitialVars;

protected function countInitialEqns
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Equation, tuple<Integer,list<BackendDAE.WhenClause>>> inTpl;
 output tuple<BackendDAE.Equation, tuple<Integer,list<BackendDAE.WhenClause>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      BackendDAE.WhenEquation weqn;
      list<BackendDAE.WhenClause> whenClauseLst;
      Integer nie;

    // only when eqns with initial() 
    case ((e as BackendDAE.WHEN_EQUATION(whenEquation=weqn),(nie,whenClauseLst)))
      equation
        
      then ((e,(nie,whenClauseLst)));

    case ((e,(nie,whenClauseLst)))
      then ((e,(nie+1,whenClauseLst)));
  end matchcontinue;
end countInitialEqns;

protected function fixInitalVars"function: fixInitalVars
  author: Frenkel TUD 2010-12"
  input Integer inUnfixed;
  input Integer inInitialEqns;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<DAE.ComponentRef> inVars;
  input list<DAE.ComponentRef> inVarsWS;
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStatesWS;  
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnVariables;
algorithm
  (outVariables,outKnVariables) := matchcontinue (inUnfixed,inInitialEqns,inVariables,inKnVariables,inVars,inVarsWS,inStates,inStatesWS)
    local
      BackendDAE.Variables variables,variables1,knvariables1;
      list<DAE.ComponentRef> vars,varsws,states,statesws;
      DAE.ComponentRef cr;
      BackendDAE.Var var,var1;
      Integer unfixed,ine;
   
    case (unfixed,ine,inVariables,inKnVariables,{},{},{},{})
      then 
        (inVariables,inKnVariables);   
   
    // unfixed equal equations
    case (unfixed,ine,inVariables,inKnVariables,_,_,_,_)
      equation
        true = intEq(unfixed,ine);
      then 
        (inVariables,inKnVariables);
  
    // first states with start value
    case (unfixed,ine,inVariables,inKnVariables,vars,varsws,states,cr::statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inVariables);         
        // add Warning
        warningInitialSystem(cr,false);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,true);
        // update variables 
        variables = BackendVariable.addVar(var1,inVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,variables,inKnVariables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1);         

    // then states 
    case (unfixed,ine,inVariables,inKnVariables,vars,varsws,cr::states,statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inVariables);         
        // add Warning
        warningInitialSystem(cr,true);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,true);
        var1 = BackendVariable.setVarStartValue(var1,DAE.RCONST(0.0));
        // update variables 
        variables = BackendVariable.addVar(var1,inVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,variables,inKnVariables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1);  

    // then variables with start value
    case (unfixed,ine,inVariables,inKnVariables,vars,cr::varsws,states,statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inVariables);         
        // add Warning
        warningInitialSystem(cr,false);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,false);
        // update variables 
        variables = BackendVariable.addVar(var1,inVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,variables,inKnVariables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1);  
    case (unfixed,ine,inVariables,inKnVariables,vars,cr::varsws,states,statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inKnVariables);         
        // add Warning
        warningInitialSystem(cr,false);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,false);
        // update variables 
        variables = BackendVariable.addVar(var1,inKnVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,inVariables,variables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1); 
        
    // then variables 
    case (unfixed,ine,inVariables,inKnVariables,cr::vars,varsws,states,statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inVariables);         
        // add Warning
        warningInitialSystem(cr,false);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,false);
        // update variables 
        variables = BackendVariable.addVar(var1,inVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,variables,inKnVariables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1);   
   case (unfixed,ine,inVariables,inKnVariables,cr::vars,varsws,states,statesws)
      equation
        // get Var 
        ((var :: _),_) = BackendVariable.getVar(cr, inKnVariables);         
        // add Warning
        warningInitialSystem(cr,true);
        // set fixed=true        
        var1 = BackendVariable.setVarFixed(var,false);
        // update variables 
        variables = BackendVariable.addVar(var1,inKnVariables);
        (variables1,knvariables1) = fixInitalVars(inUnfixed-1,inInitialEqns,inVariables,variables,vars,varsws,states,statesws);
      then 
        (variables1,knvariables1);
        
    case (_,_,inVariables,inKnVariables,_,_,_,_)
      equation
        true = RTOpts.debugFlag("dumpInit");
        print("- BackendDAEUtil.fixInitalVars failed\n");
      then
        (inVariables,inKnVariables);

    case (_,_,inVariables,inKnVariables,_,_,_,_)
      then
        (inVariables,inKnVariables);

  end matchcontinue;
end fixInitalVars;


protected function warningInitialSystem
  input DAE.ComponentRef cr;
  input Boolean flag;
algorithm
  _ :=
  matchcontinue (cr,flag)
    local
      String scr,s;
    case (cr,false)
      equation
        true = RTOpts.debugFlag("dumpInit");
        scr = ComponentReference.printComponentRefStr(cr);
        s = stringAppendList({"Set ",scr," fixed=true.\n"});
        print(s);
      then
        ();
    case (cr,true)
      equation
        true = RTOpts.debugFlag("dumpInit");
        scr = ComponentReference.printComponentRefStr(cr);
        s = stringAppendList({"Set ",scr," fixed=true.\n"});
        s = stringAppendList({s, "Set default start value = 0.0.\n"});
        print(s);
      then
        ();        
    case (_,_) then ();
  end matchcontinue;  
end warningInitialSystem;

/************************************************************
  Util function at Backend using for lowering and other stuff
 ************************************************************/

public function translateDae "function: translateDae
  author: PA

  Translates the dae so variables are indexed into different arrays:
  - xd for derivatives
  - x for states
  - dummy_der for dummy derivatives
  - dummy for dummy states
  - y for algebraic variables
  - p for parameters
"
  input BackendDAE.BackendDAE inBackendDAE;
  input Option<String> dummy;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE:=
  match (inBackendDAE,dummy)
    local
      list<BackendDAE.Var> varlst,knvarlst,extvarlst;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.Variables vars, knvars, extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ieqns;
      BackendDAE.BackendDAE trans_dae;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAE(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,BackendDAE.EVENT_INFO(whenClauseLst = wc,zeroCrossingLst = zc),extObjCls),_)
      equation
        varlst = varList(vars);
        knvarlst = varList(knvars);
        extvarlst = varList(extVars);
        varlst = listReverse(varlst);
        knvarlst = listReverse(knvarlst);
        extvarlst = listReverse(extvarlst);
        (varlst,knvarlst,extvarlst) = BackendVariable.calculateIndexes(varlst, knvarlst,extvarlst);
        vars = BackendVariable.addVars(varlst, vars);
        knvars = BackendVariable.addVars(knvarlst, knvars);
        extVars = BackendVariable.addVars(extvarlst, extVars);
        trans_dae = BackendDAE.DAE(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,
          BackendDAE.EVENT_INFO(wc,zc),extObjCls);
      then
        trans_dae;
  end match;
end translateDae;

public function calculateSizes "function: calculateSizes
  author: PA
  Calculates the number of state variables, nx,
  the number of algebraic variables, ny
  and the number of parameters/constants, np.
  inputs:  BackendDAE
  outputs: (int, /* nx */
            int, /* ny */
            int, /* np */
            int  /* ng */
            int) next"
  input BackendDAE.BackendDAE inBackendDAE;
  output Integer outnx        "number of states";
  output Integer outny        "number of alg. vars";
  output Integer outnp        "number of parameters";
  output Integer outng        "number of zerocrossings";
  output Integer outng_sample "number of zerocrossings that are samples";
  output Integer outnext      "number of external objects";
  // nx cannot be strings
  output Integer outny_string "number of alg.vars which are strings";
  output Integer outnp_string "number of parameters which are strings";
  // nx cannot be int
  output Integer outny_int    "number of alg.vars which are ints";
  output Integer outnp_int    "number of parameters which are ints";
  // nx cannot be int
  output Integer outny_bool   "number of alg.vars which are bools";
  output Integer outnp_bool   "number of parameters which are bools";    
algorithm
  (outnx,outny,outnp,outng,outng_sample,outnext, outny_string, outnp_string, outny_int, outnp_int, outny_bool, outnp_bool):=
  match (inBackendDAE)
    local
      BackendDAE.Value np,ng,nsam,nx,ny,nx_1,ny_1,next,ny_string,np_string,ny_1_string,np_int,np_bool,ny_int,ny_1_int,ny_bool,ny_1_bool;
      BackendDAE.Variables vars,knvars,extvars;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
    
    case (BackendDAE.DAE(orderedVars = vars,knownVars = knvars, externalObjects = extvars,
                 eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc,
                                        zeroCrossingLst = zc)))
      equation
        // input variables are put in the known var list, but they should be counted by the ny counter
        next = BackendVariable.varsSize(extvars);
        ((np,np_string,np_int, np_bool)) = BackendVariable.traverseBackendDAEVars(knvars,calculateParamSizes,(0,0,0,0));
        (ng,nsam) = calculateNumberZeroCrossings(zc, 0, 0);
        ((nx,ny,ny_string,ny_int, ny_bool)) = BackendVariable.traverseBackendDAEVars(vars,calculateVarSizes,(0, 0, 0, 0, 0));
        ((nx_1,ny_1,ny_1_string,ny_1_int, ny_1_bool)) = BackendVariable.traverseBackendDAEVars(knvars,calculateVarSizes,(nx, ny, ny_string, ny_int, ny_bool));
      then
        (nx_1,ny_1,np,ng,nsam,next,ny_1_string, np_string, ny_1_int, np_int, ny_1_bool, np_bool);
  end match;
end calculateSizes;

public function numberOfZeroCrossings "function: numberOfZeroCrossings
  author: Frenkel TUD"
  input BackendDAE.BackendDAE inBackendDAE;
  output Integer outng        "number of zerocrossings";
  output Integer outng_sample "number of zerocrossings that are samples";
algorithm
  (outng,outng_sample):=
  match (inBackendDAE)
    local
      BackendDAE.Value ng,nsam;
      list<BackendDAE.ZeroCrossing> zc;
    case (BackendDAE.DAE(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zc)))
      equation
        (ng,nsam) = calculateNumberZeroCrossings(zc, 0, 0);
      then
        (ng,nsam);
  end match;
end numberOfZeroCrossings;

protected function calculateNumberZeroCrossings
  input list<BackendDAE.ZeroCrossing> zcLst;
  input Integer zc_index;
  input Integer sample_index;
  output Integer zc;
  output Integer sample;
algorithm
  (zc,sample) := matchcontinue (zcLst,zc_index,sample_index)
    local
      list<BackendDAE.ZeroCrossing> xs;
    
    case ({},zc_index,sample_index) then (zc_index,sample_index);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"))) :: xs,zc_index,sample_index)
      equation
        sample_index = sample_index + 1;
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(operator = _), occurEquLst = _) :: xs,zc_index,sample_index)
      equation
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (_,_,_)
      equation
        print("- BackendDAEUtil.calculateNumberZeroCrossings failed\n");
      then
        fail();

  end matchcontinue;
end calculateNumberZeroCrossings;

protected function calculateParamSizes "function: calculateParamSizes
  author: PA
  Helper function to calculateSizes"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value>> outTpl;
algorithm
  outTpl :=
  matchcontinue (inTpl)
    local
      BackendDAE.Value s1,s2,s3, s4;
      BackendDAE.Var var;
    case ((var,(s1,s2,s3,s4)))
      equation
        true = BackendVariable.isBoolParam(var);
      then
        ((var,(s1,s2,s3,s4 + 1)));  
    case ((var,(s1,s2,s3,s4)))
      equation
        true = BackendVariable.isIntParam(var);
      then
        ((var,(s1,s2,s3 + 1,s4)));
    case ((var,(s1,s2,s3,s4)))
      equation
        true = BackendVariable.isStringParam(var);
      then
        ((var,(s1,s2 + 1,s3,s4)));
    case ((var,(s1,s2,s3,s4)))
      equation
        true = BackendVariable.isParam(var);
      then
        ((var,(s1 + 1,s2,s3,s4)));
    case inTpl then inTpl;
  end matchcontinue;
end calculateParamSizes;

protected function calculateVarSizes "function: calculateVarSizes
  author: PA
  Helper function to calculateSizes"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value,BackendDAE.Value>> outTpl;
algorithm
  outTpl :=
  matchcontinue (inTpl)      
    local
      BackendDAE.Value nx,ny,ny_string, ny_int, ny_bool;
      DAE.Flow flowPrefix;
      BackendDAE.Var var;

    case ((var as BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string+1, ny_int,ny_bool)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int+1,ny_bool)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int,ny_bool+1)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny+1,ny_string, ny_int,ny_bool)));
    
     case ((var as BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string+1, ny_int,ny_bool)));
        
     case ((var as BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int+1,ny_bool)));
     
     case ((var as BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int,ny_bool+1)));
                 
     case ((var as BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny+1,ny_string, ny_int,ny_bool)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.STATE(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx+1,ny,ny_string, ny_int,ny_bool)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool))) /* A dummy state is an algebraic variable */
      then
        ((var,(nx,ny,ny_string+1, ny_int,ny_bool)));
        
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool))) /* A dummy state is an algebraic variable */
      then
        ((var,(nx,ny,ny_string, ny_int+1,ny_bool)));
    
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int,ny_bool+1)));
        
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool))) /* A dummy state is an algebraic variable */
      then
        ((var,(nx,ny+1,ny_string, ny_int,ny_bool)));

    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string+1, ny_int,ny_bool)));
        
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.INT(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int+1,ny_bool)));
    
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny,ny_string, ny_int,ny_bool+1)));
        
    case ((var as BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),flowPrefix = flowPrefix),(nx,ny,ny_string, ny_int, ny_bool)))
      then
        ((var,(nx,ny+1,ny_string, ny_int,ny_bool)));

    case inTpl then inTpl;
  end matchcontinue;
end calculateVarSizes;

public function calculateValues "function: calculateValues
  author: PA
  This function calculates the values from the parameter binding expressions."
  input Env.Cache cache;
  input Env.Env env;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := match (cache,env,inBackendDAE)
    local
      list<BackendDAE.Var> knvarlst;
      BackendDAE.Variables knvars,vars,extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (cache,env,BackendDAE.DAE(orderedVars = vars,knownVars = knvars,externalObjects=extVars,aliasVars = av,orderedEqs = eqns,
                 removedEqs = seqns,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = wc,extObjClasses=extObjCls))
      equation
        knvarlst = varList(knvars);
        knvarlst = Util.listMap3(knvarlst, calculateValue, cache, env, knvars);
        knvars = listVar(knvarlst);
      then
        BackendDAE.DAE(vars,knvars,extVars,av,eqns,seqns,ie,ae,al,wc,extObjCls);
  end match;
end calculateValues;

protected function calculateValue
  input BackendDAE.Var inVar;
  input Env.Cache cache;
  input Env.Env env;
  input BackendDAE.Variables vars;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar, cache, env, vars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind vk;
      DAE.VarDirection vd;
      BackendDAE.Type ty;
      DAE.Exp e, e2;
      DAE.InstDims dims;
      Integer idx;
      DAE.ElementSource src;
      Option<DAE.VariableAttributes> va;
      Option<SCode.Comment> c;
      DAE.Flow fp;
      DAE.Stream sp;
      Values.Value v;
    case (BackendDAE.VAR(varName = cr, varKind = vk, varDirection = vd, varType = ty,
          bindExp = SOME(e), arryDim = dims, index = idx, source = src, 
          values = va, comment = c, flowPrefix = fp, streamPrefix = sp), cache, env, _)
      equation
        ((e2, _)) = Expression.traverseExp(e, replaceCrefsWithValues, vars);
        (_, v, _) = Ceval.ceval(cache, env, e2, false,NONE(), NONE(), Ceval.MSG());
      then
        BackendDAE.VAR(cr, vk, vd, ty, SOME(e), SOME(v), dims, idx, src, va, c, fp, sp);
    else inVar;
  end matchcontinue;
end calculateValue;

protected function replaceCrefsWithValues
  input tuple<DAE.Exp, BackendDAE.Variables> inTuple;
  output tuple<DAE.Exp, BackendDAE.Variables> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
    case ((DAE.CREF(cr, _), vars))
      equation
         ({BackendDAE.VAR(bindExp = SOME(e))}, _) = BackendVariable.getVar(cr, vars);
         ((e, _)) = Expression.traverseExp(e, replaceCrefsWithValues, vars);
      then
        ((e, vars));
    case (_) then inTuple;
  end matchcontinue;
end replaceCrefsWithValues;
  
public function makeExpType
"Transforms a BackendDAE.Type to DAE.ExpType
"
  input BackendDAE.Type inType;
  output DAE.ExpType outType;
algorithm
  outType := match(inType)
    local
      list<String> strLst;
    case BackendDAE.REAL() then DAE.ET_REAL();
    case BackendDAE.INT() then DAE.ET_INT();
    case BackendDAE.BOOL() then DAE.ET_BOOL();
    case BackendDAE.STRING() then DAE.ET_STRING();
    case BackendDAE.ENUMERATION(strLst) then DAE.ET_ENUMERATION(Absyn.IDENT(""),strLst,{});
    case BackendDAE.EXT_OBJECT(_) then DAE.ET_OTHER();
  end match;
end makeExpType;

public function statesDaelow
"function: statesDaelow
  author: PA
  Returns a BackendDAE.BinTree of all states in the BackendDAE
  This function is used in matching algorithm."
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := match (inBackendDAE)
    local
      list<DAE.ComponentRef> cr_lst;
      BackendDAE.BinTree bt;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,re,ia;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
    case (BackendDAE.DAE(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = re,initialEqs = ia,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        cr_lst = BackendVariable.traverseBackendDAEVars(v,traversingisStateVarCrefFinder,{});
        bt = treeAddList(BackendDAE.emptyBintree,cr_lst);
      then
        bt;
  end match;
end statesDaelow;

protected function traversingisStateVarCrefFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, list<DAE.ComponentRef>> inTpl;
 output tuple<BackendDAE.Var, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;
    case ((v,cr_lst))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
      then ((v,cr::cr_lst));
    case inTpl then inTpl; 
  end matchcontinue;
end traversingisStateVarCrefFinder;

public function emptyVars
"function: emptyVars
  author: PA
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  output BackendDAE.Variables outVariables;
protected
  array<list<BackendDAE.CrefIndex>> arr;
  array<list<BackendDAE.StringIndex>> arr2;
  list<Option<BackendDAE.Var>> lst;
  array<Option<BackendDAE.Var>> emptyarr;
algorithm
  arr := arrayCreate(10, {});
  arr2 := arrayCreate(10, {});
  emptyarr := arrayCreate(10, NONE());
  outVariables := BackendDAE.VARIABLES(arr,arr2,BackendDAE.VARIABLE_ARRAY(0,10,emptyarr),10,0);
end emptyVars;

public function emptyAliasVariables
  output BackendDAE.AliasVariables outAliasVariables;
protected
  HashTable2.HashTable aliasMapsCref;  
  HashTable4.HashTable aliasMapsExp;
  BackendDAE.Variables aliasVariables;
algorithm
  aliasMapsCref := HashTable2.emptyHashTable();
  aliasMapsExp := HashTable4.emptyHashTable();
  aliasVariables := emptyVars();
  outAliasVariables := BackendDAE.ALIASVARS(aliasMapsCref,aliasMapsExp,aliasVariables);
end emptyAliasVariables;

public function addAliasVariables
"function: addAliasVariables
  author: Frenkel TUD 2010-12
  Add an alias variable to the AliasVariables "
  input list<BackendDAE.Var> inVars;
  input BackendDAE.AliasVariables inAliasVariables;
  output BackendDAE.AliasVariables outAliasVariables;
algorithm
algorithm
  outAliasVariables := matchcontinue (inVars,inAliasVariables)
    local
      HashTable2.HashTable aliasMappingsCref,aliasMappingsCref1;
      HashTable4.HashTable aliasMappingsExp,aliasMappingsExp1;
      BackendDAE.Variables aliasVariables;
      BackendDAE.AliasVariables Aliases;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      BackendDAE.Var v; 
      list<BackendDAE.Var> rest;
    case ({},Aliases) then Aliases;
    case (v::rest,BackendDAE.ALIASVARS(aliasMappingsCref,aliasMappingsExp,aliasVariables))
      equation
        aliasVariables = BackendVariable.addVar(v,aliasVariables);
        exp = BackendVariable.varBindExp(v);
        cr = BackendVariable.varCref(v);
        //print("++++ added Alias eqn : " +& ComponentReference.printComponentRefStr(cr) +& " = " +& ExpressionDump.printExpStr(exp) +& "\n");
        aliasMappingsCref1 = BaseHashTable.addNoUpdCheck((cr,exp),aliasMappingsCref);
        aliasMappingsExp1 = BaseHashTable.addNoUpdCheck((exp,cr),aliasMappingsExp);
        Aliases =  addAliasVariables(rest,BackendDAE.ALIASVARS(aliasMappingsCref1,aliasMappingsExp1,aliasVariables));
      then
       Aliases;
    case (_,_)
      equation
        print("- BackendDAEUtil.addAliasVariables failed\n");
      then
        fail();        
  end matchcontinue;
end addAliasVariables;

public function updateAliasVariables
"function: changeAliasVariables
  author: wbraun
  replace creaf in AliasVariable  variable to the AliasVariables "
  input BackendDAE.AliasVariables inAliasVariables;
  input DAE.ComponentRef inCref;
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output BackendDAE.AliasVariables outAliasVariables;
algorithm
  outAliasVariables := matchcontinue (inAliasVariables,inCref,inExp,inVars)
    local
      HashTable4.HashTable aliasMappingsExp; 
      BackendDAE.Variables aliasVariables;
      BackendDAE.AliasVariables Aliases;
      BackendDAE.Var v;
      list<BackendDAE.Var> vars;
      DAE.Exp exp,exp1;
      DAE.ComponentRef cr1;
      list<tuple<HashTable4.Key,HashTable4.Value>> tableList;
      list<String> str;
      DAE.ExpType ty;
    
    case (Aliases as BackendDAE.ALIASVARS( varMappingsExp = aliasMappingsExp, aliasVars = aliasVariables),inCref,inExp,inVars)
      equation
        exp1 = Expression.crefExp(inCref);
        cr1 = BaseHashTable.get(exp1,aliasMappingsExp);
        //print("update ComponentRef : " +& ComponentReference.printComponentRefStr(inCref) +& " with Exp : " +& ExpressionDump.printExpStr(inExp) +& "\n");
        
        tableList = BaseHashTable.hashTableList(aliasMappingsExp);
        Aliases = updateAliasVars(tableList,exp1,inExp,Aliases);

        ({v},_) = BackendVariable.getVar(inCref,inVars);
        v = BackendVariable.setBindExp(v,inExp);

        Aliases = addAliasVariables({v},Aliases);
      then
        Aliases;
    
    case (Aliases as BackendDAE.ALIASVARS( varMappingsExp = aliasMappingsExp, aliasVars = aliasVariables),inCref,inExp,inVars)
      equation
        exp1 = Expression.crefExp(inCref);
        ty = Expression.typeof(exp1);
        cr1 = BaseHashTable.get(DAE.UNARY(DAE.UMINUS(ty),exp1),aliasMappingsExp);
        //print("update ComponentRef : " +& ComponentReference.printComponentRefStr(inCref) +& " with  -" +& ExpressionDump.printExpStr(inExp) +& "\n");
        
        tableList = BaseHashTable.hashTableList(aliasMappingsExp);
        Aliases = updateAliasVars(tableList,exp1,inExp,Aliases);

        ({v},_) = BackendVariable.getVar(inCref,inVars);
        v = BackendVariable.setBindExp(v,inExp);

        Aliases = addAliasVariables({v},Aliases);
      then
        Aliases; 
           
    case (Aliases as BackendDAE.ALIASVARS( varMappingsExp = aliasMappingsExp, aliasVars = aliasVariables),inCref,inExp,inVars)
      equation
        //print(" Search for " +& ComponentReference.printComponentRefStr(inCref) +& " with binding : " +& ExpressionDump.printExpStr(inExp) +& "failed.\n");
        exp1 = Expression.crefExp(inCref);
        failure(_ = BaseHashTable.get(exp1,aliasMappingsExp));
        ({v},_) = BackendVariable.getVar(inCref,inVars);
        v = BackendVariable.setBindExp(v,inExp);
        Aliases = addAliasVariables({v},Aliases);
      then
        Aliases;
    //case (inAliasVariables,_,_) then inAliasVariables;
    case (_,_,_,_)
      equation
        print("- BackendDAEUtil.changeAliasVariables failed\n");
      then
        fail();        
  end matchcontinue;
end updateAliasVariables;

protected function updateAliasVars
" Helper function to changeAliasVariables.
  Collect all variables and update the alias exp binding.  
"
  input list<tuple<HashTable4.Key,HashTable4.Value>> inTableList1;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input BackendDAE.AliasVariables inAliases;
  output BackendDAE.AliasVariables outAliases;
algorithm
  (outAliases) := matchcontinue(inTableList1,inExp1,inExp2,inAliases)
    local
      list<tuple<HashTable4.Key,HashTable4.Value>> rest;
      DAE.Exp exp,exp2;
      DAE.ComponentRef cref;
      BackendDAE.Var v;
      BackendDAE.Variables aliasvars;
      BackendDAE.AliasVariables aliasVariables;
      DAE.ExpType ty;
      Boolean b;
      
      case ({},_,_,inAliases) then inAliases;
      case (((exp,cref))::rest,inExp1,inExp2,inAliases as BackendDAE.ALIASVARS(aliasVars=aliasvars))
        equation
          //print("Exp : " +& ExpressionDump.printExpStr(exp) +& " - " +& ExpressionDump.printExpStr(inExp1) +& "\n");
          ty = Expression.typeof(inExp2);
          (true,b,exp2) = compareExpAlias(exp,inExp1);
          //print("*** got : " +& ComponentReference.printComponentRefStr(cref) +& " = Exp : " +& ExpressionDump.printExpStr(exp2) +& "\n"  +& "ListLength: " +& intString(listLength(rest)) +& "\n");
          ({v},_) = BackendVariable.getVar(cref,aliasvars);
          exp = BackendVariable.varBindExp(v);
          //print("*** replace : " +& ExpressionDump.printExpStr(exp) +& " = " +& ExpressionDump.printExpStr(exp2) +& "\n");
          exp2 = Util.if_(b,DAE.UNARY(DAE.UMINUS(ty),inExp2),inExp2);
          exp2 = ExpressionSimplify.simplify1(exp2);
          v = BackendVariable.setBindExp(v,exp2);
          aliasVariables = addAliasVariables({v},inAliases);
          //print("RES *** ComponentRef : " +& ComponentReference.printComponentRefStr(cref) +& " = Exp : " +& ExpressionDump.printExpStr(exp2) +& "\n");
          aliasVariables =  updateAliasVars(rest,inExp1,inExp2,aliasVariables);
        then aliasVariables;   
      case (((exp,cref))::rest,inExp1,inExp2,aliasVariables)
        equation
          //print("*** let "  +& ExpressionDump.printExpStr(exp) +& " with binding Exp : " +& ComponentReference.printComponentRefStr(cref) +& "\n" +& "ListLength: " +& intString(listLength(rest)) +& "\n");
          aliasVariables = updateAliasVars(rest,inExp1,inExp2,aliasVariables);
        then aliasVariables;            
   end matchcontinue;
end updateAliasVars;    

protected function  compareExpAlias
"function helper function to getAllValues. 
 it compare both incomming expression for identital and output 
 that that fits"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outB;
  output Boolean outB2;
  output DAE.Exp outExp;
algorithm
  (outB, outB2, outExp) := matchcontinue(inExp1,inExp2)
    local
      DAE.Exp expNew, exp;
      DAE.ExpType ty;
      DAE.ComponentRef cref;
      Boolean b;
    // case a=a
   case (inExp1,inExp2)
     equation
       expNew = inExp2;
       true = Expression.expEqual(inExp1,expNew); 
     then (true,false, expNew);            
    // case a=-a
   case (inExp1,inExp2)
     equation
       ty = Expression.typeof(inExp2);
       expNew = DAE.UNARY(DAE.UMINUS(ty),inExp2);
       true = Expression.expEqual(inExp1,expNew); 
     then (true,true, expNew);       
   case (inExp1,_) then (false,false,inExp1);                    
   end matchcontinue;
end compareExpAlias;

public function equationList "function: equationList
  author: PA
  Transform the expandable BackendDAE.Equation array to a list of Equations."
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inEquationArray)
    local
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Equation elt;
      BackendDAE.Value lastpos,n,size;
      list<BackendDAE.Equation> lst;
    
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 0,equOptArr = arr)) then {};
    
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 1,equOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr))
      equation
        lastpos = n - 1;
        lst = equationList2(arr, 0, lastpos);
      then
        lst;
    
    case (_)
      equation
        print("- BackendDAEUtil.equationList failed\n");
      then
        fail();
  end matchcontinue;
end equationList;

protected function equationList2 "function: equationList2
  author: PA
  Helper function to equationList
  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: BackendDAE.Equation list"
  input array<Option<BackendDAE.Equation>> inEquationOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inEquationOptionArray1,inInteger2,inInteger3)
    local
      BackendDAE.Equation e;
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Value pos,lastpos,pos_1;
      list<BackendDAE.Equation> res;
    
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(e) = arr[pos + 1];
      then
        {e};
    
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(e) = arr[pos + 1];
        res = equationList2(arr, pos_1, lastpos);
      then
        (e :: res);
  end matchcontinue;
end equationList2;

public function listEquation "function: listEquation
  author: PA
  Transform the a list of Equations into an expandable BackendDAE.Equation array."
  input list<BackendDAE.Equation> lst;
  output BackendDAE.EquationArray outEquationArray;
protected
  BackendDAE.Value len,size;
  Real rlen,rlen_1;
  array<Option<BackendDAE.Equation>> optarr,eqnarr,newarr;
  list<Option<BackendDAE.Equation>> eqn_optlst;
algorithm
  len := listLength(lst);
  rlen := intReal(len);
  rlen_1 := rlen *. 1.4;
  size := realInt(rlen_1);
  optarr := arrayCreate(size, NONE());
  eqn_optlst := Util.listMap(lst, Util.makeOption);
  eqnarr := listArray(eqn_optlst);
  newarr := Util.arrayCopy(eqnarr, optarr);
  outEquationArray := BackendDAE.EQUATION_ARRAY(len,size,newarr);
end listEquation;

public function varList
"function: varList
  Takes BackendDAE.Variables and returns a list of \'Var\', useful for e.g. dumping."
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := match (inVariables)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.VariableArray vararr;
    
    case (BackendDAE.VARIABLES(varArr = vararr))
      equation
        varlst = vararrayList(vararr);
      then
        varlst;
  end match;
end varList;

public function listVar
"function: listVar
  author: PA
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := match (inVarLst)
    local
      BackendDAE.Variables res,vars,vars_1;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    
    case ({})
      equation
        res = emptyVars();
      then
        res;
    
    case ((v :: vs))
      equation
        vars = listVar(vs);
        vars_1 = BackendVariable.addVar(v, vars);
      then
        vars_1;
  end match;
end listVar;

public function vararrayList
"function: vararrayList
  Transforms a BackendDAE.VariableArray to a BackendDAE.Var list"
  input BackendDAE.VariableArray inVariableArray;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      array<Option<BackendDAE.Var>> arr;
      BackendDAE.Var elt;
      BackendDAE.Value lastpos,n,size;
      list<BackendDAE.Var> lst;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[1];
      then
        {elt};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
      equation
        lastpos = n - 1;
        lst = vararrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end vararrayList;

protected function vararrayList2
"function: vararrayList2
  Helper function to vararrayList"
  input array<Option<BackendDAE.Var>> inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      BackendDAE.Var v;
      array<Option<BackendDAE.Var>> arr;
      BackendDAE.Value pos,lastpos,pos_1;
      list<BackendDAE.Var> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = vararrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
  end matchcontinue;
end vararrayList2;

public function isDiscreteEquation
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output Boolean b;
algorithm
  b := matchcontinue(eqn,vars,knvars)
    local DAE.Exp e1,e2; DAE.ComponentRef cr; list<DAE.Exp> expl;
    
    case(BackendDAE.EQUATION(exp = e1,scalar = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    
    case(BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    
    case(BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),vars,knvars) equation
      // fails if all mapped function calls doesn't return true 
      Util.listMap2AllValue(expl,isDiscreteExp,vars,knvars,true);
    then true;
    
    case(BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),vars,knvars) equation
      e1 = Expression.crefExp(cr);  
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    
    case(BackendDAE.RESIDUAL_EQUATION(exp = e1),vars,knvars) equation
      b = isDiscreteExp(e1,vars,knvars);
    then b;
    
    case(BackendDAE.ALGORITHM(in_ = expl),vars,knvars) equation
      // fails if all mapped function calls doesn't return true
      Util.listMap2AllValue(expl,isDiscreteExp,vars,knvars,true);
    then true;
    
    case(BackendDAE.WHEN_EQUATION(whenEquation = _),vars,knvars) then true;
    // returns false otherwise!
    case(_,_,_) then false;
  end matchcontinue;
end isDiscreteEquation;

public function isDiscreteExp "function: isDiscreteExp
 Returns true if expression is a discrete expression."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables knvars;
  output Boolean outBoolean;
algorithm
  outBoolean := 
  match(inExp,inVariables,knvars)
    local 
      Boolean b;
      Option<Boolean> obool;
  case(inExp,inVariables,knvars)
    equation
      ((_,(_,_,obool))) = Expression.traverseExpTopDown(inExp, traversingisDiscreteExpFinder, (inVariables,knvars,NONE()));
      b = Util.getOptionOrDefault(obool,false);
      then
        b;
  end match;
end isDiscreteExp;


public function traversingisDiscreteExpFinder "
Author: Frenkel TUD 2010-11
Helper for isDiscreteExp"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,Option<Boolean>>> inTpl;
  output tuple<DAE.Exp, Boolean, tuple<BackendDAE.Variables,BackendDAE.Variables,Option<Boolean>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.Exp e,e1,e2;
      Option<Boolean> blst;
      Boolean b,b1,b2;
      Boolean res;
      BackendDAE.Var backendVar;

    case (((e as DAE.ICONST(integer = _),(vars,knvars,blst))))
      equation
        b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));
    case (((e as DAE.RCONST(real = _),(vars,knvars,blst))))
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.SCONST(string = _),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.BCONST(bool = _),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.ENUM_LITERAL(name = _),(vars,knvars,blst))))
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CREF(componentRef = cr),(vars,knvars,blst))))
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = BackendVariable.getVar(cr, vars);
        res = isKindDiscrete(kind);
      then
        ((e,false,(vars,knvars,SOME(res))));
    // builtin variable time is not discrete
    case (((e as DAE.CREF(componentRef = DAE.CREF_IDENT("time",_,_)),(vars,knvars,blst)))) then ((e,false,(vars,knvars,SOME(false))));      
    // Known variables that are input are continous
    case (((e as DAE.CREF(componentRef = cr),(vars,knvars,blst))))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        (backendVar::_,_) = BackendVariable.getVar(cr,knvars);
        true = isInput(backendVar);
      then
        ((e,false,(vars,knvars,SOME(false))));

    // parameters & constants
    case (((e as DAE.CREF(componentRef = cr),(vars,knvars,blst))))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        ((BackendDAE.VAR(varKind = kind) :: _),_) = BackendVariable.getVar(cr, knvars);
        b = isKindDiscrete(kind);
      then
        ((e,false,(vars,knvars,SOME(b))));
    
    case (((e as DAE.RELATION(exp1 = e1, exp2 = e2),(vars,knvars,blst)))) 
      equation
       b1 = isDiscreteExp(e1,vars,knvars);
       b2 = isDiscreteExp(e2,vars,knvars);
       b = Util.boolOrList({b1,b2});
      then ((e,false,(vars,knvars,SOME(b))));           
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "pre")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "edge")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "change")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "ceil")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "floor")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "div")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "mod")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "rem")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
/*
    This cases are wrong because of Modelica Specification:
    
    3.8.3 
    
    Unless inside noEvent: Ordered relations (>,<,>=,<=) and the functions ceil, floor, div, mod,
    rem, abs, sign. These will generate events if at least one subexpression is not a
    discrete-time expression. [In other words, relations inside noEvent(), such as noEvent(x>1),
    are not discrete-time expressions].
    
    and 
    
    3.7.1
    
    abs(v): Is expanded into 
      noEvent(if v >= 0 then v else -v)
    Argument v needs to be an Integer or Real expression.
    sign(v): Is expanded into 
      noEvent(if v>0 then 1 else if v<0 then -1 else 0)
     Argument v needs to be an Integer or Real expression.

    case (((e as DAE.CALL(path = Absyn.IDENT(name = "abs")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sign")),(vars,knvars,blst)))) 
      equation
       b = Util.getOptionOrDefault(blst,true);
      then ((e,false,(vars,knvars,SOME(b))));       
*/
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent")),(vars,knvars,blst)))) then ((e,false,(vars,knvars,SOME(false))));

    case((e,(vars,knvars,NONE()))) then ((e,true,(vars,knvars,NONE())));
    case((e,(vars,knvars,SOME(b)))) then ((e,b,(vars,knvars,SOME(b))));
  end matchcontinue;
end traversingisDiscreteExpFinder;


public function isVarDiscrete "returns true if variable is discrete"
  input BackendDAE.Var var;
  output Boolean res;
algorithm
  res := match(var)
    local BackendDAE.VarKind kind;
    case(BackendDAE.VAR(varKind=kind)) then isKindDiscrete(kind);
  end match;
end isVarDiscrete;

protected function isKindDiscrete "function: isKindDiscrete
  Returns true if BackendDAE.VarKind is discrete."
  input BackendDAE.VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVarKind)
    case (BackendDAE.DISCRETE()) then true;
    case (BackendDAE.PARAM()) then true;
    case (BackendDAE.CONST()) then true;
    case (_) then false;
  end matchcontinue;
end isKindDiscrete;

public function bintreeToList "function: bintreeToList
  author: PA

  This function takes a BackendDAE.BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      BackendDAE.BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToList2(bt, {}, {});
      then
        (klst,vlst);
    case (_)
      equation
        print("- BackendDAEUtil.bintreeToList failed\n");
      then
        fail();
  end matchcontinue;
end bintreeToList;

protected function bintreeToList2 "function: bintreeToList2
  author: PA
  helper function to bintreeToList"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst) := matchcontinue (inBinTree,inKeyLst,inValueLst)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      DAE.ComponentRef key;
      BackendDAE.Value value;
      Option<BackendDAE.BinTree> left,right;
    
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),klst,vlst) 
      then (klst,vlst);
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(key,value)),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(right, klst, vlst);
      then
        ((key :: klst),(value :: vlst));
    
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToList2;

protected function bintreeToListOpt "function: bintreeToListOpt
  author: PA
  helper function to bintreeToList"
  input Option<BackendDAE.BinTree> inBinTreeOption;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst) := match (inBinTreeOption,inKeyLst,inValueLst)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      BackendDAE.BinTree bt;
    
    case (NONE(),klst,vlst) then (klst,vlst);
    
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToList2(bt, klst, vlst);
      then
        (klst,vlst);
  end match;
end bintreeToListOpt;

public function statesAndVarsExp
"function: statesAndVarsExp
  This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (DAE.Exp, BackendDAE.Variables)
  outputs: DAE.Exp list"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := 
  match(inExp,inVariables)
    local list<DAE.Exp> exps;
  case(inExp,inVariables)
    equation
      ((_,(_,exps))) = Expression.traverseExpTopDown(inExp, traversingstatesAndVarsExpFinder, (inVariables,{}));
      then
        exps;
  end match;
end statesAndVarsExp;

public function traversingstatesAndVarsExpFinder "
Author: Frenkel TUD 2010-10
Helper for statesAndVarsExp"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.Exp>>> inTpl;
  output tuple<DAE.Exp, Boolean, tuple<BackendDAE.Variables,list<DAE.Exp>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
    DAE.ComponentRef cr;
    list<DAE.Exp> expl,res;
    DAE.Exp e,e1;
    list<list<DAE.Exp>> lst;
    list<DAE.ExpVar> varLst;
    BackendDAE.Variables vars;
    // Special Case for Records 
    case (((e as DAE.CREF(componentRef = cr,ty= DAE.ET_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)))),(vars,expl)))
      equation
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        ((e,true,(vars,res)));  
    // Special Case for unextended arrays
    case (((e as DAE.CREF(componentRef = cr,ty = DAE.ET_ARRAY(arrayDimensions=_))),(vars,expl)))
      equation
        ((e1,_)) = extendArrExp((e,NONE()));
        res = statesAndVarsExp(e1, vars);
      then
        ((e,true,(vars,res)));  
    case (((e as DAE.CREF(componentRef = cr)),(vars,expl)))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((e,false,(vars,e::expl)));  
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),(vars,expl)))
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = BackendVariable.getVar(cr, vars);
      then
        ((e,false,(vars,e::expl)));
    // is this case right?    
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,expl))))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((e,false,(vars,expl)));
  case((e,(vars,expl))) then ((e,true,(vars,expl)));
end matchcontinue;
end traversingstatesAndVarsExpFinder;

public function isLoopDependent
  "Checks if an expression is a variable that depends on a loop iterator,
  ie. for i loop
        V[i] = ...  // V depends on i
      end for;
  Used by lowerStatementInputsOutputs in STMT_FOR case."
  input DAE.Exp varExp;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(varExp, iteratorExp)
    local
      list<DAE.Exp> subscript_exprs;
      list<DAE.Subscript> subscripts;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef = cr), _)
      equation
        subscripts = ComponentReference.crefSubs(cr);
        subscript_exprs = Util.listMap(subscripts, Expression.subscriptIndexExp);
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (DAE.ASUB(sub = subscript_exprs), _)
      equation
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (_,_)
      then false;
  end matchcontinue;
end isLoopDependent;

protected function isLoopDependentHelper
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
        true = Expression.expContains(subscript, iteratorExp);
      then true;
    case (subscript :: rest, _)
      equation
        true = isLoopDependentHelper(rest, iteratorExp);
      then true;
    case (_, _) then false;
  end matchcontinue;
end isLoopDependentHelper;

public function devectorizeArrayVar
  input DAE.Exp arrayVar;
  output DAE.Exp newArrayVar;
algorithm
  newArrayVar := matchcontinue(arrayVar)
    local 
      DAE.ComponentRef cr;
      DAE.ExpType ty;
      list<DAE.Exp> subs;
      DAE.Exp e;
      
    case (DAE.ASUB(exp = DAE.ARRAY(array = (DAE.CREF(componentRef = cr, ty = ty) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        e = Expression.crefExp(cr);
      then
        // adrpo: TODO! FIXME! check if this is TYPE correct!
        //        shouldn't we change the type using the subs?
        Expression.makeASUB(e, subs);
    
    case (DAE.ASUB(exp = DAE.MATRIX(scalar = (((DAE.CREF(componentRef = cr, ty = ty), _) :: _) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        e = Expression.crefExp(cr);
      then
        // adrpo: TODO! FIXME! check if this is TYPE correct!
        //        shouldn't we change the type using the subs?
        Expression.makeASUB(e, subs);
    
    case (_) then arrayVar;
  end matchcontinue;
end devectorizeArrayVar;

public function explodeArrayVars
  "Explodes an array variable into its elements. Takes a variable that is a CREF
  or ASUB, the name of the iterator variable and a range expression that the
  iterator iterates over."
  input DAE.Exp arrayVar;
  input DAE.Exp iteratorExp;
  input DAE.Exp rangeExpr;
  input BackendDAE.Variables vars;
  output list<DAE.Exp> arrayElements;
algorithm
  arrayElements := matchcontinue(arrayVar, iteratorExp, rangeExpr, vars)
    local
      list<DAE.Exp> clonedElements, newElements;
      list<DAE.Exp> indices;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> varCrefs;
      list<DAE.Exp> varExprs;
      DAE.Exp daeExp;
      list<BackendDAE.Var> bvars;
    
    case (DAE.CREF(componentRef = _), _, _, _)
      equation
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.ASUB(exp = DAE.CREF(componentRef = _)), _, _, _)
      equation
        // If the range is constant, then we can use it to generate only those
        // array elements that are actually used.
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.CREF(componentRef = cref), _, _, _)
      equation
        (bvars, _) = BackendVariable.getVar(cref, vars);
        varCrefs = Util.listMap(bvars, BackendVariable.varCref);
        varExprs = Util.listMap(varCrefs, Expression.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (bvars, _) = BackendVariable.getVar(cref, vars);
        varCrefs = Util.listMap(bvars, BackendVariable.varCref);
        varExprs = Util.listMap(varCrefs, Expression.crefExp);
      then varExprs;
      
    case (DAE.ASUB(exp = daeExp), _, _, _)
      equation
        varExprs = Expression.flattenArrayExpToList(daeExp);
      then
        varExprs;
  end matchcontinue;
end explodeArrayVars;

protected function rangeIntExprs
  "Tries to convert a range to a list of integer expressions. Returns a list of
  integer expressions if possible, or fails. Used by explodeArrayVars."
  input DAE.Exp range;
  output list<DAE.Exp> integers;
algorithm
  integers := match(range)
    local
      list<DAE.Exp> arrayElements;
      Integer start, stop;
      list<Integer> vals;
    
    case (DAE.ARRAY(array = arrayElements)) then arrayElements;
    
    case (DAE.RANGE(exp = DAE.ICONST(integer = start), range = DAE.ICONST(integer = stop), expOption = NONE()))
      equation
        vals = ExpressionSimplify.simplifyRange(start, 1, stop);
        arrayElements = Util.listMap(vals, Expression.makeIntegerExp);
      then
        arrayElements;  
    
    case (_) then fail();
    
  end match;
end rangeIntExprs;

public function equationNth "function: equationNth
  author: PA

  Return the n:th equation from the expandable equation array
  indexed from 0..1.

  inputs:  (EquationArray, int /* n */)
  outputs:  Equation

"
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquationArray,inInteger)
    local
      BackendDAE.Equation e;
      BackendDAE.Value n,pos;
      array<Option<BackendDAE.Equation>> arr;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,equOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(e) = arr[pos + 1];
      then
        e;
    case (_,_)
      equation
        print("- BackendDAEUtil.equationNth failed\n");
      then
        fail();
  end matchcontinue;
end equationNth;

public function systemSize 
"function: equationSize
  author: Frenkel TUD
  Returns the size of the dae system, which 
  corresponds to the number of equations in a system."
  input BackendDAE.BackendDAE dae;
  output Integer n;
algorithm
  n := match(dae)
    local BackendDAE.EquationArray eqns;
    case(BackendDAE.DAE(orderedEqs = eqns))
      equation
        n = equationSize(eqns);
      then n;
  end match;
end systemSize;

public function equationSize "function: equationSize
  author: PA

  Returns the number of equations in an EquationArray, which 
  corresponds to the number of equations in a system.
  NOTE: Array equations and algorithms are represented several times
  in the array so the number of elements of the array corresponds to
  the equation system size."
  input BackendDAE.EquationArray inEquationArray;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inEquationArray)
    local BackendDAE.Value n;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n)) then n;
  end match;
end equationSize;

protected function generateArrayElements
  "Takes a list of identical CREF or ASUB expressions, a list of ICONST indices
  and a loop iterator expression, and recursively replaces the loop iterator
  with a constant index. Ex:
    generateArrayElements(cref[i,j], {1,2,3}, j) =>
      {cref[i,1], cref[i,2], cref[i,3]}"
  input list<DAE.Exp> clones;
  input list<DAE.Exp> indices;
  input DAE.Exp iteratorExp;
  output list<DAE.Exp> newElements;
algorithm
  newElements := match(clones, indices, iteratorExp)
    local
      DAE.Exp clone, newElement, newElement2, index;
      list<DAE.Exp> restClones, restIndices, elements;
    case ({}, {}, _) then {};
    case (clone :: restClones, index :: restIndices, _)
      equation
        ((newElement, _)) = Expression.replaceExp(clone, iteratorExp, index);
        newElement2 = simplifySubscripts(newElement);
        elements = generateArrayElements(restClones, restIndices, iteratorExp);
      then (newElement2 :: elements);
  end match;
end generateArrayElements;

protected function simplifySubscripts
  "Tries to simplify the subscripts of a CREF or ASUB. If an ASUB only contains
  constant subscripts, such as cref[1,4], then it also needs to be converted to
  a CREF."
  input DAE.Exp asub;
  output DAE.Exp maybeCref;
algorithm
  maybeCref := matchcontinue(asub)
    local
      DAE.Ident varIdent;
      DAE.ExpType arrayType, varType;
      list<DAE.Exp> subExprs, subExprsSimplified;
      list<DAE.Subscript> subscripts;
      DAE.Exp newCrefExp;
      DAE.ComponentRef cref_;

    // A CREF => just simplify the subscripts.
    case (DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType))
      equation
        subscripts = Util.listMap(subscripts, simplifySubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
        newCrefExp = Expression.makeCrefExp(cref_, varType);  
      then 
        newCrefExp;
        
    // An ASUB => convert to CREF if only constant subscripts.
    case (DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, _), varType), subExprs))
      equation
        {} = Util.listSelect(subExprs, Expression.isNotConst);
        // If a subscript is not a single constant value it needs to be
        // simplified, e.g. cref[3+4] => cref[7], otherwise some subscripts
        // might be counted twice, such as cref[3+4] and cref[2+5], even though
        // they reference the same element.
        subExprsSimplified = Util.listMap(subExprs, ExpressionSimplify.simplify);
        subscripts = Util.listMap(subExprsSimplified, Expression.makeIndexSubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
        newCrefExp = Expression.makeCrefExp(cref_, varType);
      then 
        newCrefExp;
        
    case (_) then asub;
  end matchcontinue;
end simplifySubscripts;

protected function simplifySubscript
  input DAE.Subscript sub;
  output DAE.Subscript simplifiedSub;
algorithm
  simplifiedSub := matchcontinue(sub)
    local
      DAE.Exp e;
    
    case (DAE.INDEX(exp = e))
      equation
        e = ExpressionSimplify.simplify(e);
      then 
        DAE.INDEX(e);
    
    case (_) then sub;
    
  end matchcontinue;
end simplifySubscript;


public function isInput
"function: isInput
  Returns true if variable is declared as input.
  See also is_ouput above"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.INPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isInput;



/*******************************************
   Functions that deals with BackendDAE as input
********************************************/

public function generateStatePartition "function:generateStatePartition

  This function traverses the equations to find out which blocks needs to
  be solved by the numerical solver (Dynamic Section) and which blocks only
  needs to be solved for output to file ( Accepted Section).
  This is done by traversing the graph of strong components, where
  equations/variable pairs correspond to nodes of the graph. The edges of
  this graph are the dependencies between blocks or components.
  The traversal is made in the backward direction of this graph.
  The result is a split of the blocks into two lists.
  inputs: (blocks: int list list,
             daeLow: BackendDAE,
             assignments1: int vector,
             assignments2: int vector,
             incidenceMatrix: IncidenceMatrix,
             incidenceMatrixT: IncidenceMatrixT)
  outputs: (dynamicBlocks: int list list, outputBlocks: int list list)
"
  input list<list<Integer>> inIntegerLstLst1;
  input BackendDAE.BackendDAE inBackendDAE2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix5;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT6;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst1,inBackendDAE2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6)
    local
      BackendDAE.Value size;
      array<BackendDAE.Value> arr,arr_1;
      list<list<BackendDAE.Value>> blt_states,blt_no_states,blt;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      array<BackendDAE.Value> ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
    case (blt,(dae as BackendDAE.DAE(orderedVars = v,knownVars = kv,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al)),ass1,ass2,m,mt)
      equation
        size = arrayLength(ass1) "equation_size(e) => size &" ;
        arr = arrayCreate(size, 0);
        arr_1 = markStateEquations(dae, arr, m, mt, ass1, ass2);
        (blt_states,blt_no_states) = splitBlocks(blt, arr);
      then
        (blt_states,blt_no_states);
    case (_,_,_,_,_,_)
      equation
        print("- BackendDAEUtil.generateStatePartition failed\n");
      then
        fail();
  end matchcontinue;
end generateStatePartition;

protected function splitBlocks "function: splitBlocks
  Split the blocks into two parts, one dynamic and one output, depedning
  on if an equation in the block is marked or not.
  inputs:  (blocks: int list list, marks: int array)
  outputs: (dynamic: int list list, output: int list list)"
  input list<list<Integer>> inIntegerLstLst;
  input array<Integer> inIntegerArray;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2) := matchcontinue (inIntegerLstLst,inIntegerArray)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
    
    case ({},_) then ({},{});
    
    case ((block_ :: blocks),arr)
      equation
        true = blockIsDynamic(block_, arr) "block is dynamic, belong in dynamic section" ;
        (states,output_) = splitBlocks(blocks, arr);
      then
        ((block_ :: states),output_);
    
    case ((block_ :: blocks),arr)
      equation
        (states,output_) = splitBlocks(blocks, arr) "block is not dynamic, belong in output section" ;
      then
        (states,(block_ :: output_));
  end matchcontinue;
end splitBlocks;

protected function blockIsDynamic "function blockIsDynamic
  Return true if the block contains a variable that is marked"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inIntegerLst,inIntegerArray)
    local
      BackendDAE.Value x_1,x,mark_value;
      Boolean res;
      list<BackendDAE.Value> xs;
      array<BackendDAE.Value> arr;
    
    case ({},_) then false;
    
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        0 = arr[x_1 + 1];
        res = blockIsDynamic(xs, arr);
      then
        res;
    
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        mark_value = arr[x_1 + 1];
        (mark_value <> 0) = true;
      then
        true;
  end matchcontinue;
end blockIsDynamic;

protected function markStateEquations "function: markStateEquations
  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: BackendDAE,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array"
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix3;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT4;
  input array<Integer> inIntegerArray5;
  input array<Integer> inIntegerArray6;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<BackendDAE.Var> statevar_lst;
      BackendDAE.BackendDAE dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
    
    case ((dae as BackendDAE.DAE(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr,m,mt,a1,a2)
      equation
        statevar_lst = BackendVariable.getAllStateVarFromVariables(v);
        ((dae,arr_1,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr,m,mt,a1,a2));
      then
        arr_1;
    
    case (_,_,_,_,_,_)
      equation
        print("- BackendDAEUtil.markStateEquations failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquations;
     
protected function markStateEquation
"function: markStateEquation
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.BackendDAE, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<BackendDAE.BackendDAE, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<BackendDAE.Value> v_indxs,v_indxs_1,eqns;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      DAE.ComponentRef cr;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      String s,str;
      BackendDAE.Value v_indx,v_indx_1;
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,v_indxs) = BackendVariable.getVar(cr, vars);
        v_indxs_1 = Util.listMap1(v_indxs, intSub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,m,mt,a1,a2)) = markStateEquation2(eqns, (arr,m,mt,a1,a2));
      then
        ((dae,arr_1,m,mt,a1,a2));
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        print("- BackendDAEUtil.markStateEquation var ");
        s = ComponentReference.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,{v_indx}) = BackendVariable.getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(_ = a1[v_indx_1 + 1]);
        print("-  BackendDAEUtil.markStateEquation index = ");
        str = intString(v_indx);
        print(str);
        print(", failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquation;

protected function markStateEquation2
"function: markStateEquation2
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  BackendDAE.IncidenceMatrix  BackendDAE.IncidenceMatrixT  int vector  int vector))
  outputs: ((marks: int array  BackendDAE.IncidenceMatrix  IncidenceMatrixT
        int vector  int vector))"
  input list<Integer> inIntegerLst;
  input tuple<array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inIntegerLst,inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      array<BackendDAE.Value> marks,marks_1,marks_2,marks_3;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      array<BackendDAE.Value> a1,a2,a1_1,a2_1;
      BackendDAE.Value eqn_1,eqn,mark_value,len;
      list<BackendDAE.Value> inv_reachable,inv_reachable_1,eqns;
      list<list<BackendDAE.Value>> inv_reachable_2;
      String eqnstr,lens,ms;
    
    case ({},(marks,m,mt,a1,a2)) then ((marks,m,mt,a1,a2));
    
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Mark an unmarked node/equation" ;
        0 = marks[eqn_1 + 1];
        marks_1 = arrayUpdate(marks, eqn_1 + 1, 1);
        inv_reachable = invReachableNodes(eqn, m, mt, a1, a2);
        inv_reachable_1 = removeNegative(inv_reachable);
        inv_reachable_2 = Util.listMap(inv_reachable_1, Util.listCreate);
        ((marks_2,m,mt,a1,a2)) = Util.listFold(inv_reachable_2, markStateEquation2, (marks_1,m,mt,a1,a2));
        ((marks_3,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks_2,m,mt,a1,a2));
      then
        ((marks_3,m_1,mt_1,a1_1,a2_1));
    
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Node allready marked." ;
        mark_value = marks[eqn_1 + 1];
        (mark_value <> 0) = true;
        ((marks_1,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks,m,mt,a1,a2));
      then
        ((marks_1,m_1,mt_1,a1_1,a2_1));
    
    case ((eqn :: _),(marks,m,mt,a1,a2))
      equation
        print("- BackendDAEUtil.markStateEquation2 failed, eqn: ");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length = ");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value: ");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

protected function invReachableNodes "function: invReachableNodes
  Similar to reachable_nodes, but follows edges in backward direction
  I.e. what equations/variables needs to be solved to solve this one."
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst :=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      BackendDAE.Value eqn_1,e,eqn;
      list<BackendDAE.Value> var_lst,var_lst_1,lst;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqn_str;
    
    case (e,m,mt,a1,a2)
      equation
        eqn_1 = e - 1;
        var_lst = m[eqn_1 + 1];
        var_lst_1 = removeNegative(var_lst);
        lst = invReachableNodes2(var_lst_1, a1);
      then
        lst;
    
    case (eqn,_,_,_,_)
      equation
        print("- BackendDAEUtil.invEeachableNodes failed, eqn: ");
        eqn_str = intString(eqn);
        print(eqn_str);
        print("\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes;

protected function invReachableNodes2 "function: invReachableNodes2
  Helper function to invReachableNodes
  inputs:  (variables: int list, assignments1: int vector)
  outputs: int list"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIntegerLst,inIntegerArray)
    local
      list<BackendDAE.Value> eqns,vs;
      BackendDAE.Value v_1,eqn,v;
      array<BackendDAE.Value> a1;
    
    case ({},_) then {};
    
    case ((v :: vs),a1)
      equation
        eqns = invReachableNodes2(vs, a1);
        v_1 = v - 1;
        eqn = a1[v_1 + 1] "Which equation is variable solved in?" ;
      then
        (eqn :: eqns);
    
    case (_,_)
      equation
        print("- BackendDAEUtil.invReachableNodes2 failed\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes2;

public function removeNegative
"function: removeNegative
  author: PA
  Removes all negative integers."
  input list<Integer> lst;
  output list<Integer> lst_1;
algorithm
  lst_1 := Util.listSelect(lst, Util.intPositive);
end removeNegative;

public function eqnsForVarWithStates
"function: eqnsForVarWithStates
  author: PA
  This function returns all equations as a list of equation indices
  given a variable as a variable index, including the equations containing
  the state variable but not its derivative. This must be used to update
  equations when a state is changed to algebraic variable in index reduction
  using dummy derivatives.
  These equation indices are represented with negative index, thus all
  indices are mapped trough int_abs (absolute value).
  inputs:  (IncidenceMatrixT, int /* variable */)
  outputs:  int list /* equations */"
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIncidenceMatrixT,inInteger)
    local
      BackendDAE.Value n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> mt;
      String s;
    
    case (mt,n)
      equation
        res = mt[n];
        res_1 = Util.listMap(res, intAbs);
      then
        res_1;
    
    case (_,indx)
      equation
        print("- BackendDAEUtil.eqnsForVarWithStates failed, indx= ");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVarWithStates;

public function varsInEqn
"function: varsInEqn
  author: PA
  This function returns all variable indices as a list for
  a given equation, given as an equation index. (1...n)
  Negative indexes are removed.
  See also: eqnsForVar and eqnsForVarWithStates
  inputs:  (IncidenceMatrix, int /* equation */)
  outputs:  int list /* variables */"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIncidenceMatrix,inInteger)
    local
      BackendDAE.Value n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> m;
      String s;
    
    case (m,n)
      equation
        res = m[n];
        res_1 = removeNegative(res);
      then
        res_1;
    
    case (m,indx)
      equation
        print("- BackendDAEUtil.varsInEqn failed, indx= ");
        s = intString(indx);
        print(s);
        print(" array length: ");
        s = intString(arrayLength(m));
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end varsInEqn;

public function subscript2dCombinations
"function: susbscript2dCombinations
  This function takes two lists of list of subscripts and combines them in
  all possible combinations. This is used when finding all indexes of a 2d
  array.
  For instance, subscript2dCombinations({{a},{b},{c}},{{x},{y},{z}})
  => {{a,x},{a,y},{a,z},{b,x},{b,y},{b,z},{c,x},{c,y},{c,z}}
  inputs:  (DAE.Subscript list list /* dim1 subs */,
              DAE.Subscript list list /* dim2 subs */)
  outputs: (DAE.Subscript list list)"
  input list<list<DAE.Subscript>> inExpSubscriptLstLst1;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst2;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := match (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
    local
      list<list<DAE.Subscript>> lst1,lst2,res,ss,ss2;
      list<DAE.Subscript> s1;
    
    case ({},_) then {};
    
    case ((s1 :: ss),ss2)
      equation
        lst1 = subscript2dCombinations2(s1, ss2);
        lst2 = subscript2dCombinations(ss, ss2);
        res = listAppend(lst1, lst2);
      then
        res;
  end match;
end subscript2dCombinations;

protected function subscript2dCombinations2
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := match (inExpSubscriptLst,inExpSubscriptLstLst)
    local
      list<list<DAE.Subscript>> lst1,ss2;
      list<DAE.Subscript> elt1,ss,s2;
    
    case (_,{}) then {};
    
    case (ss,(s2 :: ss2))
      equation
        lst1 = subscript2dCombinations2(ss, ss2);
        elt1 = listAppend(ss, s2);
      then
        (elt1 :: lst1);
  end match;
end subscript2dCombinations2;

/**************************
  BackendDAE.BinTree stuff
 **************************/

public function treeGet "function: treeGet
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BackendDAE.BinTree bt;
  input BackendDAE.Key key;
  output BackendDAE.Value v;
protected
  String keystr;
algorithm
  keystr := ComponentReference.printComponentRefStr(key);
  v := treeGet3(bt, keystr, treeGet2(bt, keystr));
end treeGet;

protected function treeGet2
  "Helper function to treeGet"
  input BackendDAE.BinTree inBinTree;
  input String inString;
  output Integer compResult;
algorithm
  compResult := match (inBinTree,inString)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey;
      
    // found it
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(key=rkey))),keystr)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey);
      then stringCompare(rkeystr, keystr);
  end match;
end treeGet2;

protected function treeGet3
  "Helper function to treeGet"
  input BackendDAE.BinTree inBinTree;
  input String inString;
  input Integer compResult;
  output BackendDAE.Value outValue;
algorithm
  outValue := match (inBinTree,inString,compResult)
    local
      String keystr;
      BackendDAE.Value rval;
      BackendDAE.BinTree right, left;
      
    // found it
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(value=rval))),keystr,0) then rval;
    // search right
    case (BackendDAE.TREENODE(rightSubTree = SOME(right)),keystr,1)
      equation
        compResult = treeGet2(right, keystr);
      then treeGet3(right, keystr, compResult);
    // search left
    case (BackendDAE.TREENODE(leftSubTree = SOME(left)),keystr,-1)
      equation
        compResult = treeGet2(left, keystr); 
      then treeGet3(left, keystr, compResult);
  end match;
end treeGet3;

public function treeAddList "function: treeAddList
  author: Frenkel TUD"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := match (inBinTree,inKeyLst)
    local
      BackendDAE.Key key;
      list<BackendDAE.Key> res;
      BackendDAE.BinTree bt,bt_1,bt_2;
    
    case (bt,{}) then bt;
    
    case (bt,key::res)
      equation
        bt_1 = treeAdd(bt,key,0);
        bt_2 = treeAddList(bt_1,res);
      then 
        bt_2;  
  end match;
end treeAddList;

public function treeAdd "function: treeAdd
  author: PA
  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering."
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  input BackendDAE.Value inValue;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inBinTree,inKey,inValue)
    local
      DAE.ComponentRef key,rkey;
      BackendDAE.Value value,rval,cmpval;
      String rkeystr,keystr;
      Option<BackendDAE.BinTree> left,right;
      BackendDAE.BinTree t_1,t,right_1,left_1;
      DAE.ComponentRef nkey;
    
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),key,value)
      equation
        nkey = key;
      then 
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(nkey,value)),NONE(),NONE());
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),key,value)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Replace this node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = stringCompare(rkeystr, keystr);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,value)),left,right);
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = stringCompare(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(t_1));
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as NONE())),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = stringCompare(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(right_1));
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = stringCompare(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(t_1),right);
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as NONE()),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = stringCompare(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(left_1),right);
    
    case (_,_,_)
      equation
        print("- BackendDAEUtil.treeAdd failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

protected function treeDelete "function: treeDelete
  author: PA
  This function deletes an entry from the BinTree."
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inBinTree,inKey)
    local
      BackendDAE.BinTree bt,right,left,t;
      DAE.ComponentRef key,rkey;
      String rkeystr,keystr;
      BackendDAE.TreeValue rightmost;
      Option<BackendDAE.BinTree> optRight,optLeft,optTree;
      BackendDAE.Value rval;
      Option<BackendDAE.TreeValue> optVal;
      
    case ((bt as BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE())),key) 
      then bt;
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = optLeft,rightSubTree = SOME(right)),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when existing right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = stringCompare(rkeystr, keystr);
        (rightmost,right) = treeDeleteRightmostValue(right);
        optRight = treePruneEmptyNodes(right);
      then
        BackendDAE.TREENODE(SOME(rightmost),optLeft,optRight);
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = SOME(left as BackendDAE.TREENODE(value=_)),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no right node, but left node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = stringCompare(rkeystr, keystr);
      then
        left;
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = NONE(),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no left or right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = stringCompare(rkeystr, keystr);
      then
        BackendDAE.TREENODE(NONE(),NONE(),NONE());
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = optLeft,rightSubTree = SOME(t)),key)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in right subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        1 = stringCompare(rkeystr, keystr);
        t = treeDelete(t, key);
        optTree = treePruneEmptyNodes(t);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),optLeft,optTree);
    
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree =  SOME(t),rightSubTree = optRight),key)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in left subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        -1 = stringCompare(rkeystr, keystr);
        t = treeDelete(t, key);
        optTree = treePruneEmptyNodes(t);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),optTree,optRight);
    
    case (_,_)
      equation
        print("- BackendDAEUtil.treeDelete failed\n");
      then
        fail();
  end matchcontinue;
end treeDelete;

protected function treeDeleteRightmostValue "function: treeDeleteRightmostValue
  author: PA
  This function takes a BackendDAE.BinTree and deletes the rightmost value of the tree.
  Tt returns this value and the updated BinTree. This function is used in
  the binary tree deletion function \'tree_delete\'.
  inputs:  (BinTree)
  outputs: (TreeValue, /* deleted value */
              BackendDAE.BinTree    /* updated bintree */)
"
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.TreeValue outTreeValue;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outTreeValue,outBinTree) := matchcontinue (inBinTree)
    local
      BackendDAE.TreeValue treeVal,value;
      BackendDAE.BinTree left,right,bt;
      Option<BackendDAE.BinTree> optRight, optLeft;
      Option<BackendDAE.TreeValue> optTreeVal;
    
    case (BackendDAE.TREENODE(value = SOME(treeVal),leftSubTree = NONE(),rightSubTree = NONE())) 
      then (treeVal,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    
    case (BackendDAE.TREENODE(value = SOME(treeVal),leftSubTree = SOME(left),rightSubTree = NONE())) 
      then (treeVal,left);
    
    case (BackendDAE.TREENODE(value = optTreeVal,leftSubTree = optLeft,rightSubTree = SOME(right)))
      equation
        (value,right) = treeDeleteRightmostValue(right);
        optRight = treePruneEmptyNodes(right);
      then
        (value,BackendDAE.TREENODE(optTreeVal,optLeft,optRight));
    
    case (BackendDAE.TREENODE(value = SOME(treeVal),leftSubTree = NONE(),rightSubTree = SOME(right)))
      equation
        failure((_,_) = treeDeleteRightmostValue(right));
        print("- Backend.treeDeleteRightmostValue: right value was empty, left NONE\n");
      then
        (treeVal,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    
    case (bt)
      equation
        print("- Backend.treeDeleteRightmostValue failed\n");
      then
        fail();
  end matchcontinue;
end treeDeleteRightmostValue;

protected function treePruneEmptyNodes "function: treePruneEmtpyNodes
  author: PA
  This function is a helper function to tree_delete
  It is used to delete empty nodes of the BackendDAE.BinTree 
  representation, that might be introduced when deleting nodes."
  input BackendDAE.BinTree inBinTree;
  output Option<BackendDAE.BinTree> outBinTreeOption;
algorithm
  outBinTreeOption := matchcontinue (inBinTree)
    local BackendDAE.BinTree bt;
    case BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()) then NONE();
    case bt then SOME(bt);
  end matchcontinue;
end treePruneEmptyNodes;

protected function bintreeDepth "function: bintreeDepth
  author: PA
  This function calculates the depth of the Binary Tree given
  as input. It can be used for debugging purposes to investigate
  how balanced binary trees are."
  input BackendDAE.BinTree inBinTree;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inBinTree)
    local
      BackendDAE.Value ld,rd,res;
      BackendDAE.BinTree left,right;
    
    case (BackendDAE.TREENODE(leftSubTree = NONE(),rightSubTree = NONE())) then 1;
    
    case (BackendDAE.TREENODE(leftSubTree = SOME(left),rightSubTree = SOME(right)))
      equation
        ld = bintreeDepth(left);
        rd = bintreeDepth(right);
        res = intMax(ld, rd);
      then
        res + 1;
    
    case (BackendDAE.TREENODE(leftSubTree = SOME(left),rightSubTree = NONE()))
      equation
        ld = bintreeDepth(left);
      then
        ld;
    
    case (BackendDAE.TREENODE(leftSubTree = NONE(),rightSubTree = SOME(right)))
      equation
        rd = bintreeDepth(right);
      then
        rd;
  end matchcontinue;
end bintreeDepth;

/************************************
  stuff that deals with extendArrExp
 ************************************/

public function extendArrExp "
Author: Frenkel TUD 2010-07"
  input tuple<DAE.Exp,Option<DAE.FunctionTree>> itpl;
  output tuple<DAE.Exp,Option<DAE.FunctionTree>> otpl;
algorithm 
  otpl := matchcontinue itpl
    local
      DAE.Exp e;
      Option<DAE.FunctionTree> funcs;
    case ((e,funcs)) then Expression.traverseExp(e, traversingextendArrExp, funcs);
    case _ then itpl;
  end matchcontinue;
end extendArrExp;

protected function traversingextendArrExp "
Author: Frenkel TUD 2010-07.
  This function extend all array and record componentrefs to there
  elements. This is necessary for BLT and substitution of simple 
  equations."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    list<DAE.ComponentRef> crlst;
    DAE.ExpType t,ty;
    DAE.Dimension id, jd;
    list<DAE.Dimension> ad;
    Integer i,j;
    list<list<DAE.Subscript>> subslst,subslst1;
    list<DAE.Exp> expl;
    DAE.Exp e_new;
    list<DAE.ExpVar> varLst;
    Absyn.Path name;
    tuple<DAE.Exp, Option<DAE.FunctionTree> > restpl;  
    list<list<tuple<DAE.Exp, Boolean>>> scalar;
    
  // CASE for Matrix    
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad as {id, jd})), funcs) )
    equation
        i = Expression.dimensionSize(id);
        j = Expression.dimensionSize(jd);
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Expression.makeCrefExp,ty);
        scalar = makeMatrix(expl,j,j,{});
        e_new = DAE.MATRIX(t,i,scalar);
        restpl = Expression.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  
  // CASE for Matrix and checkModel is on    
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad as {id, jd})), funcs) )
    equation
        true = OptManager.getOption("checkModel");
        // consider size 1
        i = Expression.dimensionSize(DAE.DIM_INTEGER(1));
        j = Expression.dimensionSize(DAE.DIM_INTEGER(1));
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Expression.makeCrefExp,ty);
        scalar = makeMatrix(expl,j,j,{});
        e_new = DAE.MATRIX(t,i,scalar);
        restpl = Expression.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  
  // CASE for Array
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad)), funcs) )
    equation
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Expression.makeCrefExp,ty);
        e_new = DAE.ARRAY(t,true,expl);
        restpl = Expression.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);

  // CASE for Array and checkModel is on
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad)), funcs) )
    equation
        true = OptManager.getOption("checkModel");
        // consider size 1      
        subslst = dimensionsToRange({DAE.DIM_INTEGER(1)});
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Expression.makeCrefExp,ty);
        e_new = DAE.ARRAY(t,true,expl);
        restpl = Expression.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  // CASE for Records
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_))), funcs) )
    equation
        expl = Util.listMap1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        e_new = DAE.CALL(name,expl,false,false,t,DAE.NO_INLINE());
        restpl = Expression.traverseExp(e_new, traversingextendArrExp, funcs);
    then 
      (restpl);
  case(inExp) then inExp;
end matchcontinue;
end traversingextendArrExp;

protected function makeMatrix
  input list<DAE.Exp> expl;
  input Integer r;
  input Integer n;
  input list<tuple<DAE.Exp, Boolean>> incol;
  output list<list<tuple<DAE.Exp, Boolean>>> scalar;
algorithm
  scalar := matchcontinue (expl, r, n, incol)
    local 
      DAE.Exp e;
      list<DAE.Exp> rest;
      list<list<tuple<DAE.Exp, Boolean>>> res;
      list<tuple<DAE.Exp, Boolean>> col;
      Expression.Type tp;
      Boolean builtin;      
  case({},r,n,incol)
    equation
      col = listReverse(incol);
    then {col};  
  case(e::rest,r,n,incol)
    equation
      true = intEq(r,0);
      col = listReverse(incol);
      res = makeMatrix(e::rest,n,n,{});
    then      
      (col::res);
  case(e::rest,r,n,incol)
    equation
      tp = Expression.typeof(e);
      builtin = Expression.typeBuiltin(tp);
      res = makeMatrix(rest,r-1,n,(e,builtin)::incol);
    then      
      res;
  end matchcontinue;
end makeMatrix;

public function removediscreteAssingments "
Author: wbraun
Function tarverse Statements and remove discrete one"
  input list<DAE.Statement> inStmts;
  input BackendDAE.Variables inVars; 
  output list<DAE.Statement> outStmts;
algorithm 
  outStmts := matchcontinue(inStmts,inVars)
    local 
      list<DAE.Statement> stmts,rest,xs;
      DAE.Else algElse;
      DAE.Statement stmt,ew;
      DAE.ComponentRef cref;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.Exp e;
      DAE.ElementSource source;
      
      DAE.ExpType tp;
      Boolean b1;
      String id1;
      list<Integer> li;
    case ({},_) then ({});
      
    case ((DAE.STMT_ASSIGN(exp1 = e) :: rest),vars)
      equation
        cref = Expression.expCref(e);
        ({v},_) = BackendVariable.getVar(cref,vars);
        true = BackendVariable.isVarDiscrete(v);
        xs = removediscreteAssingments(rest,vars);
    then xs;
        
    /*case ((DAE.STMT_TUPLE_ASSIGN(expExpLst = expl1) :: rest),vars)
      equation
        crefLst = Util.listMap(expl1,Expression.expCref);
        (vlst,_) = Util.listMap12(crefLst,BackendVariable.getVar,vars);
        //blst = Util.listMap(vlst,BackendVariable.isVarDiscrete);
        //true = boolOrList(blst);
        xs = removediscreteAssingments(rest,vars); 
      then xs;
      */  
    case ((DAE.STMT_ASSIGN_ARR(componentRef = cref) :: rest),vars)
      equation
        ({v},_) = BackendVariable.getVar(cref,vars);
        true = BackendVariable.isVarDiscrete(v);
        xs = removediscreteAssingments(rest,vars);
     then xs;
        
    case (((DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source)) :: rest),vars)
      equation
        stmts = removediscreteAssingments(stmts,vars);
        algElse = removediscreteAssingmentsElse(algElse,vars);
        xs = removediscreteAssingments(rest,vars);
      then DAE.STMT_IF(e,stmts,algElse,source) :: xs;
        
    case (((DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,range=e,statementLst=stmts, source = source)) :: rest),vars)
      equation
        stmts = removediscreteAssingments(stmts,vars);
        xs = removediscreteAssingments(rest,vars);
      then DAE.STMT_FOR(tp,b1,id1,e,stmts,source) :: xs;
        
    case (((DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source)) :: rest),vars)
      equation
        stmts = removediscreteAssingments(stmts,vars);
        xs = removediscreteAssingments(rest,vars);
    then DAE.STMT_WHILE(e,stmts,source) :: xs;
    case (((DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=NONE(),helpVarIndices=li, source = source)) :: rest),vars)
        
      equation
        stmts = removediscreteAssingments(stmts,vars);
        xs = removediscreteAssingments(rest,vars);
      then DAE.STMT_WHEN(e,stmts,NONE(),li,source) :: xs;
        
    case (((DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li, source = source)) :: rest),vars)
      equation
        stmts = removediscreteAssingments(stmts,vars);
        {ew} = removediscreteAssingments({ew},vars);
        xs = removediscreteAssingments(rest,vars);
      then DAE.STMT_WHEN(e,stmts,SOME(ew),li,source) :: xs;
        
    case ((stmt :: rest),vars)
      equation
        xs = removediscreteAssingments(rest,vars);
      then  stmt :: xs;       
  end matchcontinue;
end removediscreteAssingments;

protected function removediscreteAssingmentsElse "
Author: wbraun
Helper function for traverseDAEEquationsELse
"
  input DAE.Else inElse;
  input BackendDAE.Variables inVars; 
  output DAE.Else outElse;
algorithm 
  outElse := match(inElse,inVars)
  local
    DAE.Exp e;
    list<DAE.Statement> st;
    DAE.Else el;
    BackendDAE.Variables vars;
  case(DAE.NOELSE(),_) then (DAE.NOELSE());
  case(DAE.ELSEIF(e,st,el),vars)
    equation
      el = removediscreteAssingmentsElse(el,vars);
      st = removediscreteAssingments(st,vars);
    then DAE.ELSEIF(e,st,el);
  case(DAE.ELSE(st),vars)
    equation
      st = removediscreteAssingments(st,vars);
    then DAE.ELSE(st);
end match;
end removediscreteAssingmentsElse;

public function collateAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,infuncs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),infuncs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, collateArrExp, infuncs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,infuncs) then inAlg;        
  end matchcontinue;
end collateAlgorithm;

public function collateArrExpList
"function collateArrExpList
 author Frenkel TUD:
  replace {a[1],a[2],a[3]} for Real a[3] with a"
  input list<DAE.Exp> expl;
  input Option<DAE.FunctionTree> optfunc;
  output list<DAE.Exp> outexpl;
algorithm
  outexpl := match(expl,optfunc)
    local 
      DAE.Exp e,e1; 
      list<DAE.Exp> expl1;
    
    case({},_) then {};
    
    case(e::expl,optfunc) equation
      ((e1,_)) = collateArrExp((e,optfunc));
      expl1 = collateArrExpList(expl,optfunc);
    then 
      e1::expl1; 
  end match;
end collateArrExpList;

public function collateArrExp "
Author: Frenkel TUD 2010-07"
  input tuple<DAE.Exp,Option<DAE.FunctionTree>> itpl;
  output tuple<DAE.Exp,Option<DAE.FunctionTree>> otpl;
algorithm 
  otpl := matchcontinue itpl
    local
      DAE.Exp e;
      Option<DAE.FunctionTree> funcs;
    case ((e,funcs)) then Expression.traverseExp(e, traversingcollateArrExp, funcs);
    case itpl then itpl;
  end matchcontinue;
end collateArrExp;  
  
protected function traversingcollateArrExp "
Author: Frenkel TUD 2010-07."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    DAE.ExpType ty;
    Integer i;
    DAE.Exp e,e1,e1_1,e1_2;
    Boolean b;
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.CREF(componentRef = cr)),_)::_)::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        ((e1_2,_)) = extendArrExp((e1_1,funcs));
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr))),_)::_)::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        ((e1_2,_)) = extendArrExp((e1_1,funcs));
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));        
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.CREF(componentRef = cr))::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        ((e1_2,_)) = extendArrExp((e1_1,funcs));
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));  
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr)))::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        ((e1_2,_)) = extendArrExp((e1_1,funcs));
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));               
  case(inExp) then inExp;
end matchcontinue;
end traversingcollateArrExp;  

public function dimensionsToRange
  "Converts a list of dimensions to a list of integer ranges."
  input list<DAE.Dimension> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := matchcontinue(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    DAE.Dimension d;
    case({}) then {};
    case(DAE.DIM_UNKNOWN()::dims) 
      equation
        rangelist = dimensionsToRange(dims);
      then {}::rangelist;
    case(d::dims) equation
      i = Expression.dimensionSize(d);
      range = Util.listIntRange(i);
      subs = rangesToSubscript(range);
      rangelist = dimensionsToRange(dims);
    then subs::rangelist;
  end matchcontinue;
end dimensionsToRange;

public function rangesToSubscript "
Author: Frenkel TUD 2010-05"
  input list<Integer> inRange;
  output list<DAE.Subscript> outSubs;
algorithm
  outSubs := match(inRange)
  local 
    Integer i;
    list<Integer> res;
    list<DAE.Subscript> range;
    case({}) then {};
    case(i::res) 
      equation
        range = rangesToSubscript(res);
      then DAE.INDEX(DAE.ICONST(i))::range;
  end match;
end rangesToSubscript;

public function rangesToSubscripts "
Author: Frenkel TUD 2010-05"
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := matchcontinue(inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    list<list<list<DAE.Subscript>>> rangelistlst;
    list<DAE.Subscript> range;
    case({}) then {};
    case(range::{})
      equation
        rangelist = Util.listMap(range,Util.listCreate); 
      then rangelist;
    case(range::rangelist)
      equation
      rangelist = rangesToSubscripts(rangelist);
      rangelistlst = Util.listMap1(range,rangesToSubscripts1,rangelist);
      rangelist1 = Util.listFlatten(rangelistlst);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts;

protected function rangesToSubscripts1 "
Author: Frenkel TUD 2010-05"
  input DAE.Subscript inSub;
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := match(inSub,inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    DAE.Subscript sub;
    case(sub,rangelist)
      equation
      rangelist1 = Util.listMap1r(rangelist,Util.listAddElementFirst,sub);
    then rangelist1;
  end match;
end rangesToSubscripts1;

public function getEquationBlock "function: getEquationBlock
  author: PA

  Returns the block the equation belongs to.
"
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLstLst)
    local
      BackendDAE.Value e;
      list<BackendDAE.Value> block_,res;
      list<list<BackendDAE.Value>> blocks;
    case (e,(block_ :: blocks))
      equation
        true = listMember(e, block_);
      then
        block_;
    case (e,(block_ :: blocks))
      equation
        res = getEquationBlock(e, blocks);
      then
        res;
  end matchcontinue;
end getEquationBlock;

public function getNumberOfEquationArray 
  input BackendDAE.EquationArray inEqArr "equation array";
  output Integer noOfElements "number of elements";
algorithm
  BackendDAE.EQUATION_ARRAY(numberOfElement = noOfElements) := inEqArr;
end getNumberOfEquationArray;

/******************************************************************
 stuff to calculate incidence matrix
  
 wbraun: It should be renames to Adjacency matrix, because
    incidence matrix descibes the relation between knots and edges. 
    In the sense it is used here is the relation between knots and
    knots of a bigraph.
******************************************************************/

public function incidenceMatrix
"function: incidenceMatrix
  author: PA, adrpo
  Calculates the incidence matrix, i.e. which variables are present in each equation.
  You can ask for absolute indexes or normal (negative for der) via the IndexType"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IndexType inIndexType;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
algorithm
  outIncidenceMatrix := matchcontinue (inBackendDAE, inIndexType)
    local
      array<list<BackendDAE.Value>> arr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> wc;
      Integer numberOfEqs;
    
    case (BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns, eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc)), inIndexType)
      equation
        // get the size
        numberOfEqs = getNumberOfEquationArray(eqns);
        // create the array to hold the incidence matrix
        arr = arrayCreate(numberOfEqs, {});
        arr = incidenceMatrixDispatch(vars, eqns, wc, arr, 0, numberOfEqs, inIndexType);
      then
        arr;
    
    case (_, inIndexType)
      equation
        print("- BackendDAEUtil.incidenceMatrix failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix;

public function applyIndexType
"@author: adrpo
  Applies absolute value to all entries in the given list."
  input list<Integer> inLst;
  input BackendDAE.IndexType inIndexType;
  output list<Integer> outLst;
algorithm
  outLst := match(inLst, inIndexType)
    
    // leave as it is 
    case (inLst, BackendDAE.NORMAL()) then inLst;
    
    // transform to absolute indexes
    case (inLst, BackendDAE.ABSOLUTE()) then Util.absIntegerList(inLst);
    
  end match;
end applyIndexType;  

protected function incidenceMatrixDispatch
"@author: adrpo
  Calculates the incidence matrix as an array of list of integers"
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEqsArr;
  input list<BackendDAE.WhenClause> inWhenClause;
  input array<list<Integer>> inIncidenceArray;
  input Integer index;
  input Integer numberOfEqs;
  input BackendDAE.IndexType inIndexType;
  output array<list<Integer>> outIncidenceArray;
algorithm
  outIncidenceArray := matchcontinue (inVariables, inEqsArr, inWhenClause, inIncidenceArray, index, numberOfEqs, inIndexType)
    local
      list<BackendDAE.Value> row;
      BackendDAE.Variables vars;
      BackendDAE.Equation e;
      BackendDAE.EquationArray eqArr;
      list<BackendDAE.WhenClause> wc;
      array<list<Integer>> iArr;
      Integer i,n;
    
    // i = n (we reach the end)
    case (vars, eqArr, wc, iArr, i, n, inIndexType)
      equation
        false = intLt(i, n);
      then 
        iArr;
    
    // i < n 
    case (vars, eqArr, wc, iArr, i, n, inIndexType)
      equation
        true = intLt(i, n);
        // get the equation
        e = equationNth(eqArr, i);
        // compute the row
        row = incidenceRow(vars, e, wc);
        // only absolute indexes?
        row = applyIndexType(row, inIndexType);
        // put it in the array
        iArr = arrayUpdate(iArr, i+1, row);
        iArr = incidenceMatrixDispatch(vars, eqArr, wc, iArr, i + 1, n, inIndexType);
      then
        iArr;
    
    case (vars, eqArr, wc, iArr, i, n, inIndexType)
      equation
        print("- BackendDAEUtil.incidenceMatrixDispatch failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrixDispatch;

public function incidenceRow
"function: incidenceRow
  author: PA
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for one equation."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.WhenClause> inWhenClause;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVariables,inEquation,inWhenClause)
    local
      list<BackendDAE.Value> lst1,lst2,res;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e,expCref;
      list<list<BackendDAE.Value>> lstlst1,lstlst2,lstlst3,lstres;
      list<DAE.Exp> expl,inputs,outputs;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      BackendDAE.Value indx;
      list<BackendDAE.WhenClause> wc;
      Integer wc_index;  
      String eqnstr;      
    
    // EQUATION
    case (vars,BackendDAE.EQUATION(exp = e1,scalar = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = Util.listListUnionOnTrue({lst1, lst2},intEq);
      then
        res;
    
    // COMPLEX_EQUATION
    case (vars,BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = Util.listListUnionOnTrue({lst1, lst2},intEq);
      then
        res;
    
    // ARRAY_EQUATION
    case (vars,BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),_)
      equation
        lstlst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listListUnionOnTrue(lstlst3,intEq);
      then
        res;
    
    // SOLVED_EQUATION
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e),_)
      equation
        expCref = Expression.crefExp(cr);
        lst1 = incidenceRowExp(expCref, vars);
        lst2 = incidenceRowExp(e, vars);
        res = Util.listListUnionOnTrue({lst1, lst2},intEq);
      then
        res;
    
    // RESIDUAL_EQUATION
    case (vars,BackendDAE.RESIDUAL_EQUATION(exp = e),_)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    
    // WHEN_EQUATION
    case (vars,BackendDAE.WHEN_EQUATION(whenEquation = we as BackendDAE.WHEN_EQ(index=wc_index)),wc)
      equation
        expl = BackendEquation.getWhenCondition(wc,wc_index);
        lstlst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst1 = Util.listFlatten(lstlst3);
        (cr,e2) = BackendEquation.getWhenEquationExpr(we);
        e1 = Expression.crefExp(cr);
        lst2 = incidenceRowExp(e1, vars);
        res = incidenceRowExp(e2, vars);
        res = Util.listListUnionOnTrue({lst1, lst2, res},intEq);
      then
        res;
    
    // ALGORITHM For now assume that algorithm will be solvable for 
    // correct variables. I.e. find all variables in algorithm and add to lst.
    // If algorithm later on needs to be inverted, i.e. solved for
    // different variables than calculated, a non linear solver or
    // analysis of algorithm itself needs to be implemented.
    case (vars,BackendDAE.ALGORITHM(index = indx,in_ = inputs,out = outputs),_)
      equation
        lstlst1 = Util.listMap1(inputs, incidenceRowExp, vars);
        lstlst2 = Util.listMap1(outputs, incidenceRowExp, vars);
        lstres = listAppend(lstlst1, lstlst2);
        res = Util.listListUnionOnTrue(lstres,intEq);
      then
        res;
    
    case (vars,inEquation,_)
      equation
        eqnstr = BackendDump.equationStr(inEquation);
        print("- BackendDAE.incidenceRow failed for eqn: ");
        print(eqnstr);
        print("\n");
      then
        fail();
  end matchcontinue;
end incidenceRow;

protected function incidenceRowExp
"function: incidenceRowExp
  author: PA
  Helper function to incidenceRow, investigates expressions for
  variables, returning variable indexes."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Value> outIntegerLst;
algorithm
  outIntegerLst := match (inExp,inVariables)
    local
      list<BackendDAE.Value> vallst;
  case(inExp,inVariables)      
    equation
      ((_,(_,vallst))) = Expression.traverseExpTopDown(inExp, traversingincidenceRowExpFinder, (inVariables,{}));
      then
        vallst;
  end match;
end incidenceRowExp;

public function traversingincidenceRowExpFinder "
Author: Frenkel TUD 2010-11
Helper for statesAndVarsExp"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Value>>> inTpl;
  output tuple<DAE.Exp, Boolean, tuple<BackendDAE.Variables,list<BackendDAE.Value>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
      list<BackendDAE.Value> p,p_1,pa,res;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e;
      list<BackendDAE.Var> varslst;
    
    case (((e as DAE.CREF(componentRef = cr),(vars,pa))))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,true);
        res = Util.listListUnionOnTrue({pa,p_1},intEq);
      then
        ((e,false,(vars,res)));
    
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
        res = Util.listListUnionOnTrue({pa,p_1},intEq);        
      then
        ((e,false,(vars,res)));       
    
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))))
      equation
        cr = ComponentReference.makeCrefQual("$DER", DAE.ET_REAL(), {}, cr);
        (varslst,p) = BackendVariable.getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
        res = Util.listListUnionOnTrue({pa,p_1},intEq);
      then
        ((e,false,(vars,res)));
    /* pre(v) is considered a known variable */
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa)))) then ((e,false,(vars,pa)));  
    
    case ((e,(vars,pa))) then ((e,true,(vars,pa)));
  end matchcontinue;
end traversingincidenceRowExpFinder;

protected function incidenceRowExp1
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  input Boolean notinder;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVarLst,inIntegerLst,notinder)
    local
       list<BackendDAE.Var> rest;
       list<Integer> irest,res;
       Integer i,i1;  
       Boolean b;
    case ({},{},_) then {};   
    /*If variable x is a state, der(x) is a variable in incidence matrix,
         x is inserted as negative value, since it is needed by debugging and
         index reduction using dummy derivatives */ 
    case (BackendDAE.VAR(varKind = BackendDAE.STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
        i1 = Util.if_(b,-i,i);
      then (i1::res);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);        
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);                
    case (_ :: rest,_::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b);  
      then res;
  end matchcontinue;      
end incidenceRowExp1;

public function transposeMatrix
"function: transposeMatrix
  author: PA
  Calculates the transpose of the incidence matrix,
  i.e. which equations each variable is present in."
  input BackendDAE.IncidenceMatrix m;
  output BackendDAE.IncidenceMatrixT mt;
protected
  list<list<BackendDAE.Value>> mlst,mtlst;
algorithm
  mlst := arrayList(m);
  mtlst := transposeMatrix2(mlst);
  mt := listArray(mtlst);
end transposeMatrix;

protected function transposeMatrix2
"function: transposeMatrix2
  author: PA
  Helper function to transposeMatrix"
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst)
    local
      BackendDAE.Value neq;
      list<list<BackendDAE.Value>> mt,m;
    case (m)
      equation
        neq = listLength(m);
        mt = transposeMatrix3(m, neq, 0, {});
      then
        mt;
    case (_)
      equation
        print("- BackendDAEUtil.transposeMatrix2 failed\n");
      then
        fail();
  end matchcontinue;
end transposeMatrix2;

protected function transposeMatrix3
"function: transposeMatrix3
  author: PA
  Helper function to transposeMatrix2"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input list<list<Integer>> inIntegerLstLst4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3,inIntegerLstLst4)
    local
      BackendDAE.Value neq_1,eqno_1,neq,eqno;
      list<list<BackendDAE.Value>> mt_1,m,mt;
      list<BackendDAE.Value> row;
    case (_,0,_,_) then {};
    case (m,neq,eqno,mt)
      equation
        neq_1 = neq - 1;
        eqno_1 = eqno + 1;
        mt_1 = transposeMatrix3(m, neq_1, eqno_1, mt);
        row = transposeRow(m, eqno_1, 1);
      then
        (row :: mt_1);
  end matchcontinue;
end transposeMatrix3;

public function absIncidenceMatrix
"function absIncidenceMatrix
  author: PA
  Applies absolute value to all entries in the incidence matrix.
  This can be used when e.g. der(x) and x are considered the same variable."
  input BackendDAE.IncidenceMatrix m;
  output BackendDAE.IncidenceMatrix res;
  list<list<BackendDAE.Value>> lst,lst_1;
algorithm
  lst := arrayList(m);
  lst_1 := Util.listListMap(lst, intAbs);
  res := listArray(lst_1);
end absIncidenceMatrix;

public function varsIncidenceMatrix
"function: varsIncidenceMatrix
  author: PA
  Return all variable indices in the incidence
  matrix, i.e. all elements of the matrix."
  input BackendDAE.IncidenceMatrix m;
  output list<Integer> res;
  list<list<BackendDAE.Value>> mlst;
algorithm
  mlst := arrayList(m);
  res := Util.listFlatten(mlst);
end varsIncidenceMatrix;

protected function transposeRow
"function: transposeRow
  author: PA
  Helper function to transposeMatrix2.
  Input: BackendDAE.IncidenceMatrix (eqn => var)
  Input: row number (variable)
  Input: iterator (start with one)
  inputs:  (int list list, int /* row */,int /* iter */)
  outputs:  int list"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3)
    local
      BackendDAE.Value eqn_1,varno,eqn,varno_1,eqnneg;
      list<BackendDAE.Value> res,m;
      list<list<BackendDAE.Value>> ms;
    case ({},_,_) then {};
    case ((m :: ms),varno,eqn)
      equation
        true = listMember(varno, m);
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqn :: res);
    case ((m :: ms),varno,eqn)
      equation
        varno_1 = 0 - varno "Negative index present, state variable. list_member(varno,m) => false &" ;
        true = listMember(varno_1, m);
        eqnneg = 0 - eqn;
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqnneg :: res);
    case ((m :: ms),varno,eqn)
      equation
        eqn_1 = eqn + 1 "not present at all" ;
        res = transposeRow(ms, varno, eqn_1);
      then
        res;
    case (_,_,_)
      equation
        print("- BackendDAEUtil.transposeRow failed\n");
      then
        fail();
  end matchcontinue;
end transposeRow;

public function updateIncidenceMatrix
"function: updateIncidenceMatrix
  author: PA
  Takes a daelow and the incidence matrix and its transposed
  represenation and a list of  equation indexes that needs to be updated.
  First the BackendDAE.IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to
  update the BackendDAE.IncidenceMatrixT (transpose) mapping from variables to
  equations. The function returns an updated incidence matrix.
  inputs:  (BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input list<Integer> inIntegerLst;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inIntegerLst)
    local
      array<list<BackendDAE.Value>> m_1,mt_1,m,mt;
      list<list<BackendDAE.Value>> changedvars;
      list<BackendDAE.Value> changedvars_1,eqns;
      BackendDAE.BackendDAE dae;

    case (dae,m,mt,eqns)
      equation
        (m_1,changedvars) = updateIncidenceMatrix2(dae, m, eqns);
        changedvars_1 = Util.listFlatten(changedvars);
        mt_1 = updateTransposedMatrix(changedvars_1, m_1, mt);
      then
        (m_1,mt_1);

    case (dae,m,mt,eqns)
      equation
        print("- BackendDAE.updateIncidenceMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateIncidenceMatrix;

protected function updateIncidenceMatrix2
"function: updateIncidenceMatrix2
  author: PA
  Helper function to updateIncidenceMatrix
  inputs:  (BackendDAE,
            IncidenceMatrix,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, int list list /* changed vars */)"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input list<Integer> inIntegerLst;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outIncidenceMatrix,outIntegerLstLst):=
  matchcontinue (inBackendDAE,inIncidenceMatrix,inIntegerLst)
    local
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,m_1,m_2;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Value> row,changedvars1,eqns;
      list<list<BackendDAE.Value>> changedvars2;
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray daeeqns,daeseqns;
      list<BackendDAE.WhenClause> wc;

    case (dae,m,{}) then (m,{{}});

    case ((dae as BackendDAE.DAE(orderedVars = vars,knownVars = knvars,orderedEqs = daeeqns,removedEqs = daeseqns,eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc))),m,(e :: eqns))
      equation
        e_1 = e - 1;
        eqn = equationNth(daeeqns, e_1);
        row = incidenceRow(vars, eqn,wc);
        m_1 = Util.arrayReplaceAtWithFill(row, e, m, {});
        changedvars1 = varsInEqn(m_1, e);
        (m_2,changedvars2) = updateIncidenceMatrix2(dae, m_1, eqns);
      then
        (m_2,(changedvars1 :: changedvars2));

    case (_,_,_)
      equation
        print("- BackendDAEUtil.updateIncididenceMatrix2 failed\n");
      then
        fail();

  end matchcontinue;
end updateIncidenceMatrix2;

protected function updateTransposedMatrix
"function: updateTransposedMatrix
  author: PA
  Takes a list of variables and the transposed
  IncidenceMatrix, and updates the variable rows.
  inputs:  (int list /* var list */,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs:  IncidenceMatrixT"
  input list<Integer> inIntegerLst;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  outIncidenceMatrixT:=
  matchcontinue (inIntegerLst,inIncidenceMatrix,inIncidenceMatrixT)
    local
      array<list<BackendDAE.Value>> m,mt,mt_1,mt_2;
      list<list<BackendDAE.Value>> mlst;
      list<BackendDAE.Value> row_1,vars;
      BackendDAE.Value v;
    case ({},m,mt) then mt;
    case ((v :: vars),m,mt)
      equation
        mlst = arrayList(m);
        row_1 = transposeRow(mlst, v, 1);
        mt_1 = Util.arrayReplaceAtWithFill(row_1, v, mt, {});
        mt_2 = updateTransposedMatrix(vars, m, mt_1);
      then
        mt_2;
    case (_,_,_)
      equation
        print("- BackendDAE.updateTransposedMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateTransposedMatrix;

public function getIncidenceMatrixfromOption "function getIncidenceMatrixfromOption"
  input BackendDAE.BackendDAE inDAE;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;  
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  (outM,outMT):=
  matchcontinue (inDAE,inM,inMT)
    local  
      BackendDAE.BackendDAE dae;
      BackendDAE.IncidenceMatrix m,mT;
    case(dae,NONE(),_)
      equation  
        m = incidenceMatrix(dae, BackendDAE.NORMAL());
        mT = transposeMatrix(m);
      then
        (m,mT);
    case(_,SOME(m),NONE())
      equation  
        mT = transposeMatrix(m);
      then
        (m,mT);
    case(_,SOME(m),SOME(mT))
      then
        (m,mT);        
  end matchcontinue;
end getIncidenceMatrixfromOption;  
    
/*************************************
 jacobian stuff
 ************************************/

public function calculateJacobian "function: calculateJacobian
  This function takes an array of equations and the variables of the equation
  and calculates the jacobian of the equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inVariables,inEquationArray,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,differentiateIfExp)
    local
      list<BackendDAE.Equation> eqn_lst;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
    case (vars,eqns,ae,m,mt,differentiateIfExp)
      equation
        eqn_lst = BackendEquation.traverseBackendDAEEqns(eqns,traverseequationToResidualForm,{});
        eqn_lst = listReverse(eqn_lst);
        SOME(jac) = calculateJacobianRows(eqn_lst, vars, ae, m, mt,differentiateIfExp);
      then
        SOME(jac);
    case (_,_,_,_,_,_) then NONE();  /* no analythic jacobian available */
  end matchcontinue;
end calculateJacobian;

public function traverseequationToResidualForm "function: traverseequationToResidualForm
  author: Frenkel TUD 2010-11
  helper for calculateJacobian"
  input tuple<BackendDAE.Equation, list<BackendDAE.Equation>> inTpl;
  output tuple<BackendDAE.Equation, list<BackendDAE.Equation>> outTpl;  
algorithm
  outTpl := matchcontinue (inTpl)
    local
      list<BackendDAE.Equation> eqns;
      BackendDAE.Equation eqn,reqn;
    case ((eqn,eqns))
      equation
        reqn = BackendEquation.equationToResidualForm(eqn);
      then
        ((eqn,reqn::eqns));
    case (inTpl) then inTpl;
  end matchcontinue;
end traverseequationToResidualForm;

protected function calculateJacobianRows "function: calculateJacobianRows
  author: PA
  This function takes a list of Equations and a set of variables and
  calculates the jacobian expression for each variable over each equations,
  returned in a sparse matrix representation.
  For example, the equation on index e1: 3ax+5yz+ zz  given the
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}"
  input list<BackendDAE.Equation> eqns;
  input BackendDAE.Variables vars;
  input array<BackendDAE.MultiDimEquation> ae;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> res;
algorithm
  (res,_) := calculateJacobianRows2(eqns, vars, ae, m, mt, 1,differentiateIfExp, {});
end calculateJacobianRows;

protected function calculateJacobianRows2 "function: calculateJacobianRows2
  author: PA
  Helper function to calculateJacobianRows"
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  match (inEquationLst,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      BackendDAE.Value eqn_indx_1,eqn_indx;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> l1,l2,res;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2; 
    case ({},_,_,_,_,_,_,inEntrylst) then (SOME({}),inEntrylst);
    case ((eqn :: eqns),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        eqn_indx_1 = eqn_indx + 1;
        (SOME(l1),entrylst1) = calculateJacobianRows2(eqns, vars, ae, m, mt, eqn_indx_1,differentiateIfExp,inEntrylst);
        (SOME(l2),entrylst2) = calculateJacobianRow(eqn, vars, ae, m, mt, eqn_indx,differentiateIfExp,entrylst1);
        res = listAppend(l1, l2);
      then
        (SOME(res),entrylst2);
  end match;
end calculateJacobianRows2;

protected function calculateJacobianRow "function: calculateJacobianRow
  author: PA
  Calculates the jacobian for one equation. See calculateJacobianRows.
  inputs:  (Equation,
              Variables,
              BackendDAE.MultiDimEquation array,
              IncidenceMatrix,
              IncidenceMatrixT,
              int /* eqn index */)
  outputs: ((int  int  Equation) list option)"
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquation,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      list<BackendDAE.Value> var_indxs,var_indxs_1,ds;
      list<Option<Integer>> ad;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
      DAE.Exp e,e1,e2,new_exp;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value eqn_indx,indx;
      list<DAE.Exp> in_,out,expl;
      Expression.Type t;
      list<DAE.Subscript> subs;   
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1;   
    // residual equations
    case (BackendDAE.RESIDUAL_EQUATION(exp = e),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: ascending index" ;
        SOME(eqns) = calculateJacobianRow2(e, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),inEntrylst);
    // algorithms give no jacobian
    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst) then (NONE(),inEntrylst);
    // array equations
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = ae[indx + 1];
        t = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(t),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = getArrayEquationSub(indx,ad,inEntrylst);
        new_exp = Expression.applyExpSubscripts(new_exp,subs);
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: acsending index";
        SOME(eqns) = calculateJacobianRow2(new_exp, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),entrylst1);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.calculateJacobianRow failed");
      then
        fail();         
  end matchcontinue;
end calculateJacobianRow;

public function getArrayEquationSub"function: getArrayEquationSub
  author: Frenkel TUD
  helper for calculateJacobianRow and SimCode.dlowEqToExp"
  input Integer Index;
  input list<Option<Integer>> inAD;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inList;
  output list<DAE.Subscript> outSubs;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outList;
algorithm
  (outSubs,outList) := 
  matchcontinue (Index,inAD,inList)
    local
      Integer i,ie;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs,subs1;
      list<list<DAE.Subscript>> subslst,subslst1;
      list<tuple<Integer,list<list<DAE.Subscript>>>> rest,entrylst;
      tuple<Integer,list<list<DAE.Subscript>>> entry;
    // new entry  
    case (i,ad,{})
      equation
        subslst = arrayDimensionsToRange(ad);
        (subs::subslst1) = rangesToSubscripts(subslst);
      then
        (subs,{(i,subslst1)});
    // found last entry
    case (i,ad,(entry as (ie,{subs}))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,rest);         
    // found entry
    case (i,ad,(entry as (ie,subs::subslst))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,(ie,subslst)::rest); 
    // next entry  
    case (i,ad,(entry as (ie,subslst))::rest)
      equation
        false = intEq(i,ie);
        (subs1,entrylst) = getArrayEquationSub(i,ad,rest);
      then   
        (subs1,entry::entrylst); 
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.getArrayEquationSub failed");
      then
        fail();          
  end matchcontinue;      
end getArrayEquationSub;

protected function arrayDimensionsToRange "
Author: Frenkel TUD 2010-05"
  input list<Option<Integer>> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := match(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    case({}) then {};
    case(NONE()::dims) equation
      rangelist = arrayDimensionsToRange(dims);
    then {}::rangelist;
    case(SOME(i)::dims) equation
      range = Util.listIntRange(i);
      subs = rangesToSubscript(range);
      rangelist = arrayDimensionsToRange(dims);
    then subs::rangelist;
  end match;
end arrayDimensionsToRange;


protected function makeResidualEqn "function: makeResidualEqn
  author: PA
  Transforms an expression into a residual equation"
  input DAE.Exp inExp;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inExp)
    local DAE.Exp e;
    case (e) then BackendDAE.RESIDUAL_EQUATION(e,DAE.emptyElementSource);
  end matchcontinue;
end makeResidualEqn;

protected function calculateJacobianRow2 "function: calculateJacobianRow2
  author: PA
  Helper function to calculateJacobianRow
  Differentiates expression for each variable cref.
  inputs: (DAE.Exp,
             Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption := match (inExp,inVariables,inInteger,inIntegerLst,differentiateIfExp)
    local
      DAE.Exp e,e_1,e_2;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> es;
      BackendDAE.Variables vars;
      BackendDAE.Value eqn_indx,vindx;
      list<BackendDAE.Value> vindxs;

    case (e,_,_,{},_) then SOME({});
    case (e,vars,eqn_indx,(vindx :: vindxs),differentiateIfExp)
      equation
        v = BackendVariable.getVarAt(vars, vindx);
        cr = BackendVariable.varCref(v);
        e_1 = Derive.differentiateExp(e, cr, differentiateIfExp);
        e_2 = ExpressionSimplify.simplify(e_1);
        SOME(es) = calculateJacobianRow2(e, vars, eqn_indx, vindxs, differentiateIfExp);
      then
        SOME(((eqn_indx,vindx,BackendDAE.RESIDUAL_EQUATION(e_2,DAE.emptyElementSource)) :: es));
  end match;
end calculateJacobianRow2;

public function analyzeJacobian "function: analyzeJacobian
  author: PA

  Analyze the jacobian to find out if the jacobian of system of equations
  can be solved at compiletime or runtime or if it is a nonlinear system
  of equations.
"
  input BackendDAE.BackendDAE inBackendDAE;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output BackendDAE.JacobianType outJacobianType;
algorithm
  outJacobianType:=
  matchcontinue (inBackendDAE,inTplIntegerIntegerEquationLstOption)
    local
      BackendDAE.BackendDAE daelow;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
    case (daelow,SOME(jac))
      equation
        true = jacobianConstant(jac);
        true = rhsConstant(daelow);
      then
        BackendDAE.JAC_CONSTANT();
    case (daelow,SOME(jac))
      equation
        true = jacobianNonlinear(daelow, jac);
      then
        BackendDAE.JAC_NONLINEAR();
    case (daelow,SOME(jac)) then BackendDAE.JAC_TIME_VARYING();
    case (daelow,NONE()) then BackendDAE.JAC_NO_ANALYTIC();
  end matchcontinue;
end analyzeJacobian;

protected function rhsConstant "function: rhsConstant
  author: PA

  Determines if the right hand sides of an equation system,
  represented as a BackendDAE, is constant.
"
  input BackendDAE.BackendDAE inBackendDAE;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inBackendDAE)
    local
      Boolean res;
      BackendDAE.BackendDAE dae;
      BackendDAE.EquationArray eqns;
    case ((dae as BackendDAE.DAE(orderedEqs = eqns)))
      equation
        0 = equationSize(eqns);
      then
        true;
    case ((dae as BackendDAE.DAE(orderedEqs = eqns)))
      equation
        ((_,res)) = BackendEquation.traverseBackendDAEEqnsWithStop(eqns,rhsConstant2,(dae,false));
      then
        res;
  end matchcontinue;
end rhsConstant;

protected function rhsConstant2 "function: rhsConstant2
  author: PA
  Helper function to rhsConstant, traverses equation list."
  input tuple<BackendDAE.Equation, tuple<BackendDAE.BackendDAE,Boolean>> inTpl;
  output tuple<BackendDAE.Equation, Boolean, tuple<BackendDAE.BackendDAE,Boolean>> outTpl;  
algorithm
  outTpl := matchcontinue (inTpl)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean b,res;
      BackendDAE.Equation eqn;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      BackendDAE.Value indx_1,indx;
      list<BackendDAE.Value> ds;
      list<DAE.Exp> expl;
      array<BackendDAE.MultiDimEquation> arreqn;

    // check rhs for for EQUATION nodes.
    case ((eqn as BackendDAE.EQUATION(exp = e1,scalar = e2),(dae as BackendDAE.DAE(orderedVars = vars),b)))
      equation
        tp = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        res = Expression.isConst(rhs_exp);
      then
        ((eqn,res,(dae,b and res)));
    // check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes.
    case ((eqn as BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),(dae as BackendDAE.DAE(orderedVars = vars,arrayEqs = arreqn),b)))
      equation
        indx_1 = indx - 1;
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = arreqn[indx + 1];
        tp = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        res = Expression.isConst(rhs_exp);
      then
        ((eqn,res,(dae,b and res)));

    case ((eqn as BackendDAE.RESIDUAL_EQUATION(exp = e),(dae as BackendDAE.DAE(orderedVars = vars),b))) /* check rhs for for RESIDUAL_EQUATION nodes. */
      equation
        rhs_exp = getEqnsysRhsExp(e, vars);
        res = Expression.isConst(rhs_exp);
      then
        ((eqn,res,(dae,b and res)));
    case ((eqn,(dae,b))) then ((eqn,true,(dae,b)));
  end matchcontinue;
end rhsConstant2;

protected function freeFromAnyVar "function: freeFromAnyVar
  author: PA
  Helper function to rhsConstant2
  returns true if expression does not contain
  anyof the variables passed as argument."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e;
      list<BackendDAE.Key> crefs;
      list<Boolean> b_lst;
      Boolean res,res_1;
      BackendDAE.Variables vars;

    case (e,_)
      equation
        {} = Expression.extractCrefsFromExp(e) "Special case for expressions with no variables" ;
      then
        true;
    case (e,vars)
      equation
        crefs = Expression.extractCrefsFromExp(e);
        b_lst = Util.listMap1(crefs, BackendVariable.existsVar, vars);
        res = Util.boolOrList(b_lst);
        res_1 = boolNot(res);
      then
        res_1;
    case (_,_) then true;
  end matchcontinue;
end freeFromAnyVar;

public function jacobianTypeStr "function: jacobianTypeStr
  author: PA
  Returns the jacobian type as a string, used for debugging."
  input BackendDAE.JacobianType inJacobianType;
  output String outString;
algorithm
  outString := matchcontinue (inJacobianType)
    case BackendDAE.JAC_CONSTANT() then "Jacobian Constant";
    case BackendDAE.JAC_TIME_VARYING() then "Jacobian Time varying";
    case BackendDAE.JAC_NONLINEAR() then "Jacobian Nonlinear";
    case BackendDAE.JAC_NO_ANALYTIC() then "No analythic jacobian";
  end matchcontinue;
end jacobianTypeStr;

protected function jacobianConstant "function: jacobianConstant
  author: PA
  Checks if jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case ({}) then true;
    case (((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: eqns)) /* TODO: Algorithms and ArrayEquations */
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        true = Expression.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.SOLVED_EQUATION(exp = e)) :: eqns))
      equation
        true = Expression.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (_) then false;
  end matchcontinue;
end jacobianConstant;

protected function jacobianNonlinear "function: jacobianNonlinear
  author: PA
  Check if jacobian indicates a nonlinear system.
  TODO: Algorithms and Array equations"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inBackendDAE,inTplIntegerIntegerEquationLst)
    local
      BackendDAE.BackendDAE daelow;
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> xs;

    case (daelow,((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e1);
        false = jacobianNonlinearExp(daelow, e2);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (daelow,((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (_,{}) then false;
    case (_,_) then true;
  end matchcontinue;
end jacobianNonlinear;

protected function jacobianNonlinearExp "function: jacobianNonlinearExp
  author: PA
  Checks wheter the jacobian indicates a nonlinear system.
  This is true if the jacobian contains any of the variables
  that is solved for."
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBackendDAE,inExp)
    local
      list<BackendDAE.Key> crefs;
      Boolean res;
      BackendDAE.Variables vars;
      DAE.Exp e;
    case (BackendDAE.DAE(orderedVars = vars),e)
      equation
        crefs = Expression.extractCrefsFromExp(e);
        res = containAnyVar(crefs, vars);
      then
        res;
  end match;
end jacobianNonlinearExp;

protected function containAnyVar "function: containAnyVar
  author: PA
  Returns true if any of the variables given
  as ComponentRef list is among the Variables."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crefs;
      BackendDAE.Variables vars;
      Boolean res;
    case ({},_) then false;
    case ((cr :: crefs),vars)
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        true;
    case ((_ :: crefs),vars)
      equation
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end containAnyVar;

public function getEqnsysRhsExp "function: getEqnsysRhsExp
  author: PA

  Retrieve the right hand side expression of an equation
  in an equation system, given a set of variables.

  inputs:  (DAE.Exp, BackendDAE.Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      list<DAE.Exp> term_lst,rhs_lst,rhs_lst2;
      DAE.Exp new_exp,res,exp;
      BackendDAE.Variables vars;
    case (exp,vars)
      equation
        term_lst = Expression.allTerms(exp);
        rhs_lst = Util.listSelect1(term_lst, vars, freeFromAnyVar);
        /* A term can contain if-expressions that has branches that are on rhs and other branches that
        are on lhs*/
        rhs_lst2 = ifBranchesFreeFromVar(term_lst,vars);
        new_exp = Expression.makeSum(listAppend(rhs_lst,rhs_lst2));
        res = ExpressionSimplify.simplify(new_exp);
      then
        res;
    case (_,_)
      equation
        Debug.fprint("failtrace", "- BackendDAEUtil.getEqnsysRhsExp failed\n");
      then
        fail();
  end matchcontinue;
end getEqnsysRhsExp;

public function ifBranchesFreeFromVar "
  Retrieves if-branches free from any of the variables passed as argument.
  This is done by replacing the variables with zero."
  input list<DAE.Exp> expl;
  input BackendDAE.Variables vars;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := matchcontinue(expl,vars)
    local DAE.Exp cond,t,f,e1,e2;
      VarTransform.VariableReplacements repl;
      DAE.Operator op;
      Absyn.Path path;
      list<DAE.Exp> expl2;
      Boolean tpl ;
      Boolean b;
      DAE.InlineType i;
      DAE.ExpType ty;
    
    case({},vars) then {};
    
    case(DAE.IFEXP(cond,t,f)::expl,vars) 
      equation
        repl = makeZeroReplacements(vars);
        t = ifBranchesFreeFromVar2(t,repl);
        f = ifBranchesFreeFromVar2(f,repl);
        expl = ifBranchesFreeFromVar(expl,vars);
      then 
        (DAE.IFEXP(cond,t,f)::expl);
    
    case(DAE.BINARY(e1,op,e2)::expl,vars) 
      equation
        repl = makeZeroReplacements(vars);
        {e1} = ifBranchesFreeFromVar({e1},vars);
        {e2} = ifBranchesFreeFromVar({e2},vars);
        expl = ifBranchesFreeFromVar(expl,vars);
      then 
        (DAE.BINARY(e1,op,e2)::expl);
    
    case(DAE.UNARY(op,e1)::expl,vars) 
      equation
        repl = makeZeroReplacements(vars);
        {e1} = ifBranchesFreeFromVar({e1},vars);
        expl = ifBranchesFreeFromVar(expl,vars);
      then 
        (DAE.UNARY(op,e1)::expl);
    
    case(DAE.CALL(path,expl2,tpl,b,ty,i)::expl,vars) 
      equation
        repl = makeZeroReplacements(vars);
        (expl2 as _::_) = ifBranchesFreeFromVar(expl2,vars);
        expl = ifBranchesFreeFromVar(expl,vars);
      then 
        (DAE.CALL(path,expl2,tpl,b,ty,i)::expl);
    
    case(_::expl,vars) 
      equation
        expl = ifBranchesFreeFromVar(expl,vars);
      then expl;
  end matchcontinue;
end ifBranchesFreeFromVar;

protected function ifBranchesFreeFromVar2 "
  Help function to ifBranchesFreeFromVar,
  replaces variables in if branches (not conditions) 
  recursively (to include elseifs)"
  input DAE.Exp ifBranch;
  input VarTransform.VariableReplacements repl;
  output DAE.Exp outIfBranch;
algorithm
  outIfBranch := matchcontinue(ifBranch,repl)
    local 
      DAE.Exp cond,t,f,e;
    
    case(DAE.IFEXP(cond,t,f),repl) 
      equation
        t = ifBranchesFreeFromVar2(t,repl);
        f = ifBranchesFreeFromVar2(f,repl);
      then 
        DAE.IFEXP(cond,t,f);
    
    case(e,repl) 
      equation
        e = VarTransform.replaceExp(e,repl,NONE());
      then e;
  end matchcontinue;
end ifBranchesFreeFromVar2;

protected function makeZeroReplacements "
  Help function to ifBranchesFreeFromVar, creates replacement rules
  v -> 0, for all variables"
  input BackendDAE.Variables vars;
  output VarTransform.VariableReplacements repl;
algorithm
  repl := BackendVariable.traverseBackendDAEVars(vars,makeZeroReplacement,VarTransform.emptyReplacements());
end makeZeroReplacements;

protected function makeZeroReplacement "helper function to makeZeroReplacements.
Creates replacement Var-> 0"
  input tuple<BackendDAE.Var, VarTransform.VariableReplacements> inTpl;
  output tuple<BackendDAE.Var, VarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local    
     BackendDAE.Var var;
     DAE.ComponentRef cr;
     VarTransform.VariableReplacements repl,repl1;
    case ((var,repl))
      equation
        cr =  BackendVariable.varCref(var);
        repl1 = VarTransform.addReplacement(repl,cr,DAE.RCONST(0.0));
      then
        ((var,repl1));
    case inTpl then inTpl;
  end matchcontinue;          
end makeZeroReplacement;

/*************************************************
 * traverseBackendDAE and stuff
 ************************************************/
public function traverseBackendDAEExps "function: traverseBackendDAEExps
  author: Frenkel TUD

  This function goes through the BackendDAE.BackendDAE structure and finds all the
  expressions and performs the function on them in a list 
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;  
  input BackendDAE.BackendDAE inBackendDAE;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inBackendDAE,func,inTypeA)
    local
      BackendDAE.Variables vars1,vars2;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3,ext_arg_4,ext_arg_5,ext_arg_6,ext_arg_7;
    case (BackendDAE.DAE(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs),func,inTypeA)
      equation
        ext_arg_1 = traverseBackendDAEExpsVars(vars1,func,inTypeA);
        ext_arg_2 = traverseBackendDAEExpsVars(vars2,func,ext_arg_1);
        ext_arg_3 = traverseBackendDAEExpsEqns(eqns,func,ext_arg_2);
        ext_arg_4 = traverseBackendDAEExpsEqns(reqns,func,ext_arg_3);
        ext_arg_5 = traverseBackendDAEExpsEqns(ieqns,func,ext_arg_4);
        ext_arg_6 = traverseBackendDAEArrayNoCopy(ae,func,traverseBackendDAEExpsArrayEqn,1,arrayLength(ae),ext_arg_5);
        ext_arg_7 = traverseBackendDAEArrayNoCopy(algs,func,traverseAlgorithmExps,1,arrayLength(algs),ext_arg_6);
      then
        ext_arg_7;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.traverseBackendDAEExps failed");
      then
        fail();         
  end matchcontinue;
end traverseBackendDAEExps;

protected function traverseBackendDAEExpsVars "function: traverseBackendDAEExpsVars
  author: Frenkel TUD

  Helper for traverseBackendDAEExps
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVariables,func,inTypeA)
    local
      array<Option<BackendDAE.Var>> varOptArr;
      Type_a ext_arg_1;
    case (BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr)),func,inTypeA)
      equation
        ext_arg_1 = traverseBackendDAEArrayNoCopy(varOptArr,func,traverseBackendDAEExpsVar,1,arrayLength(varOptArr),inTypeA);
      then
        ext_arg_1;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.traverseBackendDAEExpsVars failed");
      then
        fail();        
  end matchcontinue;
end traverseBackendDAEExpsVars;

public function traverseBackendDAEArrayNoCopy "
 help function to traverseBackendDAEExps
 author: Frenkel TUD"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input array<Type_a> array;
  input FuncExpType func;
  input FuncArrayType arrayfunc;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncExpType
    input tuple<Type_c, Type_b> inTpl;
    output tuple<Type_c, Type_b> outTpl;
  end FuncExpType;
  partial function FuncArrayType
    input Type_a inTypeA;
    input FuncExpType func;
    input Type_b inTypeB;
    output Type_b outTypeB;
    partial function FuncExpType
     input tuple<Type_c, Type_b> inTpl;
     output tuple<Type_c, Type_b> outTpl;
    end FuncExpType;
  end FuncArrayType;    
algorithm
  outTypeB := matchcontinue(array,func,arrayfunc,pos,len,inTypeB)
    local 
      Type_b ext_arg_1,ext_arg_2;
    case(_,_,_,pos,len,inTypeB) equation 
      true = pos > len;
    then inTypeB;
    
    case(array,func,arrayfunc,pos,len,inTypeB) equation
      ext_arg_1 = arrayfunc(array[pos],func,inTypeB);
      ext_arg_2 = traverseBackendDAEArrayNoCopy(array,func,arrayfunc,pos+1,len,ext_arg_1);
    then ext_arg_2;
  end matchcontinue;
end traverseBackendDAEArrayNoCopy;

public function traverseBackendDAEArrayNoCopyWithStop "
 help function to traverseBackendDAEArrayNoCopyWithStop
 author: Frenkel TUD
  same like traverseBackendDAEArrayNoCopy but with a additional
  parameter to stop the traveral."
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input array<Type_a> array;
  input FuncExpTypeWithStop func;
  input FuncArrayTypeWithStop arrayfunc;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncExpTypeWithStop
    input tuple<Type_c, Type_b> inTpl;
    output tuple<Type_c, Boolean, Type_b> outTpl;
  end FuncExpTypeWithStop;
  partial function FuncArrayTypeWithStop
    input Type_a inTypeA;
    input FuncExpTypeWithStop func;
    input Type_b inTypeB;
    output Boolean outBoolean;
    output Type_b outTypeB;
    partial function FuncExpTypeWithStop
     input tuple<Type_c, Type_b> inTpl;
      output tuple<Type_c, Boolean, Type_b> outTpl;
    end FuncExpTypeWithStop;
  end FuncArrayTypeWithStop;    
algorithm
  outTypeB := matchcontinue(array,func,arrayfunc,pos,len,inTypeB)
    local 
      Type_b ext_arg_1,ext_arg_2;
    case(_,_,_,pos,len,inTypeB) equation 
      true = pos > len;
    then inTypeB;
    
    case(array,func,arrayfunc,pos,len,inTypeB) equation
      (true,ext_arg_1) = arrayfunc(array[pos],func,inTypeB);
      ext_arg_2 = traverseBackendDAEArrayNoCopyWithStop(array,func,arrayfunc,pos+1,len,ext_arg_1);
    then ext_arg_2;
    case(array,func,arrayfunc,pos,len,inTypeB) equation
      (false,ext_arg_1) = arrayfunc(array[pos],func,inTypeB);
    then ext_arg_1;
  end matchcontinue;
end traverseBackendDAEArrayNoCopyWithStop;

public function traverseBackendDAEArrayNoCopyWithUpdate "
 help function to traverseBackendDAEExps
 author: Frenkel TUD"
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  input array<Type_a> inArray;
  input FuncExpType func;
  input FuncArrayTypeWithUpdate arrayfunc;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_b inTypeB;
  output array<Type_a> outArray;
  output Type_b outTypeB;
  partial function FuncExpType
    input tuple<Type_c, Type_b> inTpl;
    output tuple<Type_c, Type_b> outTpl;
  end FuncExpType;
  partial function FuncArrayTypeWithUpdate
    input Type_a inTypeA;
    input FuncExpType func;
    input Type_b inTypeB;
    output Type_a outTypeA;
    output Type_b outTypeB;
    partial function FuncExpTypeWithUpdate
     input tuple<Type_c, Type_b> inTpl;
     output tuple<Type_c, Type_b> outTpl;
    end FuncExpTypeWithUpdate;
  end FuncArrayTypeWithUpdate;    
algorithm
  (outArray,outTypeB) := matchcontinue(inArray,func,arrayfunc,pos,len,inTypeB)
    local 
      array<Type_a> array;
      Type_a new_a;
      Type_b ext_arg_1,ext_arg_2;
    case(array,_,_,pos,len,inTypeB) equation 
      true = pos > len;
    then (array,inTypeB);
    
    case(array,func,arrayfunc,pos,len,inTypeB) equation
      (new_a,ext_arg_1) = arrayfunc(array[pos],func,inTypeB);
      array = arrayUpdate(array,pos,new_a);
      (array,ext_arg_2) = traverseBackendDAEArrayNoCopyWithUpdate(array,func,arrayfunc,pos+1,len,ext_arg_1);
    then (array,ext_arg_2);
  end matchcontinue;
end traverseBackendDAEArrayNoCopyWithUpdate;

protected function traverseBackendDAEExpsVar "function: traverseBackendDAEExpsVar
  author: Frenkel TUD
  Helper traverseBackendDAEExpsVar. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  replaceable type Type_a subtypeof Any;  
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVar,func,inTypeA)
    local
      DAE.Exp e1, expCref;
      DAE.ComponentRef cref;
      list<DAE.Subscript> instdims;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    
    case (NONE(),func,inTypeA) then inTypeA;
    
    case (SOME(BackendDAE.VAR(varName = cref,
             bindExp = SOME(e1),
             arryDim = instdims
             )),func,inTypeA)
      equation
        ((_,ext_arg_1)) = func((e1,inTypeA));
        ext_arg_2 = Util.listFold1(instdims,traverseBackendDAEExpsSubscript,func,ext_arg_1);
        expCref = Expression.crefExp(cref);
        ((_,ext_arg_3)) = func((expCref,ext_arg_2));
      then
        ext_arg_3;
    
    case (SOME(BackendDAE.VAR(varName = cref,
             bindExp = NONE(),
             arryDim = instdims
             )),func,inTypeA)
      equation
        ext_arg_2 = Util.listFold1(instdims,traverseBackendDAEExpsSubscript,func,inTypeA);
        expCref = Expression.crefExp(cref);
        ((_,ext_arg_3)) = func((expCref,ext_arg_2));
      then
        ext_arg_3;        
    
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.traverseBackendDAEExpsVar failed");
      then
        fail();          
  end matchcontinue;
end traverseBackendDAEExpsVar;

protected function traverseBackendDAEExpsSubscript "function: traverseBackendDAEExpsSubscript
  author: Frenkel TUD
  helper for traverseBackendDAEExpsSubscript"
  replaceable type Type_a subtypeof Any;  
  input DAE.Subscript inSubscript;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=
  match (inSubscript,func,inTypeA)
    local
      DAE.Exp e;
      Type_a ext_arg_1;     
    case (DAE.WHOLEDIM(),_,inTypeA) then inTypeA;
    case (DAE.SLICE(exp = e),func,inTypeA)
      equation
        ((_,ext_arg_1)) = func((e,inTypeA));  
      then ext_arg_1;
    case (DAE.INDEX(exp = e),func,inTypeA)
      equation
        ((_,ext_arg_1)) = func((e,inTypeA));  
      then ext_arg_1;
  end match;
end traverseBackendDAEExpsSubscript;

public function traverseBackendDAEExpsEqns "function: traverseBackendDAEExpsEqns
  author: Frenkel TUD

  Helper for traverseBackendDAEExpsEqns
"
  replaceable type Type_a subtypeof Any;  
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      array<Option<BackendDAE.Equation>> equOptArr;
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),func,inTypeA)
      then traverseBackendDAEArrayNoCopy(equOptArr,func,traverseBackendDAEExpsOptEqn,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- BackendDAE.traverseBackendDAEExpsEqns failed");
      then
        fail();          
  end matchcontinue;
end traverseBackendDAEExpsEqns;

protected function traverseBackendDAEExpsOptEqn "function: traverseBackendDAEExpsOptEqn
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqn."
  replaceable type Type_a subtypeof Any;  
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:= match (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn;
     Type_a ext_arg_1;
    case (NONE(),func,inTypeA) then inTypeA;
    case (SOME(eqn),func,inTypeA)
      equation
        (_,ext_arg_1) = BackendEquation.traverseBackendDAEExpsEqn(eqn,func,inTypeA);
      then
        ext_arg_1;
  end match;
end traverseBackendDAEExpsOptEqn;

protected function traverseBackendDAEExpsArrayEqn "function: traverseBackendDAEExpsArrayEqn
  author: Frenkel TUD

  Helper function to traverseBackendDAEExpsEqn
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input FuncExpType func;  
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType; 
algorithm
  outTypeA:=
  match (inMultiDimEquation,func,inTypeA)
    local 
      DAE.Exp e1,e2;
      Type_a ext_arg_1,ext_arg_2;
    case (BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2),func,inTypeA)
      equation
        ((_,ext_arg_1)) = func((e1,inTypeA)); 
        ((_,ext_arg_2)) = func((e2,ext_arg_1)); 
      then
        ext_arg_2;
  end match;
end traverseBackendDAEExpsArrayEqn;

public function traverseAlgorithmExps "function: traverseAlgorithmExps

  This function goes through the Algorithm structure and finds all the
  expressions and performs the function on them
"
  replaceable type Type_a subtypeof Any;  
  input DAE.Algorithm inAlgorithm;
  input FuncExpType func;
  input Type_a inTypeA; 
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;  
algorithm
  outTypeA := match (inAlgorithm,func,inTypeA)
    local
      list<DAE.Statement> stmts;
      Type_a ext_arg_1;
    case (DAE.ALGORITHM_STMTS(statementLst = stmts),func,inTypeA)
      equation
        (_,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
      then
        ext_arg_1;
  end match;
end traverseAlgorithmExps;

/*************************************************
 * Equation System Pipeline 
 ************************************************/

partial function preoptimiseDAEModule
"function preoptimiseDAEModule 
  This is the interface for pre optimisation modules."
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
end preoptimiseDAEModule;  

partial function pastoptimiseDAEModule
"function pastoptimiseDAEModule 
  This is the interface for past optimisation modules."
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrix inMT;
  input array<Integer> inAss1;  
  input array<Integer> inAss2;  
  input list<list<Integer>> inComps;  
  output BackendDAE.BackendDAE outDAE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<Integer> outAss1;  
  output array<Integer> outAss2;  
  output list<list<Integer>> outComps;  
  output Boolean outRunMatching;
end pastoptimiseDAEModule;

partial function daeHandlerFunc
"function daeHandlerFunc 
  This is the interface for the index reduction handler.
  Note: Not yet finished"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree outFunctionTree;
  output BackendDAE.BackendDAE outDAE;
end daeHandlerFunc; 

public function getSolvedSystem
" function: getSolvedSystem
  Run the equation system pipeline."
  input Env.Cache inCache;
  input Env.Env inEnv;   
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;
  input Option<list<String>> strPreOptModules;
  input daeHandlerFunc daeHandler;
  input Option<list<String>> strPastOptModules;
  output BackendDAE.BackendDAE outSODE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<Integer> outAss1;  
  output array<Integer> outAss2;  
  output list<list<Integer>> outComps;
  partial function preoptimiseDAEModule
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input Option<BackendDAE.IncidenceMatrix> inM;
    input Option<BackendDAE.IncidenceMatrix> inMT;
    output BackendDAE.BackendDAE outDAE;
    output Option<BackendDAE.IncidenceMatrix> outM;
    output Option<BackendDAE.IncidenceMatrix> outMT;
  end preoptimiseDAEModule;   
  partial function daeHandlerFunc
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    output BackendDAE.BackendDAE outDAE;
  end daeHandlerFunc;
  partial function pastoptimiseDAEModule
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps;  
    output Boolean outRunMatching;
  end pastoptimiseDAEModule;
protected
  BackendDAE.BackendDAE dae,optdae,sode,sode1,optsode,indexed_dlow;
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.IncidenceMatrix m,mT,m_1,mT_1;
  array<Integer> v1,v2,v1_1,v2_1;  
  list<list<Integer>> comps,comps_1;
  list<tuple<preoptimiseDAEModule,String>> preOptModules;
  list<tuple<pastoptimiseDAEModule,String>> pastOptModules;
algorithm
  
  preOptModules := getPreOptModules(strPreOptModules);
  pastOptModules := getPastOptModules(strPastOptModules);
  
  Debug.fcall("dumpdaelow", print, "dumpdaelow:\n");
  Debug.fcall("dumpdaelow", BackendDump.dump, inDAE);        
  // pre optimisation phase
  Debug.fcall("execstat",print, "*** BackendMain -> preoptimiseDAE at time: " +& realString(clock()) +& "\n" );
  (optdae,om,omT) := preoptimiseDAE(inDAE,functionTree,preOptModules,NONE(),NONE()); 

  // transformation phase (matching and sorting using a index reduction method
  Debug.fcall("execstat",print, "*** BackendMain -> transformDAE at time: " +& realString(clock()) +& "\n" );
  (sode,m,mT,v1,v2,comps) := transformDAE(optdae,functionTree,daeHandler,om,omT);
  Debug.fcall("bltdump", BackendDump.bltdump, (sode,m,mT,v1,v2,comps));

  // past optimisation phase
  Debug.fcall("execstat",print, "*** BackendMain -> pastoptimiseDAE at time: " +& realString(clock()) +& "\n" );
  (sode,outM,outMT,outAss1,outAss2,outComps) := pastoptimiseDAE(sode,functionTree,pastOptModules,m,mT,v1,v2,comps,daeHandler);
  
  sode1 := BackendDAECreate.findZeroCrossings(sode);
  Debug.fcall("execstat",print, "*** BackendMain -> translateDae: " +& realString(clock()) +& "\n" );
  indexed_dlow := translateDae(sode1,NONE());
  Debug.fcall("execstat",print, "*** BackendMain -> calculate Values: " +& realString(clock()) +& "\n" );
  outSODE := calculateValues(inCache, inEnv, indexed_dlow);
  Debug.fcall("dumpindxdae", print, "dumpindxdae:\n");
  Debug.fcall("dumpindxdae", BackendDump.dump, outSODE); 
end getSolvedSystem;

public function preOptimiseBackendDAE
"function preOptimiseBackendDAE 
  Run the optimisation modules"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;
  input Option<list<String>> strPreOptModules;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
protected
  list<tuple<preoptimiseDAEModule,String>> preOptModules;
algorithm
  preOptModules := getPreOptModules(strPreOptModules);
  (outDAE,outM,outMT) := preoptimiseDAE(inDAE,functionTree,preOptModules,inM,inMT); 
end preOptimiseBackendDAE; 

protected function preoptimiseDAE
"function preoptimiseDAE 
  Run the optimisation modules"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;
  input list<tuple<preoptimiseDAEModule,String>> optModules;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.IncidenceMatrix> outM;
  output Option<BackendDAE.IncidenceMatrix> outMT;
algorithm
  (outDAE,outM,outMT):=
  matchcontinue (inDAE,functionTree,optModules,inM,inMT)
    local 
      BackendDAE.BackendDAE dae,dae1,dae2;
      DAE.FunctionTree funcs;  
      preoptimiseDAEModule optModule;
      list<tuple<preoptimiseDAEModule,String>> rest;
      String str,moduleStr;
      Option<BackendDAE.IncidenceMatrix> m,mT,m1,mT1,m2,mT2;
    case (dae,funcs,{},m,mT) then (dae,m,mT);
    case (dae,funcs,(optModule,moduleStr)::rest,m,mT)
      equation
        (dae1,m1,mT1) = optModule(dae,funcs,m,mT);
        Debug.fcall("optdaedump", print, stringAppendList({"\nOptimisation Module ",moduleStr,":\n\n"}));
        Debug.fcall("optdaedump", BackendDump.dump, dae1);
        (dae2,m2,mT2) = preoptimiseDAE(dae1,funcs,rest,m1,mT1);
      then
        (dae2,m2,mT2);
    case (dae,funcs,(optModule,moduleStr)::rest,m,mT)
      equation
        str = stringAppendList({"Optimisation Module ",moduleStr," failed."});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        (dae1,m1,mT1) = preoptimiseDAE(dae,funcs,rest,m,mT); 
      then
        (dae1,m1,mT1);
  end matchcontinue;
end preoptimiseDAE; 

public function transformDAE
"function transformDAE 
  Run the matching Algorithm and the sorting algorithm.
  In case of an DAE an DAE-Handler is used to reduce
  the index of the dae."
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;
  input daeHandlerFunc daeHandler;
  input Option<BackendDAE.IncidenceMatrix> inM;
  input Option<BackendDAE.IncidenceMatrix> inMT;  
  output BackendDAE.BackendDAE outDAE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<Integer> outAss1;  
  output array<Integer> outAss2;  
  output list<list<Integer>> outComps;   
algorithm
  (outDAE,outM,outMT,outAss1,outAss2,outComps):=
  matchcontinue (inDAE,functionTree,daeHandler,inM,inMT)
    local 
      BackendDAE.BackendDAE dae,ode;
      DAE.FunctionTree funcs;  
      String str;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      BackendDAE.IncidenceMatrix m,mT,m1,mT1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<list<Integer>> comps,comps1;      
    case (dae,funcs,daeHandler,om,omT)
      equation
        (m,mT) = getIncidenceMatrixfromOption(dae,om,omT);
        // matching algorithm
        (v1,v2,ode,m1,mT1) = BackendDAETransform.matchingAlgorithm(dae, m, mT, (BackendDAE.INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.REMOVE_SIMPLE_EQN()),funcs);
        // sorting algorithm
        (comps) = BackendDAETransform.strongComponents(m1, mT1, v1, v2);
      then
        (ode,m1,mT1,v1,v2,comps);
    case (_,_,_,_,_)
      equation
//        str = "Transformation Module failed!";
//        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();        
  end matchcontinue;        
end transformDAE; 

protected function pastoptimiseDAE
"function optimiseDAE 
  Run the optimisation modules"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;  
  input list<tuple<pastoptimiseDAEModule,String>> optModules;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrix inMT;
  input array<Integer> inAss1;  
  input array<Integer> inAss2;  
  input list<list<Integer>> inComps;  
  input daeHandlerFunc daeHandler;
  output BackendDAE.BackendDAE outDAE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<Integer> outAss1;  
  output array<Integer> outAss2;  
  output list<list<Integer>> outComps; 
algorithm
  (outDAE,outM,outMT,outAss1,outAss2,outComps):=
  matchcontinue (inDAE,functionTree,optModules,inM,inMT,inAss1,inAss2,inComps,daeHandler)
    local 
      BackendDAE.BackendDAE dae,dae1,dae2; 
      DAE.FunctionTree funcs; 
      pastoptimiseDAEModule optModule;
      list<tuple<pastoptimiseDAEModule,String>> rest;
      String str,moduleStr;
      BackendDAE.IncidenceMatrix m,mT,m1,mT1,m2,mT2;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps1,comps2;
      Boolean runMatching;
    case (dae,funcs,{},m,mT,v1,v2,comps,_) then (dae,m,mT,v1,v2,comps);
    case (dae,funcs,(optModule,moduleStr)::rest,m,mT,v1,v2,comps,daeHandler)
      equation
        (dae1,m1,mT1,v1_1,v2_1,comps1,runMatching) = optModule(dae,funcs,m,mT,v1,v2,comps);
        (dae1,m1,mT1,v1_1,v2_1,comps1) = checktransformDAE(runMatching,dae1,funcs,m1,mT1,v1_1,v2_1,comps1,daeHandler);
        Debug.fcall("optdaedump", print, stringAppendList({"\nOptimisation Module ",moduleStr,":\n\n"}));
        Debug.fcall("optdaedump", BackendDump.dump, dae1);        
        (dae2,m2,mT2,v1_2,v2_2,comps2) = pastoptimiseDAE(dae1,funcs,rest,m1,mT1,v1_1,v2_1,comps1,daeHandler);
      then
        (dae2,m2,mT2,v1_2,v2_2,comps2);
    case (dae,funcs,(optModule,moduleStr)::rest,m,mT,v1,v2,comps,daeHandler)
      equation
        str = stringAppendList({"Optimisation Module ",moduleStr," failed."});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        (dae1,m1,mT1,v1_1,v2_1,comps1) = pastoptimiseDAE(dae,funcs,rest,m,mT,v1,v2,comps,daeHandler);
      then   
        (dae1,m1,mT1,v1_1,v2_1,comps1);
  end matchcontinue;             
end pastoptimiseDAE; 

protected function checktransformDAE
"function checktransformDAE 
  check if the matching and sorting algorithm should be performed"
  input Boolean inRunMatching;
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree functionTree;  
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrix inMT;
  input array<Integer> inAss1;  
  input array<Integer> inAss2;  
  input list<list<Integer>> inComps;  
  input daeHandlerFunc daeHandler;
  output BackendDAE.BackendDAE outDAE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<Integer> outAss1;  
  output array<Integer> outAss2;  
  output list<list<Integer>> outComps; 
algorithm
  (outDAE,outM,outMT,outAss1,outAss2,outComps):=
  match (inRunMatching,inDAE,functionTree,inM,inMT,inAss1,inAss2,inComps,daeHandler)
    local 
      BackendDAE.BackendDAE dae,sode; 
      DAE.FunctionTree funcs; 
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> v1,v2;
      list<list<Integer>> comps;
      Boolean runMatching;
    case (true,dae,funcs,m,mT,_,_,_,daeHandler)
      equation
        (sode,m,mT,v1,v2,comps) = transformDAE(dae,funcs,daeHandler,SOME(m),SOME(mT));
        Debug.fcall("bltdump", BackendDump.bltdump, (sode,m,mT,v1,v2,comps));
      then
        (sode,m,mT,v1,v2,comps);
    case (false,dae,funcs,m,mT,v1,v2,comps,_)
      then   
        (dae,m,mT,v1,v2,comps);
  end match;             
end checktransformDAE; 

/*************************************************
 * Optimisation Selection 
 ************************************************/

public function getPreOptModulesString
" function: getPreOptModulesString"
  output list<String> strPreOptModules;
algorithm
 strPreOptModules := RTOpts.getPreOptModules({"removeSimpleEquations","removeParameterEqns","expandDerOperator"});        
end getPreOptModulesString;

protected function getPreOptModules
" function: getPreOptModules"
  input Option<list<String>> ostrPreOptModules;
  output list<tuple<preoptimiseDAEModule,String>> preOptModules;
  partial function preoptimiseDAEModule
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input Option<BackendDAE.IncidenceMatrix> inM;
    input Option<BackendDAE.IncidenceMatrix> inMT;
    output BackendDAE.BackendDAE outDAE;
    output Option<BackendDAE.IncidenceMatrix> outM;
    output Option<BackendDAE.IncidenceMatrix> outMT;
  end preoptimiseDAEModule;   
protected 
  list<tuple<preoptimiseDAEModule,String>> allPreOptModules; 
  list<String> strPreOptModules;
algorithm
  allPreOptModules := {(BackendDAEOptimize.removeSimpleEquations,"removeSimpleEquations"),
          (BackendDAEOptimize.removeParameterEqns,"removeParameterEqns"),
          (BackendDAEOptimize.removeAliasEquations,"removeAliasEquations"),
          (BackendDAEOptimize.inlineArrayEqn,"inlineArrayEqn"),
          (BackendDAEOptimize.removeProtectedParameters,"removeProtectedParameters"),
          (BackendDAECreate.expandDerOperator,"expandDerOperator")};
 strPreOptModules := getPreOptModulesString();        
 strPreOptModules := Util.getOptionOrDefault(ostrPreOptModules,strPreOptModules);
 preOptModules := selectOptModules(strPreOptModules,allPreOptModules,{});  
 preOptModules := listReverse(preOptModules);     
end getPreOptModules;

public function getPastOptModulesString
" function: getPreOptModulesString"
  output list<String> strPastOptModules;
algorithm
 strPastOptModules := RTOpts.getPastOptModules({"lateInline","removeSimpleEquations"});           
end getPastOptModulesString;

protected function getPastOptModules
" function: getPastOptModules"
  input Option<list<String>> ostrPastOptModules;
  output list<tuple<pastoptimiseDAEModule,String>> pastOptModules;
  partial function pastoptimiseDAEModule
    input BackendDAE.BackendDAE inDAE;
    input DAE.FunctionTree inFunctionTree;
    input BackendDAE.IncidenceMatrix inM;
    input BackendDAE.IncidenceMatrix inMT;
    input array<Integer> inAss1;  
    input array<Integer> inAss2;  
    input list<list<Integer>> inComps;  
    output BackendDAE.BackendDAE outDAE;
    output BackendDAE.IncidenceMatrix outM;
    output BackendDAE.IncidenceMatrix outMT;
    output array<Integer> outAss1;  
    output array<Integer> outAss2;  
    output list<list<Integer>> outComps;  
    output Boolean outRunMatching;
  end pastoptimiseDAEModule;  
protected 
  list<tuple<pastoptimiseDAEModule,String>> allPastOptModules; 
  list<String> strPastOptModules;
algorithm
  allPastOptModules := {(BackendDAEOptimize.lateInline,"lateInline"),
  (BackendDAEOptimize.removeSimpleEquationsPast,"removeSimpleEquations"),
  (BackendDAEOptimize.removeAliasEquationsPast,"removeAliasEquations"),
  (BackendDAEOptimize.inlineArrayEqnPast,"inlineArrayEqn"),
  (BackendDump.dumpComponentsGraphStr,"dumpComponentsGraphStr")};
  strPastOptModules := getPastOptModulesString();        
  strPastOptModules := Util.getOptionOrDefault(ostrPastOptModules,strPastOptModules);
  pastOptModules := selectOptModules(strPastOptModules,allPastOptModules,{}); 
  pastOptModules := listReverse(pastOptModules);     
end getPastOptModules;

protected function selectOptModules
" function: selectPreOptModules"
  input list<String> strOptModules;
  input list<tuple<Type_a,String>> inOptModules;
  input list<tuple<Type_a,String>> accumulator;
  output list<tuple<Type_a,String>> outOptModules;
  replaceable type Type_a subtypeof Any;  
algorithm
  outOptModules:=
  matchcontinue (strOptModules,inOptModules,accumulator)
    local 
      list<String> restStr;
      String strOptModul,optModulName,str;
      tuple<Type_a,String> optModule;
      list<tuple<Type_a,String>> optModules,optModules1; 
    case ({},_,_) then {};
    case (_,{},_) then {};
    case (strOptModul::{},optModules,accumulator)
      equation
        optModule = selectOptModules1(strOptModul,optModules);
      then   
        (optModule::accumulator);
    case (strOptModul::{},optModules,accumulator)
      then   
        accumulator;
    case (strOptModul::restStr,optModules,accumulator)
      equation
        optModule = selectOptModules1(strOptModul,optModules);
      then   
        selectOptModules(restStr,optModules,optModule::accumulator);
    case (strOptModul::restStr,optModules,accumulator)
      equation
        str = stringAppendList({"Selection of Optimisation Module ",strOptModul," failed."});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then   
        selectOptModules(restStr,optModules,accumulator);
  end matchcontinue; 
end selectOptModules;

public function selectOptModules1 "
Author Frenkel TUD 2011-02"
  input String strOptModule;
  input list<tuple<Type_a,String>> inOptModules;
  output tuple<Type_a,String> outOptModule;
  replaceable type Type_a subtypeof Any;
algorithm
  outOptModule := matchcontinue(strOptModule,inOptModules)
    local
      Type_a a;
      String name;
      tuple<Type_a,String> module;
      list<tuple<Type_a,String>> rest;
    case(strOptModule,(module as (a,name))::rest)
      equation
        true = stringEqual(name,strOptModule);
      then
        module;
    case(strOptModule,(module as (a,name))::rest)
      equation
        false = stringEqual(name,strOptModule);
      then
        selectOptModules1(strOptModule,rest);
    case(_,{})
      then fail();
  end matchcontinue;
end selectOptModules1;

public function daeEqns
  input BackendDAE.BackendDAE inDAELow;
  output BackendDAE.EquationArray inEquationArray;
algorithm
  inEquationArray := matchcontinue (inDAELow)
    local BackendDAE.EquationArray eq;
    case (BackendDAE.DAE(orderedEqs=eq))
      then eq;
  end matchcontinue;
end daeEqns;

end BackendDAEUtil;
