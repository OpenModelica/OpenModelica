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
protected import Matching;
protected import SCode;
protected import Sorting;
protected import SymbolicJacobian;
protected import System;
protected import Util;
protected import Values;

// =============================================================================
// strongComponents and stuff
//
// =============================================================================

public function strongComponentsScalar "author: PA
  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations."
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.StrongComponents outComps "list of components";
protected
  list<list<Integer>> comps;
  array<Integer> ass1, ass2;
  BackendDAE.IncidenceMatrixT mt;
  BackendDAE.EquationArray eqs;
  BackendDAE.Variables vars;
  array<Integer> markarray;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  try
    BackendDAE.EQSYSTEM(vars, eqs, SOME(_), SOME(mt), BackendDAE.MATCHING(ass1=ass1, ass2=ass2), stateSets=stateSets, partitionKind=partitionKind) := inSystem;

    comps := Sorting.TarjanTransposed(mt, ass2);

    markarray := arrayCreate(BackendDAEUtil.equationArraySize(eqs), -1);
    outComps := analyseStrongComponentsScalar(comps, inSystem, inShared, ass1, ass2, mapEqnIncRow, mapIncRowEqn, 1, markarray);
    ass1 := varAssignmentNonScalar(ass1, mapIncRowEqn);

    // noscalass2 = eqnAssignmentNonScalar(1, arrayLength(mapEqnIncRow), mapEqnIncRow, ass2, {});
    // Frenkel TUD: Do not hand over the scalar incidence Matrix because following modules does not check if scalar or not
    outSystem := BackendDAE.EQSYSTEM(vars, eqs, NONE(), NONE(), BackendDAE.MATCHING(ass1, ass2, outComps), stateSets, partitionKind);
  else
    Error.addInternalError("function strongComponentsScalar failed (sorting strong components)", sourceInfo());
    fail();
  end try;
end strongComponentsScalar;

public function eqnAssignmentNonScalar
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> ass2;
  output array<list<Integer>> outAcc;
protected
  list<Integer> elst, vlst;
  list<list<Integer>> acc = {};
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
  list<Integer> acc = {};
algorithm
  for i in 1:arrayLength(ass1) loop
    e := ass1[i];
    e := if e > 0 then mapIncRowEqn[e] else -1;
    acc := e :: acc;
  end for;

  outAcc := listArray(listReverse(acc));
end varAssignmentNonScalar;

protected function analyseStrongComponentsScalar "author: Frenkel TUD 2011-05
  This analyses the type of the strongly connected components and calculates the jacobian."
  input list<list<Integer>> inComps;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer imark;
  input array<Integer> markarray;
  output BackendDAE.StrongComponents outComps = {};
protected
  BackendDAE.StrongComponent acomp;
  Integer mark = imark;
algorithm

  for comp in inComps loop
      (acomp, mark) := analyseStrongComponentScalar(comp, syst, shared, inAss1, inAss2, mapEqnIncRow, mapIncRowEqn, mark, markarray);
      outComps := acomp :: outComps;
  end for;
  outComps := listReverse(outComps);

end analyseStrongComponentsScalar;

protected function analyseStrongComponentScalar "author: Frenkel TUD 2011-05"
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
  output Integer omark = imark + 1;
protected
      list<Integer> comp, vlst;
      list<BackendDAE.Var> varlst;
      list<tuple<BackendDAE.Var, Integer>> var_varindx_lst;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqn_lst;
      BackendDAE.EquationArray eqns;
algorithm
     try
        BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns) := syst;
        vlst := List.map1r(inComp, arrayGet, inAss2);
        vlst := List.select1(vlst, intGt, 0);
        varlst := List.map1r(vlst, BackendVariable.getVarAt, vars);
        var_varindx_lst := List.threadTuple(varlst, vlst);
        // get from scalar eqns indexes the indexes in the equation array
        comp := List.map1r(inComp, arrayGet, mapIncRowEqn);
        comp := List.fold2(comp, uniqueComp, imark, markarray, {});
        //comp = List.unique(comp);
        eqn_lst := List.map1r(comp, BackendEquation.equationNth1, eqns);
        outComp := analyseStrongComponentBlock(comp, eqn_lst, var_varindx_lst, syst, shared);
    else
     Error.addInternalError("function analyseStrongComponentScalar failed", sourceInfo());
     fail();
  end try;
end analyseStrongComponentScalar;

protected function uniqueComp
  input Integer c;
  input Integer mark;
  input array<Integer> markarray;
  input list<Integer> iAcc;
  output list<Integer> oAcc = iAcc;
