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

 encapsulated package DynamicOptimization

" file:        DynamicOptimization.mo
  package:     DynamicOptimization
  description: DynamicOptimization contains the function that create dynamic optimization.

  RCS: $Id: DynamicOptimization.mo  xxx$
"
public import DAE;
public import BackendDAE;
public import BackendDAEOptimize;

protected import BackendDump;
protected import ExpressionDump;

protected import BackendEquation;
protected import BackendDAEUtil;


protected import BackendVariable;
protected import ComponentReference;
protected import Config;

protected import Expression;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Error;
protected import Flags;
protected import List;

public function addOptimizationVarsEqns
"author: Vitalij Ruge
 add objective function and constraints to DAE. Neeed for derivatives"
  input BackendDAE.Variables inVars;
  input list<BackendDAE.Equation> inEqns;
  input Boolean inOptimicaFlag;
  input list< .DAE.ClassAttributes> inClassAttr;
  input list< .DAE.Constraint> inConstraint;
  input BackendDAE.Variables knvars;
  input Boolean inDynOptimization;
  output BackendDAE.Variables outVars;
  output list<BackendDAE.Equation>  outEqns;
  output list< .DAE.ClassAttributes> outClassAttr;
protected
  Option<DAE.Exp> mayer, lagrange, startTimeE, finalTimeE;
  BackendDAE.Variables v, inVarsAndknvars;
  list<BackendDAE.Var> varlst;
  BackendDAE.Var tG;
  list<BackendDAE.Equation> e;
algorithm

  if not inOptimicaFlag and not inDynOptimization then //no optimization
    outVars := inVars;
    outEqns := inEqns;
    outClassAttr := inClassAttr;
  else

   if not inOptimicaFlag then
    Flags.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
   end if;

    (mayer,lagrange,startTimeE,finalTimeE) := match(inClassAttr)
                        local Option<DAE.Exp> mayer_, lagrange_, startTimeE_, finalTimeE_;
                        case({DAE.OPTIMIZATION_ATTRS(objetiveE=mayer_, objectiveIntegrandE=lagrange_,startTimeE=startTimeE_,finalTimeE=finalTimeE_)}) then(mayer_,lagrange_,startTimeE_,finalTimeE_);
                        else (NONE(), NONE(),NONE(),NONE());
                        end match;


    _ := addTimeGrid(BackendVariable.varList(knvars), knvars);
    inVarsAndknvars := BackendVariable.addVariables(inVars, BackendVariable.copyVariables(knvars));
    varlst := BackendVariable.varList(inVarsAndknvars);
    (v, e, mayer) := joinObjectFun(makeObject(BackendDAE.optimizationMayerTermName, findMayerTerm, varlst, mayer), inVars, inEqns);
    (v, e, lagrange) := joinObjectFun(makeObject(BackendDAE.optimizationLagrangeTermName, findLagrangeTerm, varlst, lagrange), v, e);
    (v, e) := joinConstraints(inConstraint, "$OMC$constarintTerm", BackendDAE.OPT_CONSTR(), knvars, varlst ,v, e, BackendVariable.hasConTermAnno);
    (outVars, outEqns) := joinConstraints({}, "$OMC$finalConstarintTerm", BackendDAE.OPT_FCONSTR(), knvars, varlst, v, e, BackendVariable.hasFinalConTermAnno);
    Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);

    outClassAttr := {DAE.OPTIMIZATION_ATTRS(mayer, lagrange, startTimeE, finalTimeE)};
  end if;

end addOptimizationVarsEqns;


protected function addTimeGrid
  input list<BackendDAE.Var> varlst;
  input BackendDAE.Variables iv;
  output BackendDAE.Variables ov = iv;
protected
  list<BackendDAE.Var> tG = findTimeGrid(varlst);
  list<Integer> ind;
algorithm
  if not listEmpty(tG) then
    ind := BackendVariable.getVarIndexFromVars(tG, ov);
    for i in ind loop
      ov := BackendVariable.setVarKindForVar(i, BackendDAE.OPT_TGRID(), ov);
      //BackendDump.printVar(BackendVariable.getVarAt(ov,i));
    end for;
  end if;

end addTimeGrid;

