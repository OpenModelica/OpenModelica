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

encapsulated package BackendDAETransform
" file:        BackendDAETransform.mo
  package:     BackendDAETransform
  description: BackendDAETransform contains functions that are needed to perform
               a transformation to a Block-Lower-Triangular-DAE.
               - matchingAlgorithm
               - strongComponents
               - reduceIndexDummyDer


  RCS: $Id$
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendDAEOptimize;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import SCode;
protected import System;
protected import Util;
protected import Values;

/******************************************
 strongComponents and stuff
 *****************************************/

public function strongComponentsScalar "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.StrongComponents outComps;
algorithm
  (osyst,outComps) :=
  matchcontinue (syst,shared,mapEqnIncRow,mapIncRowEqn)
    local
      list<list<Integer>> comps;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.StrongComponents comps1;
      BackendDAE.EquationArray eqs;
      BackendDAE.Variables vars;
      array<Integer> markarray;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(vars,eqs,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1=ass1,ass2=ass2),stateSets=stateSets),_,_,_)
      equation
        comps = tarjanAlgorithm(mt,ass2);
        markarray = arrayCreate(BackendDAEUtil.equationArraySize(eqs),-1);
        comps1 = analyseStrongComponentsScalar(comps,syst,shared,ass1,ass2,mapEqnIncRow,mapIncRowEqn,1,markarray,{});
        ass1 = varAssignmentNonScalar(1,arrayLength(ass1),ass1,mapIncRowEqn,{});
        //noscalass2 = eqnAssignmentNonScalar(1,arrayLength(mapEqnIncRow),mapEqnIncRow,ass2,{});
      then
        // Frenkel TUD: Do not hand over the scalar incidence Matrix because following modules does not check if scalar or not
        (BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.MATCHING(ass1,ass2,comps1),stateSets),comps1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"sorting equations(strongComponents failed)"});
      then fail();
  end matchcontinue;
end strongComponentsScalar;

public function eqnAssignmentNonScalar
  input Integer index;
  input Integer size;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> ass2;
  input list<list<Integer>> iAcc;
  output array<list<Integer>> oAcc;
algorithm
  oAcc := matchcontinue(index,size,mapEqnIncRow,ass2,iAcc)
    local
      list<Integer> elst,vlst;
    case (_,_,_,_,_)
      equation
        false = intGt(index,size);
        elst = mapEqnIncRow[index];
        vlst = List.map1r(elst,arrayGet,ass2);
        vlst = List.select1(vlst,intGt,0);
      then
        eqnAssignmentNonScalar(index+1,size,mapEqnIncRow,ass2,vlst::iAcc);
    else
      then
        listArray(listReverse(iAcc));
  end matchcontinue;
end eqnAssignmentNonScalar;

public function varAssignmentNonScalar
  input Integer index;
  input Integer size;
  input array<Integer> ass1;
  input array<Integer> mapIncRowEqn;
  input list<Integer> iAcc;
  output array<Integer> oAcc;
algorithm
  oAcc := matchcontinue(index,size,ass1,mapIncRowEqn,iAcc)
    local
      Integer e;
    case (_,_,_,_,_)
      equation
        false = intGt(index,size);
        e = ass1[index];
        true = intGt(e,0);
        e = mapIncRowEqn[e];
      then
        varAssignmentNonScalar(index+1,size,ass1,mapIncRowEqn,e::iAcc);
    case (_,_,_,_,_)
      equation
        false = intGt(index,size);
        e = ass1[index];
        false = intGt(e,0);
        e = -1;
      then
        varAssignmentNonScalar(index+1,size,ass1,mapIncRowEqn,e::iAcc);
    else
      then
        listArray(listReverse(iAcc));
  end matchcontinue;
end varAssignmentNonScalar;

protected function analyseStrongComponentsScalar"function: analyseStrongComponents
  author: Frenkel TUD 2011-05
  analyse the type of the strong connect components and
  calculate the jacobian."
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer imark;
  input array<Integer> markarray;
  input BackendDAE.StrongComponents iAcc;
  output BackendDAE.StrongComponents outComps;
algorithm
  outComps:=
  match (inComps,syst,shared,inAss1,inAss2,mapEqnIncRow,mapIncRowEqn,imark,markarray,iAcc)
    local
      list<Integer> comp;
      list<list<Integer>> comps;
      BackendDAE.StrongComponent acomp;
      Integer mark;
    case ({},_,_,_,_,_,_,_,_,_) then listReverse(iAcc);
    case (comp::comps,_,_,_,_,_,_,_,_,_)
      equation
        (acomp,mark) = analyseStrongComponentScalar(comp,syst,shared,inAss1,inAss2,mapEqnIncRow,mapIncRowEqn,imark,markarray);
      then
        analyseStrongComponentsScalar(comps,syst,shared,inAss1,inAss2,mapEqnIncRow,mapIncRowEqn,mark,markarray,acomp::iAcc);
    else
      equation
        print("- BackendDAETransform.analyseStrongComponents failed\n");
      then
        fail();
  end match;
end analyseStrongComponentsScalar;

protected function analyseStrongComponentScalar"function: analyseStrongComponent
  author: Frenkel TUD 2011-05
  helper for analyseStrongComponents."
  input list<Integer> inComp;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer imark;
  input array<Integer> markarray;
  output BackendDAE.StrongComponent outComp;
  output Integer omark;
algorithm
  (outComp,omark):=
  match (inComp,syst,shared,inAss1,inAss2,mapEqnIncRow,mapIncRowEqn,imark,markarray)
    local
      list<Integer> comp,vlst,eqngetlst;
      list<BackendDAE.Var> varlst;
      list<tuple<BackendDAE.Var,Integer>> var_varindx_lst;
      array<Integer> ass1,ass2;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqn_lst;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponent compX;
    case (comp,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,ass1,ass2,_,_,_,_)
      equation
        vlst = List.map1r(comp,arrayGet,ass2);
        varlst = List.map1r(vlst,BackendVariable.getVarAt,vars);
        var_varindx_lst = List.threadTuple(varlst,vlst);
        // get from scalar eqns indexes the indexes in the equation array
        comp = List.map1r(comp,arrayGet,mapIncRowEqn);
        comp = List.fold2(comp,uniqueComp,imark,markarray,{});
        //comp = List.unique(comp);
        eqngetlst = List.map1(comp,intSub,1);
        eqn_lst = List.map1r(eqngetlst,BackendDAEUtil.equationNth,eqns);
        compX = analyseStrongComponentBlock(comp,eqn_lst,var_varindx_lst,syst,shared,ass1,ass2,false);
      then
        (compX,imark+1);
    else
      equation
        print("- BackendDAETransform.analyseStrongComponent failed\n");
      then
        fail();
  end match;
