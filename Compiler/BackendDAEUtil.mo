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
public import ComponentReference;
public import Exp;
public import Util;

protected import Absyn;
protected import DAELow;
protected import Debug;
protected import HashTable2;
protected import Values;
protected import ValuesUtil;
protected import Ceval;

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
      case ({}) then ();
      case (((e,crefs))::res)
        equation
          print("Error in Exp ");
          print(Exp.printExpStr(e));print("\n Variables: ");
          strcrefs = Util.listMap(crefs,ComponentReference.crefStr);
          print(Util.stringDelimitList(strcrefs,", "));print("\nnot found in BackendDAE object.\n");
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
        expcrefs = DAELow.traverseDEALowExps(inBackendDAE,false,checkBackendDAEExp,allvars);
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
        ((_,(_,crefs))) = Exp.traverseExpTopDown(exp,traversecheckBackendDAEExp,((vars,{})));
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
		case ((e as DAE.REDUCTION(ident = ident),(vars,crefs)))
		  local 
		    DAE.Ident ident;
		    BackendDAE.Var  var;
		  equation
		    // add ident to vars
		    cr = ComponentReference.makeCrefIdent(ident,DAE.ET_INT(),{});
		    var = BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.INT(),NONE(),NONE(),{},0,
		          DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
		    vars = DAELow.addVar(var,vars);
		  then
		    ((e, (vars,crefs)));
		case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
		  equation
		     (_,_) = DAELow.getVar(cr, vars);
		  then
		    ((e, (vars,crefs)));
		case ((e as DAE.CREF(componentRef = cr),(vars,crefs)))
		  equation
		     failure((_,_) = DAELow.getVar(cr, vars));
		  then
		    ((e, (vars,cr::crefs)));
		case (_) then inTuple;
	end matchcontinue;
end traversecheckBackendDAEExp;

/*
 * Util function at Backend using for lowering and other stuff
 */
 
public function states
"function: states
  Returns a BackendDAE.BinTree of all states in the DAE.
  This function is used by the lower function."
  input list<DAE.Element> inElems;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inElems,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2;
      list<DAE.Element> xs;
      DAE.DAElist dae;
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case ({},bt) then bt;

    case (DAE.EQUATION(exp = e1,scalar = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIALEQUATION(exp1 = e1, exp2 = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DEFINE(componentRef = _, exp = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIALDEFINE(componentRef = _, exp = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2) :: xs, bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.COMP(dAElist = daeElts) :: xs,bt)
      equation
        bt = states(daeElts, bt);
        bt = states(xs, bt);
      then
        bt;

    case (_ :: xs,bt)
      equation
        bt = states(xs, bt);
      then
        bt;
  end matchcontinue;
end states;

public function statesExp
"function: statesExp
  Helper function to states."
  input DAE.Exp inExp;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inExp,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2,e,e3;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Exp> expl;
      list<list<tuple<DAE.Exp, Boolean>>> m;

    case (DAE.BINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.UNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.LUNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
        bt = statesExp(e3, bt);
      then
        bt;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt)
      equation
        //cr_1 = Exp.stringifyComponentRef(cr) "value irrelevant, give zero" ;
        bt = DAELow.treeAdd(bt, cr, 0);
      then
        bt;
    case (DAE.CALL(expLst = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.ARRAY(array = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.MATRIX(scalar = m),bt)
      equation
        bt = statesExpMatrix(m, bt);
      then
        bt;
    case (DAE.TUPLE(PR = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.CAST(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.ASUB(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.REDUCTION(expr = e1,range = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (_,bt) then bt;
  end matchcontinue;
end statesExp;

protected function statesExpMatrix
"function: statesExpMatrix
  author: PA
  Helper function to statesExp. Deals with matrix exp list."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inTplExpExpBooleanLstLst,inBinTree)
    local
      list<list<DAE.Exp>> expl_1;
      list<DAE.Exp> expl_2;
      BackendDAE.BinTree bt;
      list<list<tuple<DAE.Exp, Boolean>>> expl;

    case (expl,bt)
      equation
        expl_1 = Util.listListMap(expl, Util.tuple21);
        expl_2 = Util.listFlatten(expl_1);
        bt = Util.listFold(expl_2, statesExp, bt);
      then
        bt;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-states_exp_matrix failed\n");
      then
        fail();
  end matchcontinue;
end statesExpMatrix;

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
        vars_1 = DAELow.addVar(v, vars);
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
        ((BackendDAE.VAR(varKind = kind) :: _),_) = DAELow.getVar(cr, vars);
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
        failure((_,_) = DAELow.getVar(cr, vars));
        (v::_,_) = DAELow.getVar(cr,knvars);
        true = isInput(v);
      then
        false;

        /* parameters & constants */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        failure((_,_) = DAELow.getVar(cr, vars));
        ((BackendDAE.VAR(varKind = kind) :: _),_) = DAELow.getVar(cr, knvars);
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
        DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr);
        expl = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e);
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;  
    /* Special Case for unextended arrays */
    case ((e as DAE.CREF(componentRef = cr,ty = DAE.ET_ARRAY(arrayDimensions=_))),vars)
      equation
        (e1,_) = DAELow.extendArrExp(e,NONE());
        res = statesAndVarsExp(e1, vars);
      then
        res; 
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),vars)
      equation
        (_,_) = DAELow.getVar(cr, vars);
      then
        {e};
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
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
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
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
        res = Util.listListUnionOnTrue({s1,s2,s3}, Exp.expEqual);
      then
        res;
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = DAELow.getVar(cr, vars);
      then
        {e};
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = DAELow.getVar(cr, vars);
      then
        {};
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.PARTEVALFUNCTION(expList = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
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
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
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
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
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
        // Debug.fprintln("daelow", "- DAELow.statesAndVarsExp failed to extract states or vars from expression: " +& Exp.dumpExpStr(e,0));
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
        res = Util.listListUnionOnTrue((ms_1 :: lst), Exp.expEqual);
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
        subscript_exprs = Util.listMap(subscripts, Exp.subscriptExp);
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
        true = Exp.expContains(subscript, iteratorExp);
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
        (arrayElements, _) = DAELow.getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, DAELow.varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (arrayElements, _) = DAELow.getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, DAELow.varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;
      
    case (DAE.ASUB(exp = e), _, _, _)
      local DAE.Exp e;
      equation
        varExprs = Exp.flattenArrayExpToList(e);
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
        (newElement, _) = Exp.replaceExp(clone, iteratorExp, index);
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
        {} = Util.listSelect(subExprs, Exp.isNotConst);
        // If a subscript is not a single constant value it needs to be
        // simplified, e.g. cref[3+4] => cref[7], otherwise some subscripts
        // might be counted twice, such as cref[3+4] and cref[2+5], even though
        // they reference the same element.
        subExprsSimplified = Util.listMap(subExprs, Exp.simplify);
        subscripts = Util.listMap(subExprsSimplified, Exp.makeIndexSubscript);
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
        e = Exp.simplify(e);
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

end BackendDAEUtil;
