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

package BackendDAEUtil
" file:	       BackendDAEUtil.mo
  package:     BackendDAEUtil 
  description: BackendDAEUtil comprised functions for DAELow data types.

  RCS: $Id: BackendDAEUtil.mo 6426 2010-10-19 08:01:48Z adrpo $

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

protected import Absyn;
protected import BackendVariable;
protected import ComponentReference;
protected import Ceval;
protected import ClassInf;
protected import DAELow;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import HashTable2;
protected import OptManager;
protected import RTOpts;
protected import System;
protected import Util;
protected import Values;
protected import ValuesUtil;


public function checkBackendDAEWithErrorMsg"function: checkBackendDAEWithErrorMsg
  author: Frenkel TUD
  run checkDEALow and prints all errors"
  input BackendDAE.DAELow inBackendDAE;
  list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expCrefs;
algorithm  
  expCrefs := checkBackendDAE(inBackendDAE);
  printcheckBackendDAEWithErrorMsg(expCrefs);
end checkBackendDAEWithErrorMsg;
 
public function printcheckBackendDAEWithErrorMsg"function: printcheckBackendDAEWithErrorMsg
  author: Frenkel TUD
  helper for checkDEALowWithErrorMsg"
  input list<tuple<DAE.Exp,list<DAE.ComponentRef>>> inExpCrefs;  
algorithm   
  _:=
  matchcontinue (inExpCrefs)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> res;
      list<String> strcrefs;
      String crefstring, expstr,scopestr;
      case ({}) then ();
      case (((e,crefs))::res)
         equation
           false = RTOpts.debugFlag("checkBackendDAE");
        then
          ();                   
      case (((e,crefs))::res)
        equation
          true = RTOpts.debugFlag("checkBackendDAE");
          strcrefs = Util.listMap(crefs,ComponentReference.crefStr);
          crefstring = Util.stringDelimitList(strcrefs,", ");
          expstr = ExpressionDump.printExpStr(e);
          scopestr = System.stringAppendList({crefstring," from Expression: ",expstr});
          Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {scopestr,"BackendDAE object"});
          printcheckBackendDAEWithErrorMsg(res);
        then
          ();
  end matchcontinue;
end printcheckBackendDAEWithErrorMsg;      
      
public function checkBackendDAE "function: checkBackendDAE
  author: Frenkel TUD

  This function checks the BackendDAE object if 
  all component refercences used in the expressions are 
  part of the BackendDAE object. Returns all component references
  which not part of the BackendDAE object. 
"
  input BackendDAE.DAELow inBackendDAE;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outExpCrefs :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.Variables vars1,vars2,allvars;
      list<BackendDAE.Var> varlst1,varlst2,allvarslst;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcrefs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2))
      equation
        varlst1 = varList(vars1);
        varlst2 = varList(vars2);
        allvarslst = listAppend(varlst1,varlst2);
        allvars = listVar(allvarslst);
        expcrefs = DAELow.traverseDAELowExps(inBackendDAE,false,checkBackendDAEExp,allvars);
      then
        expcrefs;
    case (_)
      equation
        Debug.fprintln("failtrace", "- BackendDAEUtil.checkBackendDAE failed");
      then
        fail();
  end matchcontinue;
end checkBackendDAE;

protected function checkBackendDAEExp
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outExpCrefs :=
  matchcontinue (inExp,inVars)
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> lstExpCrefs;
    case (exp,vars)
      equation
        ((_,(_,crefs))) = Expression.traverseExpTopDown(exp,traversecheckBackendDAEExp,((vars,{})));
        lstExpCrefs = Util.if_(listLength(crefs)>0,{(exp,crefs)},{});
       then
        lstExpCrefs;
  end matchcontinue;      
end checkBackendDAEExp;

protected function traversecheckBackendDAEExp
	input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> inTuple;
	output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<DAE.ComponentRef>>> outTuple;
