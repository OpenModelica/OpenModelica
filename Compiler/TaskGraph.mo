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

package TaskGraph
" file:	       TaskGraph.mo
  package:     TaskGraph
  description: Building of task graphs from expressions, and equation systems.

  RCS: $Id$

  This module is used in the modpar part of OpenModelica for bulding task graphs
  from the BLT decomposition for automatic parallelization.
  The exported function buildTaskgraph takes the lowered form of the DAE defined in
  DAELow and two assignments vectors (which variable is solved in which equation) and
  the list of blocks given by the BLT decomposition.

  The package uses TaskGraphExt for the task graph datastructure itself, which
  is implemented using Boost Graph Library in C++"

public import Exp;
public import DAELow;

protected import TaskGraphExt;
protected import Util;
protected import Absyn;
protected import DAE;
protected import Values;
protected import VarTransform;
protected import SimCodegen;

public function buildTaskgraph ""
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
algorithm
  _:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4)
    local
      Integer starttask,endtask;
      list<DAELow.Var> vars,knvars;
      DAELow.DAELow dae;
      DAELow.VariableArray vararr,knvararr;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      
    case ((dae as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),knownVars = DAELow.VARIABLES(varArr = knvararr))),ass1,ass2,blocks)
      equation
        print("starting buildtaskgraph\n");
        starttask = TaskGraphExt.newTask("start");
        endtask = TaskGraphExt.newTask("end");
        TaskGraphExt.setExecCost(starttask, 1.0);
        TaskGraphExt.setExecCost(starttask, 1.0);
        TaskGraphExt.registerStartStop(starttask, endtask);
        vars = DAELow.vararrayList(vararr);
        knvars = DAELow.vararrayList(knvararr);
        addVariables(vars, starttask);
        addVariables(knvars, starttask);
        addVariables({DAELow.VAR(Exp.CREF_IDENT("sim_time",Exp.REAL(),{}),DAELow.VARIABLE(),
                      DAE.INPUT(),DAE.REAL(),NONE,NONE,{},0,Exp.CREF_IDENT("time",Exp.REAL(),{}),{},NONE,
                      NONE,DAE.NON_CONNECTOR(),DAE.NON_STREAM())}, starttask);
        buildBlocks(dae, ass1, ass2, blocks);
        print("done building taskgraph, about to build inits.\n");
        buildInits(dae);
        print("leaving TaskGraph.buildTaskgraph\n");
      then
        ();
        
    case (_,_,_,_)
      equation
        print("-TaskGraph.buildTaskgraph failed\n");
      then
        fail();
  end matchcontinue;
end buildTaskgraph;

protected function buildInits "function: buildInits
  This function traverses the DAE and calls external functions to build
  the initialization values for the DAE
  This is implemented in C++ as a set of vectors
"
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars,kvars;
      DAELow.VariableArray vararr,kvararr;
    case (DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),knownVars = DAELow.VARIABLES(varArr = kvararr)))
      equation
        vars = DAELow.vararrayList(vararr);
        kvars = DAELow.vararrayList(kvararr);
        buildInits2(vars);
        buildInits2(kvars);
      then
        ();
  end matchcontinue;
end buildInits;

protected function buildInits2
  input list<DAELow.Var> inDAELowVarLst;
