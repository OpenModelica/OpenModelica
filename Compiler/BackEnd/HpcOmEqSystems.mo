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

  RCS: $Id: HpcOmEqSystems.mo 15486 2013-05-24 11:12:35Z  $
"
// public imports

public import BackendDAE;
public import DAE;
public import HpcOmTaskGraph;
public import HpcOmSimCode;

// protected imports
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDAETransform;
protected import BackendVariable;
protected import BackendVarTransform;
protected import ComponentReference;
protected import Debug;
protected import Expression;
protected import Flags;
protected import GraphML;
protected import HpcOmSimCodeMain;
protected import HpcOmScheduler;
protected import List;
protected import Matching;
protected import Tearing;
protected import Util;

//--------------------------------------------------//
// start functions for handling linearTornSystems from here
//-------------------------------------------------//

public function traverseEqSystemsWithIndex  "traverse alle EqSystems of the BackendDAE and hold an index of the current torn system.
author:Waurich TUD 2013-10"
  input Integer eqSysIdx;
  input Integer tornSysIdxIn;
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  daeOut := matchcontinue(eqSysIdx,tornSysIdxIn,daeIn)
    local
      Integer tornSysIdx;
      BackendDAE.BackendDAE daeTmp;
      BackendDAE.EqSystem eqSyst;
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
    case(_,_,BackendDAE.DAE(eqs=eqSysts, shared=shared))
      equation
        true = listLength(eqSysts) >= eqSysIdx;
        eqSyst = listGet(eqSysts,eqSysIdx);
        (eqSyst,shared,tornSysIdx) = reduceLinearTornSystem(eqSyst,shared,tornSysIdxIn);
        eqSysts = List.replaceAt(eqSyst,eqSysIdx-1,eqSysts);
        daeTmp = BackendDAE.DAE(eqSysts,shared);
        daeTmp = traverseEqSystemsWithIndex(eqSysIdx+1,tornSysIdx,daeTmp);
      then
        daeTmp;
    case(_,_,BackendDAE.DAE(eqs=eqSysts))
      equation
        true = listLength(eqSysts) < eqSysIdx;
      then
        daeIn;
  end matchcontinue;
end traverseEqSystemsWithIndex;


public function reduceLinearTornSystem  "checks the EqSystem for tornSystems in order to dissassemble them into various SingleEquation and a reduced EquationSystem.
This is useful in order to reduce the execution costs of the equationsystem and generate a bunch of parallel singleEquations. use +d=doLienarTearing,partlintornsystem to activate it.
Remark: this is still under development
author:Waurich TUD 2013-09"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input Integer tornSysIdxIn;
  output BackendDAE.EqSystem systOut;
  output BackendDAE.Shared sharedOut;
  output Integer tornSysIdxOut;
algorithm
  (systOut, sharedOut, tornSysIdxOut) := matchcontinue(systIn,sharedIn,tornSysIdxIn)
    local
      Integer tornSysIdx;
      array<Integer> ass1, ass2;
      BackendDAE.EqSystem systTmp;
      BackendDAE.EquationArray eqs, eqsTmp;
      BackendDAE.Matching matching;
      BackendDAE.Shared sharedTmp;
      BackendDAE.StrongComponents allComps, compsTmp;
      BackendDAE.Variables vars, varsTmp;
    case(_,_,_)
      equation
        BackendDAE.EQSYSTEM(matching = BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps= allComps)) = systIn;
          //BackendDump.dumpEqSystem(systIn,"original system");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(1, allComps, ass1, ass2, systIn,sharedIn,tornSysIdxIn);
          //BackendDump.dumpEqSystem(systTmp,"new system");
        sharedTmp = sharedIn;
      then
        (systTmp, sharedTmp, tornSysIdx);
    else
      equation
        print("reduceLinearTornSystem failed!");
      then
        fail();
  end matchcontinue;
end reduceLinearTornSystem;


protected function reduceLinearTornSystem1  "traverses all StrongComponents for tornSystems, reduces them and rebuilds the BLT, the matching and the info about vars and equations
author: Waurich TUD 2013-09"
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
      list<Integer> tvarIdcs;
      list<Integer> resEqIdcs;
      list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
      BackendDAE.EqSystem systTmp;
      BackendDAE.EquationArray eqs;
      BackendDAE.Matching matching, matchingNew, matchingOther;
      BackendDAE.Shared sharedTmp;
      BackendDAE.StateSets stateSets;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsNew, compsTmp, otherComps;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqLst, eqsNew, eqsOld, resEqs;
      list<BackendDAE.Var> varLst, varsNew, varsOld, tvars;
      BackendDAE.BaseClockPartitionKind partitionKind;
    case(_,_,_,_,_,_,_)
      equation
        // completed
        true = listLength(compsIn) < compIdx;
          //print("finished at:"+&intString(compIdx)+&"\n");
      then
        (systIn,tornSysIdxIn);
    case(_,_,_,_,_,_,_)
      equation
        // strongComponent is a linear tornSystem
        true = listLength(compsIn) >= compIdx;

        comp = listGet(compsIn,compIdx);
        BackendDAE.TORNSYSTEM(tearingvars = tvarIdcs, residualequations = resEqIdcs, otherEqnVarTpl = otherEqnVarTpl, linear = linear) = comp;
        true = linear;
        Debug.fcall(Flags.HPCOM_DUMP,print,"handle linear torn systems of size: "+&intString(listLength(tvarIdcs)+listLength(otherEqnVarTpl))+&"\n");
           //print("handle tornsystem with compnumber:"+&intString(compIdx)+&"\n");
           //BackendDump.dumpEqSystem(systIn,"the original system");
           
        // build the new components, the new variables and the new equations
        (varsNew,eqsNew,_,resEqs,matchingNew) = reduceLinearTornSystem2(systIn,sharedIn,tvarIdcs,resEqIdcs,otherEqnVarTpl,tornSysIdxIn);

        BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) = matchingNew;
        // add the new vars and equations to the original EqSystem
        BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs, stateSets = stateSets, partitionKind=partitionKind) = systIn;
        varsOld = BackendVariable.varList(vars);
        eqsOld = BackendEquation.equationList(eqs);

        varLst = listAppend(varsOld,varsNew);
        eqLst = listAppend(eqsOld, eqsNew);
        eqLst = List.fold2(List.intRange(listLength(resEqIdcs)),replaceAtPositionFromList,resEqs,resEqIdcs,eqLst);  // replaces the old residualEquations with the new ones
        vars = BackendVariable.listVar1(varLst);  // !!! BackendVariable.listVar outputs the reversed order therefore listVar1
        eqs = BackendEquation.listEquation(eqLst);
        Debug.fcall(Flags.HPCOM_DUMP,print,"number of equations added: "+&intString(listLength(eqLst))+&" and the size of the linear torn system: "+&intString(listLength(tvarIdcs))+&"\n");
        //print("new systemsize:"+&intString(listLength(varLst))+&" vars. and "+&intString(listLength(eqLst))+&" eqs\n");

        // build the matching
        ass1All = arrayCreate(listLength(varLst),-1);
        ass2All = arrayCreate(listLength(varLst),-1);  // actually has to be listLength(eqLst), but there is stille the probelm taht ass1 and ass2 have the same size
        ass1All = Util.arrayCopy(ass1,ass1All);  // the comps before and after the tornsystem
        ass2All = Util.arrayCopy(ass2,ass2All);
        ((ass1All, ass2All)) = List.fold2(List.intRange(listLength(tvarIdcs)),updateResidualMatching,tvarIdcs,resEqIdcs,(ass1All,ass2All));  // sets matching info for the tearingVars and residuals

        // get the otherComps and and update the matching for the othercomps
        matchingOther = getOtherComps(otherEqnVarTpl,ass1All,ass2All);
        BackendDAE.MATCHING(ass1=_, ass2=_, comps=otherComps) = matchingOther;

        // insert the new components into the BLT instead of the TornSystem, append the updated blocks for the other equations, update matching for the new equations
        numNewSingleEqs = listLength(compsNew)-listLength(tvarIdcs);
          //print("num of new comps:"+&intString(numNewSingleEqs)+&"\n");
          //BackendDump.dumpComponents(compsNew);
        compsNew = listAppend(compsNew, otherComps);
        compsTmp = List.replaceAtWithList(compsNew,compIdx-1,compsIn);
        ((ass1All,ass2All)) = List.fold2(List.intRange(arrayLength(ass1New)),updateMatching,(listLength(eqsOld),listLength(varsOld)),(ass1New,ass2New),(ass1All,ass2All));
        matching = BackendDAE.MATCHING(ass1All, ass2All, compsTmp);

        //build new EqSystem
        systTmp = BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),matching,stateSets,partitionKind);
        (systTmp,_,_) = BackendDAEUtil.getIncidenceMatrix(systTmp, BackendDAE.NORMAL(),NONE());
          //BackendDump.dumpEqSystem(systTmp,"the whole new system");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(compIdx+1+numNewSingleEqs,compsTmp,ass1All,ass2All,systTmp,sharedIn,tornSysIdxIn+1);
      then
        (systTmp,tornSysIdx);
    else
      // go to next StrongComponent
      equation
        //print("no torn system in comp:"+&intString(compIdx)+&"\n");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(compIdx+1,compsIn,ass1,ass2,systIn,sharedIn,tornSysIdxIn);
      then
        (systTmp,tornSysIdx);
  end matchcontinue;
end reduceLinearTornSystem1;


protected function reduceLinearTornSystem2  " builds from a torn system various linear equation systems that can be computed in parallel.
author: Waurich TUD 2013-07"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> tearingVars;
  input list<Integer> residualEqs;
  input list<tuple<Integer, list<Integer>>> otherEqsVarTpl;
  input Integer tornSysIdx;
  output list<BackendDAE.Var> varsNewOut;
  output list<BackendDAE.Equation> eqsNewOut;
  output list<BackendDAE.Var> tVarsOut;
  output list<BackendDAE.Equation> resEqsOut;
  output BackendDAE.Matching matchingOut;
protected
  Boolean isSingleEq;
  array<Integer> ass1New, ass2New;
  Integer size, otherEqSize, compSize;
  list<Integer> otherEqnsInts, otherVarsInts, tVarRange, rEqIdx;
  list<list<Integer>> otherVarsIntsLst;
  BackendDAE.EqSystem systNew;
  BackendDAE.EquationArray eqns,  oeqns, hs0Eqs;
  BackendDAE.Matching matchingNew;
  BackendDAE.StrongComponent rComp;
  BackendDAE.StrongComponents comps, compsNew, oComps;
  BackendDAE.Variables vars, kv,  diffVars, ovars, dVars;
  BackendVarTransform.VariableReplacements repl, repl1;
  DAE.FunctionTree functree;
  list<BackendDAE.Equation> eqLst,reqns, otherEqnsLst,otherEqnsLstReplaced, eqNew, hs, hs1;
  list<BackendDAE.EquationArray> gEqs, hEqs, hsEqs;
  list<BackendDAE.Var> varLst, tvars, tvarsReplaced, ovarsLst, xa0, a_0, varNew;
  list<BackendDAE.Variables> xaVars, rVars, aVars;
  list<BackendVarTransform.VariableReplacements> replLst;
  list<list<BackendDAE.Equation>> g_i_lst, g_i_lst1, h_i_lst, h_i_lst1, hs_i_lst, hs_i_lst1, hs_0_lst;
  list<list<BackendDAE.Var>> xa_i_lst, xa_i_lst1, r_i_lst, r_i_lst1, a_i_lst, a_i_lst1;
  list<DAE.ComponentRef> tcrs,ovcrs;