algorithm
	outTuple := matchcontinue(inTuple)
		local
			DAE.Exp e;
			BackendDAE.Variables vars;
			DAE.ComponentRef cr;
			list<DAE.ComponentRef> crefs;
			list<DAE.Exp> expl;
		// special case for time, it is never part of the equation system	
		case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,crefs)))
		  then ((e, (vars,crefs)));
    /* Special Case for Records */
    case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
      local 
        list<list<tuple<DAE.Exp,list<DAE.ComponentRef>>>> expcreflstlst;
        list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcreflst;
        list<list<DAE.ComponentRef>> creflstlst;
        list<DAE.ComponentRef> crlst;
        list<DAE.ExpVar> varLst;
      equation
        DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        expl = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e);
        expcreflstlst = Util.listMap1(expl,checkBackendDAEExp,vars);
        expcreflst = Util.listFlatten(expcreflstlst);
        creflstlst = Util.listMap(expcreflst,Util.tuple22);
        crlst = Util.listFlatten(creflstlst);
      then
        ((e, (vars,listAppend(crlst,crefs))));  
    /* case for Reductions  */    
		case ((e as DAE.REDUCTION(ident = ident),(vars,crefs)))
		  local 
		    DAE.Ident ident;
		    BackendDAE.Var  var;
		  equation
		    // add ident to vars
		    cr = ComponentReference.makeCrefIdent(ident,DAE.ET_INT(),{});
		    var = BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.INT(),NONE(),NONE(),{},0,
		          DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
		    vars = BackendVariable.addVar(var,vars);
		  then
		    ((e, (vars,crefs)));
		/* case for functionpointers */    
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
		case (_) then inTuple;
	end matchcontinue;
end traversecheckBackendDAEExp;

/************************************************************
  Util function at Backend using for lowering and other stuff
 ************************************************************/

public function systemSize "returns the size of the dae system"
input BackendDAE.DAELow dae;
output Integer n;
algorithm
  n := matchcontinue(dae)
  local BackendDAE.EquationArray eqns;
    case(BackendDAE.DAELOW(orderedEqs = eqns))
      equation
        n = equationSize(eqns);
      then n;

  end matchcontinue;
end systemSize;



public function statesDaelow
"function: statesDaelow
  author: PA
  Returns a BackendDAE.BinTree of all states in the DAELow
  This function is used in matching algorithm."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> v_lst;
      BackendDAE.BinTree bt;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,re,ia;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
    case (BackendDAE.DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = re,initialEqs = ia,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        v_lst = varList(v);
        bt = statesDaelow2(v_lst, BackendDAE.emptyBintree);
      then
        bt;
  end matchcontinue;
end statesDaelow;

protected function statesDaelow2
"function: statesDaelow2
  author: PA
  Helper function to statesDaelow."
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inVarLst,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;

    case ({},bt) then bt;

    case ((v :: vs),bt)
      equation
        BackendDAE.STATE() = BackendVariable.varKind(v);
        cr = BackendVariable.varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
/*  is not realy a state
    case ((v :: vs),bt)
      equation
        BackendDAE.DUMMY_STATE() = BackendVariable.varKind(v);
        cr = BackendVariable.varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
*/
    case ((v :: vs),bt)
      equation
        bt = statesDaelow2(vs, bt);
      then
        bt;
  end matchcontinue;
end statesDaelow2;

public function emptyVars
"function: emptyVars
  author: PA
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  output BackendDAE.Variables outVariables;
  array<list<BackendDAE.CrefIndex>> arr;
  array<list<BackendDAE.StringIndex>> arr2;
  list<Option<BackendDAE.Var>> lst;
  array<Option<BackendDAE.Var>> emptyarr;
algorithm
  arr := arrayCreate(10, {});
  arr2 := arrayCreate(10, {});
  lst := Util.listFill(NONE(), 10);
  emptyarr := listArray(lst);
  outVariables := BackendDAE.VARIABLES(arr,arr2,BackendDAE.VARIABLE_ARRAY(0,10,emptyarr),10,0);
end emptyVars;

public function emptyAliasVariables
  output BackendDAE.AliasVariables outAliasVariables;
  HashTable2.HashTable aliasMappings;
  BackendDAE.Variables aliasVariables;
algorithm
  aliasMappings := HashTable2.emptyHashTable();
  aliasVariables := emptyVars();
  outAliasVariables := BackendDAE.ALIASVARS(aliasMappings,aliasVariables);
end emptyAliasVariables;

public function equationList "function: equationList
  author: PA

  Transform the expandable BackendDAE.Equation array to a list of Equations.
"
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationArray)
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
        print("equation_list failed\n");
      then
        fail();
  end matchcontinue;
