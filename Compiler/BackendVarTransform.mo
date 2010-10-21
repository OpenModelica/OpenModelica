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

package BackendVarTransform
" file:	       BackendVarTransform.mo
  package:     BackendVarTransform
  description: BackendVarTransform contains a Binary Tree representation of variable replacements.

  RCS: $Id$

  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import DAE;
public import DAELow;
public import VarTransform;

protected import Absyn;
protected import Exp;
protected import Util;

public function replaceEquations
"function: replaceEquations
  This function takes a list of equations ana a set of variable
  replacements and applies the replacements on all equations.
  The function returns the updated list of equations"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2,e_1,e_2,e;
      list<DAELow.Equation> es_1,es;
      VarTransform.VariableReplacements repl;
      DAELow.Equation a;
      DAE.ComponentRef cr;
      Integer indx;
      list<DAE.Exp> expl,expl1,expl2,expl3,expl4;
      DAELow.WhenEquation whenEqn,whenEqn1;
      DAE.ElementSource source "the origin of the element";
      list<list<DAE.Exp>> explstlst;

    case ({},_) then {};
    case ((DAELow.ARRAY_EQUATION(indx,expl,source)::es),repl)
      equation
        expl1 = Util.listMap2(expl,VarTransform.replaceExp,repl,NONE());
        expl2 = Util.listMap(expl1,Exp.simplify);
        es_1 = replaceEquations(es,repl);
      then
         (DAELow.ARRAY_EQUATION(indx,expl2,source)::es_1);

    case ((DAELow.EQUATION(exp = e1,scalar = e2,source = source) :: es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.EQUATION(e1_2,e2_2,source) :: es_1);

    case (((DAELow.ALGORITHM(index=indx,in_=expl,out=expl1,source = source)) :: es),repl)
      equation
        // original algorithm is done by replaceAlgorithms
        // inputs and ouputs are updated from DEALow.updateAlgorithmInputsOutputs       
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.ALGORITHM(indx,expl,expl1,source) :: es_1);

    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = e,source = source) :: es),repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.SOLVED_EQUATION(cr,e_2,source) :: es_1);

    case ((DAELow.RESIDUAL_EQUATION(exp = e,source = source) :: es),repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.RESIDUAL_EQUATION(e_2,source) :: es_1);

    case ((DAELow.WHEN_EQUATION(whenEqn,source) :: es),repl)
      equation
				whenEqn1 = replaceWhenEquation(whenEqn,repl);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.WHEN_EQUATION(whenEqn1,source) :: es_1);

    case ((a :: es),repl)
      equation
        es_1 = replaceEquations(es, repl);
      then
        (a :: es_1);
  end matchcontinue;
end replaceEquations;

protected function replaceWhenEquation "Replaces variables in a when equation"
	input DAELow.WhenEquation whenEqn;
  input VarTransform.VariableReplacements repl;
  output DAELow.WhenEquation outWhenEqn;
algorithm
  outWhenEqn := matchcontinue(whenEqn,repl)
  local Integer i;
    DAE.ComponentRef cr,cr1;
    DAE.Exp e,e1,e2;
    DAE.ExpType tp;
    DAELow.WhenEquation elsePart,elsePart2;

    case (DAELow.WHEN_EQ(i,cr,e,NONE()),repl) equation
        e1 = VarTransform.replaceExp(e, repl, NONE);
        e2 = Exp.simplify(e1);
        DAE.CREF(cr1,_) = VarTransform.replaceExp(DAE.CREF(cr,DAE.ET_OTHER()),repl,NONE());
    then DAELow.WHEN_EQ(i,cr1,e2,NONE());

			// Replacements makes cr negative, a = -b
	  case (DAELow.WHEN_EQ(i,cr,e,NONE()),repl) equation
        DAE.UNARY(DAE.UMINUS(tp),DAE.CREF(cr1,_)) = VarTransform.replaceExp(DAE.CREF(cr,DAE.ET_OTHER()),repl,NONE());
        e1 = VarTransform.replaceExp(e, repl, NONE);
        e2 = Exp.simplify(DAE.UNARY(DAE.UMINUS(tp),e1));
    then DAELow.WHEN_EQ(i,cr1,e2,NONE());

    case (DAELow.WHEN_EQ(i,cr,e,SOME(elsePart)),repl) equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        e1 = VarTransform.replaceExp(e, repl, NONE);
        e2 = Exp.simplify(e1);
        DAE.CREF(cr1,_) = VarTransform.replaceExp(DAE.CREF(cr,DAE.ET_OTHER()),repl,NONE());
    then DAELow.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

			// Replacements makes cr negative, a = -b
	  case (DAELow.WHEN_EQ(i,cr,e,SOME(elsePart)),repl) equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        DAE.UNARY(DAE.UMINUS(tp),DAE.CREF(cr1,_)) = VarTransform.replaceExp(DAE.CREF(cr,DAE.ET_OTHER()),repl,NONE());
        e1 = VarTransform.replaceExp(e, repl, NONE);
        e2 = Exp.simplify(DAE.UNARY(DAE.UMINUS(tp),e1));
    then DAELow.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

  end matchcontinue;