algorithm
  if mark <> markarray[c] then
    arrayUpdate(markarray,c,mark);
    oAcc := c::iAcc;
  end if;
end uniqueComp;

protected function analyseStrongComponentBlock "author: Frenkel TUD 2011-05"
  input list<Integer> inComp;
  input list<BackendDAE.Equation> inEqnLst;
  input list<tuple<BackendDAE.Var, Integer>> inVarVarindxLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp := matchcontinue (inComp, inEqnLst, inVarVarindxLst)
    local
      Integer compelem, v;
      list<Integer> comp, varindxs;
      list<tuple<BackendDAE.Var, Integer>> var_varindx_lst, var_varindx_lst_cond;
      array<Integer> ass1, ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Variables vars, vars_1;
      list<BackendDAE.Equation> eqn_lst, eqn_lst1, cont_eqn, disc_eqn;
      list<BackendDAE.Var> var_lst, var_lst_1, cont_var, disc_var;
      list<Integer> indxcont_var, indxdisc_var, indxcont_eqn, indxdisc_eqn;
      BackendDAE.EquationArray eqns_1, eqns;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.StrongComponent sc;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      String msg;
      list<DAE.ComponentRef> crlst;
      list<DAE.Exp> expLst;
      list<String> slst;
      Boolean jacConstant, mixedSystem, b1;

    case (compelem::{}, BackendDAE.ALGORITHM()::{}, var_varindx_lst) equation
      varindxs = List.map(var_varindx_lst, Util.tuple22);
    then BackendDAE.SINGLEALGORITHM(compelem, varindxs);

    case (compelem::{}, BackendDAE.ARRAY_EQUATION()::{}, var_varindx_lst) equation
      varindxs = List.map(var_varindx_lst, Util.tuple22);
      var_lst = List.map(var_varindx_lst, Util.tuple21);
      crlst = List.map(var_lst,BackendVariable.varCref);
       // its only an array equation if all the solved variables belong to an array. Otherwise we have to handle it as a non-linear system
      b1 =  List.fold(List.map(crlst,ComponentReference.isArrayElement),boolAnd,true);
      if not b1 then
        expLst = List.map(crlst, Expression.crefExp);
        true = List.exist1(inEqnLst,crefsAreArray,expLst);
      end if;
    then BackendDAE.SINGLEARRAY(compelem, varindxs);

    case (compelem::{}, BackendDAE.IF_EQUATION()::{}, var_varindx_lst) equation
      varindxs = List.map(var_varindx_lst, Util.tuple22);
    then BackendDAE.SINGLEIFEQUATION(compelem, varindxs);

    case (compelem::{}, BackendDAE.COMPLEX_EQUATION()::{}, var_varindx_lst) equation
      varindxs = List.map(var_varindx_lst, Util.tuple22);
    then BackendDAE.SINGLECOMPLEXEQUATION(compelem, varindxs);

    case (compelem::{}, BackendDAE.WHEN_EQUATION()::{}, var_varindx_lst) equation
      varindxs = List.map(var_varindx_lst, Util.tuple22);
    then BackendDAE.SINGLEWHENEQUATION(compelem, varindxs);

    case (compelem::{}, _, (_, v)::{})
    then BackendDAE.SINGLEEQUATION(compelem, v);

    case (comp, eqn_lst, var_varindx_lst) equation
      var_lst = List.map(var_varindx_lst, Util.tuple21);
      //false = BackendVariable.hasDiscreteVar(var_lst); //lochel: mixed systems and non-linear systems are treated the same
      true = BackendVariable.hasContinousVar(var_lst);   //lochel: pure discrete equation systems are not supported
      varindxs = List.map(var_varindx_lst, Util.tuple22);
      eqn_lst1 = BackendEquation.replaceDerOpInEquationList(eqn_lst);
      // States are solved for der(x) not x.
      var_lst_1 = List.map(var_lst, transformXToXd);
      vars_1 = BackendVariable.listVar1(var_lst_1);
      eqns_1 = BackendEquation.listEquation(eqn_lst1);
      (mixedSystem, _) = BackendEquation.iterationVarsinRelations(eqn_lst1, vars_1);
      syst = BackendDAE.EQSYSTEM(vars_1, eqns_1, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
      (m, mt) = BackendDAEUtil.incidenceMatrix(syst, BackendDAE.ABSOLUTE(), NONE());
      // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
      (jac, shared) = SymbolicJacobian.calculateJacobian(vars_1, eqns_1, m, true, ishared);
      // Jacobian of a Linear System is always linear
      (jac_tp, jacConstant) = SymbolicJacobian.analyzeJacobian(vars_1, eqns_1, jac);
      // if constant check for singular jacobian
      true = analyzeConstantJacobian(jacConstant, jac, arrayLength(mt), var_lst, eqn_lst, shared);
    then BackendDAE.EQUATIONSYSTEM(comp, varindxs, BackendDAE.FULL_JACOBIAN(jac), jac_tp, mixedSystem);

    case (_, eqn_lst, var_varindx_lst) equation
      var_lst = List.map(var_varindx_lst, Util.tuple21);
      true = BackendVariable.hasDiscreteVar(var_lst);
      false = BackendVariable.hasContinousVar(var_lst);
      msg = getInstanceName() + " failed (Sorry - Support for Discrete Equation Systems is not yet implemented)\n";
      crlst = List.map(var_lst, BackendVariable.varCref);
      slst = List.map(crlst, ComponentReference.printComponentRefStr);
      msg = msg + stringDelimitList(slst, "\n");
      slst = List.map(eqn_lst, BackendDump.equationString);
      msg = msg + "\n" + stringDelimitList(slst, "\n");
      Error.addInternalError(msg, sourceInfo());
    then fail();

    case (_, eqn_lst, var_varindx_lst) equation
      var_lst = List.map(var_varindx_lst, Util.tuple21);
      msg = getInstanceName() + " failed\nvariables:\n  ";
      crlst = List.map(var_lst, BackendVariable.varCref);
      slst = List.map(crlst, ComponentReference.printComponentRefStr);
      msg = msg + stringDelimitList(slst, "\n  ");
      slst = List.map(eqn_lst, BackendDump.equationString);
      msg = msg + "\nequations:\n  " + stringDelimitList(slst, "\n  ");
      Error.addInternalError(msg, sourceInfo());
    then fail();

    else equation
      Error.addInternalError("function analyseStrongComponentBlock failed", sourceInfo());
    then fail();
  end matchcontinue;
end analyseStrongComponentBlock;

protected function crefsAreArray "author:Waurich TUD 2015-03
  checks if the crefs build an array on one side of the equation (sometimes used in FMUs)"
  input BackendDAE.Equation eqIn;
  input list<DAE.Exp> crefLst;
  output Boolean isUnsolvable;
algorithm
  isUnsolvable := matchcontinue(eqIn)
    local
      list<DAE.Exp> expLst;

    case BackendDAE.ARRAY_EQUATION(left=DAE.ARRAY(array=expLst)) algorithm
      (_, _, expLst) := List.intersection1OnTrue(expLst, crefLst, Expression.expEqual);
    then listEmpty(expLst);

    case BackendDAE.ARRAY_EQUATION(right=DAE.ARRAY(array=expLst)) algorithm
      (_, _, expLst) := List.intersection1OnTrue(expLst, crefLst, Expression.expEqual);
    then listEmpty(expLst);

    else false;
  end matchcontinue;
end crefsAreArray;

protected function analyzeConstantJacobian
  input Boolean jacConstant;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> iJac;
  input Integer size;
  input list<BackendDAE.Var> iVars;
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Shared shared;
  output Boolean valid;
algorithm
  valid := matchcontinue(jacConstant, iJac)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<Real> rhsVals, solvedVals;
      list<list<Real>> jacVals;
      Integer linInfo;
      String infoStr, syst, varnames, varname, rhsStr, jacStr, eqnstr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.FunctionTree funcs;
      list<DAE.Exp> beqs;

    case(true, SOME(jac)) equation
      jacVals = SymbolicJacobian.evaluateConstantJacobian(size, jac);
      rhsVals = List.fill(0.0, size);
      (_, linInfo) = System.dgesv(jacVals, rhsVals);
      false = intEq(linInfo, 0);
      varname = ComponentReference.printComponentRefStr(BackendVariable.varCref(listGet(iVars, linInfo)));
      infoStr = intString(linInfo);
      varnames = stringDelimitList(List.map(List.map(iVars, BackendVariable.varCref), ComponentReference.printComponentRefStr), " ;\n  ");
      eqns = BackendEquation.listEquation(iEqns);
      vars = BackendVariable.listVar1(iVars);
      funcs = BackendDAEUtil.getFunctions(shared);
      (beqs, _) = BackendDAEUtil.getEqnSysRhs(eqns, vars, SOME(funcs));
      beqs = listReverse(beqs);
      rhsStr = stringDelimitList(List.map(beqs, ExpressionDump.printExpStr), " ;\n  ");
      jacStr = stringDelimitList(List.map1(List.mapList(jacVals, realString), stringDelimitList, " , "), " ;\n  ");
      eqnstr = BackendDump.dumpEqnsStr(iEqns);
      syst = stringAppendList({"\n", eqnstr, "\n[\n  ", jacStr, "\n]\n  *\n[\n  ", varnames, "\n]\n  =\n[\n  ", rhsStr, "\n]"});
      if intGt(linInfo, 0) then
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst, infoStr, varname});
      end if;
      syst = stringAppendList({eqnstr, "\n[", jacStr, "] * [", varnames, "] = [", rhsStr, "]"});
      if intLt(linInfo, 0) then
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv", syst});
      end if;
    then false;

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
      Option<BackendDAE.TearingSelect> ts;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      DAE.VarInnerOuter io;

    case BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varDirection=dir, varParallelism=prl, varType=tp, bindExp=exp, bindValue=v, arryDim=dim, source=source, values=attr, tearingSelectOption=ts, comment=comment, connectorType=ct, innerOuter=io) equation
      cr = ComponentReference.crefPrefixDer(cr);
    then BackendDAE.VAR(cr, BackendDAE.STATE_DER(), dir, prl, tp, exp, v, dim, source, attr, ts, comment, ct, io, false);

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

    case (BackendDAE.SINGLEEQUATION(eqn=e, var=v), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      var = BackendVariable.getVarAt(vars, v);
    then ({eqn}, {var}, e);

    case (BackendDAE.EQUATIONSYSTEM(eqns=elst, vars=vlst), eqns, vars) equation
      eqnlst = BackendEquation.getEqns(elst, eqns);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      e = listHead(elst);
    then (eqnlst, varlst, e);

    case (BackendDAE.SINGLEARRAY(eqn=e, vars=vlst), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
    then ({eqn}, varlst, e);

    case (BackendDAE.SINGLEIFEQUATION(eqn=e, vars=vlst), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
    then ({eqn}, varlst, e);

    case (BackendDAE.SINGLEALGORITHM(eqn=e, vars=vlst), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
    then ({eqn}, varlst, e);

    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e, vars=vlst), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
    then ({eqn}, varlst, e);

    case (BackendDAE.SINGLEWHENEQUATION(eqn=e, vars=vlst), eqns, vars) equation
      eqn = BackendEquation.equationNth1(eqns, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
    then ({eqn}, varlst, e);

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=elst, otherEqnVarTpl=eqnvartpllst)), eqns, vars) equation
      eqnlst = BackendEquation.getEqns(elst, eqns);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
      eqnlst1 = BackendEquation.getEqns(List.map(eqnvartpllst, Util.tuple21), eqns);
      varlst1 = List.map1r(List.flatten(List.map(eqnvartpllst, Util.tuple22)), BackendVariable.getVarAt, vars);
      eqnlst = listAppend(eqnlst, eqnlst1);
      varlst = listAppend(varlst, varlst1);
      e = listHead(elst);
    then (eqnlst, varlst, e);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("BackendDAETransform.getEquationAndSolvedVar failed!");
    then fail();
  end matchcontinue;
end getEquationAndSolvedVar;

public function getEquationAndSolvedVarIndxes "author: Frenkel TUD
  Retrieves the equation and the variable indexes solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  output list<Integer> outEquation;
  output list<Integer> outVar;
algorithm
  (outEquation, outVar) := matchcontinue(inComp)
    local
      Integer v, e;
      list<Integer> elst, vlst, elst1, vlst1;
      BackendDAE.StrongComponent comp;
      list<tuple<Integer, list<Integer>>> eqnvartpllst;

    case (BackendDAE.SINGLEEQUATION(eqn=e, var=v))
    then ({e}, {v});

    case BackendDAE.EQUATIONSYSTEM(eqns=elst, vars=vlst)
    then (elst, vlst);

    case BackendDAE.SINGLEARRAY(eqn=e, vars=vlst)
    then ({e}, vlst);

    case BackendDAE.SINGLEIFEQUATION(eqn=e, vars=vlst)
    then ({e}, vlst);

    case BackendDAE.SINGLEALGORITHM(eqn=e, vars=vlst)
    then ({e}, vlst);

    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=e, vars=vlst)
    then ({e}, vlst);

    case BackendDAE.SINGLEWHENEQUATION(eqn=e, vars=vlst)
    then ({e}, vlst);

    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=elst, otherEqnVarTpl=eqnvartpllst)) equation
      elst1 = List.map(eqnvartpllst, Util.tuple21);
      vlst1 = List.flatten(List.map(eqnvartpllst, Util.tuple22));
      elst = listAppend(elst1, elst);
      vlst = listAppend(vlst1, vlst);
    then (elst, vlst);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("BackendDAETransform.getEquationAndSolvedVarIndxes failed!");
    then fail();
  end matchcontinue;