end equationList;

public function listEquation "function: listEquation
  author: PA

  Transform the a list of Equations into an expandable BackendDAE.Equation array.
"
  input list<BackendDAE.Equation> lst;
  output BackendDAE.EquationArray outEquationArray;
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

protected function equationList2 "function: equationList2
  author: PA

  Helper function to equation_list

  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: BackendDAE.Equation list

"
  input array<Option<BackendDAE.Equation>> inEquationOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationOptionArray1,inInteger2,inInteger3)
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


public function varList
"function: varList
  Takes BackendDAE.Variables and returns a list of \'Var\', useful for e.g. dumping."
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr))
      equation
        varlst = vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;

public function listVar
"function: listVar
  author: PA
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables:=
  matchcontinue (inVarLst)
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
  end matchcontinue;
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
        SOME(elt) = arr[0 + 1];
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
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(DAE.CREF(cr,DAE.ET_OTHER()),vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(BackendDAE.RESIDUAL_EQUATION(exp = e1),vars,knvars) equation
      b = isDiscreteExp(e1,vars,knvars);
    then b;
    case(BackendDAE.ALGORITHM(in_ = expl),vars,knvars) equation
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(BackendDAE.WHEN_EQUATION(whenEquation = _),vars,knvars) then true;
  end matchcontinue;
end isDiscreteEquation;


public function isDiscreteExp "function: isDiscreteExp
 Returns true if expression is a discrete expression."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables knvars;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables,knvars)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      Boolean res,b1,b2,b3;
      DAE.Exp e1,e2,e,e3;
      DAE.Operator op;
      list<Boolean> blst;
      list<DAE.Exp> expl,expl_2;
      DAE.ExpType tp;
      list<tuple<DAE.Exp, Boolean>> expl_1;

    case (DAE.ICONST(integer = _),vars,knvars) then true;
    case (DAE.RCONST(real = _),vars,knvars) then true;
    case (DAE.SCONST(string = _),vars,knvars) then true;
    case (DAE.BCONST(bool = _),vars,knvars) then true;
    case (DAE.ENUM_LITERAL(name = _),vars,knvars) then true;

    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = BackendVariable.getVar(cr, vars);
        res = isKindDiscrete(kind);
      then
        res;
        /* builtin variable time is not discrete */
    case (DAE.CREF(componentRef = DAE.CREF_IDENT("time",_,_)),vars,knvars)
      then false;

        /* Known variables that are input are continous */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      local BackendDAE.Var v;
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        (v::_,_) = BackendVariable.getVar(cr,knvars);
        true = isInput(v);
      then
        false;

        /* parameters & constants */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        ((BackendDAE.VAR(varKind = kind) :: _),_) = BackendVariable.getVar(cr, knvars);
        res = isKindDiscrete(kind);
      then
        res;
        /* enumerations */
    //case (DAE.CREF(DAE.CREF_IDENT(identType = DAE.ET_ENUMERATION(path = _)),_),vars,knvars) then true;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),vars,knvars) then true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT(name = "pre")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "edge")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "change")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "ceil")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "floor")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "div")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "mod")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "rem")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "abs")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "sign")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "noEvent")),vars,knvars) then false;

    case (DAE.CALL(expLst = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.ARRAY(ty = tp,array = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.MATRIX(ty = tp,scalar = expl),vars,knvars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        blst = Util.listMap2(expl_2, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.CAST(ty = tp,exp = e1),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.ASUB(exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = SOME(e2)),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = NONE()),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (_,vars,knvars) then false;
  end matchcontinue;
end isDiscreteExp;


public function isVarDiscrete " returns true if variable is discrete"
input BackendDAE.Var var;
output Boolean res;
algorithm
  res := matchcontinue(var)
    case(BackendDAE.VAR(varKind=kind)) local BackendDAE.VarKind kind;
      then isKindDiscrete(kind);
  end matchcontinue;
end isVarDiscrete;


protected function isKindDiscrete "function: isKindDiscrete

  Returns true if BackendDAE.VarKind is discrete.
"
  input BackendDAE.VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarKind)
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
        print("-bintree_to_list failed\n");
      then
        fail();
  end matchcontinue;
end bintreeToList;

protected function bintreeToList2 "function: bintreeToList2
  author: PA

  helper function to bintree_to_list
"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree,inKeyLst,inValueLst)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      DAE.ComponentRef key;
      BackendDAE.Value value;
      Option<BackendDAE.BinTree> left,right;
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),klst,vlst) then (klst,vlst);
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

  helper function to bintree_to_list
"
  input Option<BackendDAE.BinTree> inBinTreeOption;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTreeOption,inKeyLst,inValueLst)
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
  end matchcontinue;