end analyseStrongComponentScalar;


protected function uniqueComp
  input Integer c;
  input Integer mark;
  input array<Integer> markarray;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(c,mark,markarray,iAcc)
    case(_,_,_,_)
      equation
        false = intEq(mark,markarray[c]);
        _ = arrayUpdate(markarray,c,mark);
      then
        c::iAcc;
    else
      then
        iAcc;
  end matchcontinue;
end uniqueComp;


public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.StrongComponents outComps;
algorithm
  (osyst,outComps) :=
  matchcontinue (syst,shared)
    local
      list<list<Integer>> comps;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.StrongComponents comps1;
      BackendDAE.EquationArray eqs;
      BackendDAE.Variables vars;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(vars,eqs,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1=ass1,ass2=ass2),stateSets=stateSets),_)
      equation
        comps = tarjanAlgorithm(mt,ass2);
        comps1 = analyseStrongComponents(comps,syst,shared,ass1,ass2,{});
      then
        (BackendDAE.EQSYSTEM(vars,eqs,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1,ass2,comps1),stateSets),comps1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"sorting equations(strongComponents failed)"});
      then fail();
  end matchcontinue;
end strongComponents;

protected function analyseStrongComponents"function: analyseStrongComponents
  author: Frenkel TUD 2011-05
  analyse the type of the strong connect components and
  calculate the jacobian."
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.StrongComponents iAcc;
  output BackendDAE.StrongComponents outComps;
algorithm
  outComps:=
  match (inComps,syst,shared,inAss1,inAss2,iAcc)
    local
      list<Integer> comp;
      list<list<Integer>> comps;
      BackendDAE.StrongComponent acomp;
    case ({},_,_,_,_,_) then listReverse(iAcc);
    case (comp::comps,_,_,_,_,_)
      equation
        acomp = analyseStrongComponent(comp,syst,shared,inAss1,inAss2);
      then
        analyseStrongComponents(comps,syst,shared,inAss1,inAss2,acomp::iAcc);
    else
      equation
        print("- BackendDAETransform.analyseStrongComponents failed\n");
      then
        fail();
  end match;
end analyseStrongComponents;

protected function analyseStrongComponent"function: analyseStrongComponent
  author: Frenkel TUD 2011-05
  helper for analyseStrongComponents."
  input list<Integer> inComp;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp:=
  match (inComp,syst,shared,inAss1,inAss2)
    local
      list<Integer> comp;
      list<tuple<BackendDAE.Var,Integer>> var_varindx_lst;
      array<Integer> ass1,ass2;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqn_lst;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponent compX;
    case (comp,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,ass1,ass2)
      equation
        (eqn_lst,var_varindx_lst) = List.map3_2(comp, getEquationAndSolvedVar_Internal, eqns, vars, ass2);
        compX = analyseStrongComponentBlock(comp,eqn_lst,var_varindx_lst,syst,shared,ass1,ass2,false);
      then
        compX;
    else
      equation
        print("- BackendDAETransform.analyseStrongComponent failed\n");
      then
        fail();
  end match;
end analyseStrongComponent;

