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

encapsulated package TaskGraph
" file:  TaskGraph.mo
  package:     TaskGraph
  description: Building of task graphs from expressions, and equation systems.

  RCS: $Id$

  This module is used in the modpar part of OpenModelica for bulding task graphs
  from the BLT decomposition for automatic parallelization.
  The exported function buildTaskgraph takes the lowered form of the DAE defined in
  BackendDAE and two assignments vectors (which variable is solved in which equation) and
  the list of blocks given by the BLT decomposition.

  The package uses TaskGraphExt for the task graph datastructure itself, which
  is implemented using Boost Graph Library in C++"

public import BackendDAE;
public import SCode;

protected import Absyn;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendDAETransform;
protected import ComponentReference;
protected import DAE;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import List;
protected import TaskGraphExt;
protected import Values;
protected import ValuesUtil;
protected import VarTransform;

public function buildTaskgraph ""
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StrongComponents inComps;
algorithm
  _ := matchcontinue (inBackendDAE,inComps)
    local
      Integer starttask,endtask;
      list<BackendDAE.Var> vars,knvars;
      BackendDAE.Variables vararr,knvararr;
      BackendDAE.BackendDAE dae;
      BackendDAE.StrongComponents comps;
      DAE.ComponentRef cref_;

    case ((dae as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vararr)::{},shared=BackendDAE.SHARED(knownVars = knvararr))),comps)
      equation
  print("starting buildtaskgraph\n");
  starttask = TaskGraphExt.newTask("start");
  endtask = TaskGraphExt.newTask("end");
  TaskGraphExt.setExecCost(starttask, 1.0);
  TaskGraphExt.setExecCost(starttask, 1.0);
  TaskGraphExt.registerStartStop(starttask, endtask);
  vars = BackendVariable.varList(vararr);
  knvars = BackendVariable.varList(knvararr);
  List.map1_0(vars,addVariable, starttask);
  List.map1_0(knvars,addVariable, starttask);
  cref_ = ComponentReference.makeCrefIdent("sim_time",DAE.T_REAL_DEFAULT,{});
  addVariables({BackendDAE.VAR(cref_,BackendDAE.VARIABLE(),
                DAE.INPUT(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),
                NONE(),DAE.NON_CONNECTOR())}, starttask);
  buildBlocks(dae, comps);
  print("done building taskgraph, about to build inits.\n");
  buildInits(dae);
  print("leaving TaskGraph.buildTaskgraph\n");
      then
  ();

    case (_,_)
      equation
  print("-TaskGraph.buildTaskgraph failed\n");
      then
  fail();
  end matchcontinue;
end buildTaskgraph;

protected function buildInits "function: buildInits
  This function traverses the DAE and calls external functions to build
  the initialization values for the DAE
  This is implemented in C++ as a set of vectors"
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _ := match (inBackendDAE)
    local
      list<BackendDAE.Var> vars,kvars;
      BackendDAE.Variables vararr,kvararr;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vararr)::{},shared=BackendDAE.SHARED(knownVars = kvararr)))
      equation
  vars = BackendVariable.varList(vararr);
  kvars = BackendVariable.varList(kvararr);
  buildInits2(vars,1);
  buildInits2(kvars,1);
      then
  ();
  end match;
end buildInits;