end replaceWhenEquation;

/*
public function replaceEquations "function: replaceEquations

  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all equations.
  The function returns the updated list of equations
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2,e_1,e_2,e;
      list<DAELow.Equation> es_1,es;
      VarTransform.VariableReplacements repl;
      DAELow.Equation a;
      DAE.ComponentRef cr,cr1,cr2;
      Integer indx;
      list<DAE.Exp> expl,expl1,expl2;
      DAELow.WhenEquation whenEqn,whenEqn1;
    case ({},_) then {};
    case ((DAELow.ARRAY_EQUATION(indx,expl)::es),repl)
      equation
        expl1 = Util.listMap2(expl,VarTransform.replaceExp,repl,NONE());
        expl2 = Util.listMap(expl1,Exp.simplify);
        es_1 = replaceEquations(es,repl);
      then
         (DAELow.ARRAY_EQUATION(indx,expl2)::es_1);
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.EQUATION(e1_2,e2_2) :: es_1);
     case ((DAELow.EQUEQUATION(cr1,cr2) :: es),repl)
      equation
        DAE.CREF(cr1,_) = VarTransform.replaceExp(DAE.CREF(cr1,DAE.ET_OTHER()), repl, NONE);
        DAE.CREF(cr2,_) = VarTransform.replaceExp(DAE.CREF(cr2,DAE.ET_OTHER()), repl, NONE);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.EQUEQUATION(cr1,cr2) :: es_1);
    case (((a as DAELow.ALGORITHM(index = id,in_ = expl1,out = expl2)) :: es),repl)
      local Integer id;
      equation
        expl1 = Util.listMap2(expl1,VarTransform.replaceExp,repl,NONE());
        expl1 = Util.listMap(expl1,Exp.simplify);
        expl2 = Util.listMap2(expl2,VarTransform.replaceExp,repl,NONE());
        expl2 = Util.listMap(expl2,Exp.simplify);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.ALGORITHM(id,expl1,expl2) :: es_1);
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = e) :: es),repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.SOLVED_EQUATION(cr,e_2) :: es_1);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),repl)
      equation
        e_1 = VarTransform.replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.RESIDUAL_EQUATION(e_2) :: es_1);

    case ((DAELow.WHEN_EQUATION(whenEqn) :: es),repl)
      equation
				whenEqn1 = replaceWhenEquation(whenEqn,repl);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.WHEN_EQUATION(whenEqn1) :: es_1);

   case ((DAELow.IF_EQUATION(indx,eindx,expl) :: es),repl)
     local Integer indx,eindx;
      equation
        expl1 = Util.listMap2(expl,VarTransform.replaceExp,repl,NONE());
        expl2 = Util.listMap(expl1,Exp.simplify);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.IF_EQUATION(indx,eindx,expl2) :: es_1);

    case ((a :: es),repl)
      equation
        es_1 = replaceEquations(es, repl);
      then
        (a :: es_1);
  end matchcontinue;
end replaceEquations;
*/
/*
protected function replaceWhenEquation "Replaces variables in a when equation"
	input DAELow.WhenEquation whenEqn;
  input VarTransform.VariableReplacements repl;
  output DAELow.WhenEquation outWhenEqn;
algorithm
  outWhenEqn := matchcontinue(whenEqn,repl)
  local Integer i;
    DAE.Exp e,e1,e2,cond;
    DAELow.WhenEquation elsePart,elsePart2;
    DAELow.Equation eq;
    case (DAELow.WHEN_EQ(i,_,cond,eq,NONE()),repl)
      equation
        {eq as DAELow.EQUATION(e1,e2)} = replaceEquations({eq},repl);
        (e1,e2) = shiftUnaryMinusToRHS(e1,e2);
    then DAELow.WHEN_EQ(i,cond,DAELow.EQUATION(e1,e2),NONE());
    case (DAELow.WHEN_EQ(i,cond,eq,SOME(elsePart)),repl) equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
      {eq as DAELow.EQUATION(e1,e2)} = replaceEquations({eq},repl);
      (e1,e2) = shiftUnaryMinusToRHS(e1,e2);
    then DAELow.WHEN_EQ(i,cond,DAELow.EQUATION(e1,e2),SOME(elsePart2));
  end matchcontinue;
end replaceWhenEquation;
*/