protected function analyseStrongComponentBlock "function: analyseStrongComponentBlock
  author: Frenkel TUD 2011-05
  helper for analyseStrongComponent."
  input list<Integer> inComp;
  input list<BackendDAE.Equation> inEqnLst;
  input list<tuple<BackendDAE.Var,Integer>> inVarVarindxLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input Boolean inLoop; //true if the function call itself
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp:=
  matchcontinue (inComp,inEqnLst,inVarVarindxLst,isyst,ishared,inAss1,inAss2,inLoop)
    local
      Integer compelem,v;
      list<Integer> comp,varindxs;
      list<tuple<BackendDAE.Var,Integer>> var_varindx_lst,var_varindx_lst_cond;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Variables vars,vars_1;
      list<BackendDAE.Equation> eqn_lst,eqn_lst1,cont_eqn,disc_eqn;
      list<BackendDAE.Var> var_lst,var_lst_1,cont_var,disc_var;
      list<Integer> indxcont_var,indxdisc_var,indxcont_eqn,indxdisc_eqn;
      BackendDAE.EquationArray eqns_1,eqns;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.StrongComponent sc;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      String msg;
      list<DAE.ComponentRef> crlst;
      list<String> slst;
      Boolean jacConstant;
    case (compelem::{},BackendDAE.ALGORITHM(size = _)::{},var_varindx_lst,_,_,_,_,false)
      equation
        varindxs = List.map(var_varindx_lst,Util.tuple22);
      then
        BackendDAE.SINGLEALGORITHM(compelem,varindxs);
    case (compelem::{},BackendDAE.ARRAY_EQUATION(dimSize = _)::{},var_varindx_lst,_,_,_,_,false)
      equation
        varindxs = List.map(var_varindx_lst,Util.tuple22);
      then
        BackendDAE.SINGLEARRAY(compelem,varindxs);
    case (compelem::{},BackendDAE.IF_EQUATION(conditions = _)::{},var_varindx_lst,_,_,_,_,false)
      equation
        varindxs = List.map(var_varindx_lst,Util.tuple22);
      then
        BackendDAE.SINGLEIFEQUATION(compelem,varindxs);
    case (compelem::{},BackendDAE.COMPLEX_EQUATION(size=_)::{},var_varindx_lst,_,_,_,_,false)
      equation
        varindxs = List.map(var_varindx_lst,Util.tuple22);
      then
        BackendDAE.SINGLECOMPLEXEQUATION(compelem,varindxs);
    case (compelem::{},BackendDAE.WHEN_EQUATION(size=_)::{},var_varindx_lst,_,_,_,_,false)
      equation
        varindxs = List.map(var_varindx_lst,Util.tuple22);
      then
        BackendDAE.SINGLEWHENEQUATION(compelem,varindxs);
    case (compelem::{},_,(_,v)::{},_,_,_,ass2,false)
      then BackendDAE.SINGLEEQUATION(compelem,v);
    case (comp,eqn_lst,var_varindx_lst,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,ass1,ass2,false)
      equation
        var_lst = List.map(var_varindx_lst,Util.tuple21);
        true = BackendVariable.hasDiscreteVar(var_lst);
        true = BackendVariable.hasContinousVar(var_lst);
        varindxs = List.map(var_varindx_lst,Util.tuple22);
        (cont_eqn,cont_var,disc_eqn,disc_var,indxcont_eqn,indxcont_var,indxdisc_eqn,indxdisc_var) = splitMixedEquations(eqn_lst, comp, var_lst, varindxs);
        var_varindx_lst_cond = List.threadTuple(cont_var,indxcont_var);
        sc = analyseStrongComponentBlock(indxcont_eqn,cont_eqn,var_varindx_lst_cond,syst,shared,ass1,ass2,true);
      then
        BackendDAE.MIXEDEQUATIONSYSTEM(sc,indxdisc_eqn,indxdisc_var);
    case (comp,eqn_lst,var_varindx_lst,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,ass1,ass2,_)
      equation
        var_lst = List.map(var_varindx_lst,Util.tuple21);
        false = BackendVariable.hasDiscreteVar(var_lst);
        varindxs = List.map(var_varindx_lst,Util.tuple22);
        eqn_lst1 = replaceDerOpInEquationList(eqn_lst);
        // States are solved for der(x) not x.
        var_lst_1 = List.map(var_lst, transformXToXd);
        vars_1 = BackendVariable.listVar1(var_lst_1);
        eqns_1 = BackendEquation.listEquation(eqn_lst1);
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst,BackendDAE.ABSOLUTE(),NONE());
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, m, true,shared);
        // Jacobian of a Linear System is always linear
        (jac_tp,jacConstant) = BackendDAEUtil.analyzeJacobian(vars_1,eqns_1,jac);
        // if constant check for singular jacobian
        true = analyzeConstantJacobian(jacConstant,jac,arrayLength(mt),var_lst,eqn_lst,shared);
      then
        BackendDAE.EQUATIONSYSTEM(comp,varindxs,jac,jac_tp);
    case (comp,eqn_lst,var_varindx_lst,syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,ass1,ass2,_)
      equation
        var_lst = List.map(var_varindx_lst,Util.tuple21);
        true = BackendVariable.hasDiscreteVar(var_lst);
        false = BackendVariable.hasContinousVar(var_lst);
        msg = "Sorry - Support for Discrete Equation Systems is not yet implemented\n";
        crlst = List.map(var_lst,BackendVariable.varCref);
        slst = List.map(crlst,ComponentReference.printComponentRefStr);
        msg = msg +& stringDelimitList(slst,"\n");
        slst = List.map(eqn_lst,BackendDump.equationString);
        msg = msg +& "\n" +& stringDelimitList(slst,"\n");
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponentBlock failed"});
      then
        fail();
  end matchcontinue;
end analyseStrongComponentBlock;

protected function analyzeConstantJacobian
  input Boolean jacConstant;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> iJac;
  input Integer size;
  input list<BackendDAE.Var> iVars;
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Shared shared;
  output Boolean valid;
algorithm
  valid := matchcontinue(jacConstant,iJac,size,iVars,iEqns,shared)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<Real> rhsVals,solvedVals;
      list<list<Real>> jacVals;
      Integer linInfo;
      String infoStr,syst,varnames,varname,rhsStr,jacStr,eqnstr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.FunctionTree funcs;
      list<DAE.Exp> beqs;
    case(true,SOME(jac),_,_,_,_)
      equation
        jacVals = BackendDAEOptimize.evaluateConstantJacobian(size,jac);
        rhsVals = List.fill(0.0,size);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        false = intEq(linInfo,0);
        varname = ComponentReference.printComponentRefStr(BackendVariable.varCref(listGet(iVars,linInfo)));
        infoStr = intString(linInfo);
        varnames = stringDelimitList(List.map(List.map(iVars,BackendVariable.varCref),ComponentReference.printComponentRefStr)," ;\n  ");
        eqns = BackendEquation.listEquation(iEqns);
        vars = BackendVariable.listVar1(iVars);
        funcs = BackendDAEUtil.getFunctions(shared);
        (beqs,_) = BackendDAEUtil.getEqnSysRhs(eqns,vars,SOME(funcs));
        beqs = listReverse(beqs);
        rhsStr = stringDelimitList(List.map(beqs, ExpressionDump.printExpStr)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jacVals,realString),stringDelimitList," , ")," ;\n  ");
        eqnstr = BackendDump.dumpEqnsStr(iEqns);
        syst = stringAppendList({"\n",eqnstr,"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Debug.bcall2(intGt(linInfo,0), Error.addMessage, Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
        syst = stringAppendList({eqnstr,"\n[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Debug.bcall2(intLt(linInfo,0), Error.addMessage, Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then
        false;
    else then true;
  end matchcontinue;
end analyzeConstantJacobian;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar)
    local
      Expression.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<Expression.Subscript> dim;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.ElementSource source;

    case (BackendDAE.VAR(varName = cr,
      varKind = BackendDAE.STATE(index=_),
      varDirection = dir,
      varParallelism = prl,
      varType = tp,
      bindExp = exp,
      bindValue = v,
      arryDim = dim,
      source = source,
      values = attr,
      comment = comment,
      connectorType = ct))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
      then
        BackendDAE.VAR(cr,BackendDAE.STATE_DER(),dir,prl,tp,exp,v,dim,source,attr,comment,ct);

    else then inVar;
  end match;
end transformXToXd;

protected function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (outEqns,_) := BackendEquation.traverseBackendDAEExpsEqnList(inEqns, replaceDerOpInExp,0);
end replaceDerOpInEquationList;

protected function replaceDerOpInExp
  "Replaces all der(cref) with $DER.cref in an expression."
    input tuple<DAE.Exp, Integer> inTpl;
    output tuple<DAE.Exp, Integer> outTpl;
protected
  DAE.Exp exp,exp1;
  Integer i;
algorithm
  (exp,i) := inTpl;
  ((exp1, _)) := Expression.traverseExp(exp, replaceDerOpInExpTraverser, NONE());
  outTpl := ((exp1,i));
end replaceDerOpInExp;

protected function replaceDerOpInExpTraverser
  "Used with Expression.traverseExp to traverse an expression an replace calls to
  der(cref) with a component reference $DER.cref. If an optional component
  reference is supplied, then only that component reference is replaced.
  Otherwise all calls to der are replaced.

  This is done since some parts of the compiler can't handle der-calls, such as
  Derive.differentiateExpression. Ideally these parts should be fixed so that they can
  handle der-calls, but until that happens we just replace the der-calls with
  crefs."
  input tuple<DAE.Exp, Option<DAE.ComponentRef>> inExp;
  output tuple<DAE.Exp, Option<DAE.ComponentRef>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef cr, der_cr;
      DAE.Exp cref_exp;
      DAE.ComponentRef cref;

    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        SOME(cref)))
      equation
        der_cr = ComponentReference.crefPrefixDer(cr);
        true = ComponentReference.crefEqualNoStringCompare(der_cr, cref);
        cref_exp = Expression.crefExp(der_cr);
      then
        ((cref_exp, SOME(cref)));

    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        NONE()))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        cref_exp = Expression.crefExp(cr);
      then
        ((cref_exp, NONE()));
    case (_) then inExp;
  end matchcontinue;
