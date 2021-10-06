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


"

public
  import BackendDAE;
  import DAE;

protected
  import BackendDAEUtil;
  import BackendDump;
  import BackendEquation;
  import BackendVariable;
  import ComponentReference;
  import DAEUtil;
  import Debug;
  import ElementSource;
  import Error;
  import Expression;
  import ExpressionDump;
  import Flags;
  import GC;
  import List;
  import MetaModelica.Dangerous;
  import Sorting;
  import SymbolicJacobian;
  import System;
  import Util;

// =============================================================================
// strongComponents and stuff
//
// =============================================================================

public function strongComponentsScalar "author: PA
  This is the second part of the BLT sorting. It takes the variable
  assignments and the adjacency matrix as input and identifies strong
  components, i.e. subsystems of equations."
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.StrongComponents outComps "list of components";
algorithm
  (outSystem, outComps) := matchcontinue inSystem
    local
      BackendDAE.EqSystem syst;
      BackendDAE.AdjacencyMatrixT mt;
      BackendDAE.StrongComponents comps;
      array<Integer> ass1, ass2;
      array<Integer> markarray;
      list<list<Integer>> comps_m;

    case syst as BackendDAE.EQSYSTEM(mT=SOME(mt), matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2)) algorithm
      comps_m := Sorting.TarjanTransposed(mt, ass2);

      markarray := arrayCreate(BackendEquation.getNumberOfEquations(inSystem.orderedEqs), -1);
      comps := analyseStrongComponentsScalar(comps_m, inSystem, inShared, ass1, ass2, mapEqnIncRow, mapIncRowEqn, 1, markarray);
      GC.free(markarray);
      ass1 := varAssignmentNonScalar(ass1, mapIncRowEqn);

      // Frenkel TUD: Do not hand over the scalar adjacency Matrix because following modules does not check if scalar or not
      syst := BackendDAE.EQSYSTEM(syst.orderedVars, syst.orderedEqs, NONE(), NONE(), NONE(), BackendDAE.MATCHING(ass1, ass2, comps), syst.stateSets, syst.partitionKind, syst.removedEqs);
    then (syst, comps);

    else algorithm
      Error.addInternalError("function strongComponentsScalar failed (sorting strong components)", sourceInfo());
    then fail();
  end matchcontinue;
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
    acc := vlst::acc;
  end for;

  outAcc := List.listArrayReverse(acc);
end eqnAssignmentNonScalar;

public function varAssignmentNonScalar
  input array<Integer> ass1;
  input array<Integer> mapIncRowEqn;
  output array<Integer> outAcc;
algorithm
  outAcc := Dangerous.arrayCreateNoInit(arrayLength(ass1),-1);
  for i in 1:arrayLength(ass1) loop
    Dangerous.arrayUpdateNoBoundsChecking(outAcc, i, if Dangerous.arrayGetNoBoundsChecking(ass1,i) > 0 then mapIncRowEqn[Dangerous.arrayGetNoBoundsChecking(ass1,i)] else -1);
  end for;
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
  list<BackendDAE.StrongComponent> acomp;
  Integer mark = imark;
algorithm
  for comp in inComps loop
    (acomp, mark) := analyseStrongComponentScalar(comp, syst, shared, inAss1, inAss2, mapEqnIncRow, mapIncRowEqn, mark, markarray);
    outComps := listAppend(acomp,outComps);
  end for;

  outComps := Dangerous.listReverseInPlace(outComps);
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
  output list<BackendDAE.StrongComponent> outComp;
  output Integer omark = imark + 1;
protected
  list<Integer> comp, vlst;
  list<BackendDAE.Var> varlst;
  BackendDAE.Variables vars;
  list<BackendDAE.Equation> eqn_lst;
  BackendDAE.EquationArray eqns;