protected function buildInits2
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input Integer index;
algorithm
  _ := matchcontinue (inBackendDAEVarLst,index)
    local
      String v,origname_str;
      DAE.ComponentRef origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<BackendDAE.Var> rest;
      DAE.Exp e;
      Values.Value value;
    case ({},_) then ();
    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  e = DAEUtil.getStartAttr(dae_var_attr);
  v = ExpressionDump.printExpStr(e);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(index=_),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  e = DAEUtil.getStartAttr(dae_var_attr);
  v = ExpressionDump.printExpStr(e);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitState(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(index=_),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitState(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  e = DAEUtil.getStartAttr(dae_var_attr);
  v = ExpressionDump.printExpStr(e);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  e = DAEUtil.getStartAttr(dae_var_attr);
  v = ExpressionDump.printExpStr(e);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitVar(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.PARAM(),bindValue = SOME(value),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  v = ValuesUtil.valString(value);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitParam(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.PARAM(),bindValue = NONE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitParam(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.CONST(),bindValue = SOME(value),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  v = ValuesUtil.valString(value);
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitParam(index, v, origname_str);
  buildInits2(rest,index+1);
      then
  ();
    case ((BackendDAE.VAR(varKind = BackendDAE.CONST(),bindValue = NONE(),varName = origname,values = dae_var_attr,comment = comment) :: rest),_)
      equation
  origname_str = ComponentReference.printComponentRefStr(origname);
  TaskGraphExt.addInitParam(index, "0.0", origname_str);
  buildInits2(rest,index+1);
      then
  ();
  end matchcontinue;
end buildInits2;

protected function addVariables
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input Integer inInteger;
algorithm
  _:=
  match (inBackendDAEVarLst,inInteger)
    local
      Integer start;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ({},start) then ();
    case ((v :: vs),start)
      equation
  addVariable(v, start);
  addVariables(vs, start);
      then
  ();
  end match;
end addVariables;

protected function buildBlocks
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StrongComponents inComps;
algorithm
  _:=
  matchcontinue (inBackendDAE,inComps)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp;
    case (_,{}) then ();
    case (dae,(comp as BackendDAE.SINGLEEQUATION(eqn=_))::comps)
      equation
  buildEquation(dae, comp) "for single equations" ;
  buildBlocks(dae, comps);
      then
  ();
    case (dae,comp::comps)
      equation
  buildSystem(dae, comp) "For system of equations" ;
  buildBlocks(dae, comps);
      then
  ();
    case (_,_)
      equation
  print("-build_blocks failed\n");
      then
  fail();
  end matchcontinue;
end buildBlocks;

protected function buildEquation "Build task graph for a single equation."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StrongComponent inComp;
algorithm
  _:=
  matchcontinue (inBackendDAE,inComp)
    local
      Integer e_1,v_1,e;
      DAE.Exp e1,e2,varexp,expr;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      String origname_str;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{}),BackendDAE.SINGLEEQUATION(eqn=e,var=v_1))
      equation
  e_1 = e - 1 "Solving for non-states" ;
  BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns, e_1);
  (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(vars,v_1);
  varexp = Expression.crefExp(cr);
  varexp = Debug.bcallret1(BackendVariable.isStateVar(v), Expression.expDer, varexp, varexp);
  (expr,{}) = ExpressionSolve.solve(e1, e2, varexp);
  cr = Debug.bcallret1(BackendVariable.isStateVar(v), ComponentReference.crefPrefixDer, cr, cr);
  origname_str = ComponentReference.printComponentRefStr(cr);
  buildAssignment(cr, expr, origname_str) "  Expression.print_exp_str e1 => e1s &
  Expression.print_exp_str e2 => e2s &
  print \"Equation \" & print e1s & print \" = \" & print e2s &
  print \" solved for \" & Expression.print_exp_str varexp => s &
  print s & print \" giving \" &
  Expression.print_exp_str expr => s2 & print s2 & print \"\\n\" &" ;
      then
  ();
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{}),BackendDAE.SINGLEEQUATION(eqn=e,var=v_1)) /* rule  intSub(e,1) => e\' &
  BackendDAE.equation_nth(eqns,e\') => BackendDAE.EQUATION(e1,e2,_) &
  vector_nth(ass2,e\') => v & ( v==variable no solved in this equation ))
  intSub(v,1) => v\' &
  BackendDAE.vararray_nth(vararr,v\') => BackendDAE.VAR(cr,_,_,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flow) &
  let varexp = Expression.crefExp(cr) &
  not ExpressionSolve.solve(e1,e2,varexp) => _ &
  print \"nonlinear equation not implemented yet\\n\"
  --------------------------------
  build_equation(BackendDAE.DAE(BackendDAE.VARIABLES(_,_,vararr,_,_),_,eqns,_,_,_,_,_),ass1,ass2,e) => fail
 */
      equation
  e_1 = e - 1 "Solving nonlinear" ;
  BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns, e_1);
  (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(vars,v_1);
  varexp = Expression.crefExp(cr);
  varexp = Debug.bcallret1(BackendVariable.isStateVar(v), Expression.expDer, varexp, varexp);
  failure((_,_) = ExpressionSolve.solve(e1, e2, varexp)) "print \"Solving nonlinear \\n\" &";
  buildNonlinearEquations({varexp}, {DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2)});
      then
  ();
    case (_,_)
      equation
  print("-TaskGraph.buildEquation failed\n");
      then
  fail();
  end matchcontinue;