end replaceDerOpInExpTraverser;

public function getEquationAndSolvedVar
"function: getEquationAndSolvedVar
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Equation> outEquation;
  output list<BackendDAE.Var> outVar;
  output Integer outIndex;
algorithm
  (outEquation,outVar,outIndex):=
  matchcontinue (inComp,inEquationArray,inVariables)
    local
      Integer e_1,v,e;
      list<Integer> elst,vlst;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqnlst,eqnlst1;
      list<BackendDAE.Var> varlst,varlst1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponent comp;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        var = BackendVariable.getVarAt(vars, v);
      then
        ({eqn},{var},e);
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst,disc_vars=vlst),eqns,vars)
      equation
        eqnlst1 = BackendEquation.getEqns(elst,eqns);
        varlst1 = List.map1r(vlst, BackendVariable.getVarAt, vars);
        e = List.first(elst);
        (eqnlst,varlst,_) = getEquationAndSolvedVar(comp,eqns,vars);
        eqnlst = listAppend(eqnlst,eqnlst1);
        varlst = listAppend(varlst,varlst1);
      then
        (eqnlst,varlst,e);
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst),eqns,vars)
      equation
        eqnlst = BackendEquation.getEqns(elst,eqns);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        e = List.first(elst);
      then
        (eqnlst,varlst,e);
    case (BackendDAE.SINGLEARRAY(eqn=e,vars=vlst),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn},varlst,e);
    case (BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vlst),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn},varlst,e);
    case (BackendDAE.SINGLEALGORITHM(eqn=e,vars=vlst),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn},varlst,e);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vlst),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn},varlst,e);
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vlst),eqns,vars)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn},varlst,e);
    case (BackendDAE.TORNSYSTEM(tearingvars=vlst, residualequations=elst, otherEqnVarTpl=eqnvartpllst),eqns,vars)
      equation
        eqnlst = BackendEquation.getEqns(elst,eqns);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqnlst1 = BackendEquation.getEqns(List.map(eqnvartpllst,Util.tuple21),eqns);
        varlst1 = List.map1r(List.flatten(List.map(eqnvartpllst,Util.tuple22)), BackendVariable.getVarAt, vars);
        eqnlst = listAppend(eqnlst,eqnlst1);
        varlst = listAppend(varlst,varlst1);
        e = List.first(elst);
      then
        (eqnlst,varlst,e);
    case (_,eqns,vars)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAETransform.getEquationAndSolvedVar failed!");
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar;

protected function getEquationAndSolvedVar_Internal
"function: getEquationAndSolvedVar_Internal
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input Integer inInteger;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  input array<Integer> inIntegerArray;
  output BackendDAE.Equation outEquation;
  output tuple<BackendDAE.Var,Integer> outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue (inInteger,inEquationArray,inVariables,inIntegerArray)
    local
      Integer e_1,v,e;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      array<Integer> ass2;
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        v = ass2[e];
        var = BackendVariable.getVarAt(vars, v);
      then
        (eqn,(var,v));
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAETransform.getEquationAndSolvedVar_Internal failed at index: " +& intString(e));
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar_Internal;

public function getEquationAndSolvedVarIndxes
"function: getEquationAndSolvedVarIndxes
  author: Frenkel TUD
  Retrieves the equation and the variable indexes solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  output list<Integer> outEquation;
  output list<Integer> outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue(inComp)
    local
      Integer v,e;
      list<Integer> elst,vlst,elst1,vlst1;
      BackendDAE.StrongComponent comp;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v))
      then
        ({e},{v});
    case BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst,disc_vars=vlst)
      equation
        (elst1,vlst1) = getEquationAndSolvedVarIndxes(comp);
        elst = listAppend(elst1,elst);
        vlst = listAppend(vlst1,vlst);
      then
        (elst,vlst);
    case BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst)
      then
        (elst,vlst);
    case BackendDAE.SINGLEARRAY(eqn=e,vars=vlst)
      then
        ({e},vlst);
    case BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vlst)
      then
        ({e},vlst);
    case BackendDAE.SINGLEALGORITHM(eqn=e,vars=vlst)
      then
        ({e},vlst);
    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vlst)
      then
        ({e},vlst);
    case BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vlst)
      then
        ({e},vlst);
    case BackendDAE.TORNSYSTEM(tearingvars=vlst, residualequations=elst, otherEqnVarTpl=eqnvartpllst)
      equation
        elst1 = List.map(eqnvartpllst,Util.tuple21);
        vlst1 = List.flatten(List.map(eqnvartpllst,Util.tuple22));
        elst = listAppend(elst1,elst);
        vlst = listAppend(vlst1,vlst);
      then
        (elst,vlst);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAETransform.getEquationAndSolvedVarIndxes failed!");
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVarIndxes;

protected function splitMixedEquations "function: splitMixedEquations
  author: PA

  Splits the equation of a mixed equation system into its continuous and
  discrete parts.

  Even though the matching algorithm might say that a discrete variable is solved in a specific equation
  (when part of a mixed system) this is not always correct. It might be impossible to solve the discrete
  variable from that equation, for instance solving v from equation x = v < 0; This happens for e.g. the Gear model.
  Instead, to split the equations and variables the following scheme is used:

  1. Split the variables into continuous and discrete.
  2. For each discrete variable v, select among the equations where it is present
   for an equation v = expr. (This could be done
   by looking at incidence matrix but for now we look through all equations. This is sufficiently
   efficient for small systems of mixed equations < 100)
  3. The equations not selected in step 2 are continuous equations.
