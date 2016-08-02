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

encapsulated package HpcOmEqSystems
" file:        HpcOmEqSystems.mo
  package:     HpcOmEqSystems
  description: HpcOmEqSystems contains the logic to manipulate systems of equations for the parallel simulation.

"
// public imports

public import BackendDAE;
public import DAE;
public import HpcOmTaskGraph;
public import HpcOmSimCode;

// protected imports
protected import Array;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDAETransform;
protected import BackendVariable;
protected import BackendVarTransform;
protected import ComponentReference;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import ExpressionDump;
protected import Flags;
protected import GraphML;
protected import HpcOmSimCodeMain;
protected import HpcOmScheduler;
protected import IndexReduction;
protected import List;
protected import Matching;
protected import Tearing;
protected import Util;
protected import SimCodeVar;

//--------------------------------------------------//
// matrix type
//-------------------------------------------------//
protected uniontype EqSys
  record LINSYS
  Integer dim;
  array<list<DAE.Exp>> matrixA;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
  end LINSYS;
end EqSys;

//--------------------------------------------------//
// start functions for handling linearTornSystems from here
//-------------------------------------------------//

public function partitionLinearTornSystem "checks the EqSystem for tornSystems in order to dissassemble them into various SingleEquation and a reduced EquationSystem.
This is useful in order to reduce the execution costs of the equationsystem and generate a bunch of parallel singleEquations. use +d=doLienarTearing +partlintorn=x to activate it.
Remark: this is still under development

idea:
we have the algebraic equations (other equations): g(xa,xt) : 0 = Ag*xt + Bg*xa + cg;
and the      residual equations                  h(xa,xt,r) : r = Ah*xt + Bh*xa + ch;
and we want something like this:
            new algebraic equations               gs(xa,xt) : xa = B_*xt + dg;
            new residual equations                hs(xt,r)  : r = A_*xt +dh;
so, we get a bunch of single equations in order to compute the coefficient of A_,  a 100% dense system of equations, and single equations to compute xa
author:Waurich TUD 2013-09"
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  daeOut := matchcontinue(daeIn)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
    case(BackendDAE.DAE(eqs=eqs,shared=shared))
     equation
       true = intGt(Flags.getConfigInt(Flags.PARTLINTORN),0);
       (eqs,_) = List.map1Fold(eqs,reduceLinearTornSystem,shared,1);
    then BackendDAE.DAE(eqs,shared);
    else daeIn;
  end matchcontinue;
end partitionLinearTornSystem;

protected function reduceLinearTornSystem "author: Waurich TUD 2013-09
  Checks the EqSystem for tornSystems in order to dissassemble them into various SingleEquation and
  a reduced EquationSystem. This is useful in order to reduce the execution costs of the equationsystem
  and generate a bunch of parallel singleEquations. use +d=doLienarTearing +partlintorn=x to activate it.
  Remark: this is still under development"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input Integer tornSysIdxIn;
  output BackendDAE.EqSystem systOut;
  output Integer tornSysIdxOut;
algorithm
  (systOut, tornSysIdxOut) := matchcontinue(systIn,sharedIn,tornSysIdxIn)
    local
      Integer tornSysIdx;
      array<Integer> ass1, ass2;
      BackendDAE.EqSystem systTmp;
      BackendDAE.EquationArray eqs, eqsTmp;
      BackendDAE.Matching matching;
      BackendDAE.StrongComponents allComps, compsTmp;
      BackendDAE.Variables vars, varsTmp;
    case(_,_,_)
      equation
        BackendDAE.EQSYSTEM(matching = BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps= allComps)) = systIn;
          //BackendDump.dumpEqSystem(systIn,"original system");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(1, allComps, ass1, ass2, systIn, sharedIn, tornSysIdxIn);
          //BackendDump.dumpEqSystem(systTmp,"new system");
      then
        (systTmp, tornSysIdx);
    else
      equation
        print("reduceLinearTornSystem failed!");
      then
        fail();
  end matchcontinue;
end reduceLinearTornSystem;

protected function reduceLinearTornSystem1 "author: Waurich TUD 2013-09
  traverses all StrongComponents for tornSystems, reduces them and rebuilds the BLT, the matching and the info about vars and equations"
  input Integer compIdx;
  input BackendDAE.StrongComponents compsIn;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input Integer tornSysIdxIn;
  output BackendDAE.EqSystem systOut;
  output Integer tornSysIdxOut;
algorithm
  (systOut,tornSysIdxOut) := matchcontinue(compIdx,compsIn,ass1,ass2,systIn,sharedIn,tornSysIdxIn)
    local
      Integer numNewSingleEqs, tornSysIdx;
      Boolean linear;
      array<Integer> ass1New, ass2New, ass1All, ass2All, ass1Other, ass2Other;
      list<Integer> tvarIdcs, resEqIdcs, eqIdcs, varIdcs;
      BackendDAE.InnerEquations innerEquations;
      BackendDAE.BaseClockPartitionKind partitionKind;
      BackendDAE.EqSystem syst;
      EqSys hpcSyst;
      BackendDAE.EquationArray eqs;
      BackendDAE.Jacobian jac;
      BackendDAE.JacobianType jacType;
      BackendDAE.Matching matching, matchingNew, matchingOther;
      BackendDAE.Shared sharedTmp;
      BackendDAE.StateSets stateSets;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsNew, compsTmp, otherComps;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements derRepl;
      list<BackendDAE.Equation> eqLst, eqsNew, eqsOld, resEqs, addEqs;
      list<BackendDAE.Var> varLst,varLstRepl, varsNew, varsOld, tvars, addVars;
    case(_,_,_,_,_,_,_)
      equation
        // completed
        true = listLength(compsIn) < compIdx;
      then
        (systIn,tornSysIdxIn);
    case(_,_,_,_,syst,_,_)
      equation
        // strongComponent is a linear tornSystem
        true = listLength(compsIn) >= compIdx;
        comp = listGet(compsIn,compIdx);
        BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars = tvarIdcs, residualequations = resEqIdcs, innerEquations = innerEquations), linear = linear) = comp;
        true = linear;
        true = intLe(listLength(tvarIdcs),Flags.getConfigInt(Flags.PARTLINTORN));
        //print("LINEAR TORN SYSTEM OF SIZE "+intString(listLength(tvarIdcs))+"\n");
        //false = compHasDummyState(comp,systIn);
        // build the new components, the new variables and the new equations
        (varsNew,eqsNew,_,resEqs,matchingNew) = reduceLinearTornSystem2(systIn,sharedIn,tvarIdcs,resEqIdcs,innerEquations,tornSysIdxIn);

        // add the new vars and equations to the original EqSystem
        BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) = matchingNew;
        varsOld = BackendVariable.varList(syst.orderedVars);
        eqsOld = BackendEquation.equationList(syst.orderedEqs);

        varLst = listAppend(varsOld,varsNew);
        eqLst = listAppend(eqsOld, eqsNew);
        eqLst = List.fold2(List.intRange(listLength(resEqIdcs)),replaceAtPositionFromList,resEqs,resEqIdcs,eqLst);  // replaces the old residualEquations with the new ones
        syst.orderedVars = BackendVariable.listVar1(varLst);  // !!! BackendVariable.listVar outputs the reversed order therefore listVar1
        syst.orderedEqs = BackendEquation.listEquation(eqLst);

        // build the matching
        ass1All = arrayCreate(listLength(varLst),-1);
        ass2All = arrayCreate(listLength(varLst),-1);  // actually has to be listLength(eqLst), but there is still the problem that ass1 and ass2 have the same size
        ass1All = Array.copy(ass1,ass1All);  // the comps before and after the tornsystem
        ass2All = Array.copy(ass2,ass2All);
        ((ass1All, ass2All)) = List.fold2(List.intRange(listLength(tvarIdcs)),updateResidualMatching,tvarIdcs,resEqIdcs,(ass1All,ass2All));  // sets matching info for the tearingVars and residuals

        // get the otherComps and and update the matching for the othercomps
        matchingOther = getOtherComps(innerEquations,ass1All,ass2All);
        BackendDAE.MATCHING(comps=otherComps) = matchingOther;

        // insert the new components into the BLT instead of the TornSystem, append the updated blocks for the other equations, update matching for the new equations
        numNewSingleEqs = listLength(compsNew)-listLength(tvarIdcs);
        compsNew = listAppend(compsNew, otherComps);
        compsTmp = List.replaceAtWithList(compsNew,compIdx-1,compsIn);
        ((ass1All,ass2All)) = List.fold2(List.intRange(arrayLength(ass1New)),updateMatching,(listLength(eqsOld),listLength(varsOld)),(ass1New,ass2New),(ass1All,ass2All));
        syst.matching = BackendDAE.MATCHING(ass1All, ass2All, compsTmp);

        //build new DAE-EqSystem
        syst = BackendDAEUtil.setEqSystMatrices(syst);
        (syst,_,_) = BackendDAEUtil.getIncidenceMatrix(syst, BackendDAE.NORMAL(),NONE());
        (syst, tornSysIdx) = reduceLinearTornSystem1(compIdx+1+numNewSingleEqs,compsTmp,ass1All,ass2All,syst,sharedIn,tornSysIdxIn+1);
      then
        (syst, tornSysIdx);
    case(_,_,_,_,syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqs),_,_)
      equation
        // strongComponent is a system of equations
        true = listLength(compsIn) >= compIdx;
        comp = listGet(compsIn,compIdx);
        BackendDAE.EQUATIONSYSTEM(vars = varIdcs, eqns = eqIdcs) = comp;
        true = intLe(listLength(varIdcs),2);
        //false = compHasDummyState(comp,systIn);

        //print("EQUATION SYSTEM OF SIZE "+intString(listLength(varIdcs))+"\n");
          //print("Jac:\n" + BackendDump.jacobianString(jac) + "\n");

         // get equations and variables
         eqLst = BackendEquation.getEqns(eqIdcs, eqs);
         eqLst = BackendEquation.replaceDerOpInEquationList(eqLst);
         varLst = List.map1r(varIdcs, BackendVariable.getVarAt, vars);
         varLstRepl = List.map(varLst, BackendVariable.transformXToXd);
         derRepl = BackendVarTransform.emptyReplacements(); // to retransform $DER. to der(.) in the new equations
         derRepl = List.threadFold(varLst,varLstRepl,addDerReplacement,derRepl);

              //BackendDump.dumpVarList(varLst,"varLst");
              //BackendDump.dumpEquationList(eqLst,"eqLst");

         // build linear system
         hpcSyst = getEqSystem(eqLst, varLstRepl);
           //dumpEqSys(hpcSyst);
         (eqsNew,addEqs,addVars) = CramerRule(hpcSyst);
         (eqsNew,_) = BackendVarTransform.replaceEquations(eqsNew,derRepl,NONE());//introduce der(.) for $DER.

           //BackendDump.dumpEquationList(eqsNew,"eqsNew");
           //BackendDump.dumpVarList(addVars,"addVars");
           //BackendDump.dumpEquationList(addEqs,"addEqs");

        // make new components for the system equations and add the comps for the additional equations in front of them
        varsOld = BackendVariable.varList(vars);
        eqsOld = BackendEquation.equationList(eqs);
        compsNew = matchComponent(eqsNew,varLstRepl,eqIdcs,varIdcs,sharedIn);
        otherComps = matchComponent(addEqs,addVars,List.intRange2(listLength(eqsOld)+1,listLength(eqsOld)+1+listLength(addEqs)),List.intRange2(listLength(varsOld)+1,listLength(varsOld)+1+listLength(addVars)),sharedIn);
        compsNew = listAppend(otherComps,compsNew);

        // insert the new components into the BLT, update matching for the new equations
        compsTmp = List.replaceAtWithList(compsNew,compIdx-1,compsIn);
          //print("compsTmp\n");
          //BackendDump.dumpComponents(compsTmp);

        // add the new vars and equations to the original EqSystem
        eqLst = listAppend(eqsOld,addEqs);
        varLst = listAppend(varsOld,addVars);
        eqLst = List.fold2(List.intRange(listLength(eqsNew)),replaceAtPositionFromList,eqsNew,eqIdcs,eqLst);  // replaces the old residualEquations with the new ones
        syst.orderedEqs = BackendEquation.listEquation(eqLst);
        syst.orderedVars = BackendVariable.listVar1(varLst);

        // update assignments
        ass1All = arrayCreate(listLength(varLst),-1);
        ass2All = arrayCreate(listLength(varLst),-1);  // actually has to be listLength(eqLst), but there is still the problem that ass1 and ass2 have the same size
        ass1All = Array.copy(ass1,ass1All);  // the comps before and after the tornsystem
        ass2All = Array.copy(ass2,ass2All);
        List.map2_0(compsNew,updateAssignmentsByComp,ass1All,ass2All);
        syst.matching = BackendDAE.MATCHING(ass1All, ass2All, compsTmp);
           //BackendDump.dumpFullMatching(syst.matching);

        //build new DAE-EqSystem
        syst = BackendDAEUtil.setEqSystMatrices(syst);
        //(systTmp,_,_) = BackendDAEUtil.getIncidenceMatrix(systTmp, BackendDAE.NORMAL(),NONE());

        (syst,tornSysIdx) = reduceLinearTornSystem1(compIdx+1,compsTmp,ass1All,ass2All,syst,sharedIn,tornSysIdxIn+1);
      then
        (syst,tornSysIdx);
    else
      // go to next StrongComponent
      equation
        (syst, tornSysIdx) = reduceLinearTornSystem1(compIdx+1,compsIn,ass1,ass2,systIn,sharedIn,tornSysIdxIn);
      then
        (syst, tornSysIdx);
  end matchcontinue;
end reduceLinearTornSystem1;

protected function compHasDummyState "author: Waurich TUD 2014-12
  outputs true if the component solves a dummy state var"
  input BackendDAE.StrongComponent comp;
  input BackendDAE.EqSystem syst;
  output Boolean hasDummy;
algorithm
  hasDummy := match(comp,syst)
    local
      Boolean b;
      BackendDAE.Variables vars;
      list<Integer> varIdcs, otherVars;
      list<BackendDAE.Var> varLst;
      // list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
  case(BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=varIdcs)),BackendDAE.EQSYSTEM(orderedVars=vars))
    equation
      // _ = List.flatten(List.map(otherEqnVarTpl,Util.tuple22));
      //varIdcs = listAppend(varIdcs,otherVars);
      varLst = List.map1(varIdcs,BackendVariable.getVarAtIndexFirst,vars);
      b = List.fold(List.map(varLst,BackendVariable.isDummyStateVar),boolOr,false);
      //b = List.fold(List.map(varLst,BackendVariable.isDummyDerVar),boolOr,b);
      b = b and intGt(listLength(varIdcs),1);
      //if b then print("THERE IS A DUMMY STATE!\n"); end if;
    then b;
  case(BackendDAE.EQUATIONSYSTEM(vars=varIdcs),BackendDAE.EQSYSTEM(orderedVars=vars))
    equation
      varLst = List.map1(varIdcs,BackendVariable.getVarAtIndexFirst,vars);
      b = List.fold(List.map(varLst,BackendVariable.isDummyStateVar),boolOr,false);
      //b = List.fold(List.map(varLst,BackendVariable.isDummyDerVar),boolOr,b);
      //if b then print("THERE IS A DUMMY STATE!"); end if;
    then b;
    else false;
  end match;