end bintreeToListOpt;

/* NOT USED
protected function statesEqns "function: statesEqns
  author: PA
  Takes a list of equations and an (empty) BackendDAE.BinTree and
  fills the tree with the state variables present in the 
  equations"
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inEquationLst,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2;
      list<BackendDAE.Equation> es;
      BackendDAE.Value ds,indx;
      list<DAE.Exp> expl,expl1,expl2;
    case ({},bt) then bt;
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case ((BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case ((BackendDAE.ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es),bt)
      equation
        bt = Util.listFold(expl1, statesExp, bt);
        bt = Util.listFold(expl2, statesExp, bt);
        bt = statesEqns(es, bt);
      then
        bt;
    case ((BackendDAE.WHEN_EQUATION(whenEquation = _) :: es),bt)
      equation
        bt = statesEqns(es, bt);
      then
        bt;
    case (_,_)
      equation
        print("-states_eqns failed\n");
      then
        fail();
  end matchcontinue;
end statesEqns;
*/


public function statesAndVarsExp
"function: statesAndVarsExp
  This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (DAE.Exp, BackendDAE.Variables /* vars */)
  outputs: DAE.Exp list"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e,e1,e2,e3;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      BackendDAE.Variables vars;
      list<DAE.Exp> s1,s2,res,s3,expl;
      DAE.Flow flowPrefix;
      list<BackendDAE.Value> p;
      list<list<DAE.Exp>> lst;
      list<list<tuple<DAE.Exp, Boolean>>> mexp;
      list<DAE.ExpVar> varLst;
    /* Special Case for Records */
    case ((e as DAE.CREF(componentRef = cr)),vars)
      equation
        DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        expl = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e);
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        res;  
    /* Special Case for unextended arrays */
    case ((e as DAE.CREF(componentRef = cr,ty = DAE.ET_ARRAY(arrayDimensions=_))),vars)
      equation
        (e1,_) = extendArrExp(e,NONE());
        res = statesAndVarsExp(e1, vars);
      then
        res; 
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),vars)
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        {e};
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Expression.expEqual);
      then
        res;
    case (DAE.UNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Expression.expEqual);
      then
        res;
    case (DAE.LUNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        s3 = statesAndVarsExp(e3, vars);
        res = Util.listListUnionOnTrue({s1,s2,s3}, Expression.expEqual);
      then
        res;
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = BackendVariable.getVar(cr, vars);
      then
        {e};
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = BackendVariable.getVar(cr, vars);
      then
        {};
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        res;
    case (DAE.PARTEVALFUNCTION(expList = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        res;
    case (DAE.MATRIX(scalar = mexp),vars)
      equation
        res = statesAndVarsMatrixExp(mexp, vars);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Expression.expEqual);
      then
        res;
    case (DAE.CAST(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.ASUB(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Expression.expEqual);
      then
        res;
    // ignore constants!
    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.ENUM_LITERAL(name = _),_) then {};

    // deal with possible failure
    case (e,vars)
      equation
        // adrpo: TODO! FIXME! this function fails for some of the expressions: cr.cr.cr[{1,2,3}] for example.
        // Debug.fprintln("daelow", "- DAELow.statesAndVarsExp failed to extract states or vars from expression: " +& ExpressionDump.dumpExpStr(e,0));
      then {};
  end matchcontinue;
end statesAndVarsExp;

protected function statesAndVarsMatrixExp
"function: statesAndVarsMatrixExp"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1,ms_1,res;
      list<list<DAE.Exp>> lst;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> ms;
      BackendDAE.Variables vars;
    case ({},_) then {};
    case ((expl :: ms),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        lst = Util.listMap1(expl_1, statesAndVarsExp, vars);
        ms_1 = statesAndVarsMatrixExp(ms, vars);
        res = Util.listListUnionOnTrue((ms_1 :: lst), Expression.expEqual);
      then
        res;
  end matchcontinue;
end statesAndVarsMatrixExp;

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
        subscript_exprs = Util.listMap(subscripts, Expression.subscriptExp);
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
    case (DAE.ASUB(exp = DAE.ARRAY(array = (DAE.CREF(componentRef = cr, ty = ty) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
    case (DAE.ASUB(exp = DAE.MATRIX(scalar = (((DAE.CREF(componentRef = cr, ty = ty), _) :: _) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
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
      list<DAE.Exp> subs;
      list<DAE.Exp> clonedElements, newElements;
      list<DAE.Exp> indices;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> arrayElements;
      list<DAE.ComponentRef> varCrefs;
      list<DAE.Exp> varExprs;

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
        (arrayElements, _) = BackendVariable.getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, BackendVariable.varCref);
        varExprs = Util.listMap(varCrefs, Expression.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (arrayElements, _) = BackendVariable.getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, BackendVariable.varCref);
        varExprs = Util.listMap(varCrefs, Expression.crefExp);
      then varExprs;
      
    case (DAE.ASUB(exp = e), _, _, _)
      local DAE.Exp e;
      equation
        varExprs = Expression.flattenArrayExpToList(e);
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
  integers := matchcontinue(range)
    local
      list<DAE.Exp> arrayElements;
    case (DAE.ARRAY(array = arrayElements))
      then arrayElements;
    case (DAE.RANGE(exp = DAE.ICONST(integer = start), range = DAE.ICONST(integer = stop), expOption = NONE()))
      local
        Integer start, stop;
        list<Values.Value> vals;
      equation
        vals = Ceval.cevalRange(start, 1, stop);
        arrayElements = Util.listMap(vals, ValuesUtil.valueExp);
      then
        arrayElements;  
    case (_) then fail();
  end matchcontinue;
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
        print("equation_nth failed\n");
      then
        fail();
  end matchcontinue;
end equationNth;

public function equationSize "function: equationSize
  author: PA

  Returns the number of equations in an EquationArray, which
  corresponds to the number of equations in a system.
  NOTE: Array equations and algorithms are represented several times
  in the array so the number of elements of the array corresponds to
  the equation system size.
"
  input BackendDAE.EquationArray inEquationArray;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inEquationArray)
    local BackendDAE.Value n;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n)) then n;
  end matchcontinue;
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
  newElements := matchcontinue(clones, indices, iteratorExp)
    local
      DAE.Exp clone, newElement, newElement2, index;
      list<DAE.Exp> restClones, restIndices, elements;
    case ({}, {}, _) then {};
    case (clone :: restClones, index :: restIndices, _)
      equation
        (newElement, _) = Expression.replaceExp(clone, iteratorExp, index);
        newElement2 = simplifySubscripts(newElement);
        elements = generateArrayElements(restClones, restIndices, iteratorExp);
      then (newElement2 :: elements);
  end matchcontinue;
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
      DAE.Exp newCref;
      DAE.ComponentRef cref_;

    // A CREF => just simplify the subscripts.
    case (DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType))
      equation
        subscripts = Util.listMap(subscripts, simplifySubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
      then DAE.CREF(cref_, varType);
        
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
      then DAE.CREF(cref_, varType);
    case (_) then asub;
  end matchcontinue;
end simplifySubscripts;

protected function simplifySubscript
  input DAE.Subscript sub;
  output DAE.Subscript simplifiedSub;
algorithm
  simplifiedSub := matchcontinue(sub)
    case (DAE.INDEX(exp = e))
      local
        DAE.Exp e;
      equation
        e = ExpressionSimplify.simplify(e);
      then DAE.INDEX(e);
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
   Functions that deals with DAELow as input
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
             daeLow: DAELow,
             assignments1: int vector,
             assignments2: int vector,
             incidenceMatrix: IncidenceMatrix,
             incidenceMatrixT: IncidenceMatrixT)
  outputs: (dynamicBlocks: int list list, outputBlocks: int list list)
"
  input list<list<Integer>> inIntegerLstLst1;
  input BackendDAE.DAELow inDAELow2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix5;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT6;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6)
    local
      BackendDAE.Value size;
      array<BackendDAE.Value> arr,arr_1;
      list<list<BackendDAE.Value>> blt_states,blt_no_states,blt;
      BackendDAE.DAELow dae;
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      array<BackendDAE.Value> ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
    case (blt,(dae as BackendDAE.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al)),ass1,ass2,m,mt)
      equation
        size = arrayLength(ass1) "equation_size(e) => size &" ;
        arr = arrayCreate(size, 0);
        arr_1 = markStateEquations(dae, arr, m, mt, ass1, ass2);
        (blt_states,blt_no_states) = splitBlocks(blt, arr);
      then
        (blt_states,blt_no_states);
    case (_,_,_,_,_,_)
      equation
        print("-generate_state_partition failed\n");
      then
        fail();
  end matchcontinue;
end generateStatePartition;

protected function splitBlocks "function: splitBlocks

  Split the blocks into two parts, one dynamic and one output, depedning
  on if an equation in the block is marked or not.
  inputs:  (blocks: int list list, marks: int array)
  outputs: (dynamic: int list list, output: int list list)
"
  input list<list<Integer>> inIntegerLstLst;
  input array<Integer> inIntegerArray;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray)
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

  Return true if the block contains a variable that is marked
"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inIntegerLst,inIntegerArray)
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
  inputs: (daeLow: DAELow,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array
"
  input BackendDAE.DAELow inDAELow1;
  input array<Integer> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix3;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT4;
  input array<Integer> inIntegerArray5;
  input array<Integer> inIntegerArray6;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray:=
  matchcontinue (inDAELow1,inIntegerArray2,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<BackendDAE.Var> v_lst,statevar_lst;
      BackendDAE.DAELow dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
    case ((dae as BackendDAE.DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr,m,mt,a1,a2)
      equation
        v_lst = varList(v);
        statevar_lst = Util.listSelect(v_lst, BackendVariable.isStateVar);
        ((dae,arr_1,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr,m,mt,a1,a2));
      then
        arr_1;
    case (_,_,_,_,_,_)
      equation
        print("-mark_state_equations failed\n");
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
  input tuple<BackendDAE.DAELow, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<BackendDAE.DAELow, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<BackendDAE.Value> v_indxs,v_indxs_1,eqns;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      DAE.ComponentRef cr;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars;
      String s,str;
      BackendDAE.Value v_indx,v_indx_1;
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,v_indxs) = BackendVariable.getVar(cr, vars);
        v_indxs_1 = Util.listMap1(v_indxs, int_sub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,m,mt,a1,a2)) = markStateEquation2(eqns, (arr,m,mt,a1,a2));
      then
        ((dae,arr_1,m,mt,a1,a2));
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        print("mark_state_equation var ");
        s = ComponentReference.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,{v_indx}) = BackendVariable.getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(eqn = a1[v_indx_1 + 1]);
        print("mark_state_equation index =");
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
        print("mark_state_equation2 failed, eqn:");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length =");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value:");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

protected function invReachableNodes "function: invReachableNodes

  Similar to reachable_nodes, but follows edges in backward direction
  I.e. what equations/variables needs to be solved to solve this one.
"
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
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
        print("-inv_reachable_nodes failed, eqn:");
        eqn_str = intString(eqn);
        print(eqn_str);
        print("\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes;

protected function invReachableNodes2 "function: invReachableNodes2

  Helper function to inv_reachable_nodes
  inputs:  (variables: int list, assignments1: int vector)
  outputs: int list
"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIntegerLst,inIntegerArray)
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
        print("-inv_reachable_nodes2 failed\n");
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
  outIntegerLst:=
  matchcontinue (inIncidenceMatrixT,inInteger)
    local
      BackendDAE.Value n_1,n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> mt;
      String s;
    case (mt,n)
      equation
        n_1 = n - 1;
        res = mt[n_1 + 1];
        res_1 = Util.listMap(res, int_abs);
      then
        res_1;
    case (_,indx)
      equation
        print("eqnsForVarWithStates failed, indx=");
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
  outIntegerLst:=
  matchcontinue (inIncidenceMatrix,inInteger)
    local
      BackendDAE.Value n_1,n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> m;
      String s;
    case (m,n)
      equation
        n_1 = n - 1;
        res = m[n_1 + 1];
        res_1 = removeNegative(res);
      then
        res_1;
    case (_,indx)
      equation
        print("vars_in_eqn failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end varsInEqn;

public function subscript2dCombinations
"function: susbscript_2d_combinations
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
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
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
  end matchcontinue;
end subscript2dCombinations;

protected function subscript2dCombinations2
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLst,inExpSubscriptLstLst)
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
  end matchcontinue;
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
  String keystr;
algorithm
  keystr := ComponentReference.printComponentRefStr(key);
  v := treeGet2(bt, keystr);
end treeGet;

protected function treeGet2 "function: treeGet2
  author: PA

  Helper function to tree_get
"
  input BackendDAE.BinTree inBinTree;
  input String inString;
  output BackendDAE.Value outValue;
algorithm
  outValue:=
  matchcontinue (inBinTree,inString)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey;
      BackendDAE.Value rval,cmpval,res;
      Option<BackendDAE.BinTree> left,right;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),keystr)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),keystr)
      local BackendDAE.BinTree right;
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Search to the right" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet2(right, keystr);
      then
        res;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = SOME(left),rightSubTree = right),keystr)
      local BackendDAE.BinTree left;
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Search to the left" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet2(left, keystr);
      then
        res;
  end matchcontinue;