"
  input list<BackendDAE.Equation> eqnLst;
  input list<Integer> indxEqnLst;
  input list<BackendDAE.Var> varLst;
  input list<Integer> indxVarLst;
  output list<BackendDAE.Equation> contEqnLst;
  output list<BackendDAE.Var> contVarLst;
  output list<BackendDAE.Equation> discEqnLst;
  output list<BackendDAE.Var> discVarLst;
  output list<Integer> indxcontEqnLst;
  output list<Integer> indxcontVarLst;
  output list<Integer> indxdiscEqnLst;
  output list<Integer> indxdiscVarLst;
algorithm
  (contEqnLst,contVarLst,discEqnLst,discVarLst,indxcontEqnLst,indxcontVarLst,indxdiscEqnLst,indxdiscVarLst):=
  matchcontinue (eqnLst, indxEqnLst, varLst, indxVarLst)
    local list<tuple<BackendDAE.Equation,Integer>> eqnindxlst;
    case (_,_,_,_)
      equation
      (discVarLst,contVarLst,indxdiscVarLst,indxcontVarLst) = splitVars(varLst,indxVarLst,BackendVariable.isVarDiscrete,{},{},{},{});
      eqnindxlst = List.map1(discVarLst,findDiscreteEquation,(eqnLst,indxEqnLst));
      discEqnLst = List.map(eqnindxlst,Util.tuple21);
      indxdiscEqnLst = List.map(eqnindxlst,Util.tuple22);
      contEqnLst = List.setDifferenceOnTrue(eqnLst,discEqnLst,BackendEquation.equationEqual);
      indxcontEqnLst = List.setDifferenceOnTrue(indxEqnLst,indxdiscEqnLst,intEq);
    then (contEqnLst,contVarLst,discEqnLst,discVarLst,indxcontEqnLst,indxcontVarLst,indxdiscEqnLst,indxdiscVarLst);
    case (_,_,_,_)
      equation
        BackendDump.printVarList(varLst);
        BackendDump.printEquationList(eqnLst);
    then fail();
  end matchcontinue;
end splitMixedEquations;

protected function splitVars
  "Helper function to splitMixedEquations."
  input list<Type_a> inList;
  input list<Type_b> inListb;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  input list<Type_b> inTrueListb;
  input list<Type_b> inFalseListb;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;
  output list<Type_b> outTrueListb;
  output list<Type_b> outFalseListb;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList,outTrueListb, outFalseListb) :=
  match(inList, inListb, inFunc, inTrueList, inFalseList, inTrueListb, inFalseListb)
    local
      Type_a e;
      Type_b eb;
      list<Type_a> rest_e, tl, fl;
      list<Type_b> rest_eb, tlb, flb;
      Boolean pred;

    case ({}, {}, _, tl, fl, tlb, flb)
      then (listReverse(tl), listReverse(fl),listReverse(tlb), listReverse(flb));

    case (e :: rest_e,eb :: rest_eb, _, tl, fl, tlb, flb)
      equation
        pred = inFunc(e);
        (tl, fl,tlb, flb) = splitVars1(e, rest_e,eb, rest_eb, pred, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl,tlb, flb);
  end match;
end splitVars;

protected function splitVars1
  "Helper function to splitVars."
  input Type_a inHead;
  input list<Type_a> inRest;
  input Type_b inHeadb;
  input list<Type_b> inRestb;
  input Boolean inPred;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  input list<Type_b> inTrueListb;
  input list<Type_b> inFalseListb;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;
  output list<Type_b> outTrueListb;
  output list<Type_b> outFalseListb;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList,outTrueListb, outFalseListb) :=
  match(inHead, inRest,inHeadb, inRestb, inPred, inFunc, inTrueList, inFalseList,inTrueListb, inFalseListb)
    local
      list<Type_a>  tl, fl;
      list<Type_b>  tlb, flb;

    case (_, _, _, _, true, _, tl, fl, tlb, flb)
      equation
        tl = inHead :: tl;
        tlb = inHeadb :: tlb;
        (tl, fl, tlb, flb) = splitVars(inRest, inRestb, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl, tlb, flb);

    case (_, _, _, _, false, _, tl, fl, tlb, flb)
      equation
        fl = inHead :: fl;
        flb = inHeadb :: flb;
        (tl, fl, tlb, flb) = splitVars(inRest, inRestb, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl, tlb, flb);
  end match;
end splitVars1;

protected function findDiscreteEquation "help function to splitMixedEquations, finds the discrete equation
on the form v = expr for solving variable v"
  input BackendDAE.Var v;
  input tuple<list<BackendDAE.Equation>,list<Integer>> eqnIndxLst;
  output tuple<BackendDAE.Equation,Integer> eqnindx;
algorithm
  eqnindx := matchcontinue(v,eqnIndxLst)
    local Expression.ComponentRef cr1,cr;
      DAE.Exp e2;
      Integer i;
      BackendDAE.Equation eqn;
      list<Integer> ilst;
      list<BackendDAE.Equation> eqnLst;
      String errstr;
    case (_,(((eqn as BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr),scalar=e2))::_),i::_)) equation
      cr1=BackendVariable.varCref(v);
      true = ComponentReference.crefEqualNoStringCompare(cr1,cr);
    then ((eqn,i));
    case(_,(((eqn as BackendDAE.EQUATION(exp=e2,scalar=DAE.CREF(componentRef=cr)))::_),i::_)) equation
      cr1=BackendVariable.varCref(v);
      true = ComponentReference.crefEqualNoStringCompare(cr1,cr);
    then ((eqn,i));
    case(_,(_::eqnLst,_::ilst)) equation
      ((eqn,i)) = findDiscreteEquation(v,(eqnLst,ilst));
    then ((eqn,i));
    else equation
      Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAETransform.findDiscreteEquation failed.\n