end getEquationAndSolvedVarIndxes;


// =============================================================================
// traverseBackendDAEExps stuff
//
// =============================================================================

public function traverseExpsOfEquation "author: Frenkel TUD 2010-11
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
  (outEquation, (_, outTypeA)) := traverseBackendDAEExpsEqnWithSymbolicOperation(inEquation, traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper, (func, inTypeA));
end traverseExpsOfEquation;

protected function traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input tuple<list<DAE.SymbolicOperation>, tuple<FuncExpType, Type_a>> inTpl;
  output DAE.Exp exp;
  output tuple<list<DAE.SymbolicOperation>, tuple<FuncExpType, Type_a>> outTpl;
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
  (ops, (func, arg)) := inTpl;
  (exp, arg) := func(inExp, arg);
  outTpl := (ops, (func, arg));
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
    input tuple<list<DAE.SymbolicOperation>, Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation, outTypeA) := matchcontinue (inEquation)
    local
      DAE.Exp e1_1, e2_1, e1, e2, cond;
      DAE.ComponentRef cr, cr1;
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
      Type_a ext_arg_1, ext_arg_2, ext_arg_3;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;

    case BackendDAE.EQUATION(exp = e1, scalar = e2, source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.EQUATION(e1_1, e2_1, source, eqAttr), ext_arg_2);

    // Array equation
    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left = e1, right = e2, source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.ARRAY_EQUATION(dimSize, e1_1, e2_1, source, eqAttr), ext_arg_2);

    case BackendDAE.SOLVED_EQUATION(componentRef = cr, exp = e2, source=source, attr=eqAttr) equation
      e1 = Expression.crefExp(cr);
      (DAE.CREF(cr1, _), (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, _)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.SOLVED_EQUATION(cr1, e2_1, source, eqAttr), ext_arg_1);

    case BackendDAE.RESIDUAL_EQUATION(exp = e1, source=source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.RESIDUAL_EQUATION(e1_1, source, eqAttr), ext_arg_1);

    // Algorithms
    case BackendDAE.ALGORITHM(size = size, alg=DAE.ALGORITHM_STMTS(statementLst = statementLst), source = source, expand = crefExpand, attr=eqAttr) equation
      (statementLst, (ops, ext_arg_1)) = DAEUtil.traverseDAEEquationsStmts(statementLst, func, ({}, inTypeA));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(statementLst), source, crefExpand, eqAttr), ext_arg_1);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left = cr, right = e1, elsewhenPart=NONE()), source = source, attr=eqAttr) equation
      e2 = Expression.crefExp(cr);
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (DAE.CREF(cr1, _), (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      (cond, (ops, ext_arg_3)) = func(cond, (ops, ext_arg_2));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      res = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr1, e1_1, NONE()), source, eqAttr);
   then (res, ext_arg_3);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left = cr, right = e1, elsewhenPart=SOME(elsepart)), source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (cond, (ops, ext_arg_2)) = func(cond, (ops, ext_arg_1));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      (BackendDAE.WHEN_EQUATION(whenEquation=elsepartRes, source=source), ext_arg_3) = traverseBackendDAEExpsEqnWithSymbolicOperation(BackendDAE.WHEN_EQUATION(size, elsepart, source, eqAttr), func, ext_arg_2);
      res = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr, e1_1, SOME(elsepartRes)), source, eqAttr);
    then (res, ext_arg_3);

    case BackendDAE.COMPLEX_EQUATION(size=size, left = e1, right = e2, source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
    then (BackendDAE.COMPLEX_EQUATION(size, e1_1, e2_1, source, eqAttr), ext_arg_2);

    case BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source, attr=eqAttr) equation
      (expl, (ops, ext_arg_1)) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(expl, func, ({}, inTypeA), {});
      source = List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
      (eqnslst, ext_arg_1) = traverseBackendDAEExpsEqnLstLstWithSymbolicOperation(eqnslst, func, ext_arg_1, {});
      (eqns, ext_arg_1) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(eqns, func, ext_arg_1, {});
    then (BackendDAE.IF_EQUATION(expl, eqnslst, eqns, source, eqAttr), ext_arg_1);

    else equation
      Error.addInternalError("function traverseBackendDAEExpsEqnWithSymbolicOperation failed", sourceInfo());
    then fail();
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
  (outExps, outTypeA) := match (inExps)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest, exps;
      Type_a arg;

    case {}
    then (listReverse(iAcc), inTypeA);

    case exp::rest equation
      (exp, arg) = func(exp, inTypeA);
      (exps, arg) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(rest, func, arg, exp::iAcc);
    then (exps, arg);
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
    input tuple<list<DAE.SymbolicOperation>, Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEqns, outTypeA) := match (inEqns)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest, eqns;
      Type_a arg;

    case {}
    then (listReverse(iAcc), inTypeA);

    case eqn::rest equation
      (eqn, arg) = traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, func, inTypeA);
      (eqns, arg) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(rest, func, arg, eqn::iAcc);
    then (eqns, arg);
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
    input tuple<list<DAE.SymbolicOperation>, Type_a> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEqns, outTypeA) := match (inEqns, func, inTypeA, iAcc)
    local
      list<BackendDAE.Equation> eqn;
      list<list<BackendDAE.Equation>> rest, eqnslst;
      Type_a arg;
    case({}, _, _, _) then (listReverse(iAcc), inTypeA);
    case(eqn::rest, _, _, _)
      equation
        (eqn, arg) = traverseBackendDAEExpsEqnLstWithSymbolicOperation(eqn, func, inTypeA, {});
        (eqnslst, arg) = traverseBackendDAEExpsEqnLstLstWithSymbolicOperation(rest, func, arg, eqn::iAcc);
      then
        (eqnslst, arg);
  end match;