end treeGet2;

public function treeAddList "function: treeAddList
  author: Frenkel TUD
"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree :=
  matchcontinue (inBinTree,inKeyLst)
    local
      BackendDAE.Key key;
      list<BackendDAE.Key> res;
      BackendDAE.BinTree bt,bt_1,bt_2;
    case (bt,{}) then bt;
    case (bt,key::res)
      local DAE.ComponentRef nkey;
    equation
      bt_1 = treeAdd(bt,key,0);
      bt_2 = treeAddList(bt_1,res);
    then bt_2;  
  end matchcontinue;
end treeAddList;

public function treeAdd "function: treeAdd
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  input BackendDAE.Value inValue;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey,inValue)
    local
      DAE.ComponentRef key,rkey;
      BackendDAE.Value value,rval,cmpval;
      String rkeystr,keystr;
      Option<BackendDAE.BinTree> left,right;
      BackendDAE.BinTree t_1,t,right_1,left_1;
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),key,value)
      local DAE.ComponentRef nkey;
      equation
        nkey = key;
      then BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(nkey,value)),NONE(),NONE());
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),key,value)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Replace this node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,value)),left,right);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as NONE())),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as NONE()),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

protected function treeDelete "function: treeDelete
  author: PA

  This function deletes an entry from the BinTree.