algorithm
   // handle torn systems for the linear case
   BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqns, matching = BackendDAE.MATCHING(comps=comps)) := isyst;
   BackendDAE.SHARED(knownVars=kv, functionTree=functree) := ishared;
   eqLst := BackendEquation.equationList(eqns);
   varLst := BackendVariable.varList(vars);
   tvars := List.map1r(tearingVars, BackendVariable.getVarAt, vars);
   tvarsReplaced := List.map(tvars, BackendVariable.transformXToXd);
   tcrs := List.map(tvarsReplaced, BackendVariable.varCref);

   // get residual eqns
   reqns := BackendEquation.getEqns(residualEqs, eqns);
   reqns := BackendEquation.replaceDerOpInEquationList(reqns);

   // get the other equations and the other variables
   otherEqnsInts := List.map(otherEqsVarTpl, Util.tuple21);
   otherEqnsLst := BackendEquation.getEqns(otherEqnsInts, eqns);
   oeqns := BackendEquation.listEquation(otherEqnsLst);
   otherEqnsLstReplaced := BackendEquation.replaceDerOpInEquationList(otherEqnsLst);   // for computing the new equations

   otherVarsIntsLst := List.map(otherEqsVarTpl, Util.tuple22);
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
   repl1 := BackendVarTransform.emptyReplacements();

   //  get g_i(xt=e_i, xa=xa_i) with xa_i as variables to be solved
   (g_i_lst,xa_i_lst,replLst) := getAlgebraicEquationsForEI(tVarRange,size,otherEqnsLstReplaced,tvarsReplaced,tcrs,ovarsLst,ovcrs,{},{},{},tornSysIdx);
   (g_i_lst1,xa_i_lst1,repl1) := simplifyEquations(g_i_lst,xa_i_lst,repl1);
     //dumpVarLst(xa_i_lst,"xa");
     //dumpEqLstLst(g_i_lst,"g");

   //  compute residualValues h_i(xt=e_i,xa_i,r_i) for r_i
   (h_i_lst,r_i_lst) := addResidualVarToEquation(tVarRange,reqns,{},{},tornSysIdx);  
   h_i_lst := replaceVarsInResidualEquations(tVarRange,h_i_lst,replLst,{});
   (h_i_lst1,r_i_lst1,repl1) := simplifyEquations(h_i_lst,r_i_lst,repl1);
     //dumpVarLstLst(r_i_lst,"r");
     //dumpEqLstLst(h_i_lst,"h");

   //  get the co-efficients for the new residualEquations a_i from hs_i(r_i,xt=e_i, a_i)
   (hs_i_lst,a_i_lst) := getTornSystemCoefficients(tVarRange,size,r_i_lst,{},{},tornSysIdx);
   (hs_i_lst1,a_i_lst1,repl1) := simplifyEquations(hs_i_lst,a_i_lst,repl1);
      //dumpVarLstLst(a_i_lst,"a");
      //dumpEqLstLst(hs_i_lst,"hs_i");

   // gather all additional equations and build the strongComponents (not including the new residual equation)
   eqsNewOut := List.flatten(listAppend(listAppend(g_i_lst1,h_i_lst1),hs_i_lst1));
   varsNewOut := List.flatten(listAppend(listAppend(xa_i_lst1,r_i_lst1),a_i_lst1));
     //BackendDump.dumpVarList(varsNewOut,"varsNew");
     //BackendDump.dumpEquationList(eqsNewOut,"eqsNew");
   
   matchingNew := buildSingleEquationSystem(compSize,eqsNewOut,varsNewOut,ishared,{});
   BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) := matchingNew;
   compsNew := List.map2(compsNew,updateIndicesInComp,listLength(varLst),listLength(eqLst));
     //BackendDump.dumpComponents(compsNew);

   // compute the tearing vars in the new residual equations hs
   (a_0::a_i_lst) := a_i_lst;
   //a_0 := listReverse(a_0);

   hs := buildNewResidualEquation(1,a_i_lst,a_0,tvars,{});
   (hs1,_) := BackendVarTransform.replaceEquations(hs,repl1,NONE());
   tVarsOut := tvars;
   resEqsOut := hs1;

   //// get the strongComponent for the residual equations and add it at the end of the new StrongComponents
   //BackendDump.dumpEquationList(resEqsOut,"the equations of the system\n");
   //BackendDump.dumpVarList(tVarsOut, "the vars of the system\n");

   isSingleEq := intEq(listLength(resEqsOut),1);
   rComp := buildEqSystemComponent(isSingleEq,tearingVars,residualEqs,a_i_lst);
   oComps := List.appendElt(rComp,compsNew);
   matchingOut := BackendDAE.MATCHING(ass1New,ass2New,oComps);

   //printPartLinTornInfo(tcrs,reqns,otherEqnsLst,ovcrs,xa_i_lst,g_i_lst,r_i_lst,h_i_lst,a_i_lst,hs_i_lst,hs,compsNew);
end reduceLinearTornSystem2;


protected function buildEqSystemComponent "builds a strongComponent for the reduced System. if the system size is 1, a SingleEquation is built, otherwise a EqSystem with jacobian.
author:Waurich TUD 2013-12"
  input Boolean isSingleEq;
  input list<Integer> varIdcsIn;
  input list<Integer> eqIdcsIn;
  input list<list<BackendDAE.Var>> jacValuesIn;
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp := match(isSingleEq,varIdcsIn,eqIdcsIn,jacValuesIn)
    local
      Integer eqIdx,varIdx;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.StrongComponent comp;
    case(true,_,_,_)
      equation
        eqIdx = listGet(eqIdcsIn,1);
        varIdx = listGet(varIdcsIn,1);
        comp = BackendDAE.SINGLEEQUATION(eqIdx,varIdx);
        Debug.fcall(Flags.HPCOM_DUMP,print,"a linear equationsystem of size 1 was found and was replaced by a single equation\n\n");
      then
        comp;
    case(false,_,_,_)
      equation
        jac = buildLinearJacobian(jacValuesIn);
        //print("Jac:\n" +& BackendDump.dumpJacobianStr(jac) +& "\n");
        comp = BackendDAE.EQUATIONSYSTEM(eqIdcsIn,varIdcsIn,BackendDAE.FULL_JACOBIAN(jac),BackendDAE.JAC_LINEAR());
        //print("the eqs of the sys: "+&stringDelimitList(List.map(varIdcsIn,intString),"\n")+&"\n");
        //print("the vars of the sys: "+&stringDelimitList(List.map(eqIdcsIn,intString),"\n")+&"\n");
        //comp = BackendDAE.EQUATIONSYSTEM(eqIdcsIn,varIdcsIn,NONE(),BackendDAE.JAC_NO_ANALYTIC());
        //comp = BackendDAE.TORNSYSTEM(varIdcsIn,eqIdcsIn,{},true);
        Debug.fcall(Flags.HPCOM_DUMP,print,"a linear equationsystem of size "+&intString(listLength(eqIdcsIn))+&" is left from the partitioning.\n\n");
      then
        comp;
  end match;
end buildEqSystemComponent;


protected function buildLinearJacobian "builds the jacobian out of the given jacobian-entries
author:Waurich TUD 2013-12"
  input list<list<BackendDAE.Var>> inElements;  //outer list refers to the row, inner list to the column
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outJac;
protected
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
algorithm
  jac := List.fold1(List.intRange(listLength(inElements)),buildLinearJacobian1,inElements,{});
  jac := listReverse(jac);
  outJac := SOME(jac);
end buildLinearJacobian;


protected function buildLinearJacobian1 "helper for buildLinearJacobian.
author:Waurich TUD 2013-12"
  input Integer rowIdx;
  input list<list<BackendDAE.Var>> inElements;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inJac;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outJac;
protected
  list<BackendDAE.Var> elements;
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
algorithm
  elements := listGet(inElements,rowIdx);
  outJac := List.fold2(List.intRange(listLength(inElements)),buildLinearJacobian2,elements,rowIdx,inJac);
end buildLinearJacobian1;