end traverseBackendDAEExpsEqnLstLstWithSymbolicOperation;

protected function traverseBackendDAEExpsWhenOperator<ArgT> "author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  input list<BackendDAE.WhenOperator> inReinitStmtLst;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.WhenOperator> outReinitStmtLst = {};
  output ArgT outArg = inArg;
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

      case BackendDAE.REINIT(cr, cond, src) equation
        (cond, outArg) = func(cond, outArg);
        (DAE.CREF(componentRef = cr), outArg) = func(Expression.crefExp(cr), outArg);
      then BackendDAE.REINIT(cr, cond, src);

      case BackendDAE.ASSERT(cond, msg, level, src) equation
        (cond, outArg) = func(cond, outArg);
      then BackendDAE.ASSERT(cond, msg, level, src);

      case BackendDAE.NORETCALL(exp, src) equation
        (exp, outArg) = Expression.traverseExpBottomUp(exp, func, outArg);
      then BackendDAE.NORETCALL(exp, src);

      else rs;
    end match;

    outReinitStmtLst := rs::outReinitStmtLst;
  end for;

  outReinitStmtLst := listReverse(outReinitStmtLst);
end traverseBackendDAEExpsWhenOperator;

public function traverseBackendDAEExpsWhenClauseLst<ArgT> "author: Frenkel TUD 2010-11
  Traverse all expressions of a when clause list. It is possible to change the expressions"
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.WhenClause> outWhenClauseLst = {};
  output ArgT outArg = inArg;
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

      case BackendDAE.WHEN_CLAUSE(cond, reinit_lst, else_idx) equation
        (cond, outArg) = func(cond, inArg);
        (reinit_lst, outArg) = traverseBackendDAEExpsWhenOperator(reinit_lst, func, outArg);
      then BackendDAE.WHEN_CLAUSE(cond, reinit_lst, else_idx);

      else equation
        Error.addInternalError("function traverseBackendDAEExpsWhenClauseLst failed.", sourceInfo());
      then fail();
    end matchcontinue;

    outWhenClauseLst := wc :: outWhenClauseLst;
  end for;

  outWhenClauseLst := listReverse(outWhenClauseLst);
end traverseBackendDAEExpsWhenClauseLst;

public function traverseExpsOfEquationList<ArgT> "author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.Equation> outEquations = {};
  output ArgT outArg = inArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncExpType;
algorithm
  for eq in inEquations loop
    (eq, outArg) := traverseExpsOfEquation(eq, func, outArg);
    outEquations := eq :: outEquations;
  end for;

  outEquations := listReverse(outEquations);
end traverseExpsOfEquationList;

annotation(__OpenModelica_Interface="backend");
end BackendDAETransform;