protected function shiftUnaryMinusToRHS "
Author: BZ, 2008-09
Helper function for replaceWhenEquation, moves possible unary minus from lefthand side to right hand side.
"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Exp lhsFixed,rhsFixed;
algorithm (lhsFixed,rhsFixed) := matchcontinue(lhs,rhs)
  local
    DAE.ExpType tp;
    DAE.Exp e1,e2;
  case((e1 as DAE.CREF(_,_)),e2) then (e1,e2);
  case(DAE.UNARY(DAE.UMINUS(tp),e1),e2)
    equation
      e2 = Exp.simplify(DAE.UNARY(DAE.UMINUS(tp),e2));
    then
      (e1,e2);
end matchcontinue;
end shiftUnaryMinusToRHS;

/*
public function replaceIfEquations "This function takes a list of if-equations and a set of
variable replacement sand applies the replacements on all if-equations.
The function returns the updated list of if-equations."
  input list<DAELow.IfEquation> ifeqns;
  input VarTransform.VariableReplacements repl;
  output list<DAELow.IfEquation> outIfeqns;
algorithm
  outIfeqns := matchcontinue(ifeqns,repl)
  local list<DAE.Exp> conds,conds1;
    list<DAELow.Equation> fb,fb1;
    list<list<DAELow.Equation>> tbs,tbs1;
    list<DAELow.IfEquation> es;
    case ({},_) then {};

    case(DAELow.IFEQUATION(conds,tbs,fb) :: es,repl) equation
       conds1 = Util.listMap2(conds, VarTransform.replaceExp, repl, NONE);
        tbs1 = Util.listMap1(tbs,replaceEquations,repl);
        fb1 = replaceEquations(fb,repl);
        es = replaceIfEquations(es,repl);
     then DAELow.IFEQUATION(conds1, tbs1,fb1)::es;

    case(_,_) equation
      Debug.fprint("failtrace","replaceIfEquations failed\n");
    then fail();

  end matchcontinue;
end replaceIfEquations;
*/

public function replaceMultiDimEquations "function: replaceMultiDimEquations

  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<DAELow.MultiDimEquation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.MultiDimEquation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e,e1_2,e2_2;
      list<DAELow.MultiDimEquation> es_1,es;
      VarTransform.VariableReplacements repl;
      DAELow.Equation a;
      DAE.ComponentRef cr;
      list<Integer> dims;
      DAE.ElementSource source "the origin of the element";

    case ({},_) then {};
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2,dimSize = dims,source=source) :: es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceMultiDimEquations(es, repl);
      then
        (DAELow.MULTIDIM_EQUATION(dims,e1_2,e2_2,source) :: es_1);
  end matchcontinue;
end replaceMultiDimEquations;

public function replaceAlgorithms "function: replaceAlgorithms

  This function takes a list of algorithms ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<DAE.Algorithm> inAlgorithmLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAE.Algorithm> outAlgorithmLst;
algorithm
  outAlgorithmLst:=
  matchcontinue (inAlgorithmLst,inVariableReplacements)
    local
      VarTransform.VariableReplacements repl;
      list<DAE.Statement> statementLst,statementLst_1;
      list<DAE.Algorithm> es,es_1;
    case ({},_) then {};
    case ((DAE.ALGORITHM_STMTS(statementLst=statementLst) :: es),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst,repl);
        es_1 = replaceAlgorithms(es,repl);
      then
        (DAE.ALGORITHM_STMTS(statementLst_1)  :: es_1);
  end matchcontinue;
end replaceAlgorithms;

protected function replaceStatementLst "function: replaceStatementLst

  Helper for replaceMultiDimEquations.
"
  input list<DAE.Statement> inStatementLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAE.Statement> outStatementLst;