end compHasDummyState;

protected function updateAssignmentsByComp "author:Waurich TUD 2014-11
  updates the assignments by the information given in the component."
  input BackendDAE.StrongComponent comp;
  input array<Integer> ass1;
  input array<Integer> ass2;
protected
  Integer eqn,var;
algorithm
  BackendDAE.SINGLEEQUATION(eqn=eqn,var=var) := comp;
  arrayUpdate(ass2,eqn,var);
  arrayUpdate(ass1,var,eqn);
end updateAssignmentsByComp;

protected function matchComponent
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input list<Integer> eqIdcs;
  input list<Integer> varIdcs;
  input BackendDAE.Shared sharedIn;
  output list<BackendDAE.StrongComponent> compsOut;
protected
  BackendDAE.Matching matching;
  list<BackendDAE.StrongComponent> comps;
algorithm
  matching := buildSingleEquationSystem(listLength(eqLstIn),eqLstIn,varLstIn,sharedIn,{});
  BackendDAE.MATCHING(comps=comps) := matching;
  compsOut := List.map2(comps,replaceIndecesInComp,listArray(eqIdcs),listArray(varIdcs));
end matchComponent;

protected function replaceIndecesInComp
  input BackendDAE.StrongComponent comp;
  input array<Integer> eqMap;
  input array<Integer> varMap;
  output BackendDAE.StrongComponent compOut;
algorithm
  compOut := match(comp,eqMap,varMap)
    local
      Integer eqn,var;
    case(BackendDAE.SINGLEEQUATION(eqn=eqn,var=var),_,_)
      equation
        eqn = arrayGet(eqMap,eqn);
        var = arrayGet(varMap,var);
      then
        BackendDAE.SINGLEEQUATION(eqn,var);
    else fail();
  end match;
end replaceIndecesInComp;


protected function reduceLinearTornSystem2 "author: Waurich TUD 2013-07
  builds from a torn system various linear equation systems that can be computed in parallel."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> tVarIdcs0;
  input list<Integer> resEqIdcs0;
  input BackendDAE.InnerEquations innerEquations;
  input Integer tornSysIdx;
  output list<BackendDAE.Var> varsNewOut;
  output list<BackendDAE.Equation> eqsNewOut;
  output list<BackendDAE.Var> tVarsOut;
  output list<BackendDAE.Equation> resEqsOut;
  output BackendDAE.Matching matchingOut;
protected
  array<Integer> ass1New, ass2New;
  Integer size, otherEqSize, compSize;
  list<Integer> otherEqnsInts, otherVarsInts, tVarRange, rEqIdx;
  list<list<Integer>> otherVarsIntsLst;
  BackendDAE.EqSystem systNew;
  BackendDAE.EquationArray eqns,  oeqns, hs0Eqs;
  BackendDAE.Matching matchingNew;
  BackendDAE.StrongComponents comps, compsNew, oComps, compsEqSys;
  BackendDAE.Variables vars, diffVars, ovars, dVars;
  BackendVarTransform.VariableReplacements derRepl;
  DAE.FunctionTree functree;
  list<BackendDAE.Equation> eqLst,reqns, otherEqnsLst,otherEqnsLstReplaced, eqNew, hs, hs1, hLst, hsLst, hs_0, addEqLst;
  list<BackendDAE.EquationArray> gEqs, hEqs, hsEqs;
  list<BackendDAE.Var> varLst, tvars, tvarsReplaced, ovarsLst, xa0, a_0, varNew, addVarLst;
  list<BackendDAE.Variables> xaVars, rVars, aVars;
  list<list<BackendDAE.Equation>> g_i_lst,  h_i_lst,  hs_i_lst,  hs_0_lst;
  list<list<BackendDAE.Var>>  a_i_lst, a_i_lst1;

  array<list<BackendDAE.Equation>> g_iArr,hs_iArr;
  array<list<DAE.Exp>> h_iArr;
  array<list<BackendDAE.Var>> xa_iArr, a_iArr;
  array<BackendVarTransform.VariableReplacements> replArr;

  list<DAE.ComponentRef> tcrs,ovcrs;
algorithm
   // handle torn systems for the linear case
   BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqns, matching = BackendDAE.MATCHING(comps=comps)) := isyst;
   eqLst := BackendEquation.equationList(eqns);
   varLst := BackendVariable.varList(vars);
   tvars := List.map1r(tVarIdcs0, BackendVariable.getVarAt, vars);
   tvarsReplaced := List.map(tvars, BackendVariable.transformXToXd);
   tcrs := List.map(tvarsReplaced, BackendVariable.varCref);
   derRepl := BackendVarTransform.emptyReplacements(); // to retransform $DER. to der(.) in the new residual equations
   derRepl := List.threadFold(tvars,tvarsReplaced,addDerReplacement,derRepl);

   // get residual eqns
   reqns := BackendEquation.getEqns(resEqIdcs0, eqns);
   reqns := BackendEquation.replaceDerOpInEquationList(reqns);

   // get the other equations and the other variables
   // otherEqnsInts := List.map(otherEqsVarTpl, Util.tuple21);
   (otherEqnsInts,otherVarsIntsLst,_) := List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
   otherEqnsLst := BackendEquation.getEqns(otherEqnsInts, eqns);
   oeqns := BackendEquation.listEquation(otherEqnsLst);
   otherEqnsLstReplaced := BackendEquation.replaceDerOpInEquationList(otherEqnsLst);   // for computing the new equations

   // otherVarsIntsLst := List.map(otherEqsVarTpl, Util.tuple22);
   otherVarsInts := List.unionList(otherVarsIntsLst);
   ovarsLst := List.map1r(otherVarsInts, BackendVariable.getVarAt, vars);
   ovarsLst := List.map(ovarsLst, BackendVariable.transformXToXd);  //try this
   ovars := BackendVariable.listVar1(ovarsLst);
   ovcrs := List.map(ovarsLst, BackendVariable.varCref);
       //BackendDump.dumpVarList(tvarsReplaced,"tvars");
       //BackendDump.dumpVarList(ovarsLst,"ovars");
       //BackendDump.dumpEquationList(reqns,"residualEquations");
       //BackendDump.dumpEquationList(otherEqnsLstReplaced,"otherEqnsLstReplaced");

   //build the components and systems to get the system for computing the tearingVars
   size := listLength(tvars);
   otherEqSize := listLength(otherEqnsLst);
   compSize := listLength(comps);
   tVarRange := List.intRange2(0,size);
   replArr := arrayCreate(size+1,BackendVarTransform.emptyReplacements());
   g_iArr := arrayCreate(size+1, {});
   h_iArr := arrayCreate(size+1, {});
   hs_iArr := arrayCreate(size+1, {});
   xa_iArr := arrayCreate(size+1, {});
   a_iArr := arrayCreate(size+1, {});

   //  get g_i(xt=e_i, xa=xa_i) with xa_i as variables to be solved
   (g_iArr,xa_iArr,replArr) := getAlgebraicEquationsForEI(tVarRange,size,otherEqnsLstReplaced,tvarsReplaced,tcrs,ovarsLst,ovcrs,g_iArr,xa_iArr,replArr,tornSysIdx);
        //dumpVarArrLst(xa_iArr,"xa");
        //dumpEqArrLst(g_iArr,"g");

   //  compute residualValues (as expressions) h_i(xt=e_i,xa_i,r_i) for r_i
   (h_iArr) := getResidualExpressions(tVarRange,reqns,replArr,h_iArr);
        //print("h_i\n"+stringDelimitList(arrayList(Array.map(h_iArr,ExpressionDump.printExpListStr)),"\n")+"\n");

   //  get the co-efficients for the new residualEquations a_i from hs_i(r_i,xt=e_i, a_i)
   (hs_iArr,a_iArr) := getTornSystemCoefficients(tVarRange,size,tornSysIdx,h_iArr,hs_iArr,a_iArr);
        //dumpVarArrLst(a_iArr,"a");
        //dumpEqArrLst(hs_iArr,"hs");

   a_i_lst := arrayList(a_iArr);
   hs_i_lst := arrayList(hs_iArr);
   eqsNewOut := List.flatten(listAppend(arrayList(g_iArr),hs_i_lst));
   varsNewOut := List.flatten(listAppend(arrayList(xa_iArr),a_i_lst));

   // compute the tearing vars in the new residual equations hs
   a_0::a_i_lst1 := a_i_lst;
   hs := buildNewResidualEquation(1,a_i_lst1,a_0,tvarsReplaced,{});
        //BackendDump.dumpEquationList(hs,"new residuals");

   tVarsOut := tvarsReplaced;
   resEqsOut := hs;

   // some optimization
   (eqsNewOut,varsNewOut,resEqsOut) := simplifyNewEquations(eqsNewOut,varsNewOut,resEqsOut,listLength(List.flatten(arrayList(xa_iArr))),2);

   // handle the strongComponent (system of equations) to solve the tearing vars
   (compsEqSys,resEqsOut,tVarsOut,addEqLst,addVarLst) := buildEqSystemComponent(resEqIdcs0,tVarIdcs0,resEqsOut,tVarsOut,a_iArr,ishared);
   (resEqsOut,_) := BackendVarTransform.replaceEquations(hs,derRepl,NONE());//introduce der(.) for $DER.i
       //BackendDump.dumpComponents(compsEqSys);
       //BackendDump.dumpVarList(tVarsOut,"tVarsOut");
       //BackendDump.dumpEquationList(resEqsOut,"resEqsOut");
       //BackendDump.dumpVarList(addVarLst,"addVarLst");
      //BackendDump.dumpEquationList(addEqLst,"addEqLst");

   eqsNewOut := listAppend(eqsNewOut,addEqLst);
   varsNewOut := listAppend(varsNewOut,addVarLst);
       //BackendDump.dumpVarList(varsNewOut,"varsNew");
       //BackendDump.dumpEquationList(eqsNewOut,"eqsNew");

   // gather all additional equations and match them (not including the new residual equation)
   matchingNew := buildSingleEquationSystem(compSize,eqsNewOut,varsNewOut,ishared,{});
   BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) := matchingNew;
   compsNew := List.map2(compsNew,updateIndicesInComp,listLength(varLst),listLength(eqLst));
   oComps := listAppend(compsNew,compsEqSys);
   matchingOut := BackendDAE.MATCHING(ass1New,ass2New,oComps);
       //BackendDump.dumpComponents(oComps);
end reduceLinearTornSystem2;

protected function addDerReplacement "
  if var1 is a state and var2 is $DER.var, add a new replacement rule: $DER.var-->der(var)"
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  replOut := match(var1,var2,replIn)
  local
    DAE.Exp dest;
    DAE.ComponentRef source;
    BackendVarTransform.VariableReplacements repl;
  case(BackendDAE.VAR(varKind=BackendDAE.STATE()),_,_)
      equation
        source = BackendVariable.varCref(var2);
        dest = BackendVariable.varExp(var1);
        dest = IndexReduction.makeder(dest);
        repl =  BackendVarTransform.addReplacement(replIn,source,dest,NONE());
      then repl;
  else replIn;
  end match;
end addDerReplacement;

protected function simplifyNewEquations
  input list<BackendDAE.Equation> eqsIn;
  input list<BackendDAE.Var> varsIn;
  input list<BackendDAE.Equation> resEqsIn;
  input Integer numAuxiliaryVars; // to prevent replacement of coefficients
  input Integer numIter;
  output list<BackendDAE.Equation> eqsOut;
  output list<BackendDAE.Var> varsOut;
  output list<BackendDAE.Equation> resEqsOut;
protected
  BackendDAE.EquationArray eqArr;
  BackendDAE.Variables varArr;
  BackendDAE.EqSystem eqSys;
  BackendDAE.IncidenceMatrix m, mT;
  Integer size,numIterNew, numAux;
  list<Integer> varIdcs,eqIdcs;
  list<tuple<Integer,Integer>> simplifyPairs;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
algorithm
  eqArr := BackendEquation.listEquation(eqsIn);
  varArr := BackendVariable.listVar1(varsIn);
  eqSys := BackendDAEUtil.createEqSystem(varArr, eqArr);
  (m,mT) := BackendDAEUtil.incidenceMatrix(eqSys,BackendDAE.ABSOLUTE(),NONE());
  size := listLength(eqsIn);
  (eqIdcs,varIdcs,resEqsOut) := List.fold(List.intRange(size),function simplifyNewEquations1(eqArr=eqArr,varArr=varArr,m=m,mt=mT,numAuxiliaryVars=numAuxiliaryVars),({},{},resEqsIn));
  numAux := numAuxiliaryVars-listLength(varIdcs);
  if listEmpty(varIdcs) then numIterNew:=0;
    else numIterNew := numIter;
    end if;
  //take the non-assigned vars only
  (_,varIdcs,_) := List.intersection1OnTrue(List.intRange(size),varIdcs,intEq);
  (_,eqIdcs,_) := List.intersection1OnTrue(List.intRange(size),eqIdcs,intEq);
  eqsOut := BackendEquation.getEqns(eqIdcs,eqArr);
  varsOut := List.map1(varIdcs,BackendVariable.getVarAtIndexFirst,varArr);
  if numIterNew<>0 then (eqsOut,varsOut,resEqsOut) := simplifyNewEquations(eqsOut,varsOut,resEqsOut,numAux,numIterNew-1);
    else (eqsOut,varsOut,resEqsOut) := (eqsOut,varsOut,resEqsOut);
    end if;
end simplifyNewEquations;

protected function simplifyNewEquations1
  input Integer eqIdx;
  input BackendDAE.EquationArray eqArr;
  input BackendDAE.Variables varArr;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mt;
  input Integer numAuxiliaryVars;
  input tuple<list<Integer>,list<Integer>,list<BackendDAE.Equation>> tplIn; //these can be removed afterwards (eqIdcs,varIdcs,_)
  output tuple<list<Integer>,list<Integer>,list<BackendDAE.Equation>> tplOut;
