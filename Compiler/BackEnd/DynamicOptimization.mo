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

/*
protected import BackendDump;
protected import ExpressionDump;
*/

protected import BackendEquation;

protected import BackendVariable;
protected import ComponentReference;

protected import Expression;
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

    inVarsAndknvars := BackendVariable.addVariables(inVars, knvars);
    varlst := BackendVariable.varList(inVarsAndknvars);
    (v, e, mayer) := joinObjectFun(makeObject("$OMC$objectMayerTerm", findMayerTerm, varlst, mayer), inVars, inEqns);
    (v, e, lagrange) := joinObjectFun(makeObject("$OMC$objectLagrangeTerm", findLagrangeTerm, varlst, lagrange), v, e);
    (v, e) := joinConstraints(inConstraint, "$OMC$constarintTerm", BackendDAE.OPT_CONSTR(), knvars, varlst ,v, e, BackendVariable.hasConTermAnno);
    (outVars, outEqns) := joinConstraints({}, "$OMC$finalConstarintTerm", BackendDAE.OPT_FCONSTR(), knvars, varlst, v, e, BackendVariable.hasFinalConTermAnno);
    Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);

    outClassAttr := {DAE.OPTIMIZATION_ATTRS(mayer, lagrange, startTimeE, finalTimeE)};
  end if;

end addOptimizationVarsEqns;

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
  v :=  BackendDAE.VAR(cr, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR());
end makeVar;

protected function addOptimizationVarsEqns1
 input list<DAE.Exp> constraintLst;
 input Integer inI;
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 input BackendDAE.Variables knvars;
 input String prefConCrefName;
 input BackendDAE.VarKind conKind;

 output BackendDAE.Variables outVars;
 output list<BackendDAE.Equation>  outEqns;
algorithm
 (outVars, outEqns) := match(constraintLst, inI, inVars, inEqns, knvars,prefConCrefName,conKind)
 local
   list<DAE.Exp> conLst;
   DAE.Exp e;
   DAE.ComponentRef leftcref;
   BackendDAE.Var dummyVar;
   list<BackendDAE.Equation> conEqn;
   BackendDAE.Variables v;
   list<BackendDAE.Equation> eqns;
   String conCrefName;

   case({}, _, _, _, _, _, _) then (inVars, inEqns);
   case(e::conLst, _, _, _, _, _, _) equation
    //print("con"+ intString(inI) + " "+ ExpressionDump.printExpStr(e) + "\n=>" + ExpressionDump.dumpExpStr(e,0) + "\n");
    //BackendDump.printVariables(inVars);
    //BackendDump.printVariables(knvars);
    conCrefName = prefConCrefName + intString(inI);
    (conEqn, dummyVar) = BackendEquation.generateResidualFromRelation(conCrefName, e, DAE.emptyElementSource, inVars, knvars, conKind);
    v = BackendVariable.addNewVar(dummyVar, inVars);
    eqns = listAppend(conEqn, inEqns);
    (v, eqns)= addOptimizationVarsEqns1(conLst, inI + 1, v, eqns, knvars, prefConCrefName, conKind);
   then (v, eqns);
   else (inVars, inEqns);
   end match;
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
output Option<DAE.Exp> mayer;
protected
list<BackendDAE.Var> varlst_filter;
algorithm
  varlst_filter := List.select(varlst, BackendVariable.hasMayerTermAnno);
  mayer := findMayerTerm2(varlst_filter, NONE());
end findMayerTerm;

protected function findLagrangeTerm
"author: Vitalij Ruge
find lagrange-term from annotation"
input list<BackendDAE.Var> varlst;
output Option<DAE.Exp> lagrange;
protected
list<BackendDAE.Var> varlst_filter;
algorithm
  varlst_filter := List.select(varlst, BackendVariable.hasLagrangeTermAnno);
  lagrange := findMayerTerm2(varlst_filter, NONE());
end findLagrangeTerm;


protected function findMayerTerm2
"author: Vitalij Ruge
helper findLagrangeTerm, findMayerTerm"
input list<BackendDAE.Var> InVarlst;
input Option<DAE.Exp> Inmayer;
output Option<DAE.Exp> mayer;

algorithm
  mayer := match(InVarlst, Inmayer)
  local list<BackendDAE.Var> varlst; BackendDAE.Var v;
        DAE.Exp e, e2, e3, nom; Option<DAE.Exp> opte; DAE.ComponentRef cr;

    case({},_) then Inmayer;
    case(v::varlst, SOME(e)) equation
      nom = BackendVariable.getVarNominalValue(v);
      cr = BackendVariable.varCref(v);
      e2 = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      e2 = Expression.expDiv(e2, nom);
      e3 = Expression.expAdd(e,e2);
      opte = SOME(e3);
      then findMayerTerm2(varlst, opte);
    case(v::varlst, NONE()) equation
      nom = BackendVariable.getVarNominalValue(v);
      cr = BackendVariable.varCref(v);
      e2 = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      e2 = Expression.expDiv(e2, nom);
      opte = SOME(e2);
      then findMayerTerm2(varlst, opte);
    else then NONE();
  end match;

end findMayerTerm2;

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
output list< .DAE.Exp> outConstraintLst;

algorithm
  outConstraintLst := match(inConstraintLst, inVarlst)
  local list<BackendDAE.Var> varlst; list< .DAE.Exp> constraintLst;
    BackendDAE.Var v; .DAE.Exp e; DAE.ComponentRef cr; list< .DAE.Exp> ConstraintLst;

    case({}, {}) then {};
    case({}, v::varlst) equation
      cr = BackendVariable.varCref(v);
      e = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    then addConstraints2({e},varlst);
    case(ConstraintLst, v::varlst) equation
      cr = BackendVariable.varCref(v);
      e = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    then addConstraints2(e::ConstraintLst,varlst);
    else then(inConstraintLst);

  end match;
end addConstraints2;


protected function findFinalConstraints
"author: Vitalij Ruge"
input list<BackendDAE.Var> inVarlst;
input list< .DAE.Constraint> inConstraint;
output list< .DAE.Constraint> outConstraint;

algorithm
  outConstraint := match(inVarlst, inConstraint)
  local list<BackendDAE.Var> varlst; BackendDAE.Variables v; list< .DAE.Exp> constraintLst; list< .DAE.Constraint> constraints;

    case(_,  {DAE.CONSTRAINT_EXPS(constraintLst = constraintLst)}) equation
      //print("\n1-->");
      varlst = List.select(inVarlst, BackendVariable.hasFinalConTermAnno);
      //print("\n1.3-->");
      constraintLst = addConstraints2(constraintLst, varlst);
      constraints =  {DAE.CONSTRAINT_EXPS(constraintLst)};
      //print("\n1.5-->");
    then constraints;
    case(_, {}) equation
      //print("\n2-->");
      varlst = List.select(inVarlst, BackendVariable.hasFinalConTermAnno);
      constraintLst = addConstraints2({}, varlst);
      constraints =  {DAE.CONSTRAINT_EXPS(constraintLst)};
    then constraints;
    else then (inConstraint);
  end match;
end findFinalConstraints;

annotation(__OpenModelica_Interface="backend");
end DynamicOptimization;