protected function buildLinearJacobian2 "helper for buildLinearJacobian
author:Waurich TUD 2013-12"
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
  eq := BackendDAE.RESIDUAL_EQUATION(exp,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
  entry := (colIdx,rowIdx,eq);
  outJac := entry::inJac;
end buildLinearJacobian2;


protected function updateMatching "inserts the information of matching2 into matching1 by adding an index offset for the vars and eqs of matching2.Actually only one assignment for matching 2 is needed.
author: Waurich TUD 2013-09"
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


protected function updateResidualMatching "sets the matching between tearingVars and residuals.
author: Waurich TUD 2013-09"
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


protected function getOtherComps "builds ordered StrongComponents and matching for the other equations.
author: Waurich TUD 2013-09"
  input list<tuple<Integer, list<Integer>>> otherEqsVarTpl;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output BackendDAE.Matching matchingOut;
protected
  array<Integer> ass1Tmp, ass2Tmp;
  BackendDAE.StrongComponents compsTmp;
algorithm
  ((ass1Tmp,ass2Tmp,compsTmp)) := List.fold(otherEqsVarTpl,getOtherComps1,(ass1,ass2,{}));
  compsTmp := listReverse(compsTmp);
  matchingOut := BackendDAE.MATCHING(ass1Tmp,ass2Tmp,compsTmp);
end getOtherComps;


protected function getOtherComps1 "implementation of getOtherComps
author:waurich TUD 2013-09"
  input tuple<Integer,list<Integer>> otherEqsVarTpl;
  input tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplIn;
  output tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplOut;
algorithm
  tplOut := matchcontinue(otherEqsVarTpl, tplIn)
    local
      Integer eqIdx, varIdx;
      array<Integer> ass1, ass2;
      list<Integer> varIdcs;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsIn, compsTmp;
    case((eqIdx, varIdcs),(ass1,ass2,compsIn))
      equation
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


protected function replaceAtPositionFromList  "replaces the entry from inLst indexed by positionLst[n] with with the nth entry in replacingLst. n is first input so it can be used in a folding functions.
author: Waurich TUD 2013-09"
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
  outLst := List.replaceAt(entry,idx-1,inLst);
end replaceAtPositionFromList;


protected function updateIndicesInComp " raises the indices of the vars and eqs in the given component according to the given offsets.
author: Waurich TUD 2013-09"
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

protected function buildNewResidualEquation "function to build the new linear residual equations res=0=A*xt+a0 whicht is solved for xt
author: Waurich TUD 2013-09"
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
        //aCoeffs = listGet(aCoeffLst,resIdx);
        //aCoeffs = listReverse(aCoeffs);
        aCoeffs = List.map1(aCoeffLst,listGet,resIdx);
        a0Coeff = listGet(a0CoeffLst,resIdx);
        a0Exp = varExp(a0Coeff);
        ty = DAE.T_REAL_DEFAULT;
        rhs = buildNewResidualEquation2(1,aCoeffs,tvars,DAE.RCONST(0.0)); // the start value is random and will be rejected
        rhs = DAE.BINARY(rhs, DAE.ADD(ty), a0Exp);
        lhs = DAE.RCONST(0.0);
        hs = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
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


protected function buildNewResidualEquation2 "function to build the sum of the rhs of the new residual equation, i.e. the sum of all tvars and their coefficients
author: Waurich TUD 2013-09"
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
        tVarExp = Debug.bcallret1(BackendVariable.isStateVar(tVar), Expression.expDer, tVarExp, tVarExp); // if tvar is a state, use the der(varexp)
        ty = DAE.T_REAL_DEFAULT;
        expTmp = DAE.BINARY(coeffExp,DAE.MUL(ty),tVarExp);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then
        expTmp;
    case(_,_,_,_)
      equation
        true = idx <= listLength(tVars);
        //extend the expression
        coeff = listGet(coeffs,idx);
        tVar = listGet(tVars,idx);
        expTmp = addProductToExp(coeff,tVar,expIn);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then
        expTmp;
    case(_,_,_,_)
      equation
        true = idx > listLength(tVars);
      then
        expIn;
    else
      equation
        print("buildNewResidualEquation2 failed!\n");
      then
        fail();
  end matchcontinue;
end buildNewResidualEquation2;


protected function addProductToExp " function to add the product of the given 2 BackendDAE.Var to the given inExp. expOut = expIn + fac1*fac2
author: Waurich TUD 2013-09"
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
  fac2 := Debug.bcallret1(BackendVariable.isStateVar(var2), Expression.expDer, fac2, fac2);
  ty := DAE.T_REAL_DEFAULT;
  prod := DAE.BINARY(fac1, DAE.MUL(ty), fac2);
  expOut := DAE.BINARY(inExp, DAE.ADD(ty), prod);
end addProductToExp;


protected function buildSingleEquationSystem "function to build a system of singleEquations which can be solved partially parallel, from an EquationArray and Variables.
author: Waurich TUD 2013-07"
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
        sysTmp = BackendDAE.EQSYSTEM(vars,eqArr,NONE(),NONE(),BackendDAE.NO_MATCHING(),{},BackendDAE.UNKNOWN_PARTITION());
        (sysTmp,m,mt) = BackendDAEUtil.getIncidenceMatrix(sysTmp,BackendDAE.NORMAL(),NONE());
        nVars = listLength(inVars);
        nEqs = listLength(inEqs);
        ass1 = arrayCreate(nVars, -1);
        ass2 = arrayCreate(nEqs, -1);
        Matching.matchingExternalsetIncidenceMatrix(nVars, nEqs, m);
        BackendDAEEXT.matching(nVars, nEqs, 5, -1, 0.0, 1);
        BackendDAEEXT.getAssignment(ass2, ass1);
        matching = BackendDAE.MATCHING(ass1, ass2, {});
        sysTmp = BackendDAE.EQSYSTEM(vars,eqArr,SOME(m),SOME(mt),matching,{},BackendDAE.UNKNOWN_PARTITION());
        // perform BLT to order the StrongComponents
        mapIncRowEqn = listArray(List.intRange(nEqs));
        mapEqnIncRow = Util.arrayMap(mapIncRowEqn,List.create);
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


protected function getTornSystemCoefficients "gets the co-efficients for the new residual equations of the linear torn system
the first index is for the residualvar and the second for the tearingvar
(r1) = (a11 a12..) (xt1)+(a01)
(r2) = (a21 a22..)*(xt2)+(a02)
(:)  = (:   :    ) ( : )+( : )
this is meant to be a matrix :)
author: Waurich TUD 2013-08"
  input list<Integer> iValueRange;
  input Integer numTVars;
  input list<list<BackendDAE.Var>> r_i_lstIn;
  input list<list<BackendDAE.Equation>> hs_i_lstIn;
  input list<list<BackendDAE.Var>> a_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> hs_i_lstOut;
  output list<list<BackendDAE.Var>> a_i_lstOut;