algorithm
  tplOut := matchcontinue(eqIdx,eqArr,varArr,m,mt,tplIn)
    local
      Integer varIdx, size;
      list<Integer> restIdcs,varIdcs, eqIdcs, updEqIdcs;
      BackendDAE.Equation eq;
      BackendDAE.EquationArray eqArrTmp;
      BackendDAE.Var var;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef varCref;
      DAE.Exp varExp, rhs, lhs;
      list<BackendDAE.Equation> eqLst,resEqLst;
      list<BackendDAE.Var> varLst;
  case(_,_,_,_,_,_)
    algorithm
       (eqIdcs,varIdcs,resEqLst) := tplIn;
       // a variable is directly assignable and therefore will be removed
       {varIdx} := arrayGet(m,eqIdx);
       true := varIdx <= numAuxiliaryVars;
       var := BackendVariable.getVarAt(varArr,varIdx);
       eq := BackendEquation.equationNth1(eqArr,eqIdx);
       //solve for it
       varCref := BackendVariable.varCref(var);
       varExp := Expression.crefExp(varCref);
       rhs := BackendEquation.getEquationRHS(eq);
       lhs := BackendEquation.getEquationLHS(eq);
       (rhs,_) := ExpressionSolve.solve(lhs,rhs,varExp);
       if Expression.isAsubExp(rhs) then
       rhs := List.fold1(Expression.allTerms(rhs),Expression.makeBinaryExp,DAE.ADD(Expression.typeof(varExp)),DAE.RCONST(0.0));  //in case ({a,0,b}+funcCall(1,2,3,4,5))[2] I need to get 0+funcCAll(1,2,3,4,5)[2]
       end if;
       (rhs,_) := ExpressionSimplify.simplify(rhs);
       // replace
       repl := BackendVarTransform.emptyReplacements();
       repl := BackendVarTransform.addReplacement(repl,varCref,rhs,NONE());
       updEqIdcs := arrayGet(mt,varIdx);
       eqLst := BackendEquation.getEqns(updEqIdcs,eqArr);
       (eqLst,_) := BackendVarTransform.replaceEquations(eqLst,repl,NONE());
       (resEqLst,_) := BackendVarTransform.replaceEquations(resEqLst,repl,NONE());
       _ := List.threadFold(updEqIdcs,eqLst,BackendEquation.setAtIndexFirst,eqArr);
       // remove these later
       varIdcs := varIdx::varIdcs;
       eqIdcs := eqIdx::eqIdcs;
     then (eqIdcs,varIdcs,resEqLst);
   else tplIn;
  end matchcontinue;
end simplifyNewEquations1;

protected function buildEqSystemComponent "author:Waurich TUD 2013-12
  builds a strongComponent for the reduced System. if the system size is 1, a SingleEquation is built, otherwise a EqSystem with jacobian."
  input list<Integer> eqIdcsIn;
  input list<Integer> varIdcsIn;
  input list<BackendDAE.Equation> resEqsIn;
  input list<BackendDAE.Var> tVarsIn;
  input array<list<BackendDAE.Var>> jacValuesIn;
  input BackendDAE.Shared shared;
  output list<BackendDAE.StrongComponent> outComp; // only the residual equations
  output list<BackendDAE.Equation> resEqsOut;
  output list<BackendDAE.Var> tVarsOut;
  output list<BackendDAE.Equation> addEqsOut;
  output list<BackendDAE.Var> addVarsOut;
algorithm
  (outComp,resEqsOut,tVarsOut,addEqsOut,addVarsOut) := matchcontinue(eqIdcsIn,varIdcsIn,resEqsIn,tVarsIn,jacValuesIn,shared)
    local
      Integer eqIdx,varIdx;
      list<Integer> noSccEqs,sccEqs,sccVars;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.EquationArray eqArr;
      BackendDAE.EqSystem eqSys;
      BackendDAE.IncidenceMatrix m,mT;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents comps;
      BackendDAE.Variables varArr;
      list<BackendDAE.Equation> resEqs, addEqs;
      list<BackendDAE.Var> addVars;
      list<list<BackendDAE.Var>> jacValues;
      Boolean mixedSystem;
    case({eqIdx},{varIdx},_,_,_,_)
      equation
        true = intEq(listLength(eqIdcsIn),1);
        comp = BackendDAE.SINGLEEQUATION(eqIdx,varIdx);
      then ({comp},resEqsIn,tVarsIn,{},{});
    case(_,_,_,_,_,_)
      equation
        true = intLe(listLength(tVarsIn),3);
        // apply Cramers Rule to this equation system
        (resEqs,_,addEqs,addVars) = applyCramerRule(jacValuesIn,tVarsIn);
        comps = List.threadMap(eqIdcsIn,varIdcsIn,BackendDAEUtil.makeSingleEquationComp);
      then (comps,resEqs,tVarsIn,addEqs,addVars);
    else
      equation
        // build a BackendDAE.EQUATIONSYSTEM
        _::jacValues = arrayList(jacValuesIn);
        jac = buildLinearJacobian(jacValues,List.intRange(listLength(resEqsIn)),List.intRange(listLength(tVarsIn)));
        mixedSystem = BackendVariable.hasDiscreteVar(tVarsIn);
        comp = BackendDAE.EQUATIONSYSTEM(eqIdcsIn,varIdcsIn,BackendDAE.FULL_JACOBIAN(jac),BackendDAE.JAC_LINEAR(), mixedSystem);
      then ({comp},resEqsIn,tVarsIn,{},{});
  end matchcontinue;
end buildEqSystemComponent;


protected function buildLinearJacobian "author:Waurich TUD 2013-12
  builds the jacobian out of the given jacobian-entries"
  input list<list<BackendDAE.Var>> inElements;  //outer list refers to the row, inner list to the column
  input list<Integer> eqIdcs;
  input list<Integer> varIdcs;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outJac;
protected
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
algorithm
  jac := List.fold2(eqIdcs,buildLinearJacobian1,varIdcs,inElements,{});
  jac := listReverse(jac);
  outJac := SOME(jac);
end buildLinearJacobian;


protected function buildLinearJacobian1 "author:Waurich TUD 2013-12
  helper for buildLinearJacobian."
  input Integer rowIdx;
  input list<Integer> columns;
  input list<list<BackendDAE.Var>> inElements;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inJac;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outJac;
protected
  list<BackendDAE.Var> elements;
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
algorithm
  elements := listGet(inElements,rowIdx);
  elements := List.map1(columns,List.getIndexFirst,elements);
  outJac := List.fold2(columns,buildLinearJacobian2,elements,rowIdx,inJac);
end buildLinearJacobian1;


protected function buildLinearJacobian2 "author:Waurich TUD 2013-12
  helper for buildLinearJacobian"
  input Integer colIdx;
  input list<BackendDAE.Var> inElements;
  input Integer rowIdx;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inJac;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outJac;
protected
  DAE.ComponentRef cref;
  DAE.Exp exp;
  BackendDAE.Equation eq;
  BackendDAE.Var elem;
  tuple<Integer,Integer,BackendDAE.Equation> entry;
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
algorithm
  elem := listGet(inElements,colIdx);
  cref := BackendVariable.varCref(elem);
  exp := DAE.CREF(cref,DAE.T_REAL_DEFAULT);
  exp := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp);
  eq := BackendDAE.RESIDUAL_EQUATION(exp,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
  entry := (colIdx,rowIdx,eq);
  outJac := entry::inJac;
end buildLinearJacobian2;


protected function updateMatching "author: Waurich TUD 2013-09
  inserts the information of matching2 into matching1 by adding an index offset for the vars and eqs of matching2.Actually only one assignment for matching 2 is needed."
  input Integer idx;
  input tuple<Integer,Integer> offsetTpl;
  input tuple<array<Integer>,array<Integer>> matching2;
  input tuple<array<Integer>,array<Integer>> matching1In;
  output tuple<array<Integer>,array<Integer>> matching1Out;
protected
  Integer eqOffset, varOffset, eqValue, varValue;
  array<Integer> ass11, ass21, ass12, ass22;
algorithm
  (eqOffset, varOffset) := offsetTpl;
  (ass12, ass22) := matching2;
  (ass11, ass21) := matching1In;
  eqValue := idx + eqOffset;
  varValue := arrayGet(ass22,idx)+varOffset;
  ass11 := arrayUpdate(ass11,varValue,eqValue);
  ass21 := arrayUpdate(ass21, eqValue, varValue);
  matching1Out := (ass11, ass21);
end updateMatching;


protected function updateResidualMatching "author: Waurich TUD 2013-09
  sets the matching between tearingVars and residuals."
  input Integer idx;
  input list<Integer> tvars;
  input list<Integer> resEqs;
  input tuple<array<Integer>,array<Integer>> tplIn;
  output tuple<array<Integer>,array<Integer>> tplOut;
protected
  array<Integer> ass1, ass2;
  Integer eqIdx, varIdx;
algorithm
  (ass1,ass2) := tplIn;
  eqIdx := listGet(resEqs,idx);
  varIdx := listGet(tvars,idx);
  ass1 := arrayUpdate(ass1,varIdx,eqIdx);
  ass2 := arrayUpdate(ass2,eqIdx,varIdx);
  tplOut := (ass1,ass2);
end updateResidualMatching;


protected function getOtherComps "author: Waurich TUD 2013-09
  builds ordered StrongComponents and matching for the other equations."
  input BackendDAE.InnerEquations innerEquations;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output BackendDAE.Matching matchingOut;
protected
  array<Integer> ass1Tmp, ass2Tmp;
  BackendDAE.StrongComponents compsTmp;
algorithm
  ((ass1Tmp,ass2Tmp,compsTmp)) := List.fold(innerEquations,getOtherComps1,(ass1,ass2,{}));
  compsTmp := listReverse(compsTmp);
  matchingOut := BackendDAE.MATCHING(ass1Tmp,ass2Tmp,compsTmp);
end getOtherComps;


protected function getOtherComps1 "author:waurich TUD 2013-09
  implementation of getOtherComps"
  input BackendDAE.InnerEquation innerEquation;
  input tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplIn;
  output tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplOut;
algorithm
  tplOut := matchcontinue(innerEquation, tplIn)
    local
      Integer eqIdx, varIdx;
      array<Integer> ass1, ass2;
      list<Integer> varIdcs;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsIn, compsTmp;
    case(_,(ass1,ass2,compsIn))
      equation
        (eqIdx, varIdcs, _) = BackendDAEUtil.getEqnAndVarsFromInnerEquation(innerEquation);
        true = listLength(varIdcs) == 1;
        varIdx = listGet(varIdcs,1);
        comp = BackendDAE.SINGLEEQUATION(eqIdx,varIdx);
        ass1 = arrayUpdate(ass1,varIdx,eqIdx);
        ass2 = arrayUpdate(ass2,eqIdx,varIdx);
        compsTmp = comp::compsIn;
      then
        ((ass1,ass2,compsTmp));
    else
      equation
        print("getOtherComps failed\n");
      then
        fail();
  end matchcontinue;
end getOtherComps1;


protected function replaceAtPositionFromList "author: Waurich TUD 2013-09
  replaces the entry from inLst indexed by positionLst[n] with the nth entry in replacingLst. n is first input so it can be used in a folding functions."
  replaceable type ElementType subtypeof Any;
  input Integer n;
  input list<ElementType> replacingLst;
  input list<Integer> positionLst;
  input list<ElementType> inLst;
  output list<ElementType> outLst;
protected
  Integer idx;
  ElementType entry;
algorithm
  idx := listGet(positionLst,n);
  entry := listGet(replacingLst,n);
  outLst := List.replaceAt(entry,idx,inLst);
end replaceAtPositionFromList;


protected function updateIndicesInComp "author: Waurich TUD 2013-09
  raises the indices of the vars and eqs in the given component according to the given offsets."
  input BackendDAE.StrongComponent compIn;
  input Integer varOffset;
  input Integer eqOffset;
  output BackendDAE.StrongComponent compOut;
algorithm
  compOut := matchcontinue(compIn,varOffset,eqOffset)
    local
      Integer varIdx;
      Integer eqIdx;
      BackendDAE.StrongComponent compTmp;
    case(BackendDAE.SINGLEEQUATION(eqn=eqIdx, var=varIdx),_,_)
      equation
        varIdx = varIdx+varOffset;
        eqIdx = eqIdx+eqOffset;
        compTmp = BackendDAE.SINGLEEQUATION(eqIdx, varIdx);
      then
        compTmp;
    else
      equation
        print("updateVarEqIndices failed\n");
      then
        fail();
  end matchcontinue;
end updateIndicesInComp;

protected function buildNewResidualEquation "author: Waurich TUD 2013-09
  function to build the new linear residual equations res=0=A*xt+a0 whicht is solved for xt"
  input Integer resIdx;
  input list<list<BackendDAE.Var>> aCoeffLst;
  input list<BackendDAE.Var> a0CoeffLst;
  input list<BackendDAE.Var> tvars;
  input list<BackendDAE.Equation> resEqsIn;
  output list<BackendDAE.Equation> resEqsOut;
algorithm
  resEqsOut := matchcontinue(resIdx,aCoeffLst,a0CoeffLst,tvars,resEqsIn)
    local
      list<BackendDAE.Equation> eqLstTmp;
      list<BackendDAE.Var> aCoeffs;
      BackendDAE.Equation eqTmp, hs;
      BackendDAE.Var a0Coeff;
      DAE.Exp lhs, rhs, a0Exp;
      DAE.Type ty;
    case(_,_,_,_,_)
      equation
        true = resIdx > listLength(tvars);
        eqLstTmp = listReverse(resEqsIn);
      then
        eqLstTmp;
    case(_,_,_,_,_)
      equation
        true = resIdx <= listLength(tvars);
        aCoeffs = List.map1(aCoeffLst,listGet,resIdx);
        a0Coeff = listGet(a0CoeffLst,resIdx);
        a0Exp = varExp(a0Coeff);
        ty = DAE.T_REAL_DEFAULT;
        rhs = buildNewResidualEquation2(1,aCoeffs,tvars,DAE.RCONST(0.0)); // the start value is random and will be rejected
        rhs = DAE.BINARY(rhs, DAE.ADD(ty), a0Exp);
        lhs = DAE.RCONST(0.0);
        hs = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        eqLstTmp = hs::resEqsIn;
        eqLstTmp = buildNewResidualEquation(resIdx+1,aCoeffLst,a0CoeffLst,tvars,eqLstTmp);
      then
        eqLstTmp;
    else
      equation
        print("buildNewResidualEquation failed");
      then
        fail();
  end matchcontinue;
end buildNewResidualEquation;


protected function buildNewResidualEquation2 "author: Waurich TUD 2013-09
  function to build the sum of the rhs of the new residual equation, i.e. the sum of all tvars and their coefficients"
  input Integer idx;
  input list<BackendDAE.Var> coeffs;
  input list<BackendDAE.Var> tVars;
  input DAE.Exp expIn;
  output DAE.Exp expOut;
algorithm
  expOut := matchcontinue(idx,coeffs,tVars,expIn)
    local
      BackendDAE.Var coeff;
      BackendDAE.Var tVar;
      DAE.Exp coeffExp, tVarExp, expTmp;
      DAE.Type ty;
    case(_,_,_,_)
      equation
        // the first product of the term
        true = idx == 1;
        coeff = listGet(coeffs,idx);
        coeffExp = varExp(coeff);
        tVar = listGet(tVars,idx);
        tVarExp = varExp(tVar);
        tVarExp = if BackendVariable.isStateVar(tVar) then Expression.expDer(tVarExp) else tVarExp; // if tvar is a state, use the der(varexp)
        ty = DAE.T_REAL_DEFAULT;
        expTmp = DAE.BINARY(coeffExp,DAE.MUL(ty),tVarExp);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then expTmp;

    case(_,_,_,_)
      equation
        true = idx <= listLength(tVars);
        //extend the expression
        coeff = listGet(coeffs,idx);
        tVar = listGet(tVars,idx);
        expTmp = addProductToExp(coeff,tVar,expIn);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then expTmp;

    case(_,_,_,_)
      equation
        true = idx > listLength(tVars);
      then expIn;

    else
      equation
        print("buildNewResidualEquation2 failed!\n");
      then fail();

  end matchcontinue;
end buildNewResidualEquation2;


protected function addProductToExp "author: Waurich TUD 2013-09
  function to add the product of the given 2 BackendDAE.Var to the given inExp. expOut = expIn + fac1*fac2"
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  input DAE.Exp inExp;
  output DAE.Exp expOut;
protected
  DAE.Exp fac1, fac2, prod;
  DAE.Type ty;
algorithm
  fac1 := varExp(var1);
  fac2 := varExp(var2);
  fac2 := if BackendVariable.isStateVar(var2) then Expression.expDer(fac2) else fac2;
  ty := DAE.T_REAL_DEFAULT;
  prod := DAE.BINARY(fac1, DAE.MUL(ty), fac2);
  expOut := DAE.BINARY(inExp, DAE.ADD(ty), prod);
end addProductToExp;


protected function buildSingleEquationSystem "author: Waurich TUD 2013-07
  function to build a system of singleEquations which can be solved partially parallel."
  input Integer eqSizeOrig;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents compsIn;
  output BackendDAE.Matching matchingOut;
algorithm
  matchingOut := matchcontinue(eqSizeOrig,inEqs,inVars,shared,compsIn)
    local
      array<list<Integer>> mapEqnIncRow;
      array<Integer> ass1, ass2;
      array<Integer> mapIncRowEqn;
      Integer nVars, nEqs, compIdxTmp;
      BackendDAE.EquationArray eqArr;
      BackendDAE.EqSystem sysTmp;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Matching matching, matchingTmp;
      BackendDAE.StrongComponents compsTmp;
      BackendDAE.Variables vars;
    case(_,_,_,_,_)
      equation
        // build a singleEquation from a list<Equation> and list<Var> which are indexed by compIdx;
        // get the EQSYSTEM, the incidenceMatrix and a matching
        vars = BackendVariable.listVar1(inVars);
        eqArr = BackendEquation.listEquation(inEqs);
        sysTmp = BackendDAEUtil.createEqSystem(vars, eqArr);
        (sysTmp,m,_) = BackendDAEUtil.getIncidenceMatrix(sysTmp,BackendDAE.NORMAL(),NONE());
        nVars = listLength(inVars);
        nEqs = listLength(inEqs);
        ass1 = arrayCreate(nVars, -1);
        ass2 = arrayCreate(nEqs, -1);
        Matching.matchingExternalsetIncidenceMatrix(nVars, nEqs, m);
        BackendDAEEXT.matching(nVars, nEqs, 5, -1, 0.0, 1);
        BackendDAEEXT.getAssignment(ass2, ass1);
        matching = BackendDAE.MATCHING(ass1, ass2, {});
        sysTmp = BackendDAEUtil.createEqSystem(vars, eqArr);
        (sysTmp,_,_) = BackendDAEUtil.getIncidenceMatrix(sysTmp,BackendDAE.ABSOLUTE(),NONE());
        sysTmp = BackendDAEUtil.setEqSystMatching(sysTmp, matching);

        // perform BLT to order the StrongComponents
        mapIncRowEqn = Array.createIntRange(nEqs);
        mapEqnIncRow = Array.map(mapIncRowEqn,List.create);
        (sysTmp,compsTmp) = BackendDAETransform.strongComponentsScalar(sysTmp,shared,mapEqnIncRow,mapIncRowEqn);
        compsTmp = listAppend(compsIn,compsTmp);
        matchingTmp = BackendDAE.MATCHING(ass1, ass2, compsTmp);
      then
        matchingTmp;
    else
      equation
        print("buildSingleEquationSystem failed\n");
      then
        fail();
  end matchcontinue;
end buildSingleEquationSystem;


protected function getTornSystemCoefficients "author: Waurich TUD 2013-08
  gets the co-efficients for the new residual equations of the linear torn system
the first index is for the residualvar and the second for the tearingvar
(r1) = (a11 a12..) (xt1)+(a01)
(r2) = (a21 a22..)*(xt2)+(a02)
(:)  = (:   :    ) ( : )+( : )
this is meant to be a matrix :)"
  input list<Integer> iValueRange;
  input Integer numTVars;
  input Integer tornSysIdx;
  input array<list<DAE.Exp>> h_iArr;
  input array<list<BackendDAE.Equation>> hs_iArrIn;
  input array<list<BackendDAE.Var>> a_iArrIn;
  output array<list<BackendDAE.Equation>> hs_iArrOut;
  output array<list<BackendDAE.Var>> a_iArrOut;
