/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
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
protected import SymbolicJacobian;
protected import System;
protected import Util;
protected import Values;

/******************************************
 strongComponents and stuff
 *****************************************/

public function strongComponentsScalar "author: PA

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
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (BackendDAE.EQSYSTEM(vars,eqs,SOME(_),SOME(mt),BackendDAE.MATCHING(ass1=ass1,ass2=ass2),stateSets=stateSets,partitionKind=partitionKind),_,_,_)
      equation
        comps = tarjanAlgorithm(mt,ass2);
        markarray = arrayCreate(BackendDAEUtil.equationArraySize(eqs),-1);
        comps1 = analyseStrongComponentsScalar(comps,syst,shared,ass1,ass2,mapEqnIncRow,mapIncRowEqn,1,markarray,{});
        ass1 = varAssignmentNonScalar(ass1,mapIncRowEqn);
        //noscalass2 = eqnAssignmentNonScalar(1,arrayLength(mapEqnIncRow),mapEqnIncRow,ass2,{});
      then
        // Frenkel TUD: Do not hand over the scalar incidence Matrix because following modules does not check if scalar or not
        (BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.MATCHING(ass1,ass2,comps1),stateSets,partitionKind),comps1);
    else
      equation
      Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function strongComponentsScalar failed
- sorting equations (strongComponents) failed");
      then fail();
  end matchcontinue;
end strongComponentsScalar;

public function eqnAssignmentNonScalar
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> ass2;
  output array<list<Integer>> outAcc;
protected
  list<Integer> elst, vlst;
  list<list<Integer>> acc := {};
algorithm
  for i in 1:arrayLength(mapEqnIncRow) loop
    elst := mapEqnIncRow[i];
    vlst := list(arrayGet(ass2, e) for e guard(arrayGet(ass2, e) > 0) in elst);
  end for;

  outAcc := listArray(listReverse(acc));
end eqnAssignmentNonScalar;

public function varAssignmentNonScalar
  input array<Integer> ass1;
  input array<Integer> mapIncRowEqn;
  output array<Integer> outAcc;
protected
  Integer e;
  list<Integer> acc := {};
algorithm
  for i in 1:arrayLength(ass1) loop
    e := ass1[i];
    e := if e > 0 then mapIncRowEqn[e] else -1;
    acc := e :: acc;
  end for;

  outAcc := listArray(listReverse(acc));
end varAssignmentNonScalar;

protected function analyseStrongComponentsScalar"author: Frenkel TUD 2011-05
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
  end match;
end analyseStrongComponentsScalar;

protected function analyseStrongComponentScalar"author: Frenkel TUD 2011-05
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
      list<Integer> comp,vlst;
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
        vlst = List.select1(vlst,intGt,0);
        varlst = List.map1r(vlst,BackendVariable.getVarAt,vars);
        var_varindx_lst = List.threadTuple(varlst,vlst);
        // get from scalar eqns indexes the indexes in the equation array
        comp = List.map1r(comp,arrayGet,mapIncRowEqn);
        comp = List.fold2(comp,uniqueComp,imark,markarray,{});
        //comp = List.unique(comp);
        eqn_lst = List.map1r(comp,BackendEquation.equationNth1,eqns);
        compX = analyseStrongComponentBlock(comp,eqn_lst,var_varindx_lst,syst,shared,ass1,ass2,false);
      then
        (compX,imark+1);
    else
      equation
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponentScalar failed");
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


public function strongComponents "author: PA

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
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (BackendDAE.EQSYSTEM(vars,eqs,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1=ass1,ass2=ass2),stateSets=stateSets,partitionKind=partitionKind),_)
      equation
        comps = tarjanAlgorithm(mt,ass2);
        comps1 = analyseStrongComponents(comps,syst,shared,ass1,ass2,{});
      then
        (BackendDAE.EQSYSTEM(vars,eqs,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1,ass2,comps1),stateSets,partitionKind),comps1);
    else
      equation
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function strongComponents failed
- sorting equations (strongComponents) failed");
      then fail();
  end matchcontinue;
end strongComponents;

protected function analyseStrongComponents"author: Frenkel TUD 2011-05
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
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponents failed");
      then
        fail();
  end match;
end analyseStrongComponents;

protected function analyseStrongComponent"author: Frenkel TUD 2011-05
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
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponent failed");
      then
        fail();
  end match;
end analyseStrongComponent;