Your model contains a mixed system involving algorithms or other complex-equations.\n
Sorry. Currently are supported only mixed system involving simple equations and boolean variables.\n
Try to break the loop by using the pre operator."});
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.trace("findDiscreteEquation failed, searching for variables:  ");
      errstr = ComponentReference.printComponentRefStr(BackendVariable.varCref(v));
      Debug.traceln(errstr);
    then
      fail();
  end matchcontinue;
end findDiscreteEquation;

public function tarjanAlgorithm "function: tarjanAlgorithm
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> ass2 "ass[eqnindx]=varindx";
  output list<list<Integer>> outComps;
algorithm
  outComps :=
  matchcontinue (mt,ass2)
    local
      Integer n;
      list<list<Integer>> comps;
      array<Integer> number,lowlink;
      array<Boolean> stackflag;
    case (_,_)
      equation
        n = arrayLength(ass2);
        number = arrayCreate(n,0);
        lowlink = arrayCreate(n,0);
        stackflag = arrayCreate(n,false);
        (_,_,comps) = strongConnectMain(mt, ass2, number, lowlink, stackflag, n, 0, 1, {}, {});
      then
        comps;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"-BackendDAETransform-tarjansAlgorithm failed! The sorting of the equations could not be done.(strongComponents failed), Use +d=failtrace for more information."});
      then fail();
  end matchcontinue;
end tarjanAlgorithm;

public function strongConnectMain "function: strongConnectMain
  author: PA

  Helper function to strong_components

  inputs:  (IncidenceMatrix,
              IncidenceMatrixT,
              int vector, /* Assignment */
              int vector, /* Assignment */
              int vector, /* Number */
              int vector, /* Lowlink */
              int, /* n - number of equations */
              int, /* i */
              int, /* w */
              int list, /* stack */
              int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer i;
  input Integer w;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output Integer oi;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
algorithm
  (oi,ostack,ocomps):=
  matchcontinue (mt,a2,number,lowlink,stackflag,n,i,w,istack,icomps)
    local
      Integer i1,num;
      list<Integer> stack;
      list<list<Integer>> comps;

    case (_,_,_,_,_,_,_,_,_,_)
      equation
        (w > n) = true;
      then
        (i,istack,icomps);
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(number[w],0);
        (i1,stack,comps) = strongConnect(mt,a2,number,lowlink,stackflag,i,w,istack,icomps);
        (i1,stack,comps) = strongConnectMain(mt,a2,number,lowlink,stackflag,n,i,w + 1,stack,comps);
      then
        (i1,stack,comps);
    else
      equation
        num = number[w];
        (num == 0) = false;
        (i1,stack,comps) = strongConnectMain(mt,a2,number,lowlink, stackflag, n, i, w + 1, istack, icomps);
      then
        (i1,stack,comps);
  end matchcontinue;
end strongConnectMain;

protected function strongConnect "function: strongConnect
  author: PA

  Helper function to strong_connect_main

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )
"
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer i;
  input Integer v;
  input list<Integer> stack;
  input list<list<Integer>> comps;
  output Integer oi;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
algorithm
  (oi,ostack,ocomps):=
  matchcontinue (mt,a2,number,lowlink,stackflag,i,v,stack,comps)
    local
      Integer i_1;
      list<Integer> stack_1,eqns,stack_2,stack_3,comp;
      list<list<Integer>> comps_1,comps_2;
    case (_,_,_,_,_,_,_,_,_)
      equation
        i_1 = i + 1;
        _ = arrayUpdate(number,v,i_1);
        _ = arrayUpdate(lowlink,v,i_1);
        stack_1 = (v :: stack);
        _ = arrayUpdate(stackflag,v,true);
        eqns = reachableNodes(v, mt, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, mt, a2, number, lowlink, stackflag, i_1, v, stack_1, comps);
        (stack_3,comp) = checkRoot(v, stack_2, number, lowlink, stackflag);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    else
      equation
        Debug.traceln("- BackendDAETransform.strongConnect failed for eqn " +& intString(v));
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "function: consIfNonempty
  author: PA

  Small helper function to avoid empty sublists.
  Consider moving to Util?
"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIntegerLst,inIntegerLstLst)
    local
      list<list<Integer>> lst;
      list<Integer> e;
    case ({},lst) then lst;
    case (e,lst) then (e :: lst);
  end matchcontinue;
end consIfNonempty;

public function reachableNodes "function: reachableNodes
  author: PA

  Helper function to strong_connect.
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1,n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2.
"
  input Integer eqn;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (eqn,mt,a2)
    local
      Integer var;
      list<Integer> reachable,reachable_1;
      String eqnstr;
    case (_,_,_)
      equation
        var = a2[eqn] "Got the variable that is solved in the equation" ;
        reachable = Debug.bcallret2(intGt(var,0),arrayGet,mt,var,{}) "Got the equations of that variable" ;
        reachable_1 = BackendDAEUtil.removeNegative(reachable) "in which other equations is this variable present ?" ;
      then
        List.removeOnTrue(eqn, intEq, reachable_1);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-reachable_nodes failed, eqn: ");
        eqnstr = intString(eqn);
        Debug.traceln(eqnstr);
      then
        fail();
  end matchcontinue;
end reachableNodes;