end buildEquation;

protected function buildNonlinearEquations "function: buildNonlinearEquations
  builds task graph for solving non-linear equations
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
algorithm
  _:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      Integer size,tid;
      String size_str,taskname;
      list<String> varnames;
      list<DAE.Exp> vars,residuals;
    case (vars,residuals) /* variables residuals */
      equation
  size = listLength(vars);
  size_str = intString(size);
  taskname = buildResidualCode(vars, residuals);
  tid = TaskGraphExt.newTask(taskname);
  TaskGraphExt.setTaskType(tid, 3);
  buildNonlinearEquations2(tid, vars, residuals) "See TaskType in TaskGraph.hpp" ;
  varnames = List.map(vars, ExpressionDump.printExpStr);
  storeMultipleResults(varnames, tid);
      then
  ();
    case (vars,residuals)
      equation
  print("build_nonlinear_equatins failed\n");
      then
  fail();
  end matchcontinue;
end buildNonlinearEquations;

protected function buildResidualCode "function: buildResidualCode
  This function takes a list of expressions and builds code for
  calculating the residuals as a string. Used for e.g. solving non-linear equations.
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      VarTransform.VariableReplacements repl;
      String res;
      list<DAE.Exp> vars,es;
    case (vars,es) /* vars residuals */
      equation
  repl = makeResidualReplacements(vars);
  res = buildResidualCode2(es, 0, repl);
      then
  res;
    case (_,_)
      equation
  print("build_residual_code failed\n");
      then
  fail();
  end matchcontinue;
end buildResidualCode;

protected function makeResidualReplacements "function: makeResidualReplacements
  This function makes replacement rules for variables occuring in a
  nonlinear equation system. They should be replaced by x{index}, i.e.
  an unique index in the x vector.
"
  input list<DAE.Exp> expl;
  output VarTransform.VariableReplacements repl_1;
protected
  VarTransform.VariableReplacements repl;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, expl, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<DAE.Exp> inExpExpLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  match (inVariableReplacements,inExpExpLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      String pstr,str;
      Integer pos_1,pos;
      DAE.ComponentRef cr,cref_;
      list<DAE.Exp> es;
    case (repl,{},_) then repl;
    case (repl,(DAE.CREF(componentRef = cr) :: es),pos)
      equation
  pstr = intString(pos);
  str = stringAppendList({"xloc[",pstr,"]"});
  cref_ = ComponentReference.makeCrefIdent(str,DAE.T_REAL_DEFAULT,{});
  repl_1 = VarTransform.addReplacement(repl, cr, Expression.crefExp(cref_));
  pos_1 = pos + 1;
  repl_2 = makeResidualReplacements2(repl_1, es, pos_1);
      then
  repl_2;
  end match;
end makeResidualReplacements2;

protected function buildResidualCode2
  input list<DAE.Exp> inExpExpLst;
  input Integer inInteger;
  input VarTransform.VariableReplacements inVariableReplacements;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst,inInteger,inVariableReplacements)
    local
      DAE.Exp e_1,e;
      String s1,s2,pstr,res;
      Integer pos_1,pos;
      list<DAE.Exp> es;
      VarTransform.VariableReplacements repl;
    case ({},_,_) then "";
    case ((e :: es),pos,repl)
      equation
  (e_1,_) = VarTransform.replaceExp(e, repl,NONE());
  //s1 = SimCodegen.printExpCppStr(e_1);
  s1 = "NOT WORKING";
  pos_1 = pos + 1;
  s2 = buildResidualCode2(es, pos_1, repl);
  pstr = intString(pos);
  res = stringAppendList({"res[",pstr,"]=",s1,";\n",s2});
      then
  res;
    case (_,_,_)
      equation
  print("build_residual_code2 failed\n");
      then
  fail();
  end matchcontinue;