protected function analyseStrongComponentBlock "author: Frenkel TUD 2011-05
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

    case (compelem::{},_,(_,v)::{},_,_,_,_,false)
      then BackendDAE.SINGLEEQUATION(compelem,v);

    case (comp,eqn_lst,var_varindx_lst,syst as BackendDAE.EQSYSTEM(orderedVars=_,orderedEqs=_),shared,_,_,_)
      equation
        var_lst = List.map(var_varindx_lst,Util.tuple21);
        //false = BackendVariable.hasDiscreteVar(var_lst); //lochel: mixed systems and non-linear systems are treated the same
        true = BackendVariable.hasContinousVar(var_lst);   //lochel: pure discrete equation systems are not supported
        varindxs = List.map(var_varindx_lst,Util.tuple22);
        eqn_lst1 = BackendEquation.replaceDerOpInEquationList(eqn_lst);
        // States are solved for der(x) not x.
        var_lst_1 = List.map(var_lst, transformXToXd);
        vars_1 = BackendVariable.listVar1(var_lst_1);
        eqns_1 = BackendEquation.listEquation(eqn_lst1);
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING(),{},BackendDAE.UNKNOWN_PARTITION());
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst,BackendDAE.ABSOLUTE(),NONE());
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        (jac,shared) = SymbolicJacobian.calculateJacobian(vars_1, eqns_1, m, true, shared);
        // Jacobian of a Linear System is always linear
        (jac_tp,jacConstant) = SymbolicJacobian.analyzeJacobian(vars_1,eqns_1,jac);
        // if constant check for singular jacobian
        true = analyzeConstantJacobian(jacConstant,jac,arrayLength(mt),var_lst,eqn_lst,shared);
      then
        BackendDAE.EQUATIONSYSTEM(comp,varindxs,BackendDAE.FULL_JACOBIAN(jac),jac_tp);

    case (_,eqn_lst,var_varindx_lst,BackendDAE.EQSYSTEM(orderedVars=_,orderedEqs=_),_,_,_,_)
      equation
        var_lst = List.map(var_varindx_lst,Util.tuple21);
        true = BackendVariable.hasDiscreteVar(var_lst);
        false = BackendVariable.hasContinousVar(var_lst);
        msg = "./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponentBlock failed