algorithm
  try
    BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns) := syst;
    vlst := List.map1r(inComp, arrayGet, inAss2);
    vlst := List.select1(vlst, intGt, 0);
    varlst := List.map1r(vlst, BackendVariable.getVarAt, vars);

    // get from scalar eqns indexes the indexes in the equation array
    comp := List.map1r(inComp, arrayGet, mapIncRowEqn);
    comp := List.fold2(comp, uniqueComp, imark, markarray, {});
    //comp = List.unique(comp);
    eqn_lst := List.map1r(comp, BackendEquation.get, eqns);
    outComp := analyseStrongComponentBlock(comp, eqn_lst, varlst, vlst, syst, shared, mapEqnIncRow);
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
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inVarindxLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<list<Integer>> mapEqnIncRow;
  output list<BackendDAE.StrongComponent> outComp;
algorithm
  outComp := matchcontinue (inComp, inEqnLst, inVarLst, inVarindxLst)
    local
      Integer compelem, v;
      list<Integer> comp, varindxs;
      array<Integer> ass1, ass2;
      BackendDAE.AdjacencyMatrix m;
      BackendDAE.AdjacencyMatrixT mt;
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
      list<BackendDAE.StrongComponent> algorithmComp;

    case (compelem::{}, BackendDAE.ALGORITHM()::{}, _, varindxs)
    then {BackendDAE.SINGLEALGORITHM(compelem, varindxs)};

    case (compelem::{}, BackendDAE.ARRAY_EQUATION()::{}, var_lst, varindxs) equation
      crlst = List.map(var_lst,BackendVariable.varCref);
       // its only an array equation if all the solved variables belong to an array. Otherwise we have to handle it as a non-linear system
      b1 =  List.applyAndFold(crlst,boolAnd,ComponentReference.isArrayElement,true);
      if not b1 then
        expLst = List.map(crlst, Expression.crefExp);
        true = List.exist1(inEqnLst,crefsAreArray,expLst);
      end if;
    then {BackendDAE.SINGLEARRAY(compelem, varindxs)};

    case (compelem::{}, BackendDAE.IF_EQUATION()::{}, _, varindxs)
    then {BackendDAE.SINGLEIFEQUATION(compelem, varindxs)};

    case (compelem::{}, BackendDAE.COMPLEX_EQUATION()::{}, _, varindxs)
    then {BackendDAE.SINGLECOMPLEXEQUATION(compelem, varindxs)};

    case (compelem::{}, BackendDAE.WHEN_EQUATION()::{}, _, varindxs)
    then {BackendDAE.SINGLEWHENEQUATION(compelem, varindxs)};

    case (compelem::{}, _, _, v::{})
    then {BackendDAE.SINGLEEQUATION(compelem, v)};

    case (comp, eqn_lst, var_lst, varindxs) equation
      //false = BackendVariable.hasDiscreteVar(var_lst); //lochel: mixed systems and non-linear systems are treated the same
      true = BackendVariable.hasContinuousVar(var_lst);   //lochel: pure discrete equation systems are not supported
      eqn_lst1 = BackendEquation.replaceDerOpInEquationList(eqn_lst);
      // States are solved for der(x) not x.
      var_lst_1 = List.map(var_lst, transformXToXd);
      vars_1 = BackendVariable.listVar1(var_lst_1);
      eqns_1 = BackendEquation.listEquation(eqn_lst1);
      (mixedSystem, _) = BackendEquation.iterationVarsinRelations(eqn_lst1, vars_1);
      if not Flags.isSet(Flags.DISABLE_JACSCC) then
        syst = BackendDAEUtil.createEqSystem(vars_1, eqns_1);
        (m, mt) = BackendDAEUtil.adjacencyMatrix(syst, BackendDAE.ABSOLUTE(), NONE(), BackendDAEUtil.isInitializationDAE(ishared));
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        (jac, shared) = SymbolicJacobian.calculateJacobian(vars_1, eqns_1, m, true, ishared);
        // Jacobian of a Linear System is always linear
        (jac_tp, jacConstant) = SymbolicJacobian.analyzeJacobian(vars_1, eqns_1, jac);

        // if Jacobian is constant, then check if it is singular
        if jacConstant and isSome(jac) then
          true = analyzeConstantJacobian(Util.getOption(jac), arrayLength(mt), var_lst, eqn_lst, shared);
        end if;
      else
        jac = NONE();
        jac_tp = BackendDAE.JAC_NO_ANALYTIC();
      end if;
    then {BackendDAE.EQUATIONSYSTEM(comp, varindxs, BackendDAE.FULL_JACOBIAN(jac), jac_tp, mixedSystem)};

    /*
      All algorithms - assume each can be solved for its matched variables.
      Purely discrete algebraic loops are not solvable otherwise.
      Related to ticket #5659
    */
    case (comp, eqn_lst, var_lst, varindxs)
      guard(BackendEquation.allAlgorithmsLst(eqn_lst))
      algorithm
        true := BackendVariable.hasDiscreteVar(var_lst);
        false := BackendVariable.hasContinuousVar(var_lst);
        BackendDAE.MATCHING(ass1, ass2, _) := isyst.matching;
        algorithmComp := {};
        for c in comp loop
          indxdisc_var := {};
          // get matched variables for each aglorithm
          for j in mapEqnIncRow[c] loop
            indxdisc_var := ass2[j] :: indxdisc_var;
          end for;
          algorithmComp := BackendDAE.SINGLEALGORITHM(c, indxdisc_var) :: algorithmComp;
        end for;
    then algorithmComp;

    /* Purely discrete algebraic loops are not solvable. */
    case (_, eqn_lst, var_lst, _) equation
      true = BackendVariable.hasDiscreteVar(var_lst);
      false = BackendVariable.hasContinuousVar(var_lst);
      msg = getInstanceName() + " failed (Purely discrete algebraic loops cannot be solved by iterative processes. Try to break them open using the delay() operator.)\n";
      crlst = List.map(var_lst, BackendVariable.varCref);
      slst = List.map(crlst, ComponentReference.printComponentRefStr);
      msg = msg + stringDelimitList(slst, "\n");
      slst = List.map(eqn_lst, BackendDump.equationString);
      msg = msg + "\n" + stringDelimitList(slst, "\n");
      Error.addInternalError(msg, sourceInfo());
    then fail();

    case (_, eqn_lst, var_lst, _) equation
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
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inJac;
  input Integer inSize;
  input list<BackendDAE.Var> inVars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.Shared inShared;
  output Boolean outValid = true;