protected function joinConstraints "author: Vitalij Ruge"
  input list< .DAE.Constraint> inConstraint;
  input String name;
  input BackendDAE.VarKind conKind;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Var> varlst;
  input BackendDAE.Variables vars;
  input list<BackendDAE.Equation> e;
  input MapFunc findCon;
  output BackendDAE.Variables ovars;
  output list<BackendDAE.Equation> oe;

  partial function MapFunc
    input BackendDAE.Var inVar;
    output Boolean outBoolean;
  end MapFunc;

protected
  list< .DAE.Constraint> constraints;
algorithm
  constraints := addConstraints(varlst, inConstraint, findCon);
  (ovars, oe) := addOptimizationVarsEqns2(constraints, 1, vars, e, knvars, name, conKind);
end joinConstraints;

protected function joinObjectFun "author: Vitalij Ruge"
  input tuple<BackendDAE.Var, list<BackendDAE.Equation>, Option<DAE.Exp>> obj;
  input BackendDAE.Variables vars;
  input list<BackendDAE.Equation> e;
  output BackendDAE.Variables ovars;
  output list<BackendDAE.Equation> oe;
  output Option<DAE.Exp> objExp;
algorithm
  (ovars, oe, objExp) := match(obj)
                local BackendDAE.Var v; list<BackendDAE.Equation> e_; Option<DAE.Exp> e1;
                case((_,{},_)) then(vars, e, NONE());
                case((v, e_, e1)) then(BackendVariable.addNewVar(v, vars), listAppend(e_, e), e1);
                end match;
end joinObjectFun;

protected function makeObject  "author: Vitalij Ruge"
  input String name;
  input MapFunc findObj;
  input list<BackendDAE.Var> varlst;
  input Option<DAE.Exp> optimicaExp "expression from optimica";
  output  tuple< BackendDAE.Var, list<BackendDAE.Equation>,  Option<DAE.Exp>> outTpl;

  partial function MapFunc
    input list<BackendDAE.Var> varlst;
    output Option<DAE.Exp>  objExp;
  end MapFunc;

protected
  DAE.ComponentRef cr;
  Option<DAE.Exp> annoObj;
  BackendDAE.Var v;
  list<BackendDAE.Equation> e;