Sorry - Support for Discrete Equation Systems is not yet implemented\n";
        crlst = List.map(var_lst,BackendVariable.varCref);
        slst = List.map(crlst,ComponentReference.printComponentRefStr);
        msg = msg + stringDelimitList(slst,"\n");
        slst = List.map(eqn_lst,BackendDump.equationString);
        msg = msg + "\n" + stringDelimitList(slst,"\n");
        Error.addInternalError(msg);
      then
        fail();

    else
      equation
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function analyseStrongComponentBlock failed");
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
        jacVals = SymbolicJacobian.evaluateConstantJacobian(size,jac);
        rhsVals = List.fill(0.0,size);
        (_,linInfo) = System.dgesv(jacVals,rhsVals);
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
        if intGt(linInfo,0) then
          Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
        end if;
        syst = stringAppendList({eqnstr,"\n[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        if intLt(linInfo,0) then
          Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
        end if;
      then
        false;
    else true;
  end matchcontinue;
end analyzeConstantJacobian;

protected function transformXToXd "author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<DAE.Dimension> dim;
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

    else inVar;
  end match;
end transformXToXd;

public function getEquationAndSolvedVar "author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Equation> outEquation;
  output list<BackendDAE.Var> outVar;
  output Integer outIndex;
algorithm
  (outEquation, outVar, outIndex) := matchcontinue (inComp, inEquationArray, inVariables)
    local
      Integer v, e;
      list<Integer> elst, vlst;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqnlst, eqnlst1;
      list<BackendDAE.Var> varlst, varlst1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponent comp;
      list<tuple<Integer, list<Integer>>> eqnvartpllst;

    case (BackendDAE.SINGLEEQUATION(eqn=e, var=v), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        var = BackendVariable.getVarAt(vars, v);
      then
        ({eqn}, {var}, e);
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst, vars=vlst), eqns, vars)
      equation
        eqnlst = BackendEquation.getEqns(elst, eqns);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        e = List.first(elst);
      then
        (eqnlst, varlst, e);
    case (BackendDAE.SINGLEARRAY(eqn=e, vars=vlst), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn}, varlst, e);
    case (BackendDAE.SINGLEIFEQUATION(eqn=e, vars=vlst), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn}, varlst, e);
    case (BackendDAE.SINGLEALGORITHM(eqn=e, vars=vlst), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn}, varlst, e);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e, vars=vlst), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn}, varlst, e);
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e, vars=vlst), eqns, vars)
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      then
        ({eqn}, varlst, e);
    case (BackendDAE.TORNSYSTEM(tearingvars=vlst, residualequations=elst, otherEqnVarTpl=eqnvartpllst), eqns, vars)
      equation
        eqnlst = BackendEquation.getEqns(elst, eqns);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqnlst1 = BackendEquation.getEqns(List.map(eqnvartpllst, Util.tuple21), eqns);
        varlst1 = List.map1r(List.flatten(List.map(eqnvartpllst, Util.tuple22)), BackendVariable.getVarAt, vars);
        eqnlst = listAppend(eqnlst, eqnlst1);
        varlst = listAppend(varlst, varlst1);
        e = List.first(elst);
      then
        (eqnlst, varlst, e);
    case (_, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAETransform.getEquationAndSolvedVar failed!");
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar;

protected function getEquationAndSolvedVar_Internal
"author: PA
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
      Integer v,e;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      array<Integer> ass2;
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        eqn = BackendEquation.equationNth1(eqns, e);
        v = ass2[e];
        var = BackendVariable.getVarAt(vars, v);
      then
        (eqn,(var,v));
    case (e,_,_,_) /* equation no. assignments2 */
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAETransform.getEquationAndSolvedVar_Internal failed at index: " + intString(e));
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar_Internal;

public function getEquationAndSolvedVarIndxes
"author: Frenkel TUD
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

public function tarjanAlgorithm "author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (BackendDAE.IncidenceMatrixT, int vector)
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
        (_,comps) = strongConnectMain(mt, ass2, number, lowlink, stackflag, n, 1, {}, {});
      then
        comps;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAETransform.mo: function tarjansAlgorithm failed
The sorting of the equations could not be done. (strongComponents failed)
Use +d=failtrace for more information."});
      then fail();
  end matchcontinue;
end tarjanAlgorithm;

public function strongConnectMain
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer w;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
algorithm
  (ostack,ocomps) := strongConnectMain2(w>n,mt,a2,number,lowlink,stackflag,n,w,istack,icomps);
end strongConnectMain;

protected function strongConnectMain2
  input Boolean stop;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer w;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
algorithm
  (ostack,ocomps) := match (stop,mt,a2,number,lowlink,stackflag,n,w,istack,icomps)
    local
      Integer num;
      list<Integer> stack;
      list<list<Integer>> comps;

    case (true,_,_,_,_,_,_,_,_,_)
      then (istack,icomps);
    else
      equation
        (stack,comps) = strongConnectMain3(intEq(number[w],0),mt,a2,number,lowlink,stackflag,n,w,istack,icomps);
        (stack,comps) = strongConnectMain2(w+1>n,mt,a2,number,lowlink, stackflag, n, w + 1, stack, comps);
      then (stack,comps);
  end match;
end strongConnectMain2;

protected function strongConnectMain3
  input Boolean doCalc;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer w;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
algorithm
  (ostack,ocomps) := match (doCalc,mt,a2,number,lowlink,stackflag,n,w,istack,icomps)
    local
      Integer num;
      list<Integer> stack;
      list<list<Integer>> comps;

    case (true,_,_,_,_,_,_,_,_,_)
      equation
        (_,stack,comps) = strongConnect(mt,a2,number,lowlink,stackflag,0,w,istack,icomps);
      then (stack,comps);
    else (istack,icomps);
  end match;
end strongConnectMain3;

protected function strongConnect "author: PA

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
        Debug.traceln("- BackendDAETransform.strongConnect failed for eqn " + intString(v));
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "author: PA

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

public function reachableNodes "author: PA

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
        var = a2[eqn] "Got the variable that is solved in the equation";
        reachable = if intGt(var,0) then arrayGet(mt,var) else {} "Got the equations of that variable";
        reachable_1 = BackendDAEUtil.removeNegative(reachable) "in which other equations is this variable present ?";
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

protected function iterateReachableNodes
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
  (outI,outStack,outComps) := match (eqns,mt,a2,number,lowlink,stackflag,i,v,istack,icomps)
    local
      Integer i1,lv,lw,minv,w,nw,nv;
      list<Integer> stack,ws;
      list<list<Integer>> comps_1,comps_2,comps;

    // empty case
    case ({},_,_,_,_,_,_,_,_,_) then (i,istack,icomps);

    case (w :: ws,_,_,_,_,_,i1,_,stack,comps)
      equation
        (i1,stack,comps) = iterateReachableNodes2(w, mt, a2, number, lowlink, stackflag, i1, v, stack, comps);
        (i1,stack,comps) = iterateReachableNodes(ws, mt, a2, number, lowlink, stackflag, i1, v, stack, comps);
      then (i1,stack,comps);
  end match;
end iterateReachableNodes;

protected function iterateReachableNodes2
  input Integer eqn;
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
  (outI,outStack,outComps):= matchcontinue (eqn,mt,a2,number,lowlink,stackflag,i,v,istack,icomps)
    local
      Integer i1,lv,lw,minv,w,nw,nv;
      list<Integer> stack,ws;
      list<list<Integer>> comps_1,comps_2,comps;

    // nw is 0
    case (w,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(number[w],0);
        (i1,stack,comps_1) = strongConnect(mt, a2, number, lowlink, stackflag, i, w, istack, icomps);
        lv = lowlink[v];
        lw = lowlink[w];
        minv = intMin(lv, lw);
        _ = arrayUpdate(lowlink,v,minv);
      then (i1,stack,comps_1);

    // nw
    case (w,_,_,_,_,_,_,_,_,_)
      equation
        nw = number[w];
        nv = lowlink[v];
        (nw < nv) = true;
        true = stackflag[w];
        _ = arrayUpdate(lowlink,v,nw);
      then (i,istack,icomps);

    else (i,istack,icomps);

  end matchcontinue;
end iterateReachableNodes2;

protected function checkRoot "author: PA

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
    else (istack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "author: PA

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
    else (istack,listReverse(icomp));
  end matchcontinue;
end checkStack;

/******************************************
 traverseBackendDAEExps stuff
 *****************************************/

public function traverseBackendDAEExpsEqn
"author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outEquation,(_,outTypeA)) := traverseBackendDAEExpsEqnWithSymbolicOperation(inEquation,traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper,(func,inTypeA));
end traverseBackendDAEExpsEqn;

protected function traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>> inTpl;
  output DAE.Exp exp;
  output tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>> outTpl;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
protected
  FuncExpType func;
  Type_a arg;
  list<DAE.SymbolicOperation> ops;
algorithm
  (ops,(func,arg)) := inTpl;
  (exp,arg) := func(inExp,arg);
  outTpl := (ops,(func,arg));
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
    input DAE.Exp inExp;
    input tuple<list<DAE.SymbolicOperation>,Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>,Type_a> outTpl;
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
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source, attr=eqAttr),_,_)
      equation
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (e2_1,(ops,ext_arg_2)) = func(e2,(ops,ext_arg_1));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source,eqAttr),ext_arg_2);

    // Array equation
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source = source, attr=eqAttr),_,_)
      equation
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (e2_1,(ops,ext_arg_2)) = func(e2,(ops,ext_arg_1));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e1_1,e2_1,source,eqAttr),ext_arg_2);

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source, attr=eqAttr),_,_)
      equation
        e1 = Expression.crefExp(cr);
        (DAE.CREF(cr1,_),(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (e2_1,(ops,_)) = func(e2,(ops,ext_arg_1));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e2_1,source,eqAttr),ext_arg_1);

    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source, attr=eqAttr),_,_)
      equation
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1,source,eqAttr),ext_arg_1);

    // Algorithms
    case (BackendDAE.ALGORITHM(size = size,alg=DAE.ALGORITHM_STMTS(statementLst = statementLst),source = source, expand = crefExpand, attr=eqAttr),_,_)
      equation
        (statementLst,(ops,ext_arg_1)) = DAEUtil.traverseDAEEquationsStmts(statementLst, func, ({},inTypeA));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then (BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS(statementLst),source, crefExpand, eqAttr),ext_arg_1);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation =
          BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e1,elsewhenPart=NONE()),source = source, attr=eqAttr),_,_)
      equation
        e2 = Expression.crefExp(cr);
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (DAE.CREF(cr1,_),(ops,ext_arg_2)) = func(e2,(ops,ext_arg_1));
        (cond,(ops,ext_arg_3)) = func(cond,(ops,ext_arg_2));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        res = BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e1_1,NONE()),source,eqAttr);
     then
        (res,ext_arg_3);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation =
          BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source,attr=eqAttr),_,_)
      equation
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (cond,(ops,ext_arg_2)) = func(cond,(ops,ext_arg_1));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        (BackendDAE.WHEN_EQUATION(whenEquation=elsepartRes,source=source),ext_arg_3) = traverseBackendDAEExpsEqnWithSymbolicOperation(BackendDAE.WHEN_EQUATION(size,elsepart,source,eqAttr),func,ext_arg_2);
        res = BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr,e1_1,SOME(elsepartRes)),source,eqAttr);
      then
        (res,ext_arg_3);

    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source = source, attr=eqAttr),_,_)
      equation
        (e1_1,(ops,ext_arg_1)) = func(e1,({},inTypeA));
        (e2_1,(ops,ext_arg_2)) = func(e2,(ops,ext_arg_1));
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.COMPLEX_EQUATION(size,e1_1,e2_1,source,eqAttr),ext_arg_2);

    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source,attr=eqAttr),_,_)
      equation
        (expl,(ops,ext_arg_1)) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(expl,func,({},inTypeA),{});
        source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
        (eqnslst,ext_arg_1) = traverseBackendDAEExpsEqnLstLstWithSymbolicOperation(eqnslst,func,ext_arg_1,{});
        (eqns,ext_arg_1) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(eqns,func,ext_arg_1,{});
      then
        (BackendDAE.IF_EQUATION(expl,eqnslst,eqns,source,eqAttr),ext_arg_1);

    else
      equation
        Error.addInternalError("./Compiler/BackEnd/BackendDAETransform.mo: function traverseBackendDAEExpsEqnWithSymbolicOperation failed");
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
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
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
        (exp,arg) = func(exp,inTypeA);
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
    input DAE.Exp inExp;
    input tuple<list<DAE.SymbolicOperation>,Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>,Type_a> outTpl;
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
    input DAE.Exp inExp;
    input tuple<list<DAE.SymbolicOperation>,Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>,Type_a> outTpl;
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