algorithm
  (hs_iArrOut,a_iArrOut) := matchcontinue(iValueRange, numTVars, tornSysIdx, h_iArr, hs_iArrIn, a_iArrIn)
    local
      Integer iValue;
      String varName;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> hs_i;
      list<BackendDAE.Var> a_i, r_i;
      array<list<BackendDAE.Equation>> hs_iArrTmp;
      array<list<BackendDAE.Var>> a_iArrTmp;
      BackendDAE.Var aVar;
      DAE.ComponentRef varCRef;
      DAE.Exp varExp;

    case({},_,_,_,_,_)
      equation
      then (hs_iArrIn,a_iArrIn);

    case(iValue::iLstRest,_,_,_,_,_)
      equation
        // gets the equations for computing the coefficients for the new residual equations
        (hs_iArrTmp,a_iArrTmp) = getTornSystemCoefficients1(listReverse(List.intRange(numTVars)),iValue,h_iArr,hs_iArrIn,a_iArrIn,tornSysIdx);
        (hs_iArrTmp,a_iArrTmp) = getTornSystemCoefficients(iLstRest,numTVars,tornSysIdx,h_iArr,hs_iArrTmp,a_iArrTmp);
      then (hs_iArrTmp,a_iArrTmp);

    else
      equation
        print("getTornSystemCoefficients failed!\n");
      then fail();

  end matchcontinue;
end getTornSystemCoefficients;


protected function getTornSystemCoefficients1 "author: Waurich TUD 2013-08
  gets the equations with coefficients for one e_i"
  input list<Integer> resIdxLst;
  input Integer iIdx;
  input array<list<DAE.Exp>> h_iArr;
  input array<list<BackendDAE.Equation>> hs_iArrIn;
  input array<list<BackendDAE.Var>> a_iArrIn;
  input Integer tornSysIdx;
  output array<list<BackendDAE.Equation>> hs_iArrOut;
  output array<list<BackendDAE.Var>> a_iArrOut;
algorithm
  (hs_iArrOut, a_iArrOut) := matchcontinue(resIdxLst, iIdx, h_iArr, hs_iArrIn, a_iArrIn, tornSysIdx)
    local
      Integer resIdx,resIdx1;
      String aName;
      list<Integer> resIdxRest;
      array<list<BackendDAE.Equation>> hs_iArrTmp;
      array<list<BackendDAE.Var>> a_iArrTmp;
      list<BackendDAE.Equation> hs_iTmp;
      list<BackendDAE.Var> a_iTmp, d_lst;
      BackendDAE.Equation hs_ii;
      BackendDAE.Var a_ii, r_ii, dVar;
      DAE.ComponentRef aCRef;
      DAE.Exp lhs, rhs, dExp;
      DAE.Type ty;
    case({},_,_,_,_,_)
      equation
      then (hs_iArrIn,a_iArrIn);

    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = intEq(0,iIdx);
        // build the coefficients (offset d=a_0) of the new residual equations (hs = A*xt+d)
        aName = "$a"+intString(tornSysIdx)+"_"+intString(resIdx)+"_"+intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
        a_ii = BackendVariable.setVarStartValue(a_ii,DAE.RCONST(0.0));

        // build the equations to solve for the coefficients
        lhs = varExp(a_ii);
        rhs = listGet(arrayGet(h_iArr,iIdx+1),resIdx);
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);

        // update th a_iArr and the hs_iArr
        hs_iTmp = arrayGet(hs_iArrIn,iIdx+1);
        hs_iTmp = hs_ii::hs_iTmp;
        hs_iArrTmp = arrayUpdate(hs_iArrIn,iIdx+1,hs_iTmp);
        a_iArrTmp = a_iArrIn;
        a_iTmp = arrayGet(a_iArrIn,iIdx+1);
        a_iTmp = a_ii::a_iTmp;
        a_iArrTmp = arrayUpdate(a_iArrIn,iIdx+1,a_iTmp);

        //next residual equation
        (hs_iArrTmp,a_iArrTmp) = getTornSystemCoefficients1(resIdxRest,iIdx,h_iArr,hs_iArrTmp,a_iArrTmp,tornSysIdx);
      then (hs_iArrTmp,a_iArrTmp);

    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = iIdx > 0;
        // build the co-efficients (A-matrix-entries) of the new residual equations (hs = A*xt+d)
        aName = "$a"+intString(tornSysIdx)+"_"+intString(resIdx)+"_"+intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
        a_ii = BackendVariable.setVarStartValue(a_ii,DAE.RCONST(0.0));

        // build the equations to solve for the coefficients
        d_lst = arrayGet(a_iArrIn,1);
        dVar = listGet(d_lst, resIdx);
        dExp = varExp(dVar);
        lhs = varExp(a_ii);
        rhs = listGet(arrayGet(h_iArr,iIdx+1),resIdx);
        rhs = DAE.BINARY(rhs,DAE.SUB(ty),dExp);
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);

        // update th a_i_lst and the hs_i_lst
        hs_iTmp = arrayGet(hs_iArrIn,iIdx+1);
        hs_iTmp = hs_ii::hs_iTmp;
        hs_iArrTmp = arrayUpdate(hs_iArrIn,iIdx+1,hs_iTmp);
        a_iArrTmp = a_iArrIn;
        a_iTmp = arrayGet(a_iArrIn,iIdx+1);
        a_iTmp = a_ii::a_iTmp;
        a_iArrTmp = arrayUpdate(a_iArrIn,iIdx+1,a_iTmp);

        // next residual equation
        (hs_iArrTmp,a_iArrTmp) = getTornSystemCoefficients1(resIdxRest, iIdx, h_iArr, hs_iArrTmp, a_iArrTmp,tornSysIdx);
      then (hs_iArrTmp,a_iArrTmp);

    else
      equation
        print("getTornSystemCoefficients1 failed\n");
      then fail();

  end matchcontinue;
end getTornSystemCoefficients1;

protected function varExp "author: Waurich TUD 2013-08
  gets an DAE.Exp for the CREF of the given BackendDAE.Var"
  input BackendDAE.Var varIn;
  output DAE.Exp expOut;
protected
  DAE.ComponentRef cr;
  DAE.Type ty;
algorithm
  ty := BackendVariable.varType(varIn);
  cr := BackendVariable.varCref(varIn);
  expOut := DAE.CREF(cr,ty);
end varExp;

protected function getResidualExpressions "author: Waurich TUD 2013-08
  adds a variable r_x to  the right hand side of an equation. this corresponds to the residual value in a residual equation"
  input list<Integer> iIn;
  input list<BackendDAE.Equation> resEqLstIn;
  input array<BackendVarTransform.VariableReplacements> replArrIn;
  input array<list<DAE.Exp>> h_iArrIn;
  output array<list<DAE.Exp>> h_iArrOut;
protected
  list<DAE.Exp> resExps;
algorithm
  resExps := List.map(resEqLstIn,getResidualExpressionForEquation);
  h_iArrOut := List.fold2(iIn,getResidualExpressions1,resExps,replArrIn,h_iArrIn);
end getResidualExpressions;

protected function getResidualExpressions1 "author:Waurich TUD 2013-08
  function to parse the expressions of one residualEquation."
  input Integer i;
  input list<DAE.Exp> resExpsIn;
  input array<BackendVarTransform.VariableReplacements> replArr;
  input array<list<DAE.Exp>> h_iArrIn;
  output array<list<DAE.Exp>> h_iArrOut;
protected
  BackendVarTransform.VariableReplacements repl;
  list<DAE.Exp> h_i;
  array<list<DAE.Exp>> h_iArr;
algorithm
  (h_iArrOut) := matchcontinue(i,resExpsIn,replArr,h_iArrIn)
    local
    case(_,_,_,_)
      // traverse the residualEquations
      equation
        repl = arrayGet(replArr,i+1);
        (h_i,_) = BackendVarTransform.replaceExpList1(resExpsIn, repl, NONE());
        h_iArr = arrayUpdate(h_iArrIn,i+1,h_i);
      then h_iArr;
    else
      equation
        print("getResidualExpressions failed \n");
      then
        fail();
  end matchcontinue;
end getResidualExpressions1;

protected function getResidualExpressionForEquation "
  subtracts the lhs from the rhs of the equation. a=b+c --> b+c-a"
  input BackendDAE.Equation eq;
  output DAE.Exp exp;
algorithm
  exp := match(eq)
    local
      DAE.Exp lhs,rhs;
      DAE.Type ty;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs))
    equation
      ty = Expression.typeof(lhs);
      rhs = DAE.BINARY(rhs,DAE.SUB(ty),lhs);
      (rhs,_) = ExpressionSimplify.simplify(rhs);
      then rhs;
  else
    equation
      print("getResidualExpressionForEquation failed\n");
    then fail();
  end match;
end getResidualExpressionForEquation;