algorithm
  (cr, v) := makeVar(name);
  annoObj := findObj(varlst);
  annoObj := mergeObjectVars(annoObj, optimicaExp);
  e := BackendEquation.generateSolvedEqnsfromOption(cr, annoObj, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
  outTpl := (v, e, annoObj);
end makeObject;

protected function makeVar "author: Vitalij Ruge"
  input String name;
  output DAE.ComponentRef cr;
  output BackendDAE.Var v;

algorithm
  cr := ComponentReference.makeCrefIdent(name, DAE.T_REAL_DEFAULT, {});
  v :=  BackendDAE.VAR(cr, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), SOME(BackendDAE.AVOID()), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
end makeVar;

protected function addOptimizationVarsEqns1
 input list<DAE.Exp> constraintLst;
 input Integer inI;
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 input BackendDAE.Variables knvars;
 input String prefConCrefName;
 input BackendDAE.VarKind conKind;

 output BackendDAE.Variables outVars = inVars;
 output list<BackendDAE.Equation>  outEqns = inEqns;

protected
 Integer i = inI;
 BackendDAE.Var dummyVar;
 list<BackendDAE.Equation> conEqn;
 String conCrefName;
algorithm

 for elem in constraintLst loop
   conCrefName := prefConCrefName + intString(i);
   (conEqn, dummyVar) := BackendEquation.generateResidualFromRelation(conCrefName, elem, DAE.emptyElementSource, outVars, knvars, conKind);
   outVars := BackendVariable.addNewVar(dummyVar, outVars);
   outEqns := listAppend(conEqn, outEqns);
   i := i + 1;
 end for;
end addOptimizationVarsEqns1;

protected function addOptimizationVarsEqns2
 input list< .DAE.Constraint> inConstraint;
 input Integer inI;
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 input BackendDAE.Variables knvars;
 input String prefConCrefName;
 input BackendDAE.VarKind conKind;

 output BackendDAE.Variables outVars;
 output list<BackendDAE.Equation>  outEqns;
algorithm
  (outVars, outEqns) := match(inConstraint, inI, inVars, inEqns, knvars,prefConCrefName,conKind)
  local
   list<BackendDAE.Equation> e;
   BackendDAE.Variables v;
   list< .DAE.Exp> constraintLst;
    case({DAE.CONSTRAINT_EXPS(constraintLst = constraintLst)}, _, _, _, _, _, _) equation
      (v, e) = addOptimizationVarsEqns1(constraintLst, inI, inVars, inEqns, knvars,prefConCrefName,conKind);
      then (v, e);
  else (inVars, inEqns);
  end match;
end addOptimizationVarsEqns2;


protected function findMayerTerm
"author: Vitalij Ruge
find mayer-term from annotation"
input list<BackendDAE.Var> varlst;
output Option<DAE.Exp> mayer = findObjTerm(varlst,BackendVariable.hasMayerTermAnno);
end findMayerTerm;

protected function findLagrangeTerm
"author: Vitalij Ruge
find lagrange-term from annotation"
input list<BackendDAE.Var> varlst;
output Option<DAE.Exp> lagrange = findObjTerm(varlst,BackendVariable.hasLagrangeTermAnno);
end findLagrangeTerm;

protected function findTimeGrid
"author: Vitalij Ruge
find lagrange-term from annotation"
input list<BackendDAE.Var> varlst;
output list<BackendDAE.Var> timeGrids = List.select(varlst, BackendVariable.hasTimeGridAnno);
end findTimeGrid;


protected function findObjTerm
"author: Vitalij Ruge
helper findLagrangeTerm, findMayerTerm"
input list<BackendDAE.Var> InVarlst;
input MapFunc findObjTermFun;
output Option<DAE.Exp> objeExp = NONE();

partial function MapFunc
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
end MapFunc;

protected
DAE.Exp e, nom; DAE.ComponentRef cr;
list<BackendDAE.Var> varlst = List.select(InVarlst, findObjTermFun);

algorithm
  for v in varlst loop
      nom := BackendVariable.getVarNominalValue(v);
      cr := BackendVariable.varCref(v);
      e := DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      e := Expression.expDiv(e, nom);
      objeExp := mergeObjectVars(objeExp, SOME(e));
  end for;

end findObjTerm;

protected function mergeObjectVars
"author: Vitalij Ruge"
input Option<DAE.Exp> inmayer1;
input Option<DAE.Exp> inmayer2;
output Option<DAE.Exp> mayer;

algorithm
  mayer := match(inmayer1, inmayer2)
  local DAE.Exp e1, e2, e3;

    case(SOME(e1), SOME(e2)) equation
      e3 = Expression.expAdd(e1,e2);
    then SOME(e3);
    case(NONE(), SOME(_)) then inmayer2;
    case(_, NONE()) then inmayer1;
    else NONE();

  end match;
end mergeObjectVars;

protected function addConstraints
"author: Vitalij Ruge"
input list<BackendDAE.Var> InVarlst;
input list< .DAE.Constraint> inConstraint;
input MapFunc findCon;
output list< .DAE.Constraint> outConstraint;

  partial function MapFunc
    input BackendDAE.Var inVar;
    output Boolean outBoolean;
  end MapFunc;


protected
list<BackendDAE.Var> varlst;
list< .DAE.Exp> constraintLst;
algorithm
  constraintLst := match(inConstraint)
                   local list< .DAE.Exp> constraintLst_;
                   case({DAE.CONSTRAINT_EXPS(constraintLst = constraintLst_)}) then constraintLst_;
                   else {};
                   end match;

  varlst := List.select(InVarlst, findCon); //BackendVariable.hasConTermAnno //BackendVariable.hasFinalConTermAnno
  constraintLst := addConstraints2(constraintLst, varlst);
  outConstraint := {DAE.CONSTRAINT_EXPS(constraintLst)};

end addConstraints;

protected function addConstraints2
"author: Vitalij Ruge"
input list< .DAE.Exp> inConstraintLst;
input list<BackendDAE.Var> inVarlst;
output list< .DAE.Exp> outConstraintLst = inConstraintLst;

protected
 DAE.ComponentRef cr;
 .DAE.Exp e;
algorithm

  for v in inVarlst loop
    cr := BackendVariable.varCref(v);
    e := DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    outConstraintLst := e :: outConstraintLst;
  end for;

end addConstraints2;

// =============================================================================
// section for preOptModule >>inputDerivativesForDynOpt<<
//
// check for derivatives of inputs and replace (only for dyn. optimization)
// =============================================================================

public function inputDerivativesForDynOpt "
  checks if der(input) is used and replace for dyn. optimization"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Config.acceptOptimicaGrammar() or Flags.getConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM) then
    (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, inputDerivativesForDynOptWork, false);
  else
    outDAE := inDAE;
  end if;
end inputDerivativesForDynOpt;

protected function inputDerivativesForDynOptWork "author: "
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared;
  output Boolean outChanged;

algorithm

  (osyst, outChanged) := matchcontinue(isyst)
    local
      BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
      BackendDAE.EquationArray orderedEqs "ordered Equations";
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      list<DAE.ComponentRef> idercr={}, icr={};
      DAE.ComponentRef cr;
      String s;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;
      list<BackendDAE.Var> varLst={};
      BackendDAE.Variables vars;

    case BackendDAE.EQSYSTEM(orderedVars, orderedEqs, _, _, _, stateSets, partitionKind) algorithm
      vars := BackendVariable.daeKnVars(outShared);

      ((_, idercr, icr, varLst)) := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs, traverserinputDerivativesForDynOpt, (vars, idercr, icr, varLst));
      if listEmpty(idercr) then
        fail();
      end if;
      // der(u) -> u has der
      varLst := BackendVariable.setVarsKind(varLst, BackendDAE.OPT_INPUT_WITH_DER());
      for v in varLst loop
        outShared := BackendVariable.addKnVarDAE(v, outShared);
      end for;
      //  der(u) -> new input var
      varLst := List.map(idercr, BackendVariable.makeVar);
      varLst := List.map1(varLst, BackendVariable.setVarDirection, DAE.INPUT());
      for v in varLst loop
        v := BackendVariable.setVarKind(v,BackendDAE.OPT_INPUT_DER());
        outShared := BackendVariable.addKnVarDAE(v, outShared);
      end for;
      _ := BackendVariable.daeKnVars(outShared);
       //BackendDump.printVariables(vars);
    then (BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(),NONE(),BackendDAE.NO_MATCHING(), stateSets, partitionKind), true);

    else (isyst, inChanged);
  end matchcontinue;