protected
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  DAE.FunctionTree funcs;
  Integer info;
  String infoStr, syst, varnames, varname, rhsStr, jacStr, eqnstr;
  list<DAE.Exp> beqs;
  list<Real> rhsVals;
  list<list<Real>> jacVals;
algorithm
  jacVals := SymbolicJacobian.evaluateConstantJacobian(inSize, inJac);
  rhsVals := List.fill(0.0, inSize);
  (_, info) := System.dgesv(jacVals, rhsVals);

  if info < 0 then
    // info < 0:  if INFO = -i, the i-th argument had an illegal value
    // this case should never happen
    varnames := stringDelimitList(List.mapMap(inVars, BackendVariable.varCref, ComponentReference.printComponentRefStr), " ;\n  ");
    eqns := BackendEquation.listEquation(inEqns);
    vars := BackendVariable.listVar1(inVars);
    funcs := BackendDAEUtil.getFunctions(inShared);
    (beqs, _) := BackendDAEUtil.getEqnSysRhs(eqns, vars, SOME(funcs));
    beqs := listReverse(beqs);
    rhsStr := stringDelimitList(List.map(beqs, ExpressionDump.printExpStr), " ;\n  ");
    jacStr := stringDelimitList(List.map1(List.mapList(jacVals, realString), stringDelimitList, " , "), " ;\n  ");
    eqnstr := BackendDump.dumpEqnsStr(inEqns);
    syst := eqnstr + "\n[" + jacStr + "] * [" + varnames + "] = [" + rhsStr + "]";
    Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv", syst});
    outValid := false;
  elseif info > 0 then
    // info > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
    //            has been completed, but the factor U is exactly
    //            singular, so the solution could not be computed.
    varname := ComponentReference.printComponentRefStr(BackendVariable.varCref(listGet(inVars, info)));
    infoStr := intString(info);
    varnames := stringDelimitList(List.mapMap(inVars, BackendVariable.varCref, ComponentReference.printComponentRefStr), " ;\n  ");
    eqns := BackendEquation.listEquation(inEqns);
    vars := BackendVariable.listVar1(inVars);
    funcs := BackendDAEUtil.getFunctions(inShared);
    (beqs, _) := BackendDAEUtil.getEqnSysRhs(eqns, vars, SOME(funcs));
    beqs := listReverse(beqs);
    rhsStr := stringDelimitList(List.map(beqs, ExpressionDump.printExpStr), " ;\n  ");
    jacStr := stringDelimitList(List.map1(List.mapList(jacVals, realString), stringDelimitList, " , "), " ;\n  ");
    eqnstr := BackendDump.dumpEqnsStr(inEqns);
    syst := "\n" + eqnstr + "\n[\n  " + jacStr + "\n]\n  *\n[\n  " + varnames + "\n]\n  =\n[\n  " + rhsStr + "\n]";
    Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst, infoStr, varname});
    //outValid := false;
  end if;