end buildResidualCode2;

protected function storeMultipleResults "function storeMultipleResults
  When a task calculates several values, this function is used.
  It collects the names of the values into one string, separated by semicolons
  and uses that as the resultstring.
"
  input list<String> inStringLst;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inStringLst,inInteger)
    local
      String result_str;
      list<String> varnames;
      Integer tid;
    case (varnames,tid) /* var names task id */
      equation
  result_str = stringDelimitList(varnames, ";");
  TaskGraphExt.storeResult(result_str, tid, true, result_str);
      then
  ();
    case (_,_)
      equation
  print("store_multiple_results failed\n");
      then
  fail();
  end matchcontinue;
end storeMultipleResults;

protected function buildNonlinearEquations2
  input Integer inInteger1;
  input list<DAE.Exp> inExpExpLst2;
  input list<DAE.Exp> inExpExpLst3;
algorithm
  _:=
  matchcontinue (inInteger1,inExpExpLst2,inExpExpLst3)
    local
      Integer tid;
      list<DAE.ComponentRef> vars1,vars2,vars1_1,varslst;
      list<list<DAE.ComponentRef>> vars_1;
      DAE.Exp res,e;
      list<DAE.Exp> residuals,vars;
      String es;
    case (tid,_,{}) then ();  /* task id vars residuals */
    case (tid,vars,(res :: residuals))
      equation
  vars1 = Expression.extractCrefsFromExp(res) "Collect all variables and construct
   a string for the residual, that can be directly used in codegen." ;
  vars_1 = List.map(vars, Expression.extractCrefsFromExp);
  vars2 = List.flatten(vars_1);
  vars1_1 = List.unionOnTrue(vars1, vars2, ComponentReference.crefEqual) "No duplicate elements" ;
  varslst = List.setDifferenceOnTrue(vars1_1, vars2, ComponentReference.crefEqual);
  addEdgesFromVars(varslst, tid, 0);
      then
  ();
    case (_,_,(e :: _))
      equation
  print("build_nonlinear_equations2 failed\n");
  es = ExpressionDump.printExpStr(e);
  print("first residual :");
  print(es);
  print("\n");
      then
  fail();
  end matchcontinue;
end buildNonlinearEquations2;

protected function addEdgesFromVars "function: addEdgesFromVars
  Adds an edge between the tasks where the variables are defined and the tasks
  given as second argument.
"
  input list<DAE.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
algorithm
  _:=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      String v_str;
      Integer predt,prio_1,tid,prio;
      DAE.ComponentRef v;
      list<DAE.ComponentRef> vs;
    case ({},_,_) then ();  /* task priority */
    case ((v :: vs),tid,prio)
      equation
  v_str = ComponentReference.crefStr(v);
  predt = TaskGraphExt.getTask(v_str);
  TaskGraphExt.addEdge(predt, tid, v_str, prio);
  prio_1 = prio + 1;
  addEdgesFromVars(vs, tid, prio_1);
      then
  ();
    case ((v :: vs),_,_)
      equation
  v_str = ComponentReference.crefStr(v);
  failure(_ = TaskGraphExt.getTask(v_str));
  print("task ");
  print(v_str);
  print(" not found\n");
      then
  fail();
    case (_,_,_)
      equation
  print("add_edges_from_vars failed\n");
      then
  fail();
  end matchcontinue;