end inputDerivativesForDynOptWork;

protected function traverserinputDerivativesForDynOpt "author:"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, list<DAE.ComponentRef>,list<DAE.ComponentRef> ,list<BackendDAE.Var>> itpl;
  output DAE.Exp e;
  output tuple<BackendDAE.Variables,list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<BackendDAE.Var>> tpl;
algorithm
  (e,tpl) := Expression.traverseExpTopDown(inExp,traverserExpinputDerivativesForDynOpt,itpl);
end traverserinputDerivativesForDynOpt;

protected function traverserExpinputDerivativesForDynOpt
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<BackendDAE.Var>> tpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<BackendDAE.Var>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,tpl)
    local
      BackendDAE.Variables vars;
      DAE.Type tp;
      DAE.Exp e;
      DAE.ComponentRef cr, cr1;
      BackendDAE.Var var;
      list<DAE.ComponentRef> lst, lst1;
      list<BackendDAE.Var> varLst;

    case (DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(vars,lst,lst1,varLst))
      equation
        (var::{},_) = BackendVariable.getVar(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
        cr1 = ComponentReference.prependStringCref("$TMP$DER$P", cr);
        //cr1 = ComponentReference.crefPrefixDer(cr);
        e = Expression.crefExp(cr1);
      then (e,true,(vars, List.unionElt(cr1,lst), List.unionElt(cr,lst1),  List.unionElt(var,varLst)));

    else (inExp,true,tpl);
  end matchcontinue;
end traverserExpinputDerivativesForDynOpt;


// =============================================================================
// section for postOptModule >>extendDynamicOptimization<<
//
// transform loops from DAE in constraints for optimizer
// - bigger NLP
// - don't solve loop in each step
// - cheaper jacobians
// =============================================================================

public function removeLoops
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.isSet(Flags.EXTENDS_DYN_OPT) then
    //BackendDump.bltdump("***", inDAE);
    (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, findLoops, false);
    //BackendDump.bltdump("###", outDAE);
  else
    outDAE := inDAE;
  end if;
end removeLoops;

protected function findLoops
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared;
  output Boolean outChanged;
protected
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := isyst;
  (osyst, outShared, outChanged) := findLoops1(isyst, inShared, comps, inChanged);
end findLoops;

protected function findLoops1
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;
  input Boolean inchanged;
  output BackendDAE.EqSystem osyst = isyst;
  output BackendDAE.Shared oshared = ishared;
  output Boolean changed = inchanged "not used";
protected
  Boolean b;
  BackendDAE.StrongComponent c;
  Integer i = 1;
  BackendDAE.Variables vars;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
  BackendDAE.EquationArray eqns;

algorithm
  for comp in inComps loop
    (osyst,oshared) := removeLoopsWork(osyst,oshared,comp);
  end for;

end findLoops1;


protected function removeLoopsWork
"
  author: Vitalij Ruge
"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponent icomp;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared):=
  matchcontinue (isyst,ishared,icomp)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;
      list<Integer> eindex,vindx;
      Integer eindex_,vindx_;
      BackendDAE.Shared shared;
      DAE.Exp e1, e2, varexp;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.FunctionTree funcs;

    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets,partitionKind=partitionKind),shared,(BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx)))
    equation
      (eqns,vars,shared) = res2Con(eqns, vars, eindex, vindx,shared);
    then (BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind), shared);

    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets,partitionKind=partitionKind),shared,(BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=eindex,tearingvars=vindx))))
    equation
      (eqns,vars,shared) = res2Con(eqns, vars, eindex, vindx,shared);
    then (BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind), shared);

    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets,partitionKind=partitionKind),shared,BackendDAE.SINGLEEQUATION(eqn=eindex_,var=vindx_))
    equation
        BackendDAE.EQUATION(exp=e1, scalar=e2) = BackendEquation.equationNth1(eqns, eindex_);
        (v as BackendDAE.VAR(varName = cr)) = BackendVariable.getVarAt(vars, vindx_);
        varexp = Expression.crefExp(cr);
        varexp = if BackendVariable.isStateVar(v) then Expression.expDer(varexp) else varexp;
        BackendDAE.SHARED(functionTree = funcs) = shared;
        failure(ExpressionSolve.solve2(e1, e2, varexp, SOME(funcs), NONE()));
        (eqns,vars,shared) = res2Con(eqns, vars, {eindex_}, {vindx_},shared);
    then (BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind), shared);


    else (isyst,ishared);

  end matchcontinue;