protected function varInFrontList "author: Waurich TUD 2013-08
  puts the varIn at the front of the first list of lists"
  input BackendDAE.Var varIn;
  input list<list<BackendDAE.Var>> lstLstIn;
  output list<list<BackendDAE.Var>> lstLstOut;
algorithm
  lstLstOut := matchcontinue(varIn,lstLstIn)
    local
      list<BackendDAE.Var> varLst;
    case(_,{})
      then
        lstLstIn;
    case(_,_)
      equation
        varLst = listHead(lstLstIn);
        varLst = varIn::varLst;
        lstLstOut = List.replaceAt(varLst, 1, lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end varInFrontList;


protected function eqInFrontList "author: Waurich TUD 2013-08
  puts the eqIn at the front of the first list of lists"
  input BackendDAE.Equation eqIn;
  input list<list<BackendDAE.Equation>> lstLstIn;
  output list<list<BackendDAE.Equation>> lstLstOut;
algorithm
  lstLstOut := matchcontinue(eqIn,lstLstIn)
    local
      list<BackendDAE.Equation> eqLst;
    case(_,{})
      then
        lstLstIn;
    case(_,_)
      equation
        eqLst = listHead(lstLstIn);
        eqLst = eqIn::eqLst;
        lstLstOut = List.replaceAt(eqLst, 1, lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end eqInFrontList;


protected function getAlgebraicEquationsForEI "author: Waurich TUD 2013-08
  computes from otherEqs the equations to solve for xa_i by:
-replacing (i+1)-times in all otherEqs the tvars with i=0: all tvars=0, i=1: all tvars=0 but tvar{1}=1, i=2: all tvars=0 but tvar{2}=1  etc.
- replacing (i+1)-times in all otherEqs the otherVars(algebraic vars) with $Xai.cref in order to solve for them"
  input list<Integer> iIn;
  input Integer size;
  input list<BackendDAE.Equation> otherEqLstIn;
  input list<BackendDAE.Var> tvarLstIn;
  input list<DAE.ComponentRef> tVarCRefLstIn;
  input list<BackendDAE.Var> otherVarLstIn;
  input list<DAE.ComponentRef> oVarCRefLstIn;
  input array<list<BackendDAE.Equation>> g_iArrIn;
  input array<list<BackendDAE.Var>> xa_iArrIn;
  input array<BackendVarTransform.VariableReplacements> replacementArrIn;
  input Integer tornSysIdx;
  output array<list<BackendDAE.Equation>> g_i_Out;
  output array<list<BackendDAE.Var>> xa_i_Out;
  output array<BackendVarTransform.VariableReplacements> replacementArrOut;
algorithm
  (g_i_Out,xa_i_Out,replacementArrOut) := matchcontinue(iIn,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn,g_iArrIn,xa_iArrIn,replacementArrIn,tornSysIdx)
    local
      Integer iValue;
      String str1,str2;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> gEqLstTmp;
      list<BackendDAE.Var> xaVarLstTmp;
      array<BackendVarTransform.VariableReplacements> replArrTmp;
      list<DAE.ComponentRef> tVarCRefLst1;
      array<list<BackendDAE.Equation>> g_iArrTmp;
      array<list<BackendDAE.Var>> xa_iArrTmp;
      BackendDAE.Var tvar;
      BackendVarTransform.VariableReplacements replTmp;
      DAE.ComponentRef tVarCRef;
  case({},_,_,_,_,_,_,_,_,_,_)
    // completed
    equation
      //g_i_lstOut = listReverse(g_i_lstIn);
      //xa_i_lstOut = listReverse(xa_i_lstIn);
      //replacementLstOut = listReverse(replacementLstIn);
    then
      (g_iArrIn,xa_iArrIn,replacementArrIn);

  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // get xa_o from g_0
    equation
      true = iValue == 0;
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = List.fold1(tVarCRefLstIn,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,"$xa"+intString(tornSysIdx)+"0",oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
          //BackendVarTransform.dumpReplacements(replTmp);
          //BackendDump.dumpVarList(xaVarLstTmp,"xa 0");
          //BackendDump.dumpEquationList(gEqLstTmp,"g 0");
      g_iArrTmp = arrayUpdate(g_iArrIn,iValue+1,gEqLstTmp);
      xa_iArrTmp = arrayUpdate(xa_iArrIn,iValue+1,xaVarLstTmp);
      replArrTmp = arrayUpdate(replacementArrIn,iValue+1,replTmp);
      (g_iArrTmp,xa_iArrTmp,replArrTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn,g_iArrTmp,xa_iArrTmp,replArrTmp,tornSysIdx);
    then
      (g_iArrTmp,xa_iArrTmp,replArrTmp);

  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // computes xa_i from g_i
    equation
      true = iValue > 0;
      str1 = "$xa"+intString(tornSysIdx)+intString(iValue);
      _ = "$g"+intString(tornSysIdx)+intString(iValue);
      tVarCRef = listGet(tVarCRefLstIn,iValue);
      tVarCRefLst1 = listDelete(tVarCRefLstIn,iValue);
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = replaceTVarWithReal(tVarCRef,1.0,replTmp);
      replTmp = List.fold1(tVarCRefLst1,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,str1,oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
      g_iArrTmp = arrayUpdate(g_iArrIn,iValue+1,gEqLstTmp);
      xa_iArrTmp = arrayUpdate(xa_iArrIn,iValue+1,xaVarLstTmp);
      replArrTmp = arrayUpdate(replacementArrIn,iValue+1,replTmp);
          //BackendVarTransform.dumpReplacements(replTmp);
          //BackendDump.dumpVarList(xaVarLstTmp,str1);
          //BackendDump.dumpEquationList(gEqLstTmp,str2);
      (g_iArrTmp,xa_iArrTmp,replArrTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn,g_iArrTmp,xa_iArrTmp,replArrTmp,tornSysIdx);
    then
      (g_iArrTmp,xa_iArrTmp,replArrTmp);

  else
    equation
      print("getAlgebraicEquationsForEI failed\n");
    then
      fail();
  end matchcontinue;
end getAlgebraicEquationsForEI;


protected function replaceTVarWithReal "author: Waurich TUD 2013-08
  adds the replacement rule to set the tvar to realIn"
  input DAE.ComponentRef tVarCRefIn;
  input Real realIn;
  input BackendVarTransform.VariableReplacements replacementIn;
  output BackendVarTransform.VariableReplacements replacementOut;
algorithm
  replacementOut := BackendVarTransform.addReplacement(replacementIn,tVarCRefIn,DAE.RCONST(realIn),NONE());
end replaceTVarWithReal;


protected function replaceOtherVarsWithPrefixCref "author: Waurich TUD 2013-07
  adds the replacement rule to set the cref to $prefix.cref"
  input Integer indxIn;
  input String prefix;
  input list<DAE.ComponentRef> oVarCRefLstIn;
  input tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplOut;
protected
  list<BackendDAE.Var> replVarLstIn, replVarLstOut;
  BackendDAE.Var replVar;
  BackendVarTransform.VariableReplacements replacementIn,replacementOut;
  DAE.ComponentRef cRef;
  DAE.ComponentRef oVarCRef;
  DAE.Exp varExp;
  DAE.Type ty;
algorithm
  (replVarLstIn,replacementIn) := tplIn;
  oVarCRef := listGet(oVarCRefLstIn,indxIn);
  cRef := ComponentReference.makeCrefQual(prefix,DAE.T_COMPLEX_DEFAULT,{},oVarCRef);
  cRef := ComponentReference.replaceSubsWithString(cRef);
  varExp := Expression.crefExp(cRef);
  replacementOut := BackendVarTransform.addReplacement(replacementIn,oVarCRef,varExp,NONE());
  ty := ComponentReference.crefLastType(cRef);
  replVar := BackendDAE.VAR(cRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
  replVar := BackendVariable.setVarStartValue(replVar,DAE.RCONST(0.0));
  replVarLstOut := replVar::replVarLstIn;
  tplOut := (replVarLstOut,replacementOut);
end replaceOtherVarsWithPrefixCref;

//--------------------------------------------------//
// get EqSystem object
//-------------------------------------------------//

protected function getEqSystem "author:Waurich TUD 2014-11
  gets a eqSys object for the given set of variables and equations."
  input list<BackendDAE.Equation> eqLst;
  input list<BackendDAE.Var> varLst;
  output EqSys syst;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  syst := createEqSystem(varLst);
  crefs := List.map(varLst,BackendVariable.varCref);
  (syst,_) := List.fold1(eqLst,getEqSystem2,crefs,(syst,1));
end getEqSystem;

protected function createEqSystem
  input list<BackendDAE.Var> varLst;
  output EqSys sys;
protected
  Integer dim;
  array<list<DAE.Exp>> matrixA;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
algorithm
  dim := listLength(varLst);
  matrixA := arrayCreate(dim,{});
  vectorB := arrayCreate(dim,DAE.RCONST(0.0));
  sys := LINSYS(dim,matrixA,vectorB,listArray(varLst));
end createEqSystem;

protected function getEqSystem2 "
  gets the coefficents and offsets from the equations"
  input BackendDAE.Equation eq;
  input list<DAE.ComponentRef> crefs;
  input tuple<EqSys,Integer> foldIn;
  output tuple<EqSys,Integer> foldOut;
protected
  Integer idx, dim;
  list<DAE.Exp> summands;
  list<DAE.Exp> coeffs,offsetLst;
  DAE.Exp offset;
  EqSys sys;
  array<list<DAE.Exp>> matrixA;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
algorithm
  (sys,idx) := foldIn;
  summands := getSummands(eq);
  (summands,_) := List.map_2(summands,ExpressionSimplify.simplify);
  ((offsetLst,coeffs)) := List.fold(crefs,getEqSystem3,(summands,{}));
  if listEmpty(offsetLst) then offset := DAE.RCONST(0.0); else   offset::offsetLst := offsetLst; end if;
  offset := List.fold(offsetLst,Expression.expAdd,offset);
  offset := Expression.negate(offset);
  LINSYS(dim=dim,matrixA=matrixA, vectorB = vectorB, vectorX=vectorX) := sys;
  matrixA := arrayUpdate(matrixA,idx,listReverse(coeffs));
  vectorB := arrayUpdate(vectorB,idx,offset);
  sys := LINSYS(dim, matrixA, vectorB, vectorX);
  foldOut := (sys,idx+1);
end getEqSystem2;

protected function getEqSystem3 "
  divides the given expressions into coefficient-terms and the rest"
  input DAE.ComponentRef  cref;
  input tuple<list<DAE.Exp>,list<DAE.Exp>> foldIn;
  output tuple<list<DAE.Exp>,list<DAE.Exp>> foldOut;
protected
  DAE.Exp coeff;
  list<DAE.Exp> allTerms,coeffs,coeffsIn;
algorithm
  (allTerms,coeffsIn) := foldIn;
  (coeffs,allTerms) := List.extract1OnTrue(allTerms,Expression.expHasCref,cref);
  coeff := List.fold(coeffs,Expression.expAdd,DAE.RCONST(0));
  if containsFunctioncallOfCref(coeff,cref) then
    print("This system of equations cannot be decomposed because its actually not linear (the coeffs are function calls of x).\n");
    fail();
  end if;
  (coeff,_) := Expression.replaceExp(coeff,Expression.crefExp(cref),DAE.RCONST(1.0));
  (coeff,_) := ExpressionSimplify.simplify(coeff);
  foldOut := (allTerms,coeff::coeffsIn);
end getEqSystem3;

protected function containsFunctioncallOfCref "
  outputs true if the expIn contains a function call which has cref as input"
  input DAE.Exp expIn;
  input DAE.ComponentRef cref;
  output Boolean hasCrefInCall;
protected
  list<DAE.Exp> expLst;
algorithm
  if Expression.containFunctioncall(expIn) then
    (_,expLst) := Expression.traverseExpBottomUp(expIn,getCallExpLst,{});
    hasCrefInCall := List.fold(List.map1(expLst,Expression.expHasCref,cref),boolOr,false);
  else
    hasCrefInCall := false;
  end if;
end containsFunctioncallOfCref;

protected function getCallExpLst "author: Waurich TUD 2015-08
  Returns the list of expressions from a call."
  input DAE.Exp eIn;
  input list<DAE.Exp> eLstIn;
  output DAE.Exp eOut;
  output list<DAE.Exp> eLstOut;
algorithm
  (eOut,eLstOut) := matchcontinue(eIn,eLstIn)
    local
      list<DAE.Exp> expLst;
    case(DAE.CALL(expLst=expLst),_)
      then (eIn,listAppend(expLst,eLstIn));
    else
      then (eIn,eLstIn);
  end matchcontinue;
end getCallExpLst;

protected function getSummands "gets all sum-terms in the equation.
author: Waurich TUD"
  input BackendDAE.Equation eq;
  output list<DAE.Exp> exps;
algorithm
  exps := matchcontinue(eq)
    local
      DAE.Exp lhs;
      DAE.Exp rhs;
      list<DAE.Exp> expLst1, expLst2;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs))
    equation
      expLst1 = Expression.allTerms(lhs);
      expLst1 = List.map(expLst1,Expression.negate);
      expLst2 = Expression.allTerms(rhs);
      expLst1 = listAppend(expLst1,expLst2);
    then expLst1;
  else
    equation
      print("getSummands failed! for"+BackendDump.equationString(eq)+"\n\n");
    then {};
  end matchcontinue;
end getSummands;

//--------------------------------------------------//
// Chios Condensation
//-------------------------------------------------//

protected function chiosCondensation
  input EqSys systemIn;
  output list<BackendDAE.Equation> newResEqs;
  output list<BackendDAE.Equation> addEqsOut;
  output list<BackendDAE.Var> addVarsOut;
protected
  Integer dim;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
  array<list<DAE.Exp>> matrixA;
  list<BackendDAE.Equation> eqLst;
algorithm
  LINSYS(dim=dim, matrixA=matrixA, vectorB=vectorB, vectorX=vectorX) := systemIn;
  (addEqsOut,addVarsOut) := ChiosCondensation2(systemIn,1,{},{});
  addEqsOut := listReverse(addEqsOut);
  addVarsOut := listReverse(addVarsOut);
  newResEqs := generateCramerEqs(listReverse(List.intRange(dim)),dim,vectorX,vectorB,matrixA,{});
  newResEqs := listReverse(newResEqs);
end chiosCondensation;

protected function ChiosCondensation2
  input EqSys systemIn;
  input Integer iterIdx;
  input list<BackendDAE.Equation> addEqsIn;
  input list<BackendDAE.Var> addVarsIn;
  output list<BackendDAE.Equation> addEqsOut;
  output list<BackendDAE.Var> addVarsOut;
algorithm
  (addEqsOut,addVarsOut) := matchcontinue(systemIn,iterIdx,addEqsIn,addVarsIn)
    local
      EqSys syst;
      Integer dim;
      array<list<DAE.Exp>> matrixB, matrixA;
      array<DAE.Exp> vecAi;
      array<BackendDAE.Var> vectorX;
      list<BackendDAE.Equation> addEqs;
      list<BackendDAE.Var> addVars;
  case(LINSYS(dim=dim,  vectorX=vectorX),_,_,_)
    equation
      true = intGt(dim,1);
      //condense the matrix
      matrixB = arrayCreate(dim-1,{});
      vecAi = arrayCreate(dim-1,DAE.RCONST(real=0.0));
      (matrixB,vecAi,addEqs,addVars) = List.fold(List.intRange2(2,dim),function getNewChioRow(systemIn=systemIn,iterIdx=iterIdx),(matrixB,vecAi,addEqsIn,addVarsIn));

          print("matrixB"+intString(dim)+"\n");
          dumpMatrix(matrixB);
          print("vecAi\n");
          print(stringDelimitList(List.map1(arrayList(vecAi),ExpressionDump.dumpExpStr,0),"\n")+"\n");
          BackendDump.dumpEquationList(addEqs,"new det eqs");

      syst = LINSYS(dim=dim-1, matrixA=matrixB, vectorB= vecAi,vectorX=vectorX);
    then ChiosCondensation2(syst,iterIdx+1,addEqs,addVars);
  case(LINSYS(dim=dim, matrixA=matrixA, vectorB=vecAi),_,_,_)
    equation

          print("end matrixB"+intString(dim)+"\n");
          dumpMatrix(matrixA);
          print("end vecAi\n");
          print(stringDelimitList(List.map1(arrayList(vecAi),ExpressionDump.dumpExpStr,0),"\n")+"\n");
          BackendDump.dumpEquationList(addEqsIn,"new det eqs");

    then (addEqsIn,addVarsIn);
  end matchcontinue;
end ChiosCondensation2;

protected function generateCramerEqs "author:Waurich TUD 2014-11
  generate all equations to compute the xVector."
  input list<Integer> varIdcs;
  input Integer dim;
  input array<BackendDAE.Var> vectorX;
  input array<DAE.Exp> vectorB;
  input array<list<DAE.Exp>> matrixA;
  input list<BackendDAE.Equation> eqsIn;
  output list<BackendDAE.Equation> eqsOut;
algorithm
  eqsOut := matchcontinue(varIdcs,dim,vectorX,vectorB,matrixA,eqsIn)
    local
      Integer varIdx;
      list<Integer> rest, rangeAi,rangeX;
      DAE.Exp detAexp, detAiexp, xExp, rhs;
      list<DAE.Exp> detAiExpLst, xLst;
      DAE.Type ty;
      BackendDAE.Equation xEq;
      BackendDAE.Var xVar;
  case({},_,_,_,_,_)
    then eqsIn;
  case(varIdx::rest,_,_,_,_,_)
    equation
      true = intNe(varIdx,1);
      xVar = arrayGet(vectorX,varIdx);
      xExp = BackendVariable.varExp(xVar);
      ty = Expression.typeof(xExp);
      detAexp = makeDetExp(varIdx-1,"a",1,1,ty);
      if intNe(varIdx,dim) then
        rangeAi = List.intRange2(2,1+dim-varIdx);
        rangeX = List.intRange2(varIdx+1,dim);
        else
          rangeAi = {};
          rangeX = {};
      end if;
      detAiexp = makeDetExp(varIdx-1,"b",1,dim-varIdx+1,ty);
      detAiExpLst = List.map(rangeAi,function makeDetExp(iterIdx=varIdx-1,ident="a", row=1, ty=ty));//set the column idx with rangeAi
      xLst = List.map(List.map1(rangeX,Array.getIndexFirst,vectorX),BackendVariable.varExp);
      detAiExpLst = List.threadMap(xLst,detAiExpLst,function Expression.makeBinaryExp(inOp=DAE.MUL(ty)));
      detAiexp = List.foldr(detAiExpLst,function Expression.makeBinaryExp(inOp=DAE.SUB(ty)),detAiexp);
      (detAiexp,_) = ExpressionSimplify.simplify(detAiexp);
      rhs = DAE.BINARY(detAiexp,DAE.DIV(ty=ty),detAexp);
      xEq = BackendDAE.EQUATION(xExp,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
         BackendDump.dumpEquationList({xEq},"the new equation to solve x");
  then generateCramerEqs(rest,dim,vectorX,vectorB,matrixA,xEq::eqsIn);
  case(1::rest,_,_,_,_,_)
    equation
      varIdx = 1;
      xVar = arrayGet(vectorX,varIdx);
      xExp = BackendVariable.varExp(xVar);
      ty = Expression.typeof(xExp);
      detAexp = listGet(arrayGet(matrixA,1),1);
      rangeX = List.intRange2(2,dim);
      detAiexp = arrayGet(vectorB,1);
      detAiExpLst = List.map1(rangeX,List.getIndexFirst,arrayGet(matrixA,1));//set the column idx with rangeAi
      xLst = List.map(List.map1(rangeX,Array.getIndexFirst,vectorX),BackendVariable.varExp);
      detAiExpLst = List.threadMap(xLst,detAiExpLst,function Expression.makeBinaryExp(inOp=DAE.MUL(ty)));
      detAiexp = List.foldr(detAiExpLst,function Expression.makeBinaryExp(inOp=DAE.SUB(ty)),detAiexp);
      (detAiexp,_) = ExpressionSimplify.simplify(detAiexp);
      rhs = DAE.BINARY(detAiexp,DAE.DIV(ty=ty),detAexp);
      xEq = BackendDAE.EQUATION(xExp,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
         BackendDump.dumpEquationList({xEq},"the new equation to solve x");
  then generateCramerEqs(rest,dim,vectorX,vectorB,matrixA,xEq::eqsIn);
  end matchcontinue;
end generateCramerEqs;

protected function makeDetExp
  input Integer iterIdx;
  input String ident;
  input Integer row;
  input Integer col;
  input DAE.Type ty;
  output DAE.Exp detExp;
protected
  DAE.ComponentRef cr;
  String name;
algorithm
  name := "$det_"+ident+intString(iterIdx)+"__"+intString(row)+"_"+intString(col);
  cr := ComponentReference.makeCrefIdent(name,ty,{});
  detExp := Expression.makeCrefExp(cr,ty);
end makeDetExp;

protected function makeVarOfIdent
  input String ident;
  input DAE.Type ty;
  output BackendDAE.Var var;
protected
  DAE.ComponentRef cr;
algorithm
  cr := ComponentReference.makeCrefIdent(ident,ty,{});
  var := BackendDAE.VAR(cr,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NOT_INNER_OUTER(), false);
end makeVarOfIdent;

protected function getNewChioRow
  input Integer row;
  input EqSys systemIn;
  input Integer iterIdx;
  input tuple<array<list<DAE.Exp>>,array<DAE.Exp>,list<BackendDAE.Equation>,list<BackendDAE.Var>> foldIn;
  output tuple<array<list<DAE.Exp>>,array<DAE.Exp>,list<BackendDAE.Equation>,list<BackendDAE.Var>> foldOut;
protected
  Integer dim;
  list<Integer> columns;
  list<BackendDAE.Equation> addEqsIn,addEqs;
  list<BackendDAE.Var> addVarsIn, addVars;
algorithm
  LINSYS(dim=dim) := systemIn;
  columns := listReverse(List.intRange2(2,dim));
  foldOut := List.fold(columns,function getNewChioEntry(row = row,syst=systemIn,iter=iterIdx),foldIn);
end getNewChioRow;

protected function getNewChioEntry
  input Integer col;
  input Integer row;
  input EqSys syst;
  input Integer iter;
  input tuple<array<list<DAE.Exp>>,array<DAE.Exp>,list<BackendDAE.Equation>,list<BackendDAE.Var>> foldIn;
  output tuple<array<list<DAE.Exp>>,array<DAE.Exp>,list<BackendDAE.Equation>,list<BackendDAE.Var>> foldOut;
protected
  Integer dim;
  DAE.Exp a11,ar1,a1c,arc,br,b1,detExp, detVarExp;
  DAE.Type ty;
  DAE.ComponentRef detCR;
  BackendDAE.Equation detAeq,detAieq;
  BackendDAE.Var detAVar,detAiVar;
  String detVarName;
  array<list<DAE.Exp>> matrixA,matrixB,matrixAi;
  array<DAE.Exp> vectorB,vecAi;
  array<BackendDAE.Var> vectorX;
  list<BackendDAE.Equation> addEqs;
  list<BackendDAE.Var> addVars;
algorithm
    //print("chio entry "+intString(row)+" "+intString(col)+"\n");
  LINSYS(dim=dim, matrixA=matrixA, vectorB=vectorB,vectorX=vectorX) := syst;
  (matrixB,vecAi,addEqs,addVars) := foldIn;
  // the A determinant
  a11 := listGet(arrayGet(matrixA,1),1);
  ar1 := listGet(arrayGet(matrixA,row),1);
  a1c := listGet(arrayGet(matrixA,1),col);
  arc := listGet(arrayGet(matrixA,row),col);
  ty := Expression.typeof(a11);
  detExp := DAE.BINARY(DAE.BINARY(a11,DAE.MUL(ty = ty),arc),DAE.SUB(ty=ty),DAE.BINARY(ar1,DAE.MUL(ty = ty),a1c));
  (detExp,_) := ExpressionSimplify.simplify(detExp);
  detVarName := "$det_a"+intString(iter)+"__"+intString(row-1)+"_"+intString(col-1);
  detCR := ComponentReference.makeCrefIdent(detVarName,ty,{});
  detAVar := BackendDAE.VAR(detCR,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NOT_INNER_OUTER(), false);
  detVarExp := Expression.crefExp(detCR);
  detAeq :=  BackendDAE.EQUATION(exp=detVarExp,scalar=detExp,source=DAE.emptyElementSource,attr=BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
  matrixB := Array.consToElement(row-1,detVarExp,matrixB);
  addEqs := detAeq::addEqs;
  addVars := detAVar::addVars;

  // the Ai* determinants
  if col == dim then
  b1 := arrayGet(vectorB,1);
  br := arrayGet(vectorB,row);
  detExp := DAE.BINARY(DAE.BINARY(a11,DAE.MUL(ty = ty),br),DAE.SUB(ty=ty),DAE.BINARY(ar1,DAE.MUL(ty = ty),b1));
  (detExp,_) := ExpressionSimplify.simplify(detExp);
  detVarName := "$det_b"+intString(iter)+"__"+intString(row-1)+"_"+intString(col-1);
  detCR := ComponentReference.makeCrefIdent(detVarName,ty,{});
  detAiVar := BackendDAE.VAR(detCR,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NOT_INNER_OUTER(), false);
  detVarExp := Expression.crefExp(detCR);
  detAieq :=  BackendDAE.EQUATION(exp=detVarExp,scalar=detExp,source=DAE.emptyElementSource,attr=BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
  arrayUpdate(vecAi,row-1,detVarExp);
  addEqs := detAieq::addEqs;
  addVars := detAiVar::addVars;
  end if;

  foldOut := (matrixB,vecAi,addEqs,addVars);
end getNewChioEntry;

//--------------------------------------------------//
// Cramers Rule
//-------------------------------------------------//

protected function applyCramerRule
  input array<list<BackendDAE.Var>> jacValuesIn;
  input list<BackendDAE.Var> varsIn;
  output list<BackendDAE.Equation> resEqsOut;
  output list<BackendDAE.Var> tvarsOut;
  output list<BackendDAE.Equation> addEqsOut;
  output list<BackendDAE.Var> addVarsOut;
algorithm
  (resEqsOut,tvarsOut,addEqsOut,addVarsOut) := match(jacValuesIn,varsIn)
  local
    EqSys syst;
    list<BackendDAE.Equation> addEqs,resEqs;
    list<BackendDAE.Var> addVars;
  case(_,_)
    equation
      syst = getMatrixFromJac(jacValuesIn,varsIn);
          //dumpEqSys(syst);
      (resEqs,addEqs,addVars) = CramerRule(syst);
   then (resEqs,varsIn,addEqs,addVars);
  end match;
end applyCramerRule;

protected function CramerRule
  input EqSys system;
  output list<BackendDAE.Equation> newResEqs;
  output list<BackendDAE.Equation> otherEqsOut;
  output list<BackendDAE.Var> otherVarsOut;
algorithm
  (newResEqs,otherEqsOut,otherVarsOut) := matchcontinue(system)
    local
      Integer dim;
      array<list<DAE.Exp>> matrixA,matrixAT;
      array<DAE.Exp> vectorB;
      array<BackendDAE.Var> vectorX;
      DAE.Exp detA;
      list<DAE.Exp> detLst, varExp;
      list<BackendDAE.Equation> eqLst,addEqLst;
      list<BackendDAE.Var> addVarLst;
  case(LINSYS(dim=dim,matrixA=matrixA, vectorX=vectorX))
    equation
      // 2x2 matrix
      true = intEq(dim,2);
      matrixAT = transposeMatrix(matrixA);
          //dumpMatrix(matrixAT);
      detA = determinant(matrixA);
          //print("detA "+ExpressionDump.printExpStr(detA)+"\n");
      detLst = List.map2(List.intRange(dim),CramerRule1,system,matrixAT);
          //print("detLst \n"+stringDelimitList(List.map(detLst,ExpressionDump.printExpStr),"\n")+"\n");
      varExp = List.map(arrayList(vectorX),BackendVariable.varExp);
      detLst = List.map1(detLst,function Expression.makeBinaryExp(inOp = DAE.DIV(ty=DAE.T_ANYTYPE_DEFAULT)),detA);
      (detLst,_) = List.map_2(detLst,ExpressionSimplify.simplify);
      eqLst = List.threadMap2(varExp, detLst, BackendEquation.generateEQUATION, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
          //BackendDump.dumpEquationList(eqLst,"new residual eqs");
    then (eqLst,{},{});
  case(LINSYS(dim=dim,matrixA=matrixA, vectorX=vectorX))
    equation
      // 3x3 matrix
      true = intEq(dim,3);
      matrixAT = transposeMatrix(matrixA);
          //dumpMatrix(matrixAT);
      detA = determinant(matrixA);
          //print("detA "+ExpressionDump.printExpStr(detA)+"\n");
      detLst = List.map2(List.intRange(dim),CramerRule1,system,matrixAT);
          //print("detLst \n"+stringDelimitList(List.map(detLst,ExpressionDump.printExpStr),"\n")+"\n");
      varExp = List.map(arrayList(vectorX),BackendVariable.varExp);
      detLst = List.map1(detLst,function Expression.makeBinaryExp(inOp = DAE.DIV(ty=DAE.T_ANYTYPE_DEFAULT)),detA);
      (detLst,_) = List.map_2(detLst,ExpressionSimplify.simplify);
      eqLst = List.threadMap2(varExp, detLst, BackendEquation.generateEQUATION, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
          //BackendDump.dumpEquationList(eqLst,"new residual eqs");
    then (eqLst,{},{});
  case(LINSYS(dim=dim))
    equation
      // higher index, apply Chios condensation
      true = intGt(dim,3);
        (eqLst,addEqLst,addVarLst) = chiosCondensation(system);
    then (eqLst,addEqLst,addVarLst);
  else ({},{},{});
  end matchcontinue;
end CramerRule;

protected function CramerRule1
  input Integer idx;
  input EqSys syst;
  input array<list<DAE.Exp>> matrixAT;
  output DAE.Exp det;
algorithm
  det := match(idx,syst,matrixAT)
    local
      Integer dim;
      array<list<DAE.Exp>> matrixA;
      array<DAE.Exp> vectorB;
  case(_,LINSYS( vectorB=vectorB),_)
    equation
        //print("Cramer for "+intString(idx)+"\n");
      matrixA = arrayCopy(matrixAT);
      matrixA = replaceColumnInMatrix(matrixA,idx,arrayList(vectorB));
        //dumpMatrix(matrixA);
    then determinant(matrixA);
  end match;
end CramerRule1;

protected function determinant "
  calculates the determinant of a matrix"
  input array<list<DAE.Exp>> matrix;
  output DAE.Exp detOut;
algorithm
  detOut := matchcontinue(matrix)
    local
      DAE.Exp a11,a12,a21,a22,a13,a23,a33,a31,a32,s1,s2,s3,s4,s5,s6,det;
      DAE.Type ty;
  case(_)
    equation
      //2x2 matrix
      true = arrayLength(matrix)==2;
      a11 = listGet(arrayGet(matrix,1),1);
      a12 = listGet(arrayGet(matrix,1),2);
      a21 = listGet(arrayGet(matrix,2),1);
      a22 = listGet(arrayGet(matrix,2),2);
      ty = Expression.typeof(a11);
      det = DAE.BINARY(DAE.BINARY(a11,DAE.MUL(ty = ty),a22),DAE.SUB(ty=ty),DAE.BINARY(a12,DAE.MUL(ty = ty),a21));
      (det,_) = ExpressionSimplify.simplify(det);
  then det;
  case(_)
    equation
      //Sarrus Rule
      true = arrayLength(matrix)==3;
      a11 = listGet(arrayGet(matrix,1),1);
      a12 = listGet(arrayGet(matrix,1),2);
      a13 = listGet(arrayGet(matrix,1),3);
      a21 = listGet(arrayGet(matrix,2),1);
      a22 = listGet(arrayGet(matrix,2),2);
      a23 = listGet(arrayGet(matrix,2),3);
      a31 = listGet(arrayGet(matrix,3),1);
      a32 = listGet(arrayGet(matrix,3),2);
      a33 = listGet(arrayGet(matrix,3),3);
      ty = Expression.typeof(a11);
      s1 = DAE.BINARY(DAE.BINARY(a11,DAE.MUL(ty = ty),a22),DAE.MUL(ty = ty),a33);
      s2 = DAE.BINARY(DAE.BINARY(a12,DAE.MUL(ty = ty),a23),DAE.MUL(ty = ty),a31);
      s3 = DAE.BINARY(DAE.BINARY(a13,DAE.MUL(ty = ty),a21),DAE.MUL(ty = ty),a32);
      s4 = DAE.BINARY(DAE.BINARY(a13,DAE.MUL(ty = ty),a22),DAE.MUL(ty = ty),a31);
      s5 = DAE.BINARY(DAE.BINARY(a23,DAE.MUL(ty = ty),a32),DAE.MUL(ty = ty),a11);
      s6 = DAE.BINARY(DAE.BINARY(a33,DAE.MUL(ty = ty),a12),DAE.MUL(ty = ty),a21);
      det = DAE.BINARY(DAE.BINARY(DAE.BINARY(s1,DAE.ADD(ty = ty),s2),DAE.ADD(ty=ty),s3),DAE.SUB(ty = ty),DAE.BINARY(DAE.BINARY(s4,DAE.ADD(ty = ty),s5),DAE.ADD(ty=ty),s6));
      (det,_) = ExpressionSimplify.simplify(det);
  then det;
  else
    equation
      print("computation fo determinant failed!\n");
    then fail();
  end matchcontinue;
end determinant;

protected function replaceColumnInMatrix
  input array<list<DAE.Exp>> matrixT;
  input Integer col;
  input list<DAE.Exp> vectorB;
  output array<list<DAE.Exp>> matrixOut;
protected
  array<list<DAE.Exp>> matrix;
algorithm
  matrix := arrayUpdate(matrixT,col,vectorB);
  matrixOut := transposeMatrix(matrix);
end replaceColumnInMatrix;

protected function getMatrixFromJac
  input array<list<BackendDAE.Var>> jacValuesIn;
  input list<BackendDAE.Var> vars;
  output EqSys matrixOut;
protected
  list<list<BackendDAE.Var>> AVars;
  list<BackendDAE.Var> bVars;
  array<list<DAE.Exp>> matrixA;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
algorithm
   bVars::AVars := arrayList(jacValuesIn);
   matrixA := listArray(List.mapList(AVars,BackendVariable.varExp));
   matrixA := transposeMatrix(matrixA);
   vectorB := listArray(List.mapMap(bVars,BackendVariable.varExp,Expression.negate));
   vectorX := listArray(vars);
   matrixOut := LINSYS(dim = listLength(bVars),matrixA=matrixA, vectorB=vectorB,vectorX=vectorX);
end getMatrixFromJac;

protected function transposeMatrix "
  transposes a matrix of the form array<list<DAE.Exp>>"
  input array<list<DAE.Exp>> matrixIn;
  output array<list<DAE.Exp>> matrixOut;
protected
  Integer size;
algorithm
  size := arrayLength(matrixIn);
  matrixOut := arrayCreate(size,{});
  matrixOut := List.fold1(listReverse(List.intRange(size)),transposeMatrix1,matrixIn,matrixOut);
end transposeMatrix;

protected function transposeMatrix1
  input Integer idx;
  input array<list<DAE.Exp>> matrixOrig;
  input array<list<DAE.Exp>> matrixIn;
  output array<list<DAE.Exp>> matrixOut;
protected
  Integer size;
  list<DAE.Exp> row;
algorithm
  row := arrayGet(matrixOrig,idx);
  matrixOut := List.threadFold(List.intRange(arrayLength(matrixOrig)), row, Array.consToElement, matrixIn);
end transposeMatrix1;


//--------------------------------------------------//
// Printing stuff
//-------------------------------------------------//

protected function dumpEqSys
  input EqSys matrix;
protected
  Integer dim;
  list<String> sLst;
  array<list<DAE.Exp>> matrixA;
  array<DAE.Exp> vectorB;
  array<BackendDAE.Var> vectorX;
algorithm
  LINSYS(dim = dim, matrixA=matrixA, vectorB = vectorB, vectorX=vectorX) := matrix;
  print("Matrix("+intString(dim)+")\n");
  sLst := List.thread3Map(arrayList(matrixA),arrayList(vectorX),arrayList(vectorB),EqSysRowString);
  print(stringDelimitList(sLst,"\n")+"\n");
end dumpEqSys;

protected function EqSysRowString
  input list<DAE.Exp> Arow;
  input BackendDAE.Var x;
  input DAE.Exp b;
  output String s;
protected
  String s1,s2,s3;
algorithm
  s1 := "{ "+stringDelimitList(List.map(Arow,ExpressionDump.printExpStr),"  \t  ") + "} ";
  s2 := "{ " +ComponentReference.printComponentRefStr(BackendVariable.varCref(x))+" } ";
  s3 := " = { "+ExpressionDump.printExpStr(b)+" }";
  s:=s1+" * "+s2+s3;
end EqSysRowString;

protected function dumpMatrix
  input array<list<DAE.Exp>> matrix;
protected
  list<String> sLst;
  String s;
algorithm
  sLst := List.map(arrayList(matrix),ExpressionDump.printExpListStr);
  s := "{ "+stringDelimitList(sLst,"  \n  ") + "} \n";
  print(s);
end dumpMatrix;


protected function dumpVarArrLst "author: Waurich TUD 2013-08
  dumps a list<list<BackendDAE.Var>> as a String. TODO: remove when finished"
  input array<list<BackendDAE.Var>> inArrLst;
  input String heading;
protected
  String str;
  list<list<BackendDAE.Var>> inLstLst;
algorithm
  inLstLst := arrayList(inArrLst);
  print("---------\n"+heading+"-variables\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpVarArrLst1,inLstLst,heading);
end dumpVarArrLst;


protected function dumpVarArrLst1 "author: Waurich TUD 2013-08
  mapping function for dumpVarArrLst  TODO: remove when finished"
  input Integer lstIdx;
  input list<list<BackendDAE.Var>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Var> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+"_"+intString(lstIdx-1);
  BackendDump.dumpVarList(inLst,str1);
  headingOut := heading;
end dumpVarArrLst1;


protected function dumpEqArrLst "author: Waurich TUD 2013-08
  dumps a list<list<BackendDAE.Equation>> as a String.  TODO: remove when finished"
  input array<list<BackendDAE.Equation>> inArrLst;
  input String heading;
protected
  String str;
  list<list<BackendDAE.Equation>> inLstLst;
algorithm
  inLstLst := arrayList(inArrLst);
  print("---------\n"+heading+"-equations\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpEqArrLst1,inLstLst,heading);
end dumpEqArrLst;


protected function dumpEqArrLst1 "author: Waurich TUD 2013-08
  mapping function for dumpEqArrLst  TODO: remove when finished"
  input Integer lstIdx;
  input list<list<BackendDAE.Equation>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Equation> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+"_"+intString(lstIdx-1);
  BackendDump.dumpEquationList(inLst,str1);
  headingOut := heading;
end dumpEqArrLst1;


//--------------------------------------------------//
// solve torn systems in parallel
//-------------------------------------------------//

public function parallelizeTornSystems "author:Waurich TUD 2014-07
  analyse torn systems."
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input array<list<Integer>> sccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> simVarMapping;
  input BackendDAE.BackendDAE inDAE;
  output list<HpcOmSimCode.Task> scheduledTasks;
  output list<Integer> daeNodeIdcs;
algorithm
  (scheduledTasks,daeNodeIdcs) := matchcontinue(graphIn,metaIn,sccSimEqMapping,simVarMapping,inDAE)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
      list<HpcOmSimCode.Task> taskLst;
      list<Integer> daeNodes;
      array<list<Integer>> inComps;
      array<Integer> nodeMark;
    case (_,_,_,_,_) equation
      true = false;
      BackendDAE.DAE(eqs=eqSysts) = inDAE;
      (_,taskLst) = pts_traverseEqSystems(eqSysts,sccSimEqMapping,simVarMapping,1,{});
      // calculate the node idcs for the dae-task-gaph
      daeNodes = List.map(taskLst,getScheduledTaskCompIdx);
      //HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark) = metaIn;
      //odeNodes = List.map3(odeNodes,HpcOmTaskGraph.getCompInComps,1,inComps,nodeMark);
    then (taskLst,daeNodes);
    else ({},{});
  end matchcontinue;
end parallelizeTornSystems;

protected function getScheduledTaskCompIdx
  input HpcOmSimCode.Task taskIn;
  output Integer compIdx;
algorithm
  compIdx := match(taskIn)
    local
  case(HpcOmSimCode.SCHEDULED_TASK(compIdx=compIdx))
    then compIdx;
  end match;
end getScheduledTaskCompIdx;

protected function pts_traverseEqSystems "
author: Waurich TUD 2014-07"
  input BackendDAE.EqSystems eqSysIn;
  input array<list<Integer>> sccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> simVarMapping;
  input Integer compIdxIn;
  input list<HpcOmSimCode.Task> taskLstIn;
  output Integer compIdxOut;
  output list<HpcOmSimCode.Task> taskLstOut;
algorithm
  (compIdxOut,taskLstOut) := matchcontinue(eqSysIn,sccSimEqMapping,simVarMapping,compIdxIn,taskLstIn)
    local
      Integer compIdx;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystems eqSysRest;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponents comps;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
      list<HpcOmSimCode.Task> taskLst;
    case(BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,matching = BackendDAE.MATCHING(comps=comps))::eqSysRest,_,_,_,_)
      equation
        eqLst = BackendEquation.equationList(eqs);
        varLst = BackendVariable.varList(vars);
        (compIdx,taskLst) = pts_traverseCompsAndParallelize(comps,eqLst,varLst,sccSimEqMapping,simVarMapping,compIdxIn,taskLstIn);
        (compIdx,taskLst) = pts_traverseEqSystems(eqSysRest,sccSimEqMapping,simVarMapping,compIdx,taskLst);
      then (compIdx,taskLst);
   case({},_,_,_,_)
     then (compIdxIn,taskLstIn);
    else
      equation
        print("pts_traverseEqSystems failed\n");
      then fail();
  end matchcontinue;
end pts_traverseEqSystems;

protected function pts_traverseCompsAndParallelize"
author:Waurich TUD 2014-07"
  input list<BackendDAE.StrongComponent> inComps;
  input list<BackendDAE.Equation> eqsIn;
  input list<BackendDAE.Var> varsIn;
  input array<list<Integer>> sccSimEqMapping;
  input array<list<SimCodeVar.SimVar>> simVarMapping;
  input Integer compIdxIn;
  input list<HpcOmSimCode.Task> taskLstIn;
  output Integer compIdxOut;
  output list<HpcOmSimCode.Task> taskLstOut;
algorithm
  (compIdxOut,taskLstOut) := matchcontinue(inComps,eqsIn,varsIn,sccSimEqMapping,simVarMapping,compIdxIn,taskLstIn)
    local
      Integer numEqs, numVars, compIdx, numResEqs;
      list<Integer> eqIdcs, varIdcs, tVars, resEqs, eqIdcsSys, simEqSysIdcs,resSimEqSysIdcs,otherSimEqSysIdcs;
      list<list<Integer>> varIdcLstSys, varIdcsLsts;
      BackendDAE.InnerEquations innerEquations;
      array<list<Integer>> otherSimEqMapping;
      BackendDAE.EquationArray otherEqs;
      BackendDAE.IncidenceMatrix m,mT;
      BackendDAE.StrongComponent comp;
      BackendDAE.Variables otherVars;
      HpcOmTaskGraph.TaskGraph graph, graphMerged;
      HpcOmTaskGraph.TaskGraphMeta meta, metaMerged;
      HpcOmSimCode.Schedule schedule;
      HpcOmSimCode.Task task;
      list<HpcOmSimCode.Task> taskLst;
      list<BackendDAE.Equation> otherEqLst;
      list<BackendDAE.Var> otherVarLst;
      list<BackendDAE.StrongComponent> rest;
  case({},_,_,_,_,_,_)
    equation
    then (compIdxIn,taskLstIn);
     case((comp as BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=resEqs,innerEquations=innerEquations)))::rest,_,_,_,_,_,_)
    equation
      (eqIdcs,varIdcsLsts,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
      varIdcs = List.flatten(varIdcsLsts);
      numEqs = listLength(eqIdcs);
      numVars = listLength(varIdcs);
      numResEqs = listLength(resEqs);
      eqIdcsSys = List.intRange(numEqs);
      (varIdcLstSys,_) = List.mapFold(varIdcsLsts,genSystemVarIdcs,1);

      // create incidence matrix
      otherEqLst = List.map1(eqIdcs,List.getIndexFirst,eqsIn);
      otherVarLst = List.map1(varIdcs,List.getIndexFirst,varsIn);
      otherVars = BackendVariable.listVar1(otherVarLst);
      otherEqs = BackendEquation.listEquation(otherEqLst);
      (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(otherVars,otherEqs, BackendDAE.ABSOLUTE());

      // build task graph and taskgraphmeta
      (graph,meta) = HpcOmTaskGraph.getEmptyTaskGraph(numEqs,numEqs,numVars);
      graph = buildMatchedGraphForTornSystem(1,eqIdcsSys,varIdcLstSys,m,mT,graph);
      meta = buildTaskgraphMetaForTornSystem(graph,otherEqLst,otherVarLst,meta);
        //HpcOmTaskGraph.printTaskGraph(graph);
        //HpcOmTaskGraph.printTaskGraphMeta(meta);

      //get simEqSysIdcs and otherSimEqMapping
      simEqSysIdcs = arrayGet(sccSimEqMapping,compIdxIn);
      resSimEqSysIdcs = List.map1r(List.intRange(numResEqs),intSub,listHead(simEqSysIdcs));
      otherSimEqSysIdcs = List.map1r(List.intRange2(numResEqs+1,numResEqs+numEqs),intSub,listHead(simEqSysIdcs));
      otherSimEqMapping = listArray(List.map(otherSimEqSysIdcs,List.create));
        //print("simEqSysIdcs "+stringDelimitList(List.map(simEqSysIdcs,intString),",")+"\n");
        //print("resSimEqSysIdcs "+stringDelimitList(List.map(resSimEqSysIdcs,intString),",")+"\n");
        //print("otherSimEqSysIdcs "+stringDelimitList(List.map(otherSimEqSysIdcs,intString),",")+"\n");

      // dump graphs
      BackendDump.dumpBipartiteGraphStrongComponent1(comp,eqsIn,varsIn,NONE(),"tornSys_bipartite_"+intString(compIdxIn));
      BackendDump.dumpDAGStrongComponent(graph,meta,"tornSys_matched_"+intString(compIdxIn));

      //GRS
      //(graphMerged,metaMerged) = HpcOmSimCodeMain.applyGRS(graph,meta);
      (graphMerged,metaMerged) = (graph,meta);
      Error.addMessage(Error.INTERNAL_ERROR, {"function pts_traverseCompsAndParallelize failed. GRS is temporarily disabled."});

      BackendDump.dumpDAGStrongComponent(graphMerged,metaMerged,"tornSys_matched2_"+intString(compIdxIn));
        //HpcOmTaskGraph.printTaskGraph(graphMerged);
        //HpcOmTaskGraph.printTaskGraphMeta(metaMerged);

      //Schedule
      schedule = HpcOmScheduler.createListSchedule(graphMerged,metaMerged,2,otherSimEqMapping,simVarMapping);
      HpcOmScheduler.printSchedule(schedule);

      //transform into scheduled task object
      task = pts_transformScheduleToTask(schedule,resSimEqSysIdcs,compIdxIn);
      //HpcOmScheduler.printTask(task);
      (compIdx,taskLst) = pts_traverseCompsAndParallelize(rest,eqsIn,varsIn,sccSimEqMapping,simVarMapping,compIdxIn+1,task::taskLstIn);
    then (compIdx,taskLst);
  case(_::rest,_,_,_,_,_,_)
    equation
      (compIdx,taskLst) = pts_traverseCompsAndParallelize(rest,eqsIn,varsIn,sccSimEqMapping,simVarMapping,compIdxIn+1,taskLstIn);
    then (compIdx,taskLst);
  end matchcontinue;
end pts_traverseCompsAndParallelize;

protected function pts_transformScheduleToTask
  input HpcOmSimCode.Schedule otherEqSys;
  input list<Integer> resSimEqs;
  input Integer compIdx;
  output HpcOmSimCode.Task task;
algorithm
  task := matchcontinue(otherEqSys,resSimEqs,compIdx)
    local
      Integer numThreads;
      list<HpcOmSimCode.Task> outgoingDepTasks, outgoingDepTasksEnd;
      String lockSuffix;
      HpcOmSimCode.Schedule schedule;
      HpcOmSimCode.Task resEqsTask;
      list<HpcOmSimCode.TaskList> levelTasks;
      list<HpcOmSimCode.Task> assLocks,relLocks, firstThread;
      array<list<HpcOmSimCode.Task>> threadTasks;
      list<list<HpcOmSimCode.Task>> threadTasksLst;
      array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
    case(HpcOmSimCode.LEVELSCHEDULE(),_,_)
      equation
        print("levelScheduling is not supported for heterogenious scheduling\n");
      then
        fail();
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks),_,_)
      equation
        //05-09-2014 marcusw: Changed because of dependency-task restructuring for MPI
        numThreads = arrayLength(threadTasks);
        // rename locks, get locks before residual equations
        //lockSuffix = "_"+intString(compIdx);
        //outgoingDepTasks = List.map1(lockIdc,stringAppend,lockSuffix);
        //outgoingDepTasksEnd = List.map1r(List.map(List.intRange(numThreads),intString),stringAppend,"lock_comp"+intString(compIdx)+"_th");
        //outgoingDepTasks = listAppend(outgoingDepTasks,outgoingDepTasksEnd);
        //threadTasks = Array.map1(threadTasks,appendStringToLockIdcs,lockSuffix);

        // build missing residual tasks and locks
        //assLocks = List.map(outgoingDepTasksEnd,HpcOmScheduler.getAssignLockTask);
        //relLocks = List.map(outgoingDepTasksEnd,HpcOmScheduler.getReleaseLockTask);
        //resEqsTask = HpcOmSimCode.CALCTASK(0,-1,-1.0,-1.0,1,resSimEqs);

        threadTasksLst = arrayList(threadTasks);

        //threadTasksLst = List.threadMap(threadTasksLst,List.map(relLocks,List.create),listAppend);
        //firstThread::threadTasksLst = threadTasksLst;

        //firstThread = listAppend(firstThread,assLocks);
        //firstThread = listAppend(firstThread,{resEqsTask});

        //threadTasksLst = firstThread::threadTasksLst;
        threadTasks = listArray(threadTasksLst);
        schedule = HpcOmSimCode.THREADSCHEDULE(threadTasks,outgoingDepTasks,{},allCalcTasks);

      then
        HpcOmSimCode.SCHEDULED_TASK(compIdx,numThreads,schedule);
    else
      equation
        print("pts_transformScheduleToTask failed\n");
      then fail();
  end matchcontinue;
end pts_transformScheduleToTask;

protected function genSystemVarIdcs
  input list<Integer> idcsIn;
  input Integer idx;
  output list<Integer> idcsOut;
  output Integer idx2;
algorithm
  idx2 := listLength(idcsIn)+idx;
  idcsOut := List.intRange2(idx,idx2-1);
end genSystemVarIdcs;


//05-09-2014 marcusw: Changed because of dependency-task restructuring for MPI
//protected function appendStringToLockIdcs "author: Waurich TUD 2014-07
//  appends the suffix to the lockIds of the given tasks
//"
//  input list<HpcOmSimCode.Task> taskLstIn;
//  input String suffix;
//  output list<HpcOmSimCode.Task> taskLstOut;
//algorithm
//  taskLstOut := List.map1(taskLstIn,appendStringToLockIdcs1,suffix);
//end appendStringToLockIdcs;
//
//protected function appendStringToLockIdcs1 "author: Waurich TUD 2014-07
//  appends the suffix to the lockIds of the given tasks
//"
//  input HpcOmSimCode.Task taskIn;
//  input String suffix;
//  output HpcOmSimCode.Task taskOut;
//algorithm
//  taskOut := match(taskIn,suffix)
//    local
//      String lockId;
//    case(HpcOmSimCode.ASSIGNLOCKTASK(lockId=lockId),_)
//      equation
//        lockId = stringAppend(lockId,suffix);
//    then HpcOmSimCode.ASSIGNLOCKTASK(lockId);
//     case(HpcOmSimCode.RELEASELOCKTASK(lockId=lockId),_)
//      equation
//        lockId = stringAppend(lockId,suffix);
//    then HpcOmSimCode.RELEASELOCKTASK(lockId);
//    else
//      then taskIn;
//  end match;
//end appendStringToLockIdcs1;

protected function buildMatchedGraphForTornSystem
  input Integer idx;
  input list<Integer> eqsIn;
  input list<list<Integer>> varsIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input array<list<Integer>> graphIn;
  output array<list<Integer>> graphOut;
algorithm
  graphOut := matchcontinue(idx,eqsIn,varsIn,m,mt,graphIn)
    local
      Integer eq;
      list<Integer> vars, depVars,depEqs;
      array<list<Integer>> graph;
    case(_,_,_,_,_,_)
      equation
        true = listLength(eqsIn) >= idx;
        vars = listGet(varsIn,idx);
        eq = listGet(eqsIn,idx);
        depEqs = List.flatten(List.map1(vars,Array.getIndexFirst,mt));
        depEqs = List.deleteMember(depEqs,eq);
        graph = arrayUpdate(graphIn,eq,depEqs);
        graph = buildMatchedGraphForTornSystem(idx+1,eqsIn,varsIn,m,mt,graph);
    then graph;
    case(_,_,_,_,_,_)
      equation
        false = listLength(eqsIn) > idx;
      then graphIn;
  end matchcontinue;
end buildMatchedGraphForTornSystem;

protected function buildTaskgraphMetaForTornSystem "author:Waurich TUD 2014-07
  creates a preliminary task graph meta object"
  input HpcOmTaskGraph.TaskGraph graph;
  input list<BackendDAE.Equation> eqLst;
  input list<BackendDAE.Var> varLst;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  output HpcOmTaskGraph.TaskGraphMeta metaOut;
protected
  Integer numNodes;
  list<String> eqStrings, varStrings, descLst;
  array<tuple<Integer,Integer,Integer>> eqCompMapping, varCompMapping;
  list<list<String>> eqCharsLst;
  array<Integer> nodeMark;
  array<String> compDescs, compNames;
  array<list<Integer>> inComps;
  array<tuple<Integer,Real>> exeCosts;
  array<list<Integer>> compParamMapping;
  array<HpcOmTaskGraph.Communications> commCosts;
  array<HpcOmTaskGraph.ComponentInfo> compInformations;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, compParamMapping=compParamMapping, nodeMark=nodeMark,compInformations=compInformations) := metaIn;
  numNodes := arrayLength(graph);
  // get the inComps
  inComps := listArray(List.map(List.intRange(numNodes),List.create));
  // get the compNames
  compNames := listArray(List.map(List.intRange(numNodes),intString));
  //get the exeCost
  exeCosts := arrayCreate(numNodes,(3,20.0));
  //get the commCosts
  commCosts := Array.map(graph,buildDummyCommCosts);
  //get the node description
  eqStrings := List.map(eqLst,BackendDump.equationString);
  varStrings := List.map(varLst,HpcOmTaskGraph.getVarString);
  descLst := List.map1(eqStrings,stringAppend," FOR ");
  descLst := List.threadMap(descLst,varStrings,stringAppend);
  compDescs := listArray(descLst);
  metaOut := HpcOmTaskGraph.TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,compParamMapping,compNames,compDescs,exeCosts,commCosts,nodeMark,compInformations);
end buildTaskgraphMetaForTornSystem;

protected function buildDummyCommCosts "author:Waurich TUD 2014-07
  generates preliminary commCosts for a children list."
  input list<Integer> childNodes;
  output HpcOmTaskGraph.Communications commCosts;
algorithm
  commCosts := List.map(childNodes,buildDummyCommCost);
end buildDummyCommCosts;

protected function buildDummyCommCost "author:marcusw
  Generates preliminary commCost for a children."
  input Integer iChildNodeIdx;
  output HpcOmTaskGraph.Communication oCommCost;
algorithm
  oCommCost := HpcOmTaskGraph.COMMUNICATION(1,{},{-1},{},{},iChildNodeIdx,70.0);
end buildDummyCommCost;

public function createSingleBlockSchedule
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input list<HpcOmSimCode.Task> scheduledTasks;
  input array<list<Integer>> sccSimEqMapping;
  output HpcOmSimCode.Schedule schedule;
protected
  list<Integer> nodes, schedTaskComps;
  list<list<Integer>> comps,simEqSys;
  list<HpcOmSimCode.Task> thread1;
  array<list<HpcOmSimCode.Task>> threadTasks;
  array<list<Integer>> inComps;
  list<String> lockIdc;
  array<tuple<HpcOmSimCode.Task,Integer>> allCalcTasks;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps) := metaIn;
  nodes := List.intRange(arrayLength(graphIn));
  comps := List.map1(nodes,Array.getIndexFirst,inComps);
  simEqSys := HpcOmScheduler.getSimEqSysIdcsForNodeLst(comps,sccSimEqMapping);
  simEqSys := List.map1(simEqSys,List.sort,intGt);
  thread1 := List.threadMap1(simEqSys,nodes,HpcOmScheduler.makeCalcTask,1);
  threadTasks := arrayCreate(4,{});
  threadTasks := arrayUpdate(threadTasks,1,thread1);
  allCalcTasks := arrayCreate(listLength(thread1), (HpcOmSimCode.TASKEMPTY(),0));
  schedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{},scheduledTasks,allCalcTasks);
end createSingleBlockSchedule;

annotation(__OpenModelica_Interface="backend");
end HpcOmEqSystems;