end analyzeConstantJacobian;

protected function transformXToXd "author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar = inVar;
algorithm
  if BackendVariable.isStateVar(inVar) then
    outVar.varName := ComponentReference.crefPrefixDer(inVar.varName);
    outVar.varKind := BackendDAE.STATE_DER();
    outVar.unreplaceable := false;
  end if;
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
  (outEquation, outVar, outIndex) := match inComp
    local
      Integer v, e;
      list<Integer> elst, vlst, otherEqns, otherVars;
      list<list<Integer>> otherVarsLst;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqnlst, eqnlst1;
      list<BackendDAE.Var> varlst, varlst1;
      BackendDAE.InnerEquations innerEquations;

    case BackendDAE.SINGLEEQUATION(eqn=e, var=v) equation
      eqn = BackendEquation.get(inEquationArray, e);
      var = BackendVariable.getVarAt(inVariables, v);
    then ({eqn}, {var}, e);

    case BackendDAE.EQUATIONSYSTEM(eqns=elst, vars=vlst) equation
      eqnlst = BackendEquation.getList(elst, inEquationArray);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
      e = listHead(elst);
    then (eqnlst, varlst, e);

    case BackendDAE.SINGLEARRAY(eqn=e, vars=vlst) equation
      eqn = BackendEquation.get(inEquationArray, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
    then ({eqn}, varlst, e);

    case BackendDAE.SINGLEIFEQUATION(eqn=e, vars=vlst) equation
      eqn = BackendEquation.get(inEquationArray, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
    then ({eqn}, varlst, e);

    case BackendDAE.SINGLEALGORITHM(eqn=e, vars=vlst) equation
      eqn = BackendEquation.get(inEquationArray, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
    then ({eqn}, varlst, e);

    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=e, vars=vlst) equation
      eqn = BackendEquation.get(inEquationArray, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
    then ({eqn}, varlst, e);

    case BackendDAE.SINGLEWHENEQUATION(eqn=e, vars=vlst) equation
      eqn = BackendEquation.get(inEquationArray, e);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
    then ({eqn}, varlst, e);

    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=elst, innerEquations=innerEquations)) equation
      eqnlst = BackendEquation.getList(elst, inEquationArray);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
      (otherEqns,otherVarsLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
      otherVars = List.flatten(otherVarsLst);
      eqnlst1 = BackendEquation.getList(otherEqns, inEquationArray);
      varlst1 = List.map1r(otherVars, BackendVariable.getVarAt, inVariables);
      e = listHead(elst);
    then (listAppend(eqnlst, eqnlst1), listAppend(varlst, varlst1), e);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("BackendDAETransform.getEquationAndSolvedVar failed!");
    then fail();
  end match;
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
      list<list<Integer>> vLstLst;
      BackendDAE.StrongComponent comp;
      BackendDAE.InnerEquations innerEquations;

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

    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=elst, innerEquations=innerEquations)) equation
      (elst1,vLstLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
      vlst1 = List.flatten(vLstLst);
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

public function traverseBackendDAEExpsEqnWithSymbolicOperation
"Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms.
  // TODO: remove this together with removeEqualFunctionCall"
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
      DAE.Exp iter, start, stop;
      DAE.ComponentRef cr, cr1;
      Integer size;
      Option<Integer> recordSize;
      list<DAE.Exp> expl;
      BackendDAE.Equation eqn;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      Option<BackendDAE.WhenEquation> oelsepart;
      DAE.ElementSource source;
      list<Integer> dimSize;
      list<DAE.SymbolicOperation> ops;
      list<DAE.Statement> statementLst;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Type_a ext_arg_1, ext_arg_2, ext_arg_3;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;
      list<BackendDAE.WhenOperator> whenStmtLst;

    case BackendDAE.EQUATION(exp = e1, scalar = e2, source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.EQUATION(e1_1, e2_1, source, eqAttr), ext_arg_2);

    // Array equation
    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left = e1, right = e2, source = source, attr=eqAttr, recordSize=recordSize) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.ARRAY_EQUATION(dimSize, e1_1, e2_1, source, eqAttr, recordSize), ext_arg_2);

    case BackendDAE.FOR_EQUATION(iter = iter, start = start, stop = stop, body = eqn, source = source, attr = eqAttr) equation
      (eqn, outTypeA) = traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, func, inTypeA);
    then (BackendDAE.FOR_EQUATION(iter, start, stop, eqn, source, eqAttr), outTypeA);

    case BackendDAE.SOLVED_EQUATION(componentRef = cr, exp = e2, source=source, attr=eqAttr) equation
      e1 = Expression.crefExp(cr);
      (DAE.CREF(cr1, _), (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, _)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.SOLVED_EQUATION(cr1, e2_1, source, eqAttr), ext_arg_1);

    case BackendDAE.RESIDUAL_EQUATION(exp = e1, source=source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.RESIDUAL_EQUATION(e1_1, source, eqAttr), ext_arg_1);

    // Algorithms
    case BackendDAE.ALGORITHM(size = size, alg=DAE.ALGORITHM_STMTS(statementLst = statementLst), source = source, expand = crefExpand, attr=eqAttr) equation
      (statementLst, (ops, ext_arg_1)) = DAEUtil.traverseDAEEquationsStmts(statementLst, func, ({}, inTypeA));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(statementLst), source, crefExpand, eqAttr), ext_arg_1);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst=whenStmtLst, elsewhenPart=oelsepart), source = source, attr=eqAttr) equation
      (whenStmtLst, ext_arg_1) = traverseBackendDAEExpsWhenOperatorWithSymbolicOperation(whenStmtLst, func, inTypeA);
      (cond, (ops, ext_arg_2)) = func(cond, ({}, ext_arg_1));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
      if isSome(oelsepart) then
        SOME(elsepart) = oelsepart;
        (BackendDAE.WHEN_EQUATION(whenEquation=elsepartRes, source=source), ext_arg_3) = traverseBackendDAEExpsEqnWithSymbolicOperation(BackendDAE.WHEN_EQUATION(size, elsepart, source, eqAttr), func, ext_arg_2);
        oelsepart = SOME(elsepartRes);
      else
        oelsepart = NONE();
        ext_arg_3 = ext_arg_2;
      end if;
      eqn = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_STMTS(cond, whenStmtLst, oelsepart), source, eqAttr);
   then (eqn, ext_arg_3);

    case BackendDAE.COMPLEX_EQUATION(size=size, left = e1, right = e2, source = source, attr=eqAttr) equation
      (e1_1, (ops, ext_arg_1)) = func(e1, ({}, inTypeA));
      (e2_1, (ops, ext_arg_2)) = func(e2, (ops, ext_arg_1));
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
    then (BackendDAE.COMPLEX_EQUATION(size, e1_1, e2_1, source, eqAttr), ext_arg_2);

    case BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source, attr=eqAttr) equation
      (expl, (ops, ext_arg_1)) = traverseBackendDAEExpsLstEqnWithSymbolicOperation(expl, func, ({}, inTypeA), {});
      source = List.foldr(ops, ElementSource.addSymbolicTransformation, source);
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