end removeLoopsWork;


protected function res2Con
"
  author: Vitalij Ruge
"
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input BackendDAE.Shared ishared;
  output BackendDAE.EquationArray oeqns = ieqns;
  output BackendDAE.Variables ovars = ivars;
  output BackendDAE.Shared oshared = ishared;
protected
  list<BackendDAE.Equation> eqn_lst = BackendEquation.getEqns(eindex,ieqns);
  BackendDAE.Equation eqn;
  list<BackendDAE.Var> var_lst = List.map1r(vindx, BackendVariable.getVarAt, ivars);
  BackendDAE.Var var, var_;
  list<DAE.ComponentRef> cr_lst = List.map(var_lst, BackendVariable.varCref);
  DAE.ComponentRef cr, cr_var;
  list<String> name_lst = List.map(cr_lst,ComponentReference.crefStr);
  DAE.Exp e, res;
  Integer ind_e, ind_v;
  list<Integer> ind_lst_v = List.map(vindx,intAbs);
  list<Integer> ind_lst_e = eindex;
  BackendDAE.Variables knvars;
algorithm

  BackendDAE.SHARED(knownVars=knvars) := oshared;

  for name in name_lst loop

    // res -> con
    var_::var_lst := var_lst;
    cr_var :: cr_lst := cr_lst;
    eqn :: eqn_lst := eqn_lst;
    ind_e :: ind_lst_e := ind_lst_e;
    ind_v :: ind_lst_v := ind_lst_v;
    cr  := ComponentReference.makeCrefIdent("$OMC$con$Loop$"  + intString(ind_e), DAE.T_REAL_DEFAULT , {});
    e := Expression.crefExp(cr);

    var := BackendVariable.makeVar(cr);
    var := BackendVariable.setVarMinMax(var, SOME(DAE.RCONST(0.0)), SOME(DAE.RCONST(0.0)));
    var := BackendVariable.setVarKind(var, BackendDAE.OPT_CONSTR());
    var := BackendVariable.setVarDirection(var, DAE.OUTPUT());

    ovars := BackendVariable.addNewVar(var, ovars);
    res := BackendDAEOptimize.makeEquationToResidualExp(eqn);
    res := Expression.createResidualExp(res, Expression.makeConstZeroE(res));

    //oeqns := BackendEquation.addEquation(BackendDAE.EQUATION(e, res, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN), oeqns);
    oeqns := BackendEquation.setAtIndex(oeqns,ind_e, BackendDAE.EQUATION(e, res, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN));
    // new input(resvar)
    (cr,var) := makeVar("OMC$Input" + intString(ind_v));
    var := BackendVariable.setVarDirection(var, DAE.INPUT());
    // resvar = new input(resvar)
    e := Expression.crefExp(cr_var);
    if BackendVariable.isStateVar(var_) then
      e := Expression.expDer(e);
      var := BackendVariable.setVarKind(var, BackendDAE.OPT_LOOP_INPUT(ComponentReference.crefPrefixDer(cr_var)));
    else
      // don't merge der(x) with x
      var := BackendVariable.mergeAliasVars(var, var_, false, knvars);
      var := BackendVariable.setVarKind(var, BackendDAE.OPT_LOOP_INPUT(cr_var));
    end if;
    oshared := BackendVariable.addKnVarDAE(var, oshared);
    oeqns := BackendEquation.addEquation(BackendDAE.EQUATION(e, Expression.crefExp(cr), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN), oeqns);

  end for;