"
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey)
    local
      BackendDAE.BinTree bt,right_1,right,t_1,t;
      DAE.ComponentRef key,rkey;
      String rkeystr,keystr;
      BackendDAE.TreeValue rightmost;
      Option<BackendDAE.BinTree> optright_1,left,lleft,lright,topt_1;
      BackendDAE.Value rval,cmpval;
      Option<BackendDAE.TreeValue> leftval;
    case ((bt as BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE())),key) then bt;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when existing right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
        (rightmost,right_1) = treeDeleteRightmostValue(right);
        optright_1 = treePruneEmptyNodes(right_1);
      then
        BackendDAE.TREENODE(SOME(rightmost),left,optright_1);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = SOME(BackendDAE.TREENODE(leftval,lleft,lright)),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no right node, but left node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(leftval,lleft,lright);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = NONE(),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no left or right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(NONE(),NONE(),NONE());
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key)
      local Option<BackendDAE.BinTree> right;
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in right subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,topt_1);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key)
      local Option<BackendDAE.BinTree> right;
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in left subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),topt_1,right);
    case (_,_)
      equation
        print("tree_delete failed\n");
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
  (outTreeValue,outBinTree):=
  matchcontinue (inBinTree)
    local
      BackendDAE.TreeValue treevalue,value;
      BackendDAE.BinTree left,right_1,right,bt;
      Option<BackendDAE.BinTree> rightopt_1;
      Option<BackendDAE.TreeValue> treeval;
    case (BackendDAE.TREENODE(value = SOME(treevalue),leftSubTree = NONE(),rightSubTree = NONE())) then (treevalue,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    case (BackendDAE.TREENODE(value = SOME(treevalue),leftSubTree = SOME(left),rightSubTree = NONE())) then (treevalue,left);
    case (BackendDAE.TREENODE(value = treeval,leftSubTree = left,rightSubTree = SOME(right)))
      local Option<BackendDAE.BinTree> left;
      equation
        (value,right_1) = treeDeleteRightmostValue(right);
        rightopt_1 = treePruneEmptyNodes(right_1);
      then
        (value,BackendDAE.TREENODE(treeval,left,rightopt_1));
    case (BackendDAE.TREENODE(value = SOME(treeval),leftSubTree = NONE(),rightSubTree = SOME(right)))
      local BackendDAE.TreeValue treeval;
      equation
        failure((_,_) = treeDeleteRightmostValue(right));
        print("right value was empty , left NONE\n");
      then
        (treeval,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    case (bt)
      equation
        print("-tree_delete_rightmost_value failed\n");
      then
        fail();
  end matchcontinue;
end treeDeleteRightmostValue;

protected function treePruneEmptyNodes "function: tree_prune_emtpy_nodes
  author: PA

  This function is a helper function to tree_delete
  It is used to delete empty nodes of the BackendDAE.BinTree representation, that might be introduced
  when deleting nodes.
"
  input BackendDAE.BinTree inBinTree;
  output Option<BackendDAE.BinTree> outBinTreeOption;
algorithm
  outBinTreeOption:=
  matchcontinue (inBinTree)
    local BackendDAE.BinTree bt;
    case BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()) then NONE();
    case bt then SOME(bt);
  end matchcontinue;
end treePruneEmptyNodes;

protected function bintreeDepth "function: bintreeDepth
  author: PA

  This function calculates the depth of the Binary Tree given
  as input. It can be used for debugging purposes to investigate
  how balanced binary trees are.
"
  input BackendDAE.BinTree inBinTree;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinTree)
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
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Expression.traverseExp(inExp, traversingextendArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
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
    DAE.Exp e,e_new;
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
  case( (e as DAE.CREF(componentRef=cr,ty= t as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_))), funcs) )
    equation
        expl = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e);
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

public function collateArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Expression.traverseExp(inExp, traversingcollateArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
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
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr))),_)::_)::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));        
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.CREF(componentRef = cr))::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Expression.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));  
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr)))::_),funcs))
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
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
    case(DAE.DIM_UNKNOWN::dims) 
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
  outSubs := matchcontinue(inRange)
  local 
    Integer i;
    list<Integer> res;
    list<DAE.Subscript> range;
    case({}) then {};
    case(i::res) 
      equation
        range = rangesToSubscript(res);
      then DAE.INDEX(DAE.ICONST(i))::range;
  end matchcontinue;
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
  outSubslst := matchcontinue(inSub,inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    DAE.Subscript sub;
    case(sub,rangelist)
      equation
      rangelist1 = Util.listMap1r(rangelist,Util.listAddElementFirst,sub);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts1;

end BackendDAEUtil;