algorithm
  _:=
  matchcontinue (inDAELowVarLst)
    local
      String v,origname_str;
      Exp.Exp value;
      Integer indx;
      Exp.ComponentRef origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flowPrefix;
      list<DAELow.Var> rest;
      Exp.Exp e;
    case ({}) then ();
    case ((DAELow.VAR(varKind = DAELow.VARIABLE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAE.getStartAttr(dae_var_attr);
        v = Exp.printExpStr(e);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.VARIABLE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.STATE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAE.getStartAttr(dae_var_attr);
        v = Exp.printExpStr(e);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitState(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.STATE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitState(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.DUMMY_DER(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        e = DAE.getStartAttr(dae_var_attr);
        v = Exp.printExpStr(e);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.DUMMY_DER(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.DUMMY_STATE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
         e = DAE.getStartAttr(dae_var_attr);
        v = Exp.printExpStr(e);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.DUMMY_STATE(),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitVar(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.PARAM(),bindValue = SOME(value),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      local Values.Value value;
      equation
        v = Values.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.PARAM(),bindValue = NONE,index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.CONST(),bindValue = SOME(value),index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      local Values.Value value;
      equation
        v = Values.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, v, origname_str);
        buildInits2(rest);
      then
        ();
    case ((DAELow.VAR(varKind = DAELow.CONST(),bindValue = NONE,index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: rest))
      equation
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.addInitParam(indx, "0.0", origname_str);
        buildInits2(rest);
      then
        ();
  end matchcontinue;
end buildInits2;

protected function addVariables
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer start;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},start) then ();
    case ((v :: vs),start)
      equation
        addVariable(v, start);
        addVariables(vs, start);
      then
        ();
  end matchcontinue;
end addVariables;

protected function buildBlocks
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
algorithm
  _:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4)
    local
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
      Integer eqn;
    case (_,_,_,{}) then ();
    case (dae,ass1,ass2,((block_ as (_ :: (_ :: _))) :: blocks))
      equation
        buildSystem(dae, ass1, ass2, block_) "For system of equations" ;
        buildBlocks(dae, ass1, ass2, blocks);
      then
        ();
    case (dae,ass1,ass2,((block_ as {eqn}) :: blocks))
      equation
        buildEquation(dae, ass1, ass2, eqn) "for single equations" ;
        buildBlocks(dae, ass1, ass2, blocks);
      then
        ();
    case (_,_,_,_)
      equation
        print("-build_blocks failed\n");
      then
        fail();
  end matchcontinue;
end buildBlocks;

protected function isNonState
  input DAELow.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case (DAELow.VARIABLE()) then ();
    case (DAELow.DUMMY_DER()) then ();
    case (DAELow.DUMMY_STATE()) then ();
  end matchcontinue;
end isNonState;

protected function buildEquation "Build task graph for a single equation."
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input Integer inInteger4;
algorithm
  _:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inInteger4)
    local
      Integer e_1,v_1,e,indx;
      Exp.Exp e1,e2,varexp,expr;
      DAELow.Var v;
      list<DAELow.Var> varlst;
      Exp.ComponentRef cr,origname,cr_1;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str,indxs,name,c_name,id;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      equation
        e_1 = e - 1 "Solving for non-states" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        varlst = DAELow.varList(vars);
        ((v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = listNth(varlst, v_1);
        origname_str = Exp.printComponentRefStr(origname);
        isNonState(kind);
        varexp = Exp.CREF(cr,Exp.REAL()) "print \"Solving for non-states\\n\" &" ;
        expr = Exp.solve(e1, e2, varexp);
        buildAssignment(cr, expr, origname_str) "	Exp.print_exp_str e1 => e1s &
	Exp.print_exp_str e2 => e2s &
	print \"Equation \" & print e1s & print \" = \" & print e2s &
	print \" solved for \" & Exp.print_exp_str varexp => s &
	print s & print \" giving \" &
	Exp.print_exp_str expr => s2 & print s2 & print \"\\n\" &" ;
      then
        ();
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      local Integer v;
      equation
        e_1 = e - 1 "Solving the state s means solving for der(s)" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        varlst = DAELow.varList(vars);
        DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix) = listNth(varlst, v_1);
        indxs = intString(indx) "	print \"solving for state\\n\" &" ;
        origname_str = Exp.printComponentRefStr(origname);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = Exp.CREF_IDENT(id,Exp.REAL(),{});
        varexp = Exp.CREF(cr_1,Exp.REAL());
        expr = Exp.solve(e1, e2, varexp);
        buildAssignment(cr_1, expr, origname_str) "	Exp.print_exp_str e1 => e1s &
	Exp.print_exp_str e2 => e2s &
	print \"Equation \" & print e1s & print \" = \" & print e2s &
	print \"solved for \" & Exp.print_exp_str varexp => s &
	print s & print \"giving \" &
	Exp.print_exp_str expr => s2 & print s2 & print \"\\n\" &" ;
      then
        ();
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e) /* rule	int_sub(e,1) => e\' &
	DAELow.equation_nth(eqns,e\') => DAELow.EQUATION(e1,e2) &
	vector_nth(ass2,e\') => v & ( v==variable no solved in this equation ))
	int_sub(v,1) => v\' &
	DAELow.vararray_nth(vararr,v\') => DAELow.VAR(cr,_,_,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flow) &
	let varexp = Exp.CREF(cr,Exp.REAL) &
	not Exp.solve(e1,e2,varexp) => _ &
	print \"nonlinear equation not implemented yet\\n\"
	--------------------------------
	build_equation(DAELow.DAELOW(DAELow.VARIABLES(_,_,vararr,_,_),_,eqns,_,_,_,_,_),ass1,ass2,e) => fail
 */
      local Integer v;
      equation
        e_1 = e - 1 "state nonlinear" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        varlst = DAELow.varList(vars);
        DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,_,flowPrefix,streamPrefix) = listNth(varlst, v_1);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = Exp.CREF_IDENT(id,Exp.REAL(),{});
        varexp = Exp.CREF(cr_1,Exp.REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        buildNonlinearEquations({varexp}, {Exp.BINARY(e1,Exp.SUB(Exp.REAL()),e2)});
      then
        ();
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e)
      equation
        e_1 = e - 1 "Solving nonlinear for non-states" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        varlst = DAELow.varList(vars);
        ((v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = listNth(varlst, v_1);
        isNonState(kind);
        varexp = Exp.CREF(cr,Exp.REAL()) "print \"Solving for non-states\\n\" &" ;
        failure(expr = Exp.solve(e1, e2, varexp));
        buildNonlinearEquations({varexp}, {Exp.BINARY(e1,Exp.SUB(Exp.REAL()),e2)});
      then
        ();
    case (_,_,_,_)
      equation
        print("-TaskGraph.buildEquation failed\n");
      then
        fail();
  end matchcontinue;
end buildEquation;

protected function buildNonlinearEquations "function: buildNonlinearEquations
  builds task graph for solving non-linear equations
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Exp.Exp> inExpExpLst2;
algorithm
  _:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      Integer size,tid;
      String size_str,taskname;
      list<String> varnames;
      list<Exp.Exp> vars,residuals;
    case (vars,residuals) /* variables residuals */
      equation
        size = listLength(vars);
        size_str = intString(size);
        taskname = buildResidualCode(vars, residuals);
        tid = TaskGraphExt.newTask(taskname);
        TaskGraphExt.setTaskType(tid, 3);
        buildNonlinearEquations2(tid, vars, residuals) "See TaskType in TaskGraph.hpp" ;
        varnames = Util.listMap(vars, Exp.printExpStr);
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
  input list<Exp.Exp> inExpExpLst1;
  input list<Exp.Exp> inExpExpLst2;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      VarTransform.VariableReplacements repl;
      String res;
      list<Exp.Exp> vars,es;
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
  input list<Exp.Exp> expl;
  output VarTransform.VariableReplacements repl_1;
  VarTransform.VariableReplacements repl,repl_1;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, expl, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<Exp.Exp> inExpExpLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  matchcontinue (inVariableReplacements,inExpExpLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      String pstr,str;
      Integer pos_1,pos;
      Exp.ComponentRef cr;
      list<Exp.Exp> es;
    case (repl,{},_) then repl;
    case (repl,(Exp.CREF(componentRef = cr) :: es),pos)
      equation
        pstr = intString(pos);
        str = Util.stringAppendList({"xloc[",pstr,"]"});
        repl_1 = VarTransform.addReplacement(repl, cr, Exp.CREF(Exp.CREF_IDENT(str,Exp.REAL(),{}),Exp.REAL()));
        pos_1 = pos + 1;
        repl_2 = makeResidualReplacements2(repl_1, es, pos_1);
      then
        repl_2;
  end matchcontinue;
end makeResidualReplacements2;

protected function buildResidualCode2
  input list<Exp.Exp> inExpExpLst;
  input Integer inInteger;
  input VarTransform.VariableReplacements inVariableReplacements;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpLst,inInteger,inVariableReplacements)
    local
      Exp.Exp e_1,e;
      String s1,s2,pstr,res;
      Integer pos_1,pos;
      list<Exp.Exp> es;
      VarTransform.VariableReplacements repl;
    case ({},_,_) then "";
    case ((e :: es),pos,repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl, NONE);
        s1 = SimCodegen.printExpCppStr(e_1);
        pos_1 = pos + 1;
        s2 = buildResidualCode2(es, pos_1, repl);
        pstr = intString(pos);
        res = Util.stringAppendList({"res[",pstr,"]=",s1,";\n",s2});
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
        result_str = Util.stringDelimitList(varnames, ";");
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
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
algorithm
  _:=
  matchcontinue (inInteger1,inExpExpLst2,inExpExpLst3)
    local
      Integer tid;
      list<Exp.ComponentRef> vars1,vars2,vars1_1,vars;
      list<list<Exp.ComponentRef>> vars_1;
      Exp.Exp res,e;
      list<Exp.Exp> residuals;
      String es;
    case (tid,_,{}) then ();  /* task id vars residuals */
    case (tid,vars,(res :: residuals))
      equation
        vars1 = Exp.getCrefFromExp(res) "Collect all variables and construct
	 a string for the residual, that can be directly used in codegen." ;
        vars_1 = Util.listMap(vars, Exp.getCrefFromExp);
        vars2 = Util.listFlatten(vars_1);
        vars1_1 = Util.listUnionOnTrue(vars1, vars2, Exp.crefEqual) "No duplicate elements" ;
        vars = Util.listSetDifferenceOnTrue(vars1_1, vars2, Exp.crefEqual);
        addEdgesFromVars(vars, tid, 0);
      then
        ();
    case (_,_,(e :: _))
      equation
        print("build_nonlinear_equations2 failed\n");
        es = Exp.printExpStr(e);
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
  input list<Exp.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
algorithm
  _:=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      String v_str;
      Integer predt,prio_1,tid,prio;
      Exp.ComponentRef v;
      list<Exp.ComponentRef> vs;
    case ({},_,_) then ();  /* task priority */
    case ((v :: vs),tid,prio)
      equation
        v_str = Exp.crefStr(v);
        predt = TaskGraphExt.getTask(v_str);
        TaskGraphExt.addEdge(predt, tid, v_str, prio);
        prio_1 = prio + 1;
        addEdgesFromVars(vs, tid, prio_1);
      then
        ();
    case ((v :: vs),_,_)
      equation
        v_str = Exp.crefStr(v);
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
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
algorithm
  _:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4)
    local
      Integer tid;
      list<String> predtasks;
      list<Integer> predtaskids,system;
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
    case (dae,ass1,ass2,system)
      equation
        print("build system\n");
        tid = TaskGraphExt.newTask("equation system");
        predtasks = buildSystem2(dae, ass1, ass2, system, tid);
        predtaskids = Util.listMap(predtasks, TaskGraphExt.getTask);
        addPredecessors(tid, predtaskids, predtasks, 0);
      then
        ();
    case (_,_,_,_)
      equation
        print("build_system failed\n");
      then
        fail();
  end matchcontinue;
end buildSystem;

protected function buildSystem2
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input Integer inInteger5;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4,inInteger5)
    local
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
      Integer tid,e_1,v_1,e;
      Exp.Exp e1,e2;
      DAELow.Var v;
      Exp.ComponentRef cr,origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Exp.ComponentRef> cr1,cr2,crs,crs_1;
      list<String> crs_2,crs2,res;
      String crstr,origname_str;
      DAELow.VariableArray vararr;
      DAELow.EquationArray eqns;
      list<Integer> rest;
    case (dae,ass1,ass2,{},tid) then {};
    case ((dae as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns)),ass1,ass2,(e :: rest),tid)
      equation
        e_1 = e - 1;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        ((v as DAELow.VAR(cr,DAELow.VARIABLE(),_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        cr1 = Exp.getCrefFromExp(e1);
        cr2 = Exp.getCrefFromExp(e2);
        crs = listAppend(cr1, cr2);
        crs_1 = Util.listDeleteMember(crs, cr);
        crs_2 = Util.listMap(crs_1, Exp.crefStr);
        crstr = Exp.crefStr(cr);
        origname_str = Exp.printComponentRefStr(origname);
        TaskGraphExt.storeResult(crstr, tid, true, origname_str);
        crs2 = buildSystem2(dae, ass1, ass2, rest, tid);
        res = Util.listUnion(crs_2, crs2);
      then
        res;
    case (_,_,_,_,_)
      equation
        print("TaskGraph.buildSystem2 failed\n");
      then
        fail();
  end matchcontinue;
end buildSystem2;

protected function addVariable
  input DAELow.Var inVar;
  input Integer inInteger;
algorithm
  _:= matchcontinue (inVar,inInteger)
    local
      String cfs,name_str;
      Exp.ComponentRef cf,name;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer start;
    case (DAELow.VAR(varName = cf,origVarName = name,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix),start)
      equation
        cfs = Exp.crefStr(cf);
        name_str = Exp.printComponentRefStr(name) "print \"adding variable \" & print cfs & print \"\\n\" &" ;
        TaskGraphExt.storeResult(cfs, start, false, name_str);
      then
        ();
  end matchcontinue;
end addVariable;

protected function buildAssignment
  input Exp.ComponentRef inComponentRef;
  input Exp.Exp inExp;
  input String inString;
algorithm
  _:=
  matchcontinue (inComponentRef,inExp,inString)
    local
      Integer task,tid;
      String str,cr2s,crs,origname;
      Exp.ComponentRef cr,cr2;
      Exp.Exp exp;
      Exp.Type tp;
    case (cr,(exp as Exp.CREF(componentRef = cr2,ty = tp)),origname) /* varname expression orig. name */
      equation
        (task,str) = buildExpression(exp) "special rule for equation a:=b" ;
        tid = TaskGraphExt.newTask("copy");
        cr2s = Exp.crefStr(cr2);
        TaskGraphExt.addEdge(task, tid, cr2s, 0);
        crs = Exp.crefStr(cr);
        TaskGraphExt.storeResult(crs, tid, true, origname);
        TaskGraphExt.setTaskType(tid, 6) "See TaskType in TaskGraph.hpp" ;
      then
        ();
    case (cr,exp,origname)
      equation
        (task,str) = buildExpression(exp);
        crs = Exp.crefStr(cr);
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
  input Exp.Exp inExp;
  output Integer outInteger;
  output String outString;
algorithm
  (outInteger,outString):=
  matchcontinue (inExp)
    local
      String is,rs,crs,s1,istr,ts,s2,ops,s3,funcstr,s,es;
      Integer tid,i,t1,ival,t,t2,t3,numargs;
      Real r,rval;
      Exp.ComponentRef cr;
      Exp.Exp e1,e2,e3,e;
      Exp.Operator op,relop;
      list<Integer> tasks;
      list<String> strs;
      Absyn.Path func;
      list<Exp.Exp> expl;
    case (Exp.ICONST(integer = i))
      equation
        is = intString(i);
        tid = TaskGraphExt.newTask(is) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
        (tid,"");
        
    case (Exp.RCONST(real = r))
      equation
        rs = realString(r);
        tid = TaskGraphExt.newTask(rs) "& TaskGraphExt.getStartTask() => st & TaskGraphExt.addEdge(st,tid,\"\") & TaskGraphExt.setCommCost(st,tid,0)" ;
      then
        (tid,"");
        
    case (Exp.CREF(componentRef = cr))
      equation
        crs = Exp.crefStr(cr) "for state variables and alg. variables" ;
        tid = TaskGraphExt.getTask(crs);
      then
        (tid,crs);
        
    case (Exp.CREF(componentRef = Exp.CREF_IDENT(ident = "time")))
      equation
        tid = TaskGraphExt.getTask("sim_time") "for state variables and alg. variables" ;
      then
        (tid,"sim_time");
        
    case (Exp.CREF(componentRef = cr))
      equation
        crs = Exp.crefStr(cr) "for constants and parameters, no data to send from proc0" ;
        tid = TaskGraphExt.newTask(crs);
      then
        (tid,crs);
        
    case (Exp.BINARY(exp1 = e1,operator = Exp.POW(ty = _),exp2 = Exp.RCONST(real = rval)))
      equation
        (t1,s1) = buildExpression(e1) "special case for pow" ;
        ival = realInt(rval);
        istr = intString(ival);
        ts = Util.stringAppendList({"pow(%s,",istr,")"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");
        
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = Exp.binopSymbol1(op);
        ts = Util.stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");
        
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = Exp.binopSymbol1(op);
        ts = Util.stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");
        
    case (Exp.UNARY(operator = op,exp = e1))
      equation
        (t1,s1) = buildExpression(e1);
        ops = Exp.unaryopSymbol(op);
        ts = Util.stringAppendList({ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");
        
    case (Exp.LUNARY(operator = op,exp = e1))
      equation
        (t1,s1) = buildExpression(e1);
        ops = Exp.lunaryopSymbol(op);
        ts = Util.stringAppendList({ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
      then
        (t,"");
        
    case (Exp.RELATION(exp1 = e1,operator = relop,exp2 = e2))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        ops = Exp.relopSymbol(relop);
        ts = Util.stringAppendList({"%s",ops,"%s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
      then
        (t,"");
        
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        (t1,s1) = buildExpression(e1);
        (t2,s2) = buildExpression(e2);
        (t3,s3) = buildExpression(e3);
        ts = Util.stringAppendList({"%s ? %s : %s"});
        t = TaskGraphExt.newTask(ts);
        TaskGraphExt.addEdge(t1, t, s1, 0);
        TaskGraphExt.addEdge(t2, t, s2, 1);
        TaskGraphExt.addEdge(t3, t, s3, 2);
      then
        (t,"");
        
    case (Exp.CALL(path = func,expLst = expl))
      equation
        funcstr = Absyn.pathString(func);
        numargs = listLength(expl);
        ts = buildCallStr(funcstr, numargs);
        (tasks,strs) = Util.listMap_2(expl, buildExpression);
        t = TaskGraphExt.newTask(ts);
        addPredecessors(t, tasks, strs, 0);
      then
        (t,"");
        
    case (Exp.ARRAY(ty = _))
      equation
        print("TaskGraph.buildExpression(ARRAY) not impl. yet\n");
      then
        fail();
    case (Exp.ARRAY(ty = _))
      equation
        print("TaskGraph.buildExpression(MATRIX) not impl. yet\n");
      then
        fail();
    case (Exp.RANGE(ty = _))
      equation
        print("TaskGraph.buildExpression(RANGE) not impl. yet\n");
      then
        fail();
    case (Exp.TUPLE(PR = _))
      equation
        print("TaskGraph.buildExpression(TUPLE) not impl. yet\n");
      then
        fail();
    case (Exp.CAST(ty = t,exp = e))
      equation
        (t,s) = buildExpression(e);
      then
        (t,s);
    case (Exp.ASUB(exp = _))
      equation
        print("TaskGraph.buildExpression(ASUB) not impl. yet\n");
      then
        fail();
    case (Exp.SIZE(exp = _))
      equation
        print("TaskGraph.buildExpression(SIZE) not impl. yet\n");
      then
        fail();
    case (Exp.CODE(code = _))
      equation
        print("TaskGraph.buildExpression(CODE) not impl. yet\n");
      then
        fail();
    case (Exp.REDUCTION(path = _))
      equation
        print("TaskGraph.buildExpression(REDUCTION) not impl. yet\n");
      then
        fail();
    case (Exp.END())
      equation
        print("TaskGraph.buildExpression(END) not impl. yet\n");
      then
        fail();
    case (e)
      equation
        print("-TaskGraph.buildExpression failed\n Exp = ");
        es = Exp.printExpStr(e);
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
  list<String> ns;
  String ns_1;
algorithm
  ns := Util.listFill("%s", n);
  ns_1 := Util.stringDelimitList(ns, ", ");
  res := Util.stringAppendList({str,"(",ns_1,")"});
end buildCallStr;

protected function addPredecessors
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input list<String> inStringLst3;
  input Integer inInteger4;
algorithm
  _:=
  matchcontinue (inInteger1,inIntegerLst2,inStringLst3,inInteger4)
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
  end matchcontinue;
end addPredecessors;

end TaskGraph;