public function traverseBackendDAEExpsEqnLstWithSymbolicOperation
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEqns;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.Equation> iAcc = {};
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

protected function traverseBackendDAEExpsWhenOperatorWithSymbolicOperation<ArgT>
" Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  input list<BackendDAE.WhenOperator> inStmtLst;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.WhenOperator> outStmtLst = {};
  output ArgT outArg = inArg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input tuple<list<DAE.SymbolicOperation>, ArgT> inTpl;
    output DAE.Exp outExp;
    output tuple<list<DAE.SymbolicOperation>, ArgT> outTpl;
  end FuncExpType;
algorithm
  for rs in inStmtLst loop
    rs := match(rs)
      local
        DAE.ComponentRef cr;
        DAE.Exp lhs,cond, msg, level, exp;
        DAE.ElementSource src;
        list<DAE.SymbolicOperation> ops;

      case BackendDAE.ASSIGN(lhs, cond, src) equation
        (cond, (ops, outArg)) = func(cond, ({}, inArg));
        (lhs, (ops, outArg)) = func(lhs, (ops,outArg));
        src = List.foldr(ops, ElementSource.addSymbolicTransformation, src);
      then BackendDAE.ASSIGN(lhs, cond, src);

      case BackendDAE.REINIT(cr, cond, src) equation
        (cond, (ops, outArg)) = func(cond, ({}, inArg));
        (DAE.CREF(componentRef = cr), (ops, outArg)) = func(Expression.crefExp(cr), (ops,outArg));
        src = List.foldr(ops, ElementSource.addSymbolicTransformation, src);
      then BackendDAE.REINIT(cr, cond, src);

      case BackendDAE.ASSERT(cond, msg, level, src) equation
        (cond, (ops, outArg)) = func(cond, ({}, inArg));
        src = List.foldr(ops, ElementSource.addSymbolicTransformation, src);
      then BackendDAE.ASSERT(cond, msg, level, src);

      case BackendDAE.NORETCALL(exp, src) equation
        (exp, (ops, outArg)) = Expression.traverseExpBottomUp(exp, func, ({}, outArg));
        src = List.foldr(ops, ElementSource.addSymbolicTransformation, src);
      then BackendDAE.NORETCALL(exp, src);

      else rs;
    end match;

    outStmtLst := rs::outStmtLst;
  end for;

  outStmtLst := listReverse(outStmtLst);