end res2Con;


// =============================================================================
// section for postOptModule >>reduceDynamicOptimization<<
//
// remove eqs which not need for the calculations of cost and constraints
// =============================================================================


public function reduceDynamicOptimization
"
  author: vitalij
"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.Var> varlst, opt_varlst, conVarsList, fconVarsList, objMayer = {}, objLagrange = {};
  list<BackendDAE.EqSystem> systlst, newsyst = {};
  BackendDAE.Variables v;
  BackendDAE.Shared shared;
algorithm
  if Flags.isSet(Flags.REDUCE_DYN_OPT) then

    //BackendDump.bltdump("START:reduceDynamicOptimization", inDAE);
    BackendDAE.DAE(systlst, shared) := inDAE;
    // ToDo
    shared := BackendEquation.removeRemovedEqs(shared);
    shared := BackendVariable.removeAliasVars(shared);

    for syst in systlst loop

      BackendDAE.EQSYSTEM(orderedVars = v) := syst;
      varlst := BackendVariable.varList(v);

      opt_varlst := {};

      conVarsList := List.select(varlst, BackendVariable.isRealOptimizeConstraintsVars);
      fconVarsList := List.select(varlst, BackendVariable.isRealOptimizeFinalConstraintsVars);
      objMayer := checkObjectIsSet(v,BackendDAE.optimizationMayerTermName);
      objLagrange := checkObjectIsSet(v,BackendDAE.optimizationLagrangeTermName);

      opt_varlst := List.appendNoCopy(opt_varlst, conVarsList);
      opt_varlst := List.appendNoCopy(opt_varlst, fconVarsList);
      opt_varlst := List.appendNoCopy(opt_varlst, objMayer);
      opt_varlst := List.appendNoCopy(opt_varlst, objLagrange);

      if not listEmpty(opt_varlst) then
        newsyst := BackendDAEUtil.tryReduceEqSystem(syst, shared, opt_varlst) :: newsyst;
      end if;
    end for;

    outDAE := BackendDAE.DAE(newsyst, shared);
    //BackendDump.bltdump("END:reduceDynamicOptimization", outDAE);
  else
    outDAE := inDAE;
  end if;
end reduceDynamicOptimization;

public function checkObjectIsSet
"check: mayer or lagrange term are set"
  input BackendDAE.Variables inVars;
  input String CrefName;
  output list<BackendDAE.Var> outVars;
protected
  DAE.ComponentRef leftcref;
algorithm
  leftcref := ComponentReference.makeCrefIdent(CrefName, DAE.T_REAL_DEFAULT, {});

  try
    outVars := BackendVariable.getVar(leftcref, inVars);
  else
    outVars := {};
  end try;
end checkObjectIsSet;

annotation(__OpenModelica_Interface="backend");
end DynamicOptimization;