algorithm
  (hs_i_lstOut,a_i_lstOut) := matchcontinue(iValueRange, numTVars, r_i_lstIn, hs_i_lstIn, a_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String varName;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> hs_i;
      list<BackendDAE.Var> a_i, r_i;
      list<list<BackendDAE.Equation>> hs_i_lstTmp;
      list<list<BackendDAE.Var>> a_i_lstTmp;
      BackendDAE.Var aVar;
      DAE.ComponentRef varCRef;
      DAE.Exp varExp;
    case({},_,_,_,_,_)
      equation
        //completed
        hs_i_lstTmp = List.delete(hs_i_lstIn,1);
        a_i_lstTmp = List.delete(a_i_lstIn,1);
        hs_i_lstTmp = listReverse(hs_i_lstTmp);
        a_i_lstTmp = listReverse(a_i_lstTmp);
      then
        (hs_i_lstTmp,a_i_lstTmp);
    case(iValue::iLstRest,_,_,_,_,_)
      equation
        // gets the equations for computing the coefficients for the new residual equations
        r_i = listGet(r_i_lstIn,iValue+1);
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients1(List.intRange(numTVars),iValue,r_i,hs_i_lstIn,a_i_lstIn,tornSysIdx);
        //BackendDump.dumpVarList(listGet(a_i_lstTmp,1),"a_"+&intString(iValue)+&"\n");
        //BackendDump.dumpEquationList(listGet(hs_i_lstTmp,1),"hs_"+&intString(iValue)+&"\n");
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients(iLstRest,numTVars,r_i_lstIn,{}::hs_i_lstTmp,{}::a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp,a_i_lstTmp);
    else
      equation
        print("getTornSystemCoefficients failed!\n");
      then
        fail();
  end matchcontinue;
end getTornSystemCoefficients;


protected function getTornSystemCoefficients1 "gets the equations with coefficients for one e_i
author: Waurich TUD 2013-08"
  input list<Integer> resIdxLst;
  input Integer iIdx;
  input list<BackendDAE.Var> resVal_iIn;
  input list<list<BackendDAE.Equation>>hs_i_lstIn;
  input list<list<BackendDAE.Var>> a_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> hs_i_lstOut;
  output list<list<BackendDAE.Var>> a_i_lstOut;
algorithm
  (hs_i_lstOut, a_i_lstOut) := matchcontinue(resIdxLst, iIdx, resVal_iIn, hs_i_lstIn, a_i_lstIn,tornSysIdx)
    local
      Integer resIdx,resIdx1;
      String aName;
      list<Integer> resIdxRest;
      list<list<BackendDAE.Equation>> hs_i_lstTmp;
      list<list<BackendDAE.Var>> a_i_lstTmp;
      list<BackendDAE.Equation> hs_iTmp;
      list<BackendDAE.Var> a_iTmp, d_lst;
      BackendDAE.Equation hs_ii;
      BackendDAE.Var a_ii, r_ii, dVar;
      DAE.ComponentRef aCRef;
      DAE.Exp aExp, lhs, rhs, dExp;
      DAE.Type ty;
    case({},_,_,_,_,_)
      equation
        //complete
        //hs_i_lstTmp = listReverse(hs_i_lstIn);
        //a_i_lstTmp = listReverse(a_i_lstIn);
      then
        (hs_i_lstIn,a_i_lstIn);
    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = intEq(0,iIdx);
        // build the coefficients (offset d=a_0) of the new residual equations (hs = A*xt+d)
        aName = "$a_"+&intString(tornSysIdx)+&intString(iIdx)+&"_"+&intString(resIdx);
        //aName = "$a_"+&intString(resIdx)+&"_"+&intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        _ = Expression.makeCrefExp(aCRef,ty);
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
        // build the equations to solve for the coefficients
        resIdx1 = listLength(resVal_iIn)+1-resIdx;
        r_ii = listGet(resVal_iIn,resIdx1);
        lhs = varExp(r_ii);
        rhs = varExp(a_ii);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        // update th a_i_lst and the hs_i_lst
        a_i_lstTmp = Debug.bcallret1(List.isEmpty(a_i_lstIn), List.create, {a_ii},varInFrontList(a_ii,a_i_lstIn));
        hs_i_lstTmp = Debug.bcallret1(List.isEmpty(hs_i_lstIn), List.create, {hs_ii}, eqInFrontList(hs_ii,hs_i_lstIn));
        //next residual equation
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients1(resIdxRest,iIdx,resVal_iIn,hs_i_lstTmp,a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp, a_i_lstTmp);
    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = iIdx > 0;
        // build the co-efficients (A-matrix-entries) of the new residual equations (hs = A*xt+d)
        //aName = "$a_"+&intString(iIdx)+&"_"+&intString(resIdx);
        aName = "$a_"+&intString(tornSysIdx)+&intString(resIdx)+&"_"+&intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        aExp = Expression.makeCrefExp(aCRef,ty);
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
        // build the equations to solve for the coefficients
        resIdx1 = listLength(resVal_iIn)+1-resIdx;
        d_lst = List.last(a_i_lstIn);
        dVar = listGet(d_lst, resIdx1);
        dExp = varExp(dVar);
        aExp = varExp(a_ii);
        rhs = DAE.BINARY(aExp,DAE.ADD(ty),dExp);
        r_ii = listGet(resVal_iIn,resIdx1);
        lhs = varExp(r_ii);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        // update th a_i_lst and the hs_i_lst
        a_i_lstTmp = Debug.bcallret1(List.isEmpty(a_i_lstIn), List.create, {a_ii},varInFrontList(a_ii, a_i_lstIn));
        hs_i_lstTmp = Debug.bcallret1(List.isEmpty(hs_i_lstIn), List.create, {hs_ii}, eqInFrontList(hs_ii, hs_i_lstIn));
        // next residual equation
        (hs_i_lstTmp, a_i_lstTmp) = getTornSystemCoefficients1(resIdxRest, iIdx, resVal_iIn, hs_i_lstTmp, a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp, a_i_lstTmp);
    else
      equation
        print("getTornSystemCoefficients1 failed\n");
      then
        fail();
  end matchcontinue;
end getTornSystemCoefficients1;


protected function varExp "gets an DAE.Exp for the CREF of the given BackendDAE.Var
author: Waurich TUD 2013-08"
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


protected function replaceVarsInResidualEquations "replaces the otherVars with xa_i and the tvars with e_i
author: Waurich TUD 2013-08"
  input list<Integer> iValueRange;
  input list<list<BackendDAE.Equation>> resEqsIn;
  input list<BackendVarTransform.VariableReplacements> inReplLst;
  input list<list<BackendDAE.Equation>> h_i_lstIn;
  output list<list<BackendDAE.Equation>> h_i_lstOut;
algorithm
  h_i_lstOut := matchcontinue(iValueRange,resEqsIn,inReplLst,h_i_lstIn)
    local
      Integer iValue;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> h_i_Eqs;
      BackendVarTransform.VariableReplacements repl;
      list<list<BackendDAE.Equation>> h_i_lstTmp;
    case({},_,_,_)
      //completed
      equation
        h_i_lstTmp = listReverse(h_i_lstIn);
      then
        h_i_lstTmp;
    case(iValue::iLstRest,_,_,_)
      equation
        iValue = iValue+1;
        repl = listGet(inReplLst,iValue);
        h_i_Eqs = listGet(resEqsIn,iValue);
        (h_i_Eqs,_) = BackendVarTransform.replaceEquations(h_i_Eqs,repl,NONE());
        h_i_lstTmp = replaceVarsInResidualEquations(iLstRest,resEqsIn,inReplLst,h_i_Eqs::h_i_lstIn);
      then
       h_i_lstTmp;
    else
      equation
        print("replaceVarsInResidualEquations failed \n");
      then
        fail();
  end matchcontinue;
end replaceVarsInResidualEquations;


protected function addResidualVarToEquation "adds a variable r_x to  the right hand side of an equation. this corresponds to the residual value in a residual equation
author: Waurich TUD 2013-08"
  input list<Integer> iIn;
  input list<BackendDAE.Equation> resEqLstIn;
  input list<list<BackendDAE.Equation>> h_i_lstIn;
  input list<list<BackendDAE.Var>> r_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> h_i_lstOut;
  output list<list<BackendDAE.Var>> r_i_lstOut;
algorithm
  (h_i_lstOut,r_i_lstOut) := matchcontinue(iIn,resEqLstIn,h_i_lstIn,r_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String resVarName;
      list<Integer> eqIdxRange;
      list<Integer> iLstRest;
      list<list<BackendDAE.Equation>> h_i_lstTmp;
      list<list<BackendDAE.Var>> r_i_lstTmp;
      BackendDAE.Equation resEq;
      DAE.Exp exp1;
      DAE.Exp exp2;
      DAE.Exp scalarExp;
    case({},_,_,_,_)
      // completed
      equation
        h_i_lstTmp = List.delete(h_i_lstIn, 1);
        r_i_lstTmp = List.delete(r_i_lstIn, 1);
        h_i_lstTmp = listReverse(h_i_lstTmp);
        r_i_lstTmp = listReverse(r_i_lstTmp);
      then
        (h_i_lstTmp,r_i_lstTmp);
    case(iValue::iLstRest,_,_,_,_)
      // traverse the residualEquations
      equation
        eqIdxRange = List.intRange(listLength(resEqLstIn));
        resVarName = "r_"+&intString(tornSysIdx)+&intString(iValue);
        ((h_i_lstTmp,r_i_lstTmp)) = List.fold2(eqIdxRange,addResidualVarToEquation1,resEqLstIn,resVarName,(h_i_lstIn, r_i_lstIn));
        //BackendDump.dumpVarList(listGet(r_i_lstTmp,1),"r_"+&intString(iValue)+&"\n");
        //BackendDump.dumpEquationList(listGet(h_i_lstTmp,1),"h_"+&intString(iValue)+&"\n");
        (h_i_lstTmp,r_i_lstTmp) = addResidualVarToEquation(iLstRest,resEqLstIn,{}::h_i_lstTmp,{}::r_i_lstTmp,tornSysIdx);
      then
        (h_i_lstTmp,r_i_lstTmp);
    else
      equation
        print("addResidualVarToEquation failed! \n");
      then
        fail();
  end matchcontinue;
end addResidualVarToEquation;


protected function addResidualVarToEquation1 "function to parse the expressions of one residualEquation. creates the residuumVars and updates the residual Expressions with them
author:Waurich TUD 2013-08 "
  input Integer eqIdx;
  input list<BackendDAE.Equation> resEqLstIn;
  input String resVarName;
  input tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>> tplIn;
  output tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>> tplOut;
protected
  String resName;
  list<BackendDAE.Equation> resEqLst;
  list<BackendDAE.Var> resVarLst;
  list<list<BackendDAE.Equation>> h_i_lst;
  list<list<BackendDAE.Var>> r_i_lst;
  BackendDAE.Equation resEq;
  BackendDAE.Var resVal;
  DAE.ComponentRef resCRef;
  DAE.Exp resExp;
  DAE.Type ty;
algorithm
  (h_i_lst,r_i_lst):= tplIn;
  // add the variable for the residuumValue
  resEq := listGet(resEqLstIn,eqIdx);
  resName := "$"+&resVarName +&"_"+& intString(eqIdx);
  ty := DAE.T_REAL_DEFAULT;
  resCRef := ComponentReference.makeCrefIdent(resName,ty,{});
  resExp := Expression.makeCrefExp(resCRef,ty);
  resVal := BackendDAE.VAR(resCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
  resEq := addResidualVarToEquation2(resEq,resExp);
  
  // update the resEq and resVar lists
  r_i_lst := Debug.bcallret1(List.isEmpty(r_i_lst), List.create, {resVal},varInFrontList(resVal,r_i_lst));
  h_i_lst := Debug.bcallret1(List.isEmpty(h_i_lst), List.create, {resEq}, eqInFrontList(resEq,h_i_lst));
  tplOut := (h_i_lst,r_i_lst);
end addResidualVarToEquation1;


protected function varInFrontList  " puts the varIn at the front of the first list of lists
author: Waurich TUD 2013-08"
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
        varLst = List.first(lstLstIn);
        varLst = varIn::varLst;
        lstLstOut = List.replaceAt(varLst,0,lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end varInFrontList;


protected function eqInFrontList  " puts the eqIn at the front of the first list of lists
author: Waurich TUD 2013-08"
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
        eqLst = List.first(lstLstIn);
        eqLst = eqIn::eqLst;
        lstLstOut = List.replaceAt(eqLst,0,lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end eqInFrontList;


protected function addResidualVarToEquation2 " adds the residual variable to the equation
author: waurich TUD 2013-08"
  input BackendDAE.Equation eqIn;
  input DAE.Exp addExp;
  output BackendDAE.Equation eqOut;
algorithm
  eqOut := match (eqIn,addExp)
    local
      DAE.Exp exp1,exp2;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
    case(BackendDAE.EQUATION(exp=exp1,scalar=exp2,source=source,attr=attr),_)
      equation
        //print("rhs expression: "+&ExpressionDump.dumpExpStr(exp1,0)+&"\n");
        //print("\n append with \n");
        //print("residualValue: "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
        exp1 = Expression.expAdd(exp1,addExp);
      then BackendDAE.EQUATION(exp1,exp2,source,attr);
    else
      equation
        print("addResidualVarToEquation2 failed!\n");
      then fail();
  end match;
end addResidualVarToEquation2;


protected function getAlgebraicEquationsForEI "computes from otherEqs the equations to solve for xa_i by:
-replacing (i+1)-times in all otherEqs the tvars with i=0: all tvars=0, i=1: all tvars=0 but tvar{1}=1, i=2: all tvars=0 but tvar{2}=1  etc.
- replacing (i+1)-times in all otherEqs the otherVars(algebraic vars) with $Xai.cref in order to solve for them
author: Waurich TUD 2013-08"
  input list<Integer> iIn;
  input Integer size;
  input list<BackendDAE.Equation> otherEqLstIn;
  input list<BackendDAE.Var> tvarLstIn;
  input list<DAE.ComponentRef> tVarCRefLstIn;
  input list<BackendDAE.Var> otherVarLstIn;
  input list<DAE.ComponentRef> oVarCRefLstIn;
  input list<BackendVarTransform.VariableReplacements> replacementLstIn;
  input list<list<BackendDAE.Equation>> g_i_lstIn;
  input list<list<BackendDAE.Var>> xa_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> g_i_lstOut;
  output list<list<BackendDAE.Var>> xa_i_lstOut;
  output list<BackendVarTransform.VariableReplacements> replacementLstOut;
algorithm
  (g_i_lstOut,xa_i_lstOut,replacementLstOut) := matchcontinue(iIn,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn,replacementLstIn,g_i_lstIn,xa_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String str1,str2;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> gEqLstTmp;
      list<BackendDAE.Var> xaVarLstTmp;
      list<BackendVarTransform.VariableReplacements> replLstTmp;
      list<DAE.ComponentRef> tVarCRefLst1;
      list<list<BackendDAE.Equation>> g_i_lstTmp;
      list<list<BackendDAE.Var>> xa_i_lstTmp;
      BackendDAE.Var tvar;
      BackendVarTransform.VariableReplacements replTmp;
      DAE.ComponentRef tVarCRef;
  case({},_,_,_,_,_,_,_,_,_,_)
    // completed
    equation
      g_i_lstOut = listReverse(g_i_lstIn);
      xa_i_lstOut = listReverse(xa_i_lstIn);
      replacementLstOut = listReverse(replacementLstIn);
    then
      (g_i_lstOut,xa_i_lstOut,replacementLstOut);

  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // get xa_o from g_0
    equation
      true = iValue == 0;
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = List.fold1(tVarCRefLstIn,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,"$xa0"+&intString(tornSysIdx),oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn, replTmp::replacementLstIn, gEqLstTmp::g_i_lstIn,xaVarLstTmp::xa_i_lstIn, tornSysIdx);
    then
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp);

  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // computes xa_i from g_i
    equation
      true = iValue > 0;
      str1 = "$xa"+&intString(tornSysIdx)+&intString(iValue);
      _ = "$g"+&intString(tornSysIdx)+&intString(iValue);
      tVarCRef = listGet(tVarCRefLstIn,iValue);
      tVarCRefLst1 = List.delete(tVarCRefLstIn,iValue);
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = replaceTVarWithReal(tVarCRef,1.0,replTmp);
      replTmp = List.fold1(tVarCRefLst1,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,str1,oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
      //BackendVarTransform.dumpReplacements(replTmp);
      //BackendDump.dumpVarList(xaVarLstTmp,str1);
      //BackendDump.dumpEquationList(gEqLstTmp,str2);
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn, replTmp::replacementLstIn, gEqLstTmp::g_i_lstIn,xaVarLstTmp::xa_i_lstIn,tornSysIdx);
    then
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp);

  else
    equation
      print("getAlgebraicEquationsForEI1 failed!\n");
    then
      fail();
  end matchcontinue;
end getAlgebraicEquationsForEI;


protected function replaceTVarWithReal "adds the replacement rule to set the tvar to realIn
author: Waurich TUD 2013-08"
  input DAE.ComponentRef tVarCRefIn;
  input Real realIn;
  input BackendVarTransform.VariableReplacements replacementIn;
  output BackendVarTransform.VariableReplacements replacementOut;
algorithm
  replacementOut := BackendVarTransform.addReplacement(replacementIn,tVarCRefIn,DAE.RCONST(realIn),NONE());
end replaceTVarWithReal;


protected function replaceOtherVarsWithPrefixCref "adds the replacement rule to set the cref to $prefix.cref
author: Waurich TUD 2013-07"
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
  replVar := BackendDAE.VAR(cRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
  replVarLstOut := replVar::replVarLstIn;
  tplOut := (replVarLstOut,replacementOut);
end replaceOtherVarsWithPrefixCref;


protected function dumpVarLstLst "dumps a list<list<BackendDAE.Var>> as a String. TODO: remove when finished
author: Waurich TUD 2013-08"
  input list<list<BackendDAE.Var>> inLstLst;
  input String heading;
protected
  String str;
algorithm
  print("---------\n"+&heading+&"-variables\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpVarLstLst1,inLstLst,heading);
end dumpVarLstLst;


protected function dumpVarLstLst1 "mapping function for dumpVarLstLst  TODO: remove when finished
author: Waurich TUD 2013-08"
  input Integer lstIdx;
  input list<list<BackendDAE.Var>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Var> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+&"_"+&intString(lstIdx-1);
  BackendDump.dumpVarList(inLst,str1);
  headingOut := heading;
end dumpVarLstLst1;


protected function dumpEqLstLst "dumps a list<list<BackendDAE.Equation>> as a String.  TODO: remove when finished
author: Waurich TUD 2013-08"
  input list<list<BackendDAE.Equation>> inLstLst;
  input String heading;
protected
  String str;
algorithm
  print("---------\n"+&heading+&"-equations\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpEqLstLst1,inLstLst,heading);
end dumpEqLstLst;


protected function dumpEqLstLst1 "mapping function for dumpEqLstLst  TODO: remove when finished
author: Waurich TUD 2013-08"
  input Integer lstIdx;
  input list<list<BackendDAE.Equation>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Equation> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+&"_"+&intString(lstIdx-1);
  BackendDump.dumpEquationList(inLst,str1);
  headingOut := heading;
end dumpEqLstLst1;


protected function printPartLinTornInfo "prints information about the partitioning of a linear torn system
author: Waurich TUD 2013-10"
  input list<DAE.ComponentRef> tcrs;
  input list<BackendDAE.Equation> reqns;
  input list<BackendDAE.Equation> otherEqnsLst;
  input list<DAE.ComponentRef> ovcrs;
  input list<list<BackendDAE.Var>> xa_i_lst;
  input list<list<BackendDAE.Equation>> g_i_lst;
  input list<list<BackendDAE.Var>> r_i_lst;
  input list<list<BackendDAE.Equation>> h_i_lst;
  input list<list<BackendDAE.Var>> a_i_lst;
  input list<list<BackendDAE.Equation>> hs_i_lst;
  input list<BackendDAE.Equation> hs;
  input BackendDAE.StrongComponents compsNew;
algorithm
   print("disassemble a linear torn system\n");
   print("tvars:\n");
   print(ComponentReference.printComponentRefListStr(tcrs)+&"\n");
   print("resEqs:\n");
   BackendDump.printEquationList(reqns);
   print("otherEqs:\n");
   BackendDump.printEquationList(otherEqnsLst);
   print("other vars:\n");
   print(ComponentReference.printComponentRefListStr(ovcrs)+&"\n");
   dumpVarLstLst(xa_i_lst,"xa");
   dumpEqLstLst(g_i_lst,"g");
   dumpVarLstLst(r_i_lst,"r");
   dumpEqLstLst(h_i_lst,"h");
   dumpVarLstLst(a_i_lst,"a");
   dumpEqLstLst(hs_i_lst,"hs_i");
   BackendDump.dumpEquationList(hs,"hs");
   print("components to get the A-matrix\n");
   BackendDump.dumpComponents(compsNew);
   print("\n");
end printPartLinTornInfo;


//--------------------------------------------------//
// functions to simplify the generated equations
//-------------------------------------------------//

protected function simplifyEquations "removes simpleEquations like a=0 and replaces variables from equations like a=b, without holding them in the knownvars or aliasvars
author: Waurich TUD 2013-10"
  input list<list<BackendDAE.Equation>> eqLstLstIn;
  input list<list<BackendDAE.Var>> varLstLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<list<BackendDAE.Equation>> eqLstLstOut;
  output list<list<BackendDAE.Var>> varLstLstOut;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  ((eqLstLstOut,varLstLstOut,replOut)) := List.fold(List.intRange(listLength(eqLstLstIn)),simplifyEquations1,(eqLstLstIn,varLstLstIn,replIn));
  //(eqLstLstOut,varLstLstOut,replOut) := (eqLstLstIn,varLstLstIn,replIn);
end simplifyEquations;


protected function simplifyEquations1 "implementation for simplifyEquations. traverses a list of the list<list<equation>>"
  input Integer idx;
  input tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>,BackendVarTransform.VariableReplacements> tplOut;
protected
  BackendVarTransform.VariableReplacements repl;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<list<BackendDAE.Equation>> eqLstLst;
  list<list<BackendDAE.Var>> varLstLst;
algorithm
  (eqLstLst,varLstLst,repl) := tplIn;
  eqLst := listGet(eqLstLst,idx);
  varLst := listGet(varLstLst,idx);
  // remove all vars that are assigned to a constant or alias, remove the equations, update the replacement rule
  ((eqLst,varLst,repl)) := simplifyEquations2((eqLst,varLst,repl));
  eqLstLst := List.replaceAt(eqLst,idx-1,eqLstLst);
  varLstLst := List.replaceAt(varLst,idx-1,varLstLst);
  tplOut := ((eqLstLst,varLstLst,repl));
end simplifyEquations1;


protected function simplifyEquations2 "repeats the simplification until nothing changed anymore"
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean changed;
      BackendVarTransform.VariableReplacements repl, replIn;
      list<BackendDAE.Equation> eqLst, eqLstIn;
      list<BackendDAE.Var> varLst, varLstIn;
    case((eqLstIn,varLstIn,replIn))
      equation
        ((varLst,eqLst,repl,changed)) = removeConstOrAlias(1,(varLstIn,eqLstIn,replIn,false));
        true = changed;
        (eqLst,_) = BackendVarTransform.replaceEquations(eqLst,repl,NONE());
        ((eqLst,varLst,repl)) = simplifyEquations2((eqLst,varLst,repl));
      then
        ((eqLst,varLst,repl));
    case((eqLstIn,varLstIn,replIn))
      equation
        ((varLst,eqLst,repl,changed)) = removeConstOrAlias(1,(varLstIn,eqLstIn,replIn,false));
        false = changed;
        (eqLst,_) = BackendVarTransform.replaceEquations(eqLst,repl,NONE());
      then
        ((eqLst,varLst,repl));
    else
      equation
        print("simplifyEquations2 failed!\n");
      then
        fail();
  end matchcontinue;
end simplifyEquations2;


protected function removeConstOrAlias "removes the equations and vars for which vars are assigned to constants or alias and replaces them.
author: Waurich TUD 2013-10"
  input Integer eqIdx;
  input tuple<list<BackendDAE.Var>, list<BackendDAE.Equation>, BackendVarTransform.VariableReplacements,Boolean> tplIn;
  output tuple<list<BackendDAE.Var>, list<BackendDAE.Equation>, BackendVarTransform.VariableReplacements,Boolean> tplOut;
algorithm
  tplOut := matchcontinue(eqIdx,tplIn)
    local
      Boolean b, changed, changed1;
      Integer eqIdxTmp;
      BackendDAE.Equation eq;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl,replIn;
      DAE.ComponentRef varCref;
      DAE.Exp varExp, const, exp1, exp2;
      list<BackendDAE.Equation>  eqLst, eqLstIn;
      list<BackendDAE.Var> varLst, varLstIn;
  case(_,(_,eqLstIn,_,_))
    equation
      true = listLength(eqLstIn) < eqIdx;
    then
      tplIn;
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      //one side of the equation is constant
      eq = listGet(eqLstIn,eqIdx);
      (b,SOME((varExp,const))) = oneSideConstant(eq);
      true = b;
      //print("\neq with const: "+&BackendDump.dumpEqnsStr({eq})+&"\n");
      //print("one side is constant\n");
      (eqLst,varLst,repl,changed1) = handleConstantSide(varExp,const,eqIdx,eqLstIn,varLstIn,replIn,changed);
      eqIdxTmp = Util.if_(changed1, eqIdx, eqIdx+1);
      changed = changed1 or changed;
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdxTmp,(varLst,eqLst,repl,changed));
    then
      ((varLst,eqLst,repl,changed));
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      //both sides of the equation are crefs
      eq = listGet(eqLstIn,eqIdx);
      BackendDAE.EQUATION(exp= exp1, scalar=exp2) = eq;
      true = Expression.isCref(exp1);
      true = Expression.isCref(exp2);
      //print("\neq with both sides CREFs: "+&BackendDump.dumpEqnsStr({eq})+&"\n");
      (eqLst,varLst,repl,changed1) = checkForPosAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      eqIdxTmp = Util.if_(changed1, eqIdx, eqIdx+1);
      changed = changed1 or changed;
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdxTmp,(varLst,eqLst,repl,changed));
    then
      ((varLst,eqLst,repl,changed));
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      // nothing to simplify. go to next equation
      //print("nothing to simplify\n");
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdx+1,(varLstIn,eqLstIn,replIn,changed));
    then
      ((varLst,eqLst,repl,changed));
    else
      equation
        print("removeConstOrAlias failed!\n");
      then
        fail();
  end matchcontinue;
end removeConstOrAlias;


protected function handleConstantSide "checks if the equation is a constant assignment i.e. a=const, const=a or a simple equation i.e. a+b=0
author: Waurich TUD 2013-10"
  input DAE.Exp varExp;
  input DAE.Exp constExp;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  input Boolean changedIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changedOut;
algorithm
  (eqLstOut,varLstOut,replOut,changedOut) := matchcontinue(varExp,constExp,eqIdx,eqLstIn,varLstIn,replIn,changedIn)
    local
      Boolean changed;
      Real real;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.Exp exp1,exp2;
      DAE.Operator op;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref),DAE.RCONST(real=_),_,_,_,_,_)
      equation
        // check for simple equations: a = const.
        vars = BackendVariable.listVar(varLstIn);
        vars = BackendVariable.removeCref(cref,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        repl = BackendVarTransform.addReplacement(replIn,cref,constExp,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.BINARY(exp1=exp1,operator=op,exp2=exp2),DAE.RCONST(real=real),_,_,_,_,_)
      equation
        // check for alias vars: a+-b = 0.0
        true = real ==. 0.0;
        (eqLst,varLst,repl,changed) = checkForAlias(exp1,exp2,op,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end handleConstantSide;


protected function checkForAlias "checks if the there are alias variables for the new vars from varLstIn.
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.Operator op;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changedOut;
algorithm
  (eqLstOut,varLstOut,replOut,changedOut) := match(exp1,exp2,op,eqIdx,eqLstIn,varLstIn,replIn)
    local
      Boolean changed;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
      DAE.Exp newExp, unaryExp;
    case(_,_,DAE.ADD(_),_,_,_,_)
      equation
        true = Expression.isCref(exp1);
        true = Expression.isCref(exp2);
        // a + otherVar = 0  replace: a--> -otherVar   or   a + b = 0 replace: a --> -b
        (eqLst,varLst,repl,changed) = checkForNegAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    case(_,_,DAE.SUB(_),_,_,_,_)
      equation
        true = Expression.isCref(exp1);
        true = Expression.isCref(exp2);
        // a - otherVar = 0  replace: a--> otherVar   or   a - b = 0 replace: a --> b
        (eqLst,varLst,repl,changed) = checkForPosAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    case((DAE.CREF(componentRef = cref1)),_,DAE.DIV(_),_,_,_,_)
      equation
        // a/otherVar = 0  replace: a --> 0
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        newExp = DAE.RCONST(0.0);
        repl = BackendVarTransform.addReplacement(replIn,cref1,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    case((DAE.UNARY(operator=_,exp=unaryExp)),_,DAE.DIV(_),_,_,_,_)
      equation
        true = Expression.isCref(unaryExp);
        DAE.CREF(componentRef = cref1) = unaryExp;
        // a/otherVar = 0  replace: a --> 0
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        newExp = DAE.RCONST(0.0);
        repl = BackendVarTransform.addReplacement(replIn,cref1,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end match;
end checkForAlias;


protected function checkForNegAlias "checks if there are variables that can be replaced from a+otherVar = 0  to  a --> -otherVar. a has to be in the varLstIn
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changed;
algorithm
  (eqLstOut,varLstOut,replOut,changed) := matchcontinue(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      DAE.Exp newExp;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = _),_,_,_,_)
      equation
        // a + otherVar = 0  replace: a --> -otherVar   or   a + b = 0 replace: a --> -b
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        newExp = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp2);
        //print("checkForNegAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with "+&ExpressionDump.printExpStr(newExp)+&"\n");
        repl = BackendVarTransform.addReplacement(replIn,cref1,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.CREF(componentRef = _),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // otherVar + a = 0  replace: a --> -otherVar
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref2,vars,false);
        vars = BackendVariable.removeCref(cref2,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        newExp = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp1);
        //print("checkForNegAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with - "+&ExpressionDump.printExpStr(newExp)+&"\n");
        repl = BackendVarTransform.addReplacement(replIn,cref2,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end checkForNegAlias;


protected function checkForPosAlias"checks if there are variables that can be replaced from a-otherVar = 0  to  a --> otherVar. a has to be in the varLstIn
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changed;
algorithm
  (eqLstOut,varLstOut,replOut,changed) := matchcontinue(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = _),_,_,_,_)
      equation
        // a - otherVar = 0  replace: a --> otherVar   or   a - b = 0 replace: a --> b
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        //print("checkForPosAlias: replace "+&ComponentReference.printComponentRefStr(cref1)+&" with "+&ExpressionDump.printExpStr(exp2)+&"\n");
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        repl = BackendVarTransform.addReplacement(replIn,cref1,exp2,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.CREF(componentRef = _),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // otherVar - a = 0  replace: a --> otherVar
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref2,vars,false);
        //print("checkForPosAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with "+&ExpressionDump.printExpStr(exp1)+&"\n");
        vars = BackendVariable.removeCref(cref2,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = List.delete(eqLstIn, eqIdx);
        repl = BackendVarTransform.addReplacement(replIn,cref2,exp1,NONE());
      then
        (eqLst,varLst,repl,true);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end checkForPosAlias;


protected function oneSideConstant "checks whether the given equation has one side with a constant.
author: Waurich TUD 2013-07"
  input BackendDAE.Equation eqIn;
  output Boolean hasConst;
  output Option<tuple<DAE.Exp,DAE.Exp>> varExp;  //<non-constant side, constant side>
algorithm
  (hasConst,varExp) := matchcontinue(eqIn)
    local
      DAE.Exp lhs,rhs;
    case(BackendDAE.EQUATION(exp = rhs, scalar = lhs))
      equation
        true = Expression.isConst(lhs);
      then
        (true,SOME((rhs,lhs)));
    case(BackendDAE.EQUATION(exp = rhs, scalar = lhs))
      equation
        true = Expression.isConst(rhs);
      then
        (true,SOME((lhs,rhs)));
    else
      equation
      then
        (false,NONE());
  end matchcontinue;
end oneSideConstant;

//--------------------------------------------------//
// functions to dump the equation system as .graphml
//-------------------------------------------------//

public function dumpEquationSystemBipartiteGraph"dumps a bipartite graph of the torn systems as graphml.
waurich: TUD 2014-09"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EqSystem eqSys;
  input String name;
protected
  BackendDAE.EquationArray eqs;
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst;
  list<BackendDAE.Equation> eqLst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs) := eqSys;
  varLst := BackendVariable.varList(vars);
  eqLst := BackendEquation.equationList(eqs);
  dumpEquationSystemBipartiteGraph1(inComp,eqLst,varLst,name);
end dumpEquationSystemBipartiteGraph;

public function dumpEquationSystemBipartiteGraph1
  input BackendDAE.StrongComponent inComp;
  input list<BackendDAE.Equation> eqsIn;
  input list<BackendDAE.Var> varsIn;
  input String graphName;
algorithm
  () := matchcontinue(inComp,eqsIn,varsIn,graphName)
    local
      Integer numEqs, numVars, compIdx;
      list<Boolean> tornInfo;
      list<String> addInfo;
      list<Integer> eqIdcs,varIdcs,tVarIdcs,rEqIdcs, tVarIdcsNew, rEqIdcsNew;
      list<tuple<Integer,list<Integer>>> otherEqnVarTplIdcs;
      list<tuple<Boolean,String>> varAtts,eqAtts;
      BackendDAE.EquationArray compEqs;
      BackendDAE.Variables compVars;
      BackendDAE.StrongComponent comp;
      BackendDAE.IncidenceMatrix m,mT;
      list<BackendDAE.Equation> compEqLst;
      list<BackendDAE.Var> compVarLst;
  case((comp as BackendDAE.EQUATIONSYSTEM(eqns=eqIdcs,vars=varIdcs)),_,_,_)
    equation
      compEqLst = List.map1(eqIdcs,List.getIndexFirst,eqsIn);
      compVarLst = List.map1(varIdcs,List.getIndexFirst,varsIn);
      compVars = BackendVariable.listVar1(compVarLst);
      compEqs = BackendEquation.listEquation(compEqLst);

      numEqs = listLength(compEqLst);
      numVars = listLength(compVarLst);
      m = arrayCreate(numEqs, {});
      mT = arrayCreate(numVars, {});
      (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(compVars,compEqs,{},mT, 0, numEqs, intLt(0, numEqs), BackendDAE.ABSOLUTE(), NONE());

      varAtts = List.threadMap(List.fill(false,numVars),List.fill("",numVars),Util.makeTuple);
      eqAtts = List.threadMap(List.fill(false,numEqs),List.fill("",numEqs),Util.makeTuple);
      dumpEquationSystemBipartiteGraph2(compVars,compEqs,m,varAtts,eqAtts,"rL_eqSys_"+&graphName);
    then ();
  case((comp as BackendDAE.TORNSYSTEM(residualequations=rEqIdcs,tearingvars=tVarIdcs,otherEqnVarTpl=otherEqnVarTplIdcs)),_,_,_)
    equation
      //gather equations ans variables
      eqIdcs = List.map(otherEqnVarTplIdcs,Util.tuple21);
      eqIdcs = listAppend(eqIdcs, rEqIdcs);
      varIdcs = List.flatten(List.map(otherEqnVarTplIdcs,Util.tuple22));
      varIdcs = listAppend(varIdcs, tVarIdcs);
      compEqLst = List.map1(eqIdcs,List.getIndexFirst,eqsIn);
      compVarLst = List.map1(varIdcs,List.getIndexFirst,varsIn);
      compVars = BackendVariable.listVar1(compVarLst);
      compEqs = BackendEquation.listEquation(compEqLst);

      // get incidence matrix
      numEqs = listLength(compEqLst);
      numVars = listLength(compVarLst);
      m = arrayCreate(numEqs, {});
      mT = arrayCreate(numVars, {});
      (m,_) = BackendDAEUtil.incidenceMatrixDispatch(compVars,compEqs,{},mT, 0, numEqs, intLt(0, numEqs), BackendDAE.ABSOLUTE(), NONE());

      // add tearing info to graph object and dump graph
      addInfo = List.map(varIdcs,intString);// the DAE idcs for the vars
      tornInfo = List.fill(true,numVars);
      tVarIdcsNew = List.intRange(numVars-listLength(tVarIdcs));
      tornInfo = List.fold1(tVarIdcsNew,List.replaceAtIndexFirst,false,tornInfo);//is it a tearing var or not
      varAtts = List.threadMap(tornInfo,addInfo,Util.makeTuple);
      addInfo = List.map(eqIdcs,intString);// the DAE idcs for the eqs
      tornInfo = List.fill(true,numEqs);
      rEqIdcsNew = List.intRange(numEqs-listLength(rEqIdcs));
      tornInfo = List.fold1(rEqIdcsNew,List.replaceAtIndexFirst,false,tornInfo);//is it a residual eq or not
      eqAtts = List.threadMap(tornInfo,addInfo,Util.makeTuple);
      dumpEquationSystemBipartiteGraph2(compVars,compEqs,m,varAtts,eqAtts,graphName);
    then ();
  else
    equation
      print("dumpTornSystemBipartiteGraphML1 failed!\n");
    then ();
  end matchcontinue;
end dumpEquationSystemBipartiteGraph1;

public function dumpEquationSystemBipartiteGraph2
  input BackendDAE.Variables varsIn;
  input BackendDAE.EquationArray eqsIn;
  input BackendDAE.IncidenceMatrix mIn;
  input list<tuple<Boolean,String>> varAtts;  //<isTornVar,daeIdx>
  input list<tuple<Boolean,String>> eqAtts;  //<isResEq,daeIdx>
  input String name;
protected
  Integer nameAttIdx,typeAttIdx,idxAttIdx, numVars,numEqs;
  list<Integer> varRange,eqRange;
  BackendDAE.IncidenceMatrix m;
  GraphML.GraphInfo graphInfo;
  Integer graphIdx;
algorithm
  numEqs := BackendDAEUtil.equationArraySize(eqsIn);
  numVars := BackendVariable.varsSize(varsIn);
  varRange := List.intRange(numVars);
  eqRange := List.intRange(numEqs);
  graphInfo := GraphML.createGraphInfo();
  (graphInfo,(_,graphIdx)) := GraphML.addGraph("EqSystemGraph", true, graphInfo);
  (graphInfo,(_,typeAttIdx)) := GraphML.addAttribute("", "type", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,nameAttIdx)) := GraphML.addAttribute("", "name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,idxAttIdx)) := GraphML.addAttribute("", "systIdx", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  ((graphInfo,graphIdx)) := List.fold3(eqRange,addEqNodeToGraph,eqsIn,eqAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  ((graphInfo,graphIdx)) := List.fold3(varRange,addVarNodeToGraph,varsIn,varAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  graphInfo := List.fold1(eqRange,addEdgeToGraph,mIn,graphInfo);
  GraphML.dumpGraph(graphInfo,name+&".graphml");
end dumpEquationSystemBipartiteGraph2;

public function dumpEquationSystemBipartiteGraphSolve2
  input BackendDAE.Variables varsIn;
  input BackendDAE.EquationArray eqsIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input list<tuple<Boolean,String>> varAtts;  //<isTornVar,daeIdx>
  input list<tuple<Boolean,String>> eqAtts;  //<isResEq,daeIdx>
  input String name;
protected
  Integer nameAttIdx,typeAttIdx,idxAttIdx, numVars,numEqs;
  list<Integer> varRange,eqRange;
  GraphML.GraphInfo graphInfo;
  Integer graphIdx;
algorithm
  numEqs := BackendDAEUtil.equationArraySize(eqsIn);
  numVars := BackendVariable.varsSize(varsIn);
  varRange := List.intRange(numVars);
  eqRange := List.intRange(numEqs);
  graphInfo := GraphML.createGraphInfo();
  (graphInfo,(_,graphIdx)) := GraphML.addGraph("EqSystemGraph", true, graphInfo);
  (graphInfo,(_,typeAttIdx)) := GraphML.addAttribute("", "type", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,nameAttIdx)) := GraphML.addAttribute("", "name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,idxAttIdx)) := GraphML.addAttribute("", "systIdx", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  ((graphInfo,graphIdx)) := List.fold3(eqRange,addEqNodeToGraph,eqsIn,eqAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  ((graphInfo,graphIdx)) := List.fold3(varRange,addVarNodeToGraph,varsIn,varAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  graphInfo := List.fold1(eqRange,addSolvEdgeToGraph,meIn,graphInfo);
  GraphML.dumpGraph(graphInfo,name+&".graphml");
end dumpEquationSystemBipartiteGraphSolve2;

protected function addVarNodeToGraph "adds a node for a variable to the graph.
author:Waurich TUD 2013-12"
  input Integer indx;
  input BackendDAE.Variables vars;
  input list<tuple<Boolean,String>> attsIn; //<isTearingVar,"index in the dae">
  input list<Integer> attributeIdcs;//<name,type,daeidx>
  input tuple<GraphML.GraphInfo,Integer> graphInfoIn;
  output tuple<GraphML.GraphInfo,Integer> graphInfoOut;
protected
  BackendDAE.Var var;
  Boolean isTearVar;
  Integer nameAttrIdx,typeAttIdx,idxAttrIdx, graphIdx;
  String varString, varNodeId, idxString, typeStr, daeIdxStr;
  list<String> varChars;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel nodeLabel;
algorithm
  (graphInfo,graphIdx) := graphInfoIn;
  nameAttrIdx := listGet(attributeIdcs,1);
  typeAttIdx := listGet(attributeIdcs,2); // if its a tearingvar or not
  idxAttrIdx:= listGet(attributeIdcs,3);
  isTearVar := Util.tuple21(listGet(attsIn,indx));
  daeIdxStr := Util.tuple22(listGet(attsIn,indx));
  typeStr := Util.if_(isTearVar,"tearingVar","otherVar");
  var := BackendVariable.getVarAt(vars,indx);
  varString := BackendDump.varString(var);
  varNodeId := getVarNodeIdx(indx);
  idxString := intString(indx);
  nodeLabel := GraphML.NODELABEL_INTERNAL(idxString,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode(varNodeId, GraphML.COLOR_ORANGE2, {nodeLabel},GraphML.ELLIPSE(),SOME(varString),{(nameAttrIdx,varString),(typeAttIdx,typeStr),(idxAttrIdx,daeIdxStr)},graphIdx,graphInfo);
  graphInfoOut := (graphInfo,graphIdx);
end addVarNodeToGraph;

protected function addEqNodeToGraph "adds a node for an equation to the graph.
author:Waurich TUD 2013-12"
  input Integer indx;
  input BackendDAE.EquationArray eqs;
  input list<tuple<Boolean,String>> attsIn; // <isResEq,"daeIdx">
  input list<Integer> attributeIdcs;//<name,type>
  input tuple<GraphML.GraphInfo,Integer> graphInfoIn;
  output tuple<GraphML.GraphInfo,Integer> graphInfoOut;
protected
  BackendDAE.Equation eq;
  Boolean isResEq;
  Integer nameAttrIdx,typeAttrIdx,idxAttrIdx,  graphIdx;
  String eqString, eqNodeId, idxString, typeStr, daeIdxStr;
  list<String> eqChars;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel nodeLabel;
algorithm
  (graphInfo,graphIdx) := graphInfoIn;
  nameAttrIdx := listGet(attributeIdcs,1);
  typeAttrIdx := listGet(attributeIdcs,2); // if its a residual or not
  idxAttrIdx := listGet(attributeIdcs,3);
  isResEq := Util.tuple21(listGet(attsIn,indx));
  daeIdxStr := Util.tuple22(listGet(attsIn,indx));
  typeStr := Util.if_(isResEq,"residualEq","otherEq");
  {eq} := BackendEquation.getEqns({indx}, eqs);
  eqString := BackendDump.equationString(eq);
  eqNodeId := getEqNodeIdx(indx);
  idxString := intString(indx);
  nodeLabel := GraphML.NODELABEL_INTERNAL(idxString,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode(eqNodeId,GraphML.COLOR_GREEN2,{nodeLabel},GraphML.RECTANGLE(),SOME(eqString),{(nameAttrIdx,eqString),(typeAttrIdx,typeStr),(idxAttrIdx,daeIdxStr)},graphIdx,graphInfo);
  graphInfoOut := (graphInfo,graphIdx);
end addEqNodeToGraph;

protected function addEdgeToGraph "adds an edge to the graph by traversing the incidence matrix.
author:Waurich TUD 2013-12"
  input Integer eqIdx;
  input BackendDAE.IncidenceMatrix m;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  list<Integer> varLst;
algorithm
  varLst := arrayGet(m,eqIdx);
  graphInfoOut := List.fold1(varLst,addEdgeToGraph2,eqIdx,graphInfoIn);
end addEdgeToGraph;

protected function addEdgeToGraph2 "helper for addEdgeToGraph.
author:Waurich TUD 2013-12"
  input Integer varIdx;
  input Integer eqIdx;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
    String eqNodeId, varNodeId;
algorithm
  eqNodeId := getEqNodeIdx(eqIdx);
  varNodeId := getVarNodeIdx(varIdx);
  (graphInfoOut,_) := GraphML.addEdge("Edge_"+&intString(varIdx)+&"_"+&intString(eqIdx),varNodeId,eqNodeId,GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,{},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{}, graphInfoIn);
end addEdgeToGraph2;

protected function addSolvEdgeToGraph "adds an edge with solvability information to the graph by traversing the enhanced adjacency matrix.
author:Waurich TUD 2013-12"
  input Integer eqIdx;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced row;
algorithm
  row := arrayGet(me,eqIdx);
  graphInfoOut := List.fold1(row,addSolvEdgeToGraph2,eqIdx,graphInfoIn);
end addSolvEdgeToGraph;

protected function addSolvEdgeToGraph2 "helper for addSolvEdgeToGraph.
author:Waurich TUD 2013-12"
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry var;
  input Integer eqIdx;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
    Boolean solvable;
    String eqNodeId, varNodeId;
    Real lineWidth;
    Integer varIdx;
algorithm
  (varIdx,_) := var;
  solvable := Tearing.unsolvable({var});
  eqNodeId := getEqNodeIdx(eqIdx);
  varNodeId := getVarNodeIdx(varIdx);
  lineWidth := Util.if_(solvable,GraphML.LINEWIDTH_BOLD,GraphML.LINEWIDTH_STANDARD);
  (graphInfoOut,_) := GraphML.addEdge("Edge_"+&intString(varIdx)+&"_"+&intString(eqIdx),varNodeId,eqNodeId,GraphML.COLOR_BLACK,GraphML.LINE(),lineWidth,false,{},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{}, graphInfoIn);
end addSolvEdgeToGraph2;

protected function genSystemVarIdcs
  input list<Integer> idcsIn;
  input Integer idx;
  output list<Integer> idcsOut;
  output Integer idx2;
algorithm
  idx2 := listLength(idcsIn)+idx;
  idcsOut := List.intRange2(idx,idx2-1);
end genSystemVarIdcs;

protected function getVarNodeIdx "outputs the identifier string for the given varIdx.
author:Waurich TUD 2013-12"
  input Integer idx;
  output String varString;
algorithm
  varString := "varNode"+&intString(idx);
end getVarNodeIdx;

protected function getEqNodeIdx "outputs the identifier string for the given eqIdx.
author:Waurich TUD 2013-12"
  input Integer idx;
  output String eqString;
algorithm
  eqString := "eqNode"+&intString(idx);
end getEqNodeIdx;


//--------------------------------------------------//
// solve torn systems in parallel
//-------------------------------------------------//

public function parallelizeTornSystems"analyse torn systems.
author:Waurich TUD 2014-07"
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input array<list<Integer>> sccSimEqMapping;
  input BackendDAE.BackendDAE inDAE;
  output list<HpcOmSimCode.Task> scheduledTasks;
  output list<Integer> daeNodeIdcs;
algorithm
  (scheduledTasks,daeNodeIdcs) := matchcontinue(graphIn,metaIn,sccSimEqMapping,inDAE)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
      list<HpcOmSimCode.Task> taskLst;
      list<Integer> daeNodes;
      array<list<Integer>> inComps;
      array<Integer> nodeMark;
    case (_,_,_,_) equation
      true = false;
      BackendDAE.DAE(eqs=eqSysts, shared=shared) = inDAE;
      (_,taskLst) = pts_traverseEqSystems(eqSysts,sccSimEqMapping,1,{});
      // calculate the node idcs for the dae-task-gaph
      daeNodes = List.map(taskLst,getScheduledTaskCompIdx);
      //HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeMark=nodeMark) = metaIn;
      //odeNodes = List.map3(odeNodes,HpcOmTaskGraph.getCompInComps,1,inComps,nodeMark);
    then (taskLst,daeNodes);
    else
    then ({},{});
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
  input Integer compIdxIn;
  input list<HpcOmSimCode.Task> taskLstIn;
  output Integer compIdxOut;
  output list<HpcOmSimCode.Task> taskLstOut;
algorithm
  (compIdxOut,taskLstOut) := matchcontinue(eqSysIn,sccSimEqMapping,compIdxIn,taskLstIn)
    local
      Integer compIdx;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystems eqSysRest;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponents comps;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
      list<HpcOmSimCode.Task> taskLst;
    case(BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,matching = BackendDAE.MATCHING(comps=comps))::eqSysRest,_,_,_)
      equation
        eqLst = BackendEquation.equationList(eqs);
        varLst = BackendVariable.varList(vars);
        (compIdx,taskLst) = pts_traverseCompsAndParallelize(comps,eqLst,varLst,sccSimEqMapping,compIdxIn,taskLstIn);
        (compIdx,taskLst) = pts_traverseEqSystems(eqSysRest,sccSimEqMapping,compIdx,taskLst);
      then (compIdx,taskLst);
   case({},_,_,_)
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
  input Integer compIdxIn;
  input list<HpcOmSimCode.Task> taskLstIn;
  output Integer compIdxOut;
  output list<HpcOmSimCode.Task> taskLstOut;
algorithm
  (compIdxOut,taskLstOut) := matchcontinue(inComps,eqsIn,varsIn,sccSimEqMapping,compIdxIn,taskLstIn)
    local
      Integer numEqs, numVars, compIdx, numResEqs;
      list<Integer> eqIdcs, varIdcs, tVars, resEqs, eqIdcsSys, simEqSysIdcs,resSimEqSysIdcs,otherSimEqSysIdcs;
      list<list<Integer>> varIdcLstSys, varIdcsLsts;
      list<tuple<Integer,list<Integer>>> otherEqnVarTplIdcs;
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
  case({},_,_,_,_,_)
    equation
    then (compIdxIn,taskLstIn);
  case((comp as BackendDAE.TORNSYSTEM(residualequations=resEqs,tearingvars=tVars,otherEqnVarTpl=otherEqnVarTplIdcs))::rest,_,_,_,_,_)
    equation
      eqIdcs = List.map(otherEqnVarTplIdcs,Util.tuple21);
      varIdcsLsts = List.map(otherEqnVarTplIdcs,Util.tuple22);
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
      m = arrayCreate(numEqs, {});
      mT = arrayCreate(numVars, {});
      (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(otherVars,otherEqs,{},mT, 0, numEqs, intLt(0, numEqs), BackendDAE.ABSOLUTE(), NONE());

      // build task graph and taskgraphmeta
      (graph,meta) = HpcOmTaskGraph.getEmptyTaskGraph(numEqs,numEqs,numVars);
      graph = buildMatchedGraphForTornSystem(1,eqIdcsSys,varIdcLstSys,m,mT,graph);
      meta = buildTaskgraphMetaForTornSystem(graph,otherEqLst,otherVarLst,meta);
        //HpcOmTaskGraph.printTaskGraph(graph);
        //HpcOmTaskGraph.printTaskGraphMeta(meta);

      //get simEqSysIdcs and otherSimEqMapping
      simEqSysIdcs = arrayGet(sccSimEqMapping,compIdxIn);
      resSimEqSysIdcs = List.map1r(List.intRange(numResEqs),intSub,List.first(simEqSysIdcs));
      otherSimEqSysIdcs = List.map1r(List.intRange2(numResEqs+1,numResEqs+numEqs),intSub,List.first(simEqSysIdcs));
      otherSimEqMapping = listArray(List.map(otherSimEqSysIdcs,List.create));
        //print("simEqSysIdcs "+&stringDelimitList(List.map(simEqSysIdcs,intString),",")+&"\n");
        //print("resSimEqSysIdcs "+&stringDelimitList(List.map(resSimEqSysIdcs,intString),",")+&"\n");
        //print("otherSimEqSysIdcs "+&stringDelimitList(List.map(otherSimEqSysIdcs,intString),",")+&"\n");

      // dump graphs
      dumpEquationSystemBipartiteGraph1(comp,eqsIn,varsIn,"tornSys_bipartite_"+&intString(compIdxIn));
      dumpEquationSystemDAG(graph,meta,"tornSys_matched_"+&intString(compIdxIn));

      //GRS
      (graphMerged,metaMerged) = HpcOmSimCodeMain.applyFiltersToGraph(graph,meta,true,{});

      dumpEquationSystemDAG(graphMerged,metaMerged,"tornSys_matched2_"+&intString(compIdxIn));
        //HpcOmTaskGraph.printTaskGraph(graphMerged);
        //HpcOmTaskGraph.printTaskGraphMeta(metaMerged);

      //Schedule
      schedule = HpcOmScheduler.createListSchedule(graphMerged,metaMerged,2,otherSimEqMapping);
      HpcOmScheduler.printSchedule(schedule);

      //transform into scheduled task object
      task = pts_transformScheduleToTask(schedule,resSimEqSysIdcs,compIdxIn);
      //HpcOmScheduler.printTask(task);
      (compIdx,taskLst) = pts_traverseCompsAndParallelize(rest,eqsIn,varsIn,sccSimEqMapping,compIdxIn+1,task::taskLstIn);
    then (compIdx,taskLst);
  case(comp::rest,_,_,_,_,_)
    equation
      (compIdx,taskLst) = pts_traverseCompsAndParallelize(rest,eqsIn,varsIn,sccSimEqMapping,compIdxIn+1,taskLstIn);
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
    case(HpcOmSimCode.LEVELSCHEDULE(tasksOfLevels=levelTasks),_,_)
      equation
        print("levelScheduling is not supported for heterogenious scheduling\n");
      then
        fail();
    case(HpcOmSimCode.THREADSCHEDULE(threadTasks=threadTasks,outgoingDepTasks=outgoingDepTasks,allCalcTasks=allCalcTasks),_,_)
      equation
        //05-09-2014 marcusw: Changed because of dependency-task restructuring for MPI
        numThreads = arrayLength(threadTasks);
        // rename locks, get locks before residual equations
        //lockSuffix = "_"+&intString(compIdx);
        //outgoingDepTasks = List.map1(lockIdc,stringAppend,lockSuffix);
        //outgoingDepTasksEnd = List.map1r(List.map(List.intRange(numThreads),intString),stringAppend,"lock_comp"+&intString(compIdx)+&"_th");
        //outgoingDepTasks = listAppend(outgoingDepTasks,outgoingDepTasksEnd);
        //threadTasks = Util.arrayMap1(threadTasks,appendStringToLockIdcs,lockSuffix);

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

//05-09-2014 marcusw: Changed because of dependency-task restructuring for MPI
//protected function appendStringToLockIdcs"appends the suffix to the lockIds of the given tasks
//author: Waurich TUD 2014-07"
//  input list<HpcOmSimCode.Task> taskLstIn;
//  input String suffix;
//  output list<HpcOmSimCode.Task> taskLstOut;
//algorithm
//  taskLstOut := List.map1(taskLstIn,appendStringToLockIdcs1,suffix);
//end appendStringToLockIdcs;
//
//protected function appendStringToLockIdcs1"appends the suffix to the lockIds of the given tasks
//author: Waurich TUD 2014-07"
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
        depEqs = List.flatten(List.map1(vars,Util.arrayGetIndexFirst,mt));
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

protected function buildTaskgraphMetaForTornSystem"creates a preliminary task graph meta object
author:Waurich TUD 2014-07"
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
  array<String> nodeDescs, nodeNames;
  array<list<Integer>> inComps;
  array<tuple<Integer,Real>> exeCosts;
  array<HpcOmTaskGraph.Communications> commCosts;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(varCompMapping=varCompMapping, eqCompMapping=eqCompMapping, nodeMark=nodeMark) := metaIn;
  numNodes := arrayLength(graph);
  // get the inComps
  inComps := listArray(List.map(List.intRange(numNodes),List.create));
  // get the nodeNames
  nodeNames := listArray(List.map(List.intRange(numNodes),intString));
  //get the exeCost
  exeCosts := arrayCreate(numNodes,(3,20.0));
  //get the commCosts
  commCosts := Util.arrayMap(graph,buildDummyCommCosts);
  //get the node description
  eqStrings := List.map(eqLst,BackendDump.equationString);
  varStrings := List.map(varLst,HpcOmTaskGraph.getVarString);
  descLst := List.map1(eqStrings,stringAppend," FOR ");
  descLst := List.threadMap(descLst,varStrings,stringAppend);
  nodeDescs := listArray(descLst);
  metaOut := HpcOmTaskGraph.TASKGRAPHMETA(inComps,varCompMapping,eqCompMapping,{},nodeNames,nodeDescs,exeCosts,commCosts,nodeMark);
end buildTaskgraphMetaForTornSystem;

protected function buildDummyCommCosts "generates preliminary commCosts for a children list.
author:Waurich TUD 2014-07"
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
  comps := List.map1(nodes,Util.arrayGetIndexFirst,inComps);
  simEqSys := HpcOmScheduler.getSimEqSysIdcsForNodeLst(comps,sccSimEqMapping);
  simEqSys := List.map1(simEqSys,List.sort,intGt);
  thread1 := List.threadMap1(simEqSys,nodes,HpcOmScheduler.makeCalcTask,1);
  threadTasks := arrayCreate(4,{});
  threadTasks := arrayUpdate(threadTasks,1,thread1);
  allCalcTasks := arrayCreate(listLength(thread1), (HpcOmSimCode.TASKEMPTY(),0));
  schedule := HpcOmSimCode.THREADSCHEDULE(threadTasks,{},scheduledTasks,allCalcTasks);
end createSingleBlockSchedule;

//--------------------------------------------------//
// dump torn system of equations as a directed acyclic graph (the matched system)
//-------------------------------------------------//

protected function dumpEquationSystemDAG
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input String fileName;
protected
  Integer graphIdx, nameAttIdx;
  GraphML.GraphInfo graphInfo;
algorithm
  graphInfo := GraphML.createGraphInfo();
  (graphInfo, (_,graphIdx)) := GraphML.addGraph("TornSystemGraph", true, graphInfo);
  (graphInfo,(_,nameAttIdx)) := GraphML.addAttribute("", "Name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  graphInfo := buildGraphInfoDAG(graphIn,metaIn,graphInfo,graphIdx,{nameAttIdx});
  GraphML.dumpGraph(graphInfo, fileName+&".graphml");
end dumpEquationSystemDAG;

protected function buildGraphInfoDAG
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input GraphML.GraphInfo graphInfoIn;
  input Integer graphIdx;
  input list<Integer> attIdcs;
  output GraphML.GraphInfo graphInfoOut;
protected
  GraphML.GraphInfo graphInfo;
  list<Integer> nodeIdcs;
  list<GraphML.Node> nodes;
  Integer nameAttIdx;
algorithm
  nameAttIdx := List.first(attIdcs);
  nodeIdcs := List.intRange(arrayLength(graphIn));
  graphInfoOut := List.fold4(nodeIdcs,addNodeToDAG,graphIn,metaIn,graphIdx,{nameAttIdx},graphInfoIn);
  GraphML.GRAPHINFO(nodes=nodes) := graphInfoOut;
end buildGraphInfoDAG;

protected function addNodeToDAG"add a node to a DAG.
author:Waurich TUD 2014-07"
  input Integer nodeIdx;
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input Integer graphIdx;
  input list<Integer> atts; //{nameAtt}
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  GraphML.GraphInfo tmpGraph;
  Integer nameAttIdx;
  list<Integer> childNodes;
  array<String> nodeDescs;
  array<list<Integer>> inComps;
  GraphML.NodeLabel nodeLabel;
  String nodeString, nodeDesc, nodeName;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,nodeDescs=nodeDescs) := metaIn;
  nodeDesc := arrayGet(nodeDescs,nodeIdx);
  nodeString := intString(nodeIdx);
  nodeName := stringDelimitList(List.map(arrayGet(inComps,nodeIdx),intString),",");
  nameAttIdx := listGet(atts,1);
  nodeLabel := GraphML.NODELABEL_INTERNAL(nodeString,NONE(),GraphML.FONTPLAIN());
  (tmpGraph,(_,_)) := GraphML.addNode("Node"+&intString(nodeIdx),
                                              GraphML.COLOR_ORANGE,
                                              {nodeLabel},
                                              GraphML.RECTANGLE(),
                                              SOME(nodeDesc),
                                              {(nameAttIdx,nodeName)},
                                              graphIdx,
                                              graphInfoIn);
  childNodes := arrayGet(graphIn,nodeIdx);
  graphInfoOut := List.fold1(childNodes, addDirectedEdge, nodeIdx, tmpGraph);
end addNodeToDAG;

protected function addDirectedEdge"add a directed edge from child to parent
author: Waurich TUD 2014-07"
  input Integer child;
  input Integer parent;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
algorithm
  (graphInfoOut,(_,_)) := GraphML.addEdge( "Edge" +& intString(parent)+&intString(child),
                                      "Node" +& intString(child),
                                      "Node" +& intString(parent),
                                      GraphML.COLOR_BLACK,
                                      GraphML.LINE(),
                                      GraphML.LINEWIDTH_STANDARD,
                                      false,{},
                                      (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                                      {},
                                      graphInfoIn);
end addDirectedEdge;

end HpcOmEqSystems;