end traverseBackendDAEExpsWhenOperatorWithSymbolicOperation;

public function collapseArrayExpressions
  input output BackendDAE.BackendDAE dae;
algorithm
  for syst in dae.eqs loop
    BackendEquation.traverseEquationArray_WithUpdate(syst.orderedEqs, function traverseBackendDAEExpsEqnWithSymbolicOperation(func=collapseArrayCrefExp), 0);
    BackendEquation.traverseEquationArray_WithUpdate(syst.removedEqs, function traverseBackendDAEExpsEqnWithSymbolicOperation(func=collapseArrayCrefExp), 0);
  end for;
end collapseArrayExpressions;

public function collapseArrayCrefExp<T>
  input DAE.Exp inExp;
  input tuple<list<DAE.SymbolicOperation>, T> inTpl;
  output DAE.Exp outExp;
  output tuple<list<DAE.SymbolicOperation>, T> outTpl;
protected
  list<DAE.SymbolicOperation> ops;
  T t;
algorithm
  (ops,t) := inTpl;
  (outExp,t) := Expression.traverseExpTopDown(inExp, collapseArrayCrefExpWork, t);
  if not Expression.expEqual(inExp,outExp) then
    // print("collapseArrayCrefExp: " + ExpressionDump.printExpStr(inExp) + " -> " + ExpressionDump.printExpStr(outExp) + "\n");
    outTpl := (DAE.SIMPLIFY(DAE.PARTIAL_EQUATION(inExp),DAE.PARTIAL_EQUATION(outExp))::ops,t);
  else
    outTpl := inTpl;
  end if;