end addEdgesFromVars;

protected function buildSystem "Build task graph for a system of equations"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StrongComponent inComp;
algorithm
  _:=
  match (inBackendDAE,inComp)
    local
      Integer tid;
      list<String> predtasks;
      list<Integer> predtaskids;
      BackendDAE.BackendDAE dae;
      BackendDAE.StrongComponent comp;
      list<Integer> eqns,vars;
    case (dae,comp)
      equation
  print("build system\n");
  tid = TaskGraphExt.newTask("equation system");
  (eqns,vars) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
  predtasks = buildSystem2(dae, eqns, vars, tid);
  predtaskids = List.map(predtasks, TaskGraphExt.getTask);
  addPredecessors(tid, predtaskids, predtasks, 0);
      then
  ();
    else
      equation
  print("build_system failed\n");
      then
  fail();
  end match;
end buildSystem;

protected function buildSystem2
  input BackendDAE.BackendDAE inBackendDAE;
  input list<Integer> inEqns;
  input list<Integer> inVars;
  input Integer inInteger5;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inBackendDAE,inEqns,inVars,inInteger5)
    local
      BackendDAE.BackendDAE dae;
      Integer tid,e_1,e,v_1;
      DAE.Exp e1,e2;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> cr1,cr2,crs,crs_1;
      list<String> crs_2,crs2,res;
      String crstr,origname_str;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<Integer> reste,restv;
    case (dae,{},{},tid) then {};
    case ((dae as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{})),(e :: reste),(v_1 :: restv),tid)
      equation
  e_1 = e - 1;
  BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns, e_1);
  (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(vars,v_1);
  cr1 = Expression.extractCrefsFromExp(e1);
  cr2 = Expression.extractCrefsFromExp(e2);
  crs = listAppend(cr1, cr2);
  crs_1 = List.deleteMember(crs, cr);
  crs_2 = List.map(crs_1, ComponentReference.crefStr);
  crstr = ComponentReference.crefStr(cr);
  origname_str = ComponentReference.printComponentRefStr(cr);
  TaskGraphExt.storeResult(crstr, tid, true, origname_str);
  crs2 = buildSystem2(dae, reste, restv, tid);
  res = List.union(crs_2, crs2);
      then
  res;
    case (_,_,_,_)
      equation
  print("TaskGraph.buildSystem2 failed\n");
      then
  fail();
  end matchcontinue;
end buildSystem2;

protected function addVariable
  input BackendDAE.Var inVar;
  input Integer inInteger;
algorithm
  _:= match (inVar,inInteger)
    local
      String cfs,name_str;
      DAE.ComponentRef cf;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Integer start;
    case (BackendDAE.VAR(varName = cf,values = dae_var_attr,comment = comment),start)
      equation
  cfs = ComponentReference.crefStr(cf);
  name_str = ComponentReference.printComponentRefStr(cf) "print \"adding variable \" & print cfs & print \"\\n\" &" ;
  TaskGraphExt.storeResult(cfs, start, false, name_str);
      then
  ();
  end match;
end addVariable;

protected function buildAssignment
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input String inString;
algorithm
  _:=
  matchcontinue (inComponentRef,inExp,inString)
    local
      Integer task,tid;
      String str,cr2s,crs,origname;
      DAE.ComponentRef cr,cr2;
      DAE.Exp exp;
      DAE.Type tp;
    case (cr,(exp as DAE.CREF(componentRef = cr2,ty = tp)),origname) /* varname expression orig. name */
      equation
  (task,str) = buildExpression(exp) "special rule for equation a:=b" ;
  tid = TaskGraphExt.newTask("copy");
  cr2s = ComponentReference.crefStr(cr2);
  TaskGraphExt.addEdge(task, tid, cr2s, 0);
  crs = ComponentReference.crefStr(cr);
  TaskGraphExt.storeResult(crs, tid, true, origname);
  TaskGraphExt.setTaskType(tid, 6) "See TaskType in TaskGraph.hpp" ;
      then
  ();
    case (cr,exp,origname)
      equation
  (task,str) = buildExpression(exp);
  crs = ComponentReference.crefStr(cr);
  TaskGraphExt.storeResult(crs, task, true, origname);
      then
  ();
    case (cr,exp,origname)
      equation
  print("-TaskGraph.buildAssignment failed\n");
      then
  fail();
  end matchcontinue;
end buildAssignment;

protected function buildExpression
"function buildExpression
  Builds the task graph for the expression and returns
  the task no that calculates the result of the expr"
  input DAE.Exp inExp;
  output Integer outInteger;
  output String outString;
algorithm
  (outInteger,outString):=
  matchcontinue (inExp)
    local
      String is,rs,crs,s1,istr,ts,s2,ops,s3,funcstr,s,es;
      Integer tid,i,t1,ival,t,t2,t3,numargs;
      Real r,rval;
      DAE.ComponentRef cr;
      DAE.Exp e1,e2,e3,e;
      DAE.Operator op,relop;
      list<Integer> tasks;
      list<String> strs;
      Absyn.Path func;
      list<DAE.Exp> expl;
    case (DAE.ICONST(integer = i))
      equation
  is = intString(i);
  tid = TaskGraphExt.newTask(is) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
  (tid,"");

    case (DAE.RCONST(real = r))
      equation
  rs = realString(r);
  tid = TaskGraphExt.newTask(rs) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
  (tid,"");

    case (DAE.CREF(componentRef = cr))
      equation
  crs = ComponentReference.crefStr(cr) "for state variables and alg. variables" ;
  tid = TaskGraphExt.getTask(crs);
      then
  (tid,crs);

    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident = "time")))
      equation
  tid = TaskGraphExt.getTask("sim_time") "for state variables and alg. variables" ;
      then
  (tid,"sim_time");

    case (DAE.CREF(componentRef = cr))
      equation
  crs = ComponentReference.crefStr(cr) "for constants and parameters, no data to send from proc0" ;
  tid = TaskGraphExt.newTask(crs);
      then
  (tid,crs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.RCONST(real = rval)))
      equation
  (t1,s1) = buildExpression(e1) "special case for pow" ;
  ival = realInt(rval);
  istr = intString(ival);
  ts = stringAppendList({"pow(%s,",istr,")"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
      then
  (t,"");

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
  (t1,s1) = buildExpression(e1);
  (t2,s2) = buildExpression(e2);
  ops = ExpressionDump.binopSymbol1(op);
  ts = stringAppendList({"%s",ops,"%s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
  TaskGraphExt.addEdge(t2, t, s2, 1);
      then
  (t,"");

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
  (t1,s1) = buildExpression(e1);
  (t2,s2) = buildExpression(e2);
  ops = ExpressionDump.binopSymbol1(op);
  ts = stringAppendList({"%s",ops,"%s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
  TaskGraphExt.addEdge(t2, t, s2, 1);
      then
  (t,"");

    case (DAE.UNARY(operator = op,exp = e1))
      equation
  (t1,s1) = buildExpression(e1);
  ops = ExpressionDump.unaryopSymbol(op);
  ts = stringAppendList({ops,"%s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
      then
  (t,"");

    case (DAE.LUNARY(operator = op,exp = e1))
      equation
  (t1,s1) = buildExpression(e1);
  ops = ExpressionDump.lunaryopSymbol(op);
  ts = stringAppendList({ops,"%s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
      then
  (t,"");

    case (DAE.RELATION(exp1 = e1,operator = relop,exp2 = e2))
      equation
  (t1,s1) = buildExpression(e1);
  (t2,s2) = buildExpression(e2);
  ops = ExpressionDump.relopSymbol(relop);
  ts = stringAppendList({"%s",ops,"%s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
  TaskGraphExt.addEdge(t2, t, s2, 1);
      then
  (t,"");

    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
  (t1,s1) = buildExpression(e1);
  (t2,s2) = buildExpression(e2);
  (t3,s3) = buildExpression(e3);
  ts = stringAppendList({"%s ? %s : %s"});
  t = TaskGraphExt.newTask(ts);
  TaskGraphExt.addEdge(t1, t, s1, 0);
  TaskGraphExt.addEdge(t2, t, s2, 1);
  TaskGraphExt.addEdge(t3, t, s3, 2);
      then
  (t,"");

    case (DAE.CALL(path = func,expLst = expl))
      equation
  funcstr = Absyn.pathString(func);
  numargs = listLength(expl);
  ts = buildCallStr(funcstr, numargs);
  (tasks,strs) = List.map_2(expl, buildExpression);
  t = TaskGraphExt.newTask(ts);
  addPredecessors(t, tasks, strs, 0);
      then
  (t,"");

    case (DAE.ARRAY(ty = _))
      equation
  print("TaskGraph.buildExpression(ARRAY) not impl. yet\n");
      then
  fail();
    case (DAE.ARRAY(ty = _))
      equation
  print("TaskGraph.buildExpression(MATRIX) not impl. yet\n");
      then
  fail();
    case (DAE.RANGE(ty = _))
      equation
  print("TaskGraph.buildExpression(RANGE) not impl. yet\n");
      then
  fail();
    case (DAE.TUPLE(PR = _))
      equation
  print("TaskGraph.buildExpression(TUPLE) not impl. yet\n");
      then
  fail();
    case (DAE.CAST(exp = e))
      equation
  (t,s) = buildExpression(e);
      then
  (t,s);
    case (DAE.ASUB(exp = _))
      equation
  print("TaskGraph.buildExpression(ASUB) not impl. yet\n");
      then
  fail();
    case (DAE.SIZE(exp = _))
      equation
  print("TaskGraph.buildExpression(SIZE) not impl. yet\n");
      then
  fail();
    case (DAE.CODE(code = _))
      equation
  print("TaskGraph.buildExpression(CODE) not impl. yet\n");
      then
  fail();
    case (DAE.REDUCTION(expr = _))
      equation
  print("TaskGraph.buildExpression(REDUCTION) not impl. yet\n");
      then
  fail();
    case (e)
      equation
  print("-TaskGraph.buildExpression failed\n Exp = ");
  es = ExpressionDump.printExpStr(e);
  print(es);
  print("\n");
      then
  fail();
  end matchcontinue;
end buildExpression;

protected function buildCallStr
  input String str;
  input Integer n;
  output String res;
protected
  list<String> ns;
  String ns_1;
algorithm
  ns := List.fill("%s", n);
  ns_1 := stringDelimitList(ns, ", ");
  res := stringAppendList({str,"(",ns_1,")"});
end buildCallStr;

protected function addPredecessors
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input list<String> inStringLst3;
  input Integer inInteger4;
algorithm
  _:=
  match (inInteger1,inIntegerLst2,inStringLst3,inInteger4)
    local
      Integer prio_1,t,t1,prio;
      list<Integer> ts;
      String s;
      list<String> strs;
    case (_,{},{},_) then ();  /* task list of precessors prio */
    case (t,(t1 :: ts),(s :: strs),prio)
      equation
  TaskGraphExt.addEdge(t1, t, s, prio);
  prio_1 = prio + 1;
  addPredecessors(t, ts, strs, prio_1);
      then
  ();
  end match;
end addPredecessors;

end TaskGraph;