protected function traverseBackendDAEExpsWhenOperator<ArgT>
"author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  input list<BackendDAE.WhenOperator> inReinitStmtLst;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.WhenOperator> outReinitStmtLst := {};
  output ArgT outArg := inArg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncExpType;
algorithm
  for rs in inReinitStmtLst loop
    rs := match(rs)
      local
        DAE.ComponentRef cr;
        DAE.Exp cond, msg, level, exp;
        DAE.ElementSource src;

      case BackendDAE.REINIT(cr, cond, src)
        equation
          (cond, outArg) = func(cond, outArg);
          (DAE.CREF(componentRef = cr), outArg) = func(Expression.crefExp(cr), outArg);
        then
          BackendDAE.REINIT(cr, cond, src);

      case BackendDAE.ASSERT(cond, msg, level, src)
        equation
          (cond, outArg) = func(cond, outArg);
        then
          BackendDAE.ASSERT(cond, msg, level, src);

      case BackendDAE.NORETCALL(exp, src)
        equation
          (exp, outArg) = Expression.traverseExp(exp, func, outArg);
        then
          BackendDAE.NORETCALL(exp, src);

      else rs;
    end match;

    outReinitStmtLst := rs :: outReinitStmtLst;
  end for;

  outReinitStmtLst := listReverse(outReinitStmtLst);