end collapseArrayCrefExp;

protected function collapseArrayCrefExpWork<T>
  input output DAE.Exp e;
  output Boolean cont;
  input output T t;
algorithm
  (e,cont) := matchcontinue e
    case DAE.MATRIX() then (collapseArrayCrefExpWork2(e),false);
    case DAE.ARRAY() then (collapseArrayCrefExpWork2(e),false);
    else (e,true);
  end matchcontinue;
end collapseArrayCrefExpWork;

protected function collapseArrayCrefExpWork2
  input output DAE.Exp e;
protected
  DAE.Type ty;
  list<DAE.Dimension> dims;
  list<Integer> ds;
  Integer len, exp_count;
  list<DAE.Exp> exps;
  DAE.Exp exp1;
  DAE.ComponentRef cr1,cr2;
  list<DAE.Subscript> subs;
  Integer ndim;
algorithm
  (dims,ty) := match e
    case DAE.MATRIX(ty=ty as DAE.T_ARRAY(dims=dims)) then (dims,ty);
    case DAE.ARRAY(ty=ty as DAE.T_ARRAY(dims=dims)) then (dims,ty);
  end match;
  _ := match Types.arrayElementType(ty)
    // TODO: Figure out why the SimCode fails if we collapse arrays of records...
    case DAE.T_COMPLEX() then fail();
    else ();
  end match;
  ds := Expression.dimensionsSizes(dims);
  ndim := listLength(ds);
  len := product(i for i in ds);
  true := len > 0;
  //(DAE.CREF(componentRef=cr1)::exps) := Expression.flattenArrayExpToList(e); // TODO: Use a better routine? We now get all expressions even if no expression is a cref...
  (exp1::exps) := Expression.flattenArrayExpToList(e);
  DAE.CREF(componentRef=cr1) := exp1;
  // Check that the first element starts at index [1,...,1]
  subs := ComponentReference.crefLastSubs(cr1);
  true := ndim==listLength(subs);
  true := listLength(subs) == listLength(ComponentReference.crefSubs(cr1)) "Code generation fails for things like x[7].y when x[7] contains more things than y, and y is an array...";
  for sub in subs loop
    DAE.INDEX(DAE.ICONST(1)) := sub;
  end for;

  // Same number of expressions as expected...
  exp_count := listLength(exps) + 1;
  true := exp_count == len;

  // Check that the number of expressions matches the size of the array the cref represents.
  dims := Types.getDimensions(ComponentReference.crefLastType(cr1));
  true := exp_count == product(i for i in Expression.dimensionsSizes(dims));

  for exp in exps loop
    DAE.CREF(componentRef=cr2) := exp;
    true := ndim==listLength(ComponentReference.crefLastSubs(cr2));
    true := ComponentReference.crefEqualWithoutSubs(cr1,cr2);
    true := 1==ComponentReference.crefCompareIntSubscript(cr2,cr1); // cr2 > cr1
    cr1 := cr2;
  end for;
  // All of the crefs are in ascending order; the first one starts at 1,1; the length is the full array... So it is the complete cref!
  e := Expression.makeCrefExp(ComponentReference.crefStripLastSubs(cr1), ty);
end collapseArrayCrefExpWork2;

annotation(__OpenModelica_Interface="backend");
end BackendDAETransform;