protected function iterateReachableNodes "function: iterateReachableNodes
  author: PA

  Helper function to strong_connect.

  inputs:  (int list, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input list<Integer> eqns;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer i;
  input Integer v;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output Integer outI;
  output list<Integer> outStack;
  output list<list<Integer>> outComps;
algorithm
  (outI,outStack,outComps):=
  matchcontinue (eqns,mt,a2,number,lowlink,stackflag,i,v,istack,icomps)
    local
      Integer i1,lv,lw,minv,w,nw,nv;
      list<Integer> stack,ws;
      list<list<Integer>> comps_1,comps_2,comps;

    // empty case
    case ({},_,_,_,_,_,_,_,_,_) then (i,istack,icomps);

    // nw is 0
    case ((w :: ws),_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(number[w],0);
        (i1,stack,comps_1) = strongConnect(mt, a2, number, lowlink, stackflag, i, w, istack, icomps);
        lv = lowlink[v];
        lw = lowlink[w];
        minv = intMin(lv, lw);
        _ = arrayUpdate(lowlink,v,minv);
        (i1,stack,comps_2) = iterateReachableNodes(ws, mt, a2, number, lowlink, stackflag, i1, v, stack, comps_1);
      then
        (i1,stack,comps_2);

    // nw
    case ((w :: ws),_,_,_,_,_,_,_,_,_)
      equation
        nw = number[w];
        nv = lowlink[v];
        (nw < nv) = true;
        true = stackflag[w];
        minv = intMin(nw, nv);
        _ = arrayUpdate(lowlink,v,minv);
        (i1,stack,comps) = iterateReachableNodes(ws, mt, a2, number, lowlink, stackflag, i, v, istack, icomps);
      then
        (i1,stack,comps);

    case ((_ :: ws),_,_,_,_,_,_,_,_,_)
      equation
        (i1,stack,comps) = iterateReachableNodes(ws, mt, a2, number, lowlink, stackflag, i, v, istack, icomps);
      then
        (i1,stack,comps);

  end matchcontinue;
end iterateReachableNodes;

protected function checkRoot "function: checkRoot
  author: PA

  Helper function to strong_connect.

  inputs:  (int /* v */, int list /* stack */, int vector, int vector)
  outputs: (int list /* stack */, int list /* comps */)
"
  input Integer v;
  input list<Integer> istack;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  output list<Integer> ostack;
  output list<Integer> ocomps;
algorithm
  (ostack,ocomps):=
  matchcontinue (v,istack,number,lowlink,stackflag)
    local
      Integer lv,nv;
      list<Integer> comps,stack;
    case (_,_,_,_,_)
      equation
        lv = lowlink[v];
        nv = number[v];
        true = intEq(lv,nv);
        (stack,comps) = checkStack(nv, istack, number, stackflag, {});
      then
        (stack,comps);
    else then (istack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "function: checkStack
  author: PA

  Helper function to check_root.

  inputs:  (int /* vn */, int list /* stack */, int vector, int list /* component list */)
  outputs: (int list /* stack */, int list /* comps */)
"
  input Integer vn;
  input list<Integer> istack;
  input array<Integer> number;
  input array<Boolean> stackflag;
  input list<Integer> icomp;
  output list<Integer> ostack;
  output list<Integer> ocomp;
algorithm
  (ostack,ocomp):=
  matchcontinue (vn,istack,number,stackflag,icomp)
    local
      Integer top;
      list<Integer> rest,comp,stack;
    case (_,(top :: rest),_,_,_)
      equation
        true = intGe(number[top],vn);
        _ = arrayUpdate(stackflag,top,false);
        (stack,comp) = checkStack(vn, rest, number, stackflag, top :: icomp);
      then
        (stack,comp);
    else then (istack,listReverse(icomp));
  end matchcontinue;
end checkStack;

/******************************************
 traverseBackendDAEExps stuff
 *****************************************/

public function traverseBackendDAEExpsEqn
"function: traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,(_,outTypeA)) := traverseBackendDAEExpsEqnWithSymbolicOperation(inEquation,traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper,(func,inTypeA));
end traverseBackendDAEExpsEqn;

protected function traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper
  replaceable type Type_a subtypeof Any;
  input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>>> inTpl;
  output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>>> outTpl;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
protected
  FuncExpType func;
  Type_a arg;
  list<DAE.SymbolicOperation> ops;
  DAE.Exp exp;
algorithm
  (exp,(ops,(func,arg))) := inTpl;
  ((exp,arg)) := func((exp,arg));
  outTpl := (exp,(ops,(func,arg)));
end traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper;

public function traverseBackendDAEExpsEqnWithSymbolicOperation
"Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> inTpl;
    output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outTypeA) := matchcontinue (inEquation,func,inTypeA)
    local
      DAE.Exp e1_1,e2_1,e1,e2,cond;
      DAE.ComponentRef cr,cr1;
      Integer size;
      list<DAE.Exp> expl;
      BackendDAE.Equation res;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      DAE.ElementSource source;
      list<Integer> dimSize;
      list<DAE.SymbolicOperation> ops;
      list<DAE.Statement> statementLst;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      Boolean diffed;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source,differentiated = diffed),_,_)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source,diffed),ext_arg_2);
    /* array equation */
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source = source,differentiated = diffed),_,_)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e1_1,e2_1,source,diffed),ext_arg_2);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source,differentiated = diffed),_,_)
      equation
        e1 = Expression.crefExp(cr);
        ((DAE.CREF(cr1,_),(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e2_1,source,diffed),ext_arg_1);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source,differentiated = diffed),_,_)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1,source,diffed),ext_arg_1);
    /* Algorithms */
    case (BackendDAE.ALGORITHM(size = size,alg=DAE.ALGORITHM_STMTS(statementLst = statementLst),source = source),_,_)
      equation
        (statementLst,(ops,ext_arg_1)) = DAEUtil.traverseDAEEquationsStmts(statementLst, func, ({},inTypeA));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then (BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS(statementLst),source),ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation =
          BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e1,elsewhenPart=NONE()),source = source),_,_)
      equation
        e2 = Expression.crefExp(cr);
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((DAE.CREF(cr1,_),(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        ((cond,(ops,ext_arg_3))) = func((cond,(ops,ext_arg_2)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        res = BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e1_1,NONE()),source);
     then
        (res,ext_arg_3);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation =
          BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),_,_)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((cond,(ops,ext_arg_2))) = func((cond,(ops,ext_arg_1)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        (BackendDAE.WHEN_EQUATION(whenEquation=elsepartRes,source=source),ext_arg_3) = traverseBackendDAEExpsEqnWithSymbolicOperation(BackendDAE.WHEN_EQUATION(size,elsepart,source),func,ext_arg_2);
        res = BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr,e1_1,SOME(elsepartRes)),source);
      then
        (res,ext_arg_3);
    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source = source,differentiated = diffed),_,_)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.COMPLEX_EQUATION(size,e1_1,e2_1,source,diffed),ext_arg_2);

    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source),_,_)
      equation
        (expl,(ops,ext_arg_1)) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(expl,func,({},inTypeA),{});
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        (eqnslst,ext_arg_1) = traverseBackendDAEExpsEqnLstLstWithSymbolicOperation(eqnslst,func,ext_arg_1,{});
        (eqns,ext_arg_1) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(eqns,func,ext_arg_1,{});
      then
        (BackendDAE.IF_EQUATION(expl,eqnslst,eqns,source),ext_arg_1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsEqnWithSymbolicOperation;

protected function traverseBackendDAEExpsLstEqnWithSymbolicOperation
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExps;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<DAE.Exp> iAcc;
  output list<DAE.Exp> outExps;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outExps,outTypeA) := match (inExps,func,inTypeA,iAcc)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest,exps;
      Type_a arg;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case(exp::rest,_,_,_)
      equation
        ((exp,arg)) = func((exp,inTypeA));
        (exps,arg) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(rest,func,arg,exp::iAcc);
      then
        (exps,arg);
  end match;
