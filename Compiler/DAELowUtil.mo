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

package DAELowUtil
" file:	       DAELowUtil.mo
  package:     DAELowUtil 
  description: DAELowUtil comprised functions for DAELow data types.

  RCS: $Id: DAELowUtil.mo 6426 2010-10-19 08:01:48Z adrpo $

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

public import DAE;
public import Exp;
public import Util;
public import DAELow;

protected import Debug;

public function checkDEALowWithErrorMsg"function: checkDEALowWithErrorMsg
  author: Frenkel TUD
  run checkDEALow and prints all errors"
  input DAELow.DAELow inDAELow;
  list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expCrefs;
algorithm  
  expCrefs := checkDEALow(inDAELow);
  printcheckDEALowWithErrorMsg(expCrefs);
end checkDEALowWithErrorMsg;
 
public function printcheckDEALowWithErrorMsg"function: printcheckDEALowWithErrorMsg
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
          strcrefs = Util.listMap(crefs,Exp.crefStr);
          print(Util.stringDelimitList(strcrefs,", "));print("\nnot found in DAELow object.\n");
          printcheckDEALowWithErrorMsg(res);
        then
          ();
  end matchcontinue;
end printcheckDEALowWithErrorMsg;      
      
public function checkDEALow "function: checkDEALow
  author: Frenkel TUD

  This function checks the DAELow object if 
  all component refercences used in the expressions are 
  part of the DAELow object. Returns all component references
  which not part of the DAELow object. 
"
  input DAELow.DAELow inDAELow;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outBool:=
  matchcontinue (inDAELow)
    local
      DAELow.Variables vars1,vars2,allvars;
      list<DAELow.Var> varlst1,varlst2,allvarslst;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcrefs;
    case (DAELow.DAELOW(orderedVars = vars1,knownVars = vars2))
      equation
        varlst1 = DAELow.varList(vars1);
        varlst2 = DAELow.varList(vars2);
        allvarslst = listAppend(varlst1,varlst2);
        allvars = DAELow.listVar(allvarslst);
        expcrefs = DAELow.traverseDEALowExps(inDAELow,checkDEALowExp,allvars);
      then
        expcrefs;
    case (_)
      equation
        Debug.fprintln("failtrace", "- DAELowUtil.checkDEALow failed");
      then
        fail();
  end matchcontinue;
end checkDEALow;

protected function checkDEALowExp
  input DAE.Exp inExp;
  input DAELow.Variables inVars;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
algorithm
  outExpCrefs :=
  matchcontinue (inExp,inVars)
    local  
      DAE.Exp exp;
      DAELow.Variables vars;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> lstExpCrefs;
    case (exp,vars)
      equation
        ((_,(_,crefs))) = Exp.traverseExp(exp,traversecheckDEALowExp,((vars,{})));
        lstExpCrefs = Util.if_(listLength(crefs)>0,{(exp,crefs)},{});
       then
        lstExpCrefs;
  end matchcontinue;      
end checkDEALowExp;

protected function traversecheckDEALowExp
	input tuple<DAE.Exp, tuple<DAELow.Variables,list<DAE.ComponentRef>>> inTuple;
	output tuple<DAE.Exp, tuple<DAELow.Variables,list<DAE.ComponentRef>>> outTuple;
algorithm
	outTuple := matchcontinue(inTuple)
		local
			DAE.Exp e;
			DAELow.Variables vars;
			DAE.ComponentRef cr;
			list<DAE.ComponentRef> crefs;
		case ((e as (DAE.CREF(DAE.CREF_IDENT("time",_,_), _)),(vars,crefs)))
		  then
		    ((e, (vars,crefs)));
		case ((e as (DAE.CREF(cr, _)),(vars,crefs)))
		  equation
		     (_,_) = DAELow.getVar(cr, vars);
		  then
		    ((e, (vars,crefs)));
		case ((e as (DAE.CREF(cr, _)),(vars,crefs)))
		  equation
		     failure((_,_) = DAELow.getVar(cr, vars));
		  then
		    ((e, (vars,cr::crefs)));
		case (_) then inTuple;
	end matchcontinue;
end traversecheckDEALowExp;

end DAELowUtil;
