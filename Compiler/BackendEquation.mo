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

package BackendEquation
" file:	       BackendEquation.mo
  package:     BackendEquation
  description: BackendEquation contains functions that do something with
               BackendDAEEquation datatype.


"

public import BackendDAE;
public import DAE;

protected import Algorithm;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendVarTransform;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Util;


public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp):=
  matchcontinue (inWhenEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
    case (BackendDAE.WHEN_EQ(left = cr,right = e)) then (cr,e);
  end matchcontinue;
end getWhenEquationExpr;

public function getWhenCondition
"function: getWhenCodition
  Get expression's of condition by when equation"
  input list<BackendDAE.WhenClause> inWhenClause;
  input Integer inIndex;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := matchcontinue (inWhenClause, inIndex)
    local
      list<BackendDAE.WhenClause> wc;
      Integer ind;
      list<DAE.Exp> condlst;
      DAE.Exp e;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,condlst)) = listNth(wc, ind);
      then condlst;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=e) = listNth(wc, ind);
      then {e};
  end matchcontinue;
end getWhenCondition;

public function getZeroCrossingIndicesFromWhenClause "function: getZeroCrossingIndicesFromWhenClause
  Returns a list of indices of zerocrossings that a given when clause is dependent on.
"
  input BackendDAE.DAELow inDAELow;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inDAELow,inInteger)
    local
      list<BackendDAE.Value> res;
      list<BackendDAE.ZeroCrossing> zcLst;
      BackendDAE.Value when_index;
    case (BackendDAE.DAELOW(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst)),when_index)
      equation
        res = getZeroCrossingIndicesFromWhenClause2(zcLst, 0, when_index);
      then
        res;
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause;

protected function getZeroCrossingIndicesFromWhenClause2 "function: getZeroCrossingIndicesFromWhenClause2
  helper function to get_zero_crossing_indices_from_when_clause
"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inZeroCrossingLst1,inInteger2,inInteger3)
    local
      BackendDAE.Value count_1,count,when_index;
      list<BackendDAE.Value> resx,whenClauseList;
      list<BackendDAE.ZeroCrossing> rest;
    case ({},_,_) then {};
    case ((BackendDAE.ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        _ = Util.listGetMember(when_index, whenClauseList);
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        (count :: resx);
    case ((BackendDAE.ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        failure(_ = Util.listGetMember(when_index, whenClauseList));
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        resx;
    case (_,_,_)
      equation
        print("-get_zero_crossing_indices_from_when_clause2 failed\n");
      then
        fail();
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause2;




end BackendEquation;