end traverseBackendDAEExpsLstEqnWithSymbolicOperation;

protected function traverseBackendDAEExpsEqnLstWithSymbolicOperation
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEqns;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqns;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> inTpl;
    output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> outTpl;
  end FuncExpType;
algorithm
  (outEqns,outTypeA) := match (inEqns,func,inTypeA,iAcc)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest,eqns;
      Type_a arg;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case(eqn::rest,_,_,_)
      equation
        (eqn,arg) = traverseBackendDAEExpsEqnWithSymbolicOperation(eqn,func,inTypeA);
        (eqns,arg) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(rest,func,arg,eqn::iAcc);
      then
        (eqns,arg);
  end match;
end traverseBackendDAEExpsEqnLstWithSymbolicOperation;

protected function traverseBackendDAEExpsEqnLstLstWithSymbolicOperation
  replaceable type Type_a subtypeof Any;
  input list<list<BackendDAE.Equation>> inEqns;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<list<BackendDAE.Equation>> iAcc;
  output list<list<BackendDAE.Equation>> outEqns;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> inTpl;
    output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> outTpl;
  end FuncExpType;
algorithm
  (outEqns,outTypeA) := match (inEqns,func,inTypeA,iAcc)
    local
      list<BackendDAE.Equation> eqn;
      list<list<BackendDAE.Equation>> rest,eqnslst;
      Type_a arg;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case(eqn::rest,_,_,_)
      equation
        (eqn,arg) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(eqn,func,inTypeA,{});
        (eqnslst,arg) = traverseBackendDAEExpsEqnLstLstWithSymbolicOperation(rest,func,arg,eqn::iAcc);
      then
        (eqnslst,arg);
  end match;
end traverseBackendDAEExpsEqnLstLstWithSymbolicOperation;

protected function traverseBackendDAEExpsWhenOperator
"function: traverseBackendDAEExpsWhenOperator
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.WhenOperator> inReinitStmtLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.WhenOperator> outReinitStmtLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outReinitStmtLst,outTypeA) := matchcontinue (inReinitStmtLst,func,inTypeA)
    local
      list<BackendDAE.WhenOperator> res,res1;
      BackendDAE.WhenOperator wop;
      DAE.Exp cond,cond1,msg,level,cre;
      DAE.ComponentRef cr,cr1;
      DAE.ElementSource source;
      Type_a ext_arg_1,ext_arg_2;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;

    case ({},_,_) then ({},inTypeA);

    case (BackendDAE.REINIT(stateVar=cr,value=cond,source=source)::res,_,_)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
        ((cond1,ext_arg_2)) = func((cond,ext_arg_1));
        cre = Expression.crefExp(cr);
        ((DAE.CREF(componentRef=cr1),ext_arg_2)) = func((cre,ext_arg_2));
      then
        (BackendDAE.REINIT(cr1,cond1,source)::res1,ext_arg_2);

    case (BackendDAE.ASSERT(condition=cond,message=msg,level=level,source=source)::res,_,_)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
        ((cond1,ext_arg_2)) = func((cond,ext_arg_1));
      then
        (BackendDAE.ASSERT(cond1,msg,level,source)::res1,ext_arg_2);

    case (BackendDAE.NORETCALL(functionName=functionName,functionArgs=functionArgs,source=source)::res,_,_)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
        ((DAE.CALL(path=functionName,expLst=functionArgs),ext_arg_2)) = Expression.traverseExp(DAE.CALL(functionName,functionArgs,DAE.CALL_ATTR(DAE.T_NORETCALL_DEFAULT, false, false, false, DAE.NORM_INLINE(), DAE.NO_TAIL())),func,ext_arg_1);
      then
        (BackendDAE.NORETCALL(functionName,functionArgs,source)::res1,ext_arg_2);

    case (wop::res,_,_)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
      then
        (wop::res1,ext_arg_1);
     case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsWhenOperator failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsWhenOperator;

public function traverseBackendDAEExpsWhenClauseLst
"function: traverseBackendDAEExpsWhenClauseLst
  author: Frenkel TUD 2010-11
  Traverse all expressions of a when clause list. It is possible to change the expressions"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outWhenClauseLst,outTypeA) := matchcontinue (inWhenClauseLst,func,inTypeA)
    local
      Option<Integer> elsindx;
      list<BackendDAE.WhenOperator> reinitStmtLst,reinitStmtLst1;
      DAE.Exp cond,cond1;
      list<BackendDAE.WhenClause> wclst,wclst1;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;

    case ({},_,_) then ({},inTypeA);

    case (BackendDAE.WHEN_CLAUSE(cond,reinitStmtLst,elsindx)::wclst,_,_)
      equation
        ((cond1,ext_arg_1)) = func((cond,inTypeA));
        (reinitStmtLst1,ext_arg_2) = traverseBackendDAEExpsWhenOperator(reinitStmtLst,func,ext_arg_1);
        (wclst1,ext_arg_3) = traverseBackendDAEExpsWhenClauseLst(wclst,func,ext_arg_2);
      then
        (BackendDAE.WHEN_CLAUSE(cond1,reinitStmtLst1,elsindx)::wclst1,ext_arg_3);
     case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsWhenClauseLst failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsWhenClauseLst;

public function traverseBackendDAEExpsEqnList
"function traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outTypeA):=
  match (inEquations,func,inTypeA)
    local
      list<BackendDAE.Equation> eqns1,eqns;
      BackendDAE.Equation e,e1;
      Type_a ext_arg_1,ext_arg_2;
    case ({},_,_) then ({},inTypeA);
    case (e::eqns,_,_)
      equation
         (e1,ext_arg_1) = traverseBackendDAEExpsEqn(e,func,inTypeA);
         (eqns1,ext_arg_2) = traverseBackendDAEExpsEqnList(eqns,func,ext_arg_1);
      then
        (e1::eqns1,ext_arg_2);
  end match;
end traverseBackendDAEExpsEqnList;

end BackendDAETransform;