algorithm
  outStatementLst:=
  matchcontinue (inStatementLst,inVariableReplacements)
    local
      VarTransform.VariableReplacements repl;
      list<DAE.Statement> es,es_1,statementLst,statementLst_1;
      DAE.Statement statement,statement_1;
      DAE.ExpType type_;
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e,e1_2,e2_2;
      list<DAE.Exp> expExpLst,expExpLst_1,inputExps;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
      String str;
      Absyn.MatchType matchType;
    case ({},_) then {};
    case ((DAE.STMT_ASSIGN(type_=type_,exp1=e1,exp=e2,source=source)::es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSIGN(type_,e1_2,e2_2,source):: es_1);
    case ((DAE.STMT_TUPLE_ASSIGN(type_=type_,expExpLst=expExpLst,exp=e2,source=source)::es),repl)
      equation
        expExpLst_1 = Util.listMap2(expExpLst,VarTransform.replaceExp,repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TUPLE_ASSIGN(type_,expExpLst_1,e2_2,source):: es_1);
    case ((DAE.STMT_ASSIGN_ARR(type_=type_,componentRef=cr,exp=e1,source=source)::es),repl)
      local DAE.ComponentRef cr;
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSIGN_ARR(type_,cr,e1_2,source):: es_1);        
    case ((DAE.STMT_IF(exp=e1,statementLst=statementLst,else_=else_,source=source)::es),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        else_1 = replaceElse(else_,repl);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_IF(e1_2,statementLst_1,else_1,source):: es_1);
    case ((DAE.STMT_FOR(type_=type_,iterIsArray=iterIsArray,ident=ident,exp=e1,statementLst=statementLst,source=source)::es),repl)
      local 
        Boolean iterIsArray;
        DAE.Ident ident;
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_FOR(type_,iterIsArray,ident,e1_2,statementLst_1,source):: es_1);        
    case ((DAE.STMT_WHILE(exp=e1,statementLst=statementLst,source=source)::es),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHILE(e1_2,statementLst_1,source):: es_1);
    case ((DAE.STMT_WHEN(exp=e1,statementLst=statementLst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::es),repl)
      local list<Integer> helpVarIndices;
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHEN(e1_2,statementLst_1,NONE(),helpVarIndices,source):: es_1);
    case ((DAE.STMT_WHEN(exp=e1,statementLst=statementLst,elseWhen=SOME(statement),helpVarIndices=helpVarIndices,source=source)::es),repl)
      local list<Integer> helpVarIndices;
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        statement_1::{} = replaceStatementLst({statement}, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHEN(e1_2,statementLst_1,SOME(statement_1),helpVarIndices,source):: es_1);
    case ((DAE.STMT_ASSERT(cond=e1,msg=e2,source=source)::es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSERT(e1_2,e2_2,source):: es_1);
    case ((DAE.STMT_TERMINATE(msg=e1,source=source)::es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TERMINATE(e1_2,source):: es_1);
    case ((DAE.STMT_REINIT(var=e1,value=e2,source=source)::es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e2_1 = VarTransform.replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_REINIT(e1_2,e2_2,source):: es_1);
    case ((DAE.STMT_NORETCALL(exp=e1,source=source)::es),repl)
      equation
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_NORETCALL(e1_2,source):: es_1);
    case ((DAE.STMT_RETURN(source=source)::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_RETURN(source):: es_1);      
    case ((DAE.STMT_BREAK(source=source)::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_BREAK(source):: es_1);      
  // MetaModelica extension. KS
    case ((DAE.STMT_TRY(tryBody=statementLst,source=source)::es),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TRY(statementLst_1,source):: es_1);
    case ((DAE.STMT_CATCH(catchBody=statementLst,source=source)::es),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_CATCH(statementLst_1,source):: es_1);
    case ((DAE.STMT_THROW(source=source)::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_THROW(source):: es_1); 
    case ((DAE.STMT_GOTO(labelName=str,source=source)::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_GOTO(str,source):: es_1); 
    case ((DAE.STMT_LABEL(labelName=str,source=source)::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_LABEL(str,source):: es_1); 
    case ((DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=expExpLst,source=source)::es),repl)
      equation
        inputExps = Util.listMap2(inputExps,VarTransform.replaceExp,repl, NONE);
        expExpLst_1 = Util.listMap2(expExpLst,VarTransform.replaceExp,repl, NONE);
        es_1 = replaceStatementLst(es, repl);
      then
        (DAE.STMT_MATCHCASES(matchType,inputExps,expExpLst_1,source):: es_1);
    case ((statement::es),repl) 
      equation
        es_1 = replaceStatementLst(es, repl);
      then
        (statement:: es_1);        
  end matchcontinue;
end replaceStatementLst;

protected function replaceElse "function: replaceElse

  Helper for replaceStatementLst.
"
  input DAE.Else inElse;
  input VarTransform.VariableReplacements inVariableReplacements;
  output DAE.Else outElse;
algorithm
  outElse:=
  matchcontinue (inElse,inVariableReplacements)
    local
      VarTransform.VariableReplacements repl;
      list<DAE.Statement> statementLst,statementLst_1;
      DAE.Exp e1,e1_1,e1_2;
      list<DAE.Exp> expExpLst,expExpLst_1;
      DAE.Else else_,else_1;
    case (DAE.NOELSE(),_) then DAE.NOELSE();
    case (DAE.ELSEIF(exp=e1,statementLst=statementLst,else_=else_),repl)
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
        e1_1 = VarTransform.replaceExp(e1, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        else_1 = replaceElse(else_,repl);
      then
        DAE.ELSEIF(e1_2,statementLst_1,else_1);
    case (DAE.ELSE(statementLst=statementLst),repl) 
      equation
        statementLst_1 = replaceStatementLst(statementLst, repl);
      then
        DAE.ELSE(statementLst_1);      
  end matchcontinue;
end replaceElse;

end BackendVarTransform;