end traverseBackendDAEExpsWhenOperator;

public function traverseBackendDAEExpsWhenClauseLst<ArgT>
"author: Frenkel TUD 2010-11
  Traverse all expressions of a when clause list. It is possible to change the expressions"
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.WhenClause> outWhenClauseLst := {};
  output ArgT outArg := inArg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncExpType;
algorithm
  for wc in inWhenClauseLst loop
    wc := matchcontinue(wc)
      local
        DAE.Exp cond;
        list<BackendDAE.WhenOperator> reinit_lst;
        Option<Integer> else_idx;

      case BackendDAE.WHEN_CLAUSE(cond, reinit_lst, else_idx)
        equation
          (cond, outArg) = func(cond, inArg);
          (reinit_lst, outArg) = traverseBackendDAEExpsWhenOperator(reinit_lst, func, outArg);
        then
          BackendDAE.WHEN_CLAUSE(cond, reinit_lst, else_idx);

      else
        equation
          Error.addInternalError("BackendDAETransform.mo: function
            traverseBackendDAEExpsWhenClauseLst failed.");
        then
          fail();
    end matchcontinue;

    outWhenClauseLst := wc :: outWhenClauseLst;
  end for;

  outWhenClauseLst := listReverse(outWhenClauseLst);
end traverseBackendDAEExpsWhenClauseLst;

public function traverseBackendDAEExpsEqnList<ArgT>
"author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.Equation> outEquations := {};
  output ArgT outArg := inArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncExpType;
protected
algorithm
  for eq in inEquations loop
    (eq, outArg) := traverseBackendDAEExpsEqn(eq, func, outArg);
    outEquations := eq :: outEquations;
  end for;

  outEquations := listReverse(outEquations);
end traverseBackendDAEExpsEqnList;

annotation(__OpenModelica_Interface="backend");
end BackendDAETransform;
