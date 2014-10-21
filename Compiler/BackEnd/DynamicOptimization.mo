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
protected import Util;

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
algorithm
  (outVars, outEqns, outClassAttr) := match(inVars, inEqns, inOptimicaFlag, inClassAttr, inConstraint, knvars, inDynOptimization)
  local
      DAE.ComponentRef leftcref;
      list<BackendDAE.Equation> objectEqn;
      BackendDAE.Var dummyVar;
      Boolean b;
      BackendDAE.Variables v, inVarsAndknvars;
      list<BackendDAE.Equation> e;
      Option<DAE.Exp> mayer, mayer1, lagrange, lagrange1;
      list< .DAE.Exp> constraintLst;
      list< .DAE.Constraint> constraints;
      list<BackendDAE.Var> varlst;
      list< .DAE.ClassAttributes> tmpClassAttr;

    case (v, e, true, {DAE.OPTIMIZATION_ATTRS(objetiveE=mayer, objectiveIntegrandE=lagrange)}, _, _,_)
      equation
        inVarsAndknvars = BackendVariable.mergeVariables(inVars, knvars);
        varlst = BackendVariable.varList(inVarsAndknvars);

        leftcref = ComponentReference.makeCrefIdent("$OMC$objectMayerTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        mayer1 = findMayerTerm(varlst);
        mayer1 = mergeObjectVars(mayer1,mayer);
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, mayer1, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);

        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        leftcref = ComponentReference.makeCrefIdent("$OMC$objectLagrangeTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        lagrange1 = findLagrangeTerm(varlst);
        lagrange1 = mergeObjectVars(lagrange1,lagrange);
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, lagrange1, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);

        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        constraints = addConstraints(varlst, inConstraint);
        (v, e) = addOptimizationVarsEqns2(constraints, 1, v, e, knvars, "$OMC$constarintTerm", BackendDAE.OPT_CONSTR());

        constraints = findFinalConstraints(varlst, {});
        (v, e) = addOptimizationVarsEqns2(constraints, 1, v, e, knvars, "$OMC$finalConstarintTerm", BackendDAE.OPT_FCONSTR());

        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);
    then (v, e, inClassAttr);
    case (v, e, true, _, _, _,_)
      equation
        inVarsAndknvars = BackendVariable.mergeVariables(inVars, knvars);
        varlst = BackendVariable.varList(inVarsAndknvars);

        leftcref = ComponentReference.makeCrefIdent("$OMC$objectMayerTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        mayer1 = findMayerTerm(varlst);
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, mayer1, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);

        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        leftcref = ComponentReference.makeCrefIdent("$OMC$objectLagrangeTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        lagrange1 = findLagrangeTerm(varlst);
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, lagrange1, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);
        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        constraints = addConstraints(varlst, inConstraint);
        (v, e) = addOptimizationVarsEqns2(constraints, 1, v, e, knvars, "$OMC$constarintTerm", BackendDAE.OPT_CONSTR());

        constraints = findFinalConstraints(varlst, {});
        (v, e) = addOptimizationVarsEqns2(constraints, 1, v, e, knvars, "$OMC$finalConstarintTerm", BackendDAE.OPT_FCONSTR());

        Flags.setConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION, true);
       then (v, e,{DAE.OPTIMIZATION_ATTRS(mayer1, lagrange1, NONE(), NONE())});
    case (v, e, false, _, _, _, true)
      equation
        Flags.setConfigEnum(Flags.GRAMMAR, Flags.OPTIMICA);
        (v, e, tmpClassAttr) =  addOptimizationVarsEqns(inVars, inEqns, true, inClassAttr, inConstraint, knvars, true);
       then (v,e,tmpClassAttr);
    else then(inVars, inEqns, inClassAttr);
  end match;
end addOptimizationVarsEqns;

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
    //print("con"+& intString(inI) +& " "+& ExpressionDump.printExpStr(e) +& "\n=>" +& ExpressionDump.dumpExpStr(e,0) +& "\n");
    //BackendDump.printVariables(inVars);
    //BackendDump.printVariables(knvars);
    conCrefName = prefConCrefName +& intString(inI);
    (conEqn, dummyVar) = BackendEquation.generateResidualfromRealtion(conCrefName, e, DAE.emptyElementSource, inVars, knvars, conKind);
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
    case(NONE(), SOME(e2)) then inmayer2;
    case(_, NONE()) then inmayer1;

  end match;
end mergeObjectVars;

protected function addConstraints
"author: Vitalij Ruge"
input list<BackendDAE.Var> InVarlst;
input list< .DAE.Constraint> inConstraint;
output list< .DAE.Constraint> outConstraint;

algorithm
  outConstraint := match(InVarlst, inConstraint)
  local list<BackendDAE.Var> varlst; BackendDAE.Variables v; list< .DAE.Exp> constraintLst; list< .DAE.Constraint> constraints;

    case(_, {DAE.CONSTRAINT_EXPS(constraintLst = constraintLst)}) equation
      //print("\n1-->");
      varlst = List.select(InVarlst, BackendVariable.hasConTermAnno);
      //print("\n1.3-->");
      constraintLst = addConstraints2(constraintLst, varlst);
      constraints =  {DAE.CONSTRAINT_EXPS(constraintLst)};
      //print("\n1.5-->");
    then constraints;
    case(_, {}) equation
      //print("\n2-->");
      varlst = List.select(InVarlst, BackendVariable.hasConTermAnno);
      constraintLst = addConstraints2({}, varlst);
      constraints =  {DAE.CONSTRAINT_EXPS(constraintLst)};
    then constraints;
    else then (inConstraint);
  end match;
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
