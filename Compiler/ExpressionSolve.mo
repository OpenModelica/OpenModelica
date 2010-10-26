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

package ExpressionSolve
"
  file:	       ExpressionSolve.mo
  package:     ExpressionSolve
  description: ExpressionSolve

  RCS: $Id: Expression.mo 6615 2010-10-26 14:21:30Z Frenkel TUD $

  This file contains the module `ExpressionSolve\', which contains functions
  to solve a DAE.Exp for a DAE.Exp"

public import Absyn;
public import DAE;

protected import ComponentReference;
protected import Expression;
protected import ExpressionSimplify;
protected import Util;
protected import Derive;
protected import Debug;

public function solve
"function: solve
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp crexp,crexp2,rhs,lhs,res,res_1,cr,e1,e2,e3;
      DAE.ComponentRef cr1,cr2;
    /*
    case(debuge1,debuge2,debuge3) // FOR DEBBUGING...
      local DAE.Exp debuge1,debuge2,debuge3;
      equation
        print("(Expression.mo debugging)  To solve: rhs: " +&
          printExpStr(debuge1) +& " lhs: " +&
          printExpStr(debuge2) +& " with respect to: " +&
          printExpStr(debuge3) +& "\n");
      then
        fail();*/
    
    // special case when already solved, cr1 = rhs, otherwise division by zero when dividing with derivative
    case (crexp,rhs,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(rhs, crexp);
        res_1 = ExpressionSimplify.simplify1(rhs);
      then
        res_1;

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (lhs,crexp ,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(lhs, crexp);
        res_1 = ExpressionSimplify.simplify1(lhs);
      then
        res_1;    

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        res = solve2(lhs, rhs, cr);
        res_1 = ExpressionSimplify.simplify1(res);
      then
        res_1;
    
    case (lhs,DAE.IFEXP(e1,e2,e3),(cr as DAE.CREF(componentRef = _)))
      equation
        rhs = solve(lhs,e2,cr);
        res = solve(lhs,e3,cr);
        res_1 = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
    
    case (DAE.IFEXP(e1,e2,e3),rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        lhs = solve(rhs,e2,cr);
        res = solve(rhs,e3,cr);
        res_1 = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
        
    case (e1,e2,e3)
      equation
        Debug.fprint("failtrace", "-ExpressionSolve.solve failed\n");
        //print("solve ");print(printExpStr(e1));print(" = ");print(printExpStr(e2));
        //print(" w.r.t ");print(printExpStr(e3));print(" failed\n");
      then
        fail();
  end matchcontinue;
end solve;

public function solveLin
"function: solve
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp crexp,crexp2,rhs,lhs,res,res_1,cr,e1,e2,e3;
      DAE.ComponentRef cr1,cr2;
    /*
    case(debuge1,debuge2,debuge3) // FOR DEBBUGING...
      local DAE.Exp debuge1,debuge2,debuge3;
      equation
        print("(Expression.mo debugging)  To solve: rhs: " +&
          printExpStr(debuge1) +& " lhs: " +&
          printExpStr(debuge2) +& " with respect to: " +&
          printExpStr(debuge3) +& "\n");
      then
        fail();*/
    
    // special case when already solved, cr1 = rhs, otherwise division by zero when dividing with derivative
    case (crexp,rhs,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(rhs, crexp);
        res_1 = ExpressionSimplify.simplify1(rhs);
      then
        res_1;

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (lhs,crexp ,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(lhs, crexp);
        res_1 = ExpressionSimplify.simplify1(lhs);
      then
        res_1;    

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        true = hasOnlyFactors(lhs,rhs);
        lhs = DAE.BINARY(lhs,DAE.ADD(DAE.ET_REAL()),DAE.RCONST(1.0));
        rhs = DAE.BINARY(rhs,DAE.ADD(DAE.ET_REAL()),DAE.RCONST(1.0));
        res = solve2(lhs, rhs, cr);
        res_1 = ExpressionSimplify.simplify1(res);
      then
        res_1;

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        res = solve2(lhs, rhs, cr);
        res_1 = ExpressionSimplify.simplify1(res);
      then
        res_1;
    
    case (lhs,DAE.IFEXP(e1,e2,e3),(cr as DAE.CREF(componentRef = _)))
      equation
        rhs = solveLin(lhs,e2,cr);
        res = solveLin(lhs,e3,cr);
        res_1 = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
    
    case (DAE.IFEXP(e1,e2,e3),rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        lhs = solveLin(rhs,e2,cr);
        res = solveLin(rhs,e3,cr);
        res_1 = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
        
    case (e1,e2,e3)
      equation
        Debug.fprint("failtrace", "-Expression.solve failed\n");
        //print("solve ");print(printExpStr(e1));print(" = ");print(printExpStr(e2));
        //print(" w.r.t ");print(printExpStr(e3));print(" failed\n");
      then
        fail();
  end matchcontinue;
end solveLin;

protected function solve2
"function: solve2
  This function solves an equation e1 = e2 with
  respect to the variable given as an expression e3"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp lhs,lhsder,lhsder_1,lhszero,lhszero_1,rhs,rhs_1,e1,e2,crexp;
      DAE.ComponentRef cr;
    
    // e1 e2 e3 
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        false = hasOnlyFactors(e1,e2);
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = ExpressionSimplify.simplify(lhsder);
        false = Expression.isZero(lhsder_1);
        false = Expression.expContains(lhsder_1, crexp);
        (lhszero,_) = Expression.replaceExp(lhs, crexp, DAE.RCONST(0.0));
        lhszero_1 = ExpressionSimplify.simplify(lhszero);
        rhs = DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(lhszero_1,DAE.DIV(DAE.ET_REAL()),lhsder_1));
        rhs_1 = ExpressionSimplify.simplify(rhs);
      then
        rhs_1;

    case(e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      local DAE.Exp invCr; list<DAE.Exp> factors;
      equation
        ({invCr},factors) = Util.listSplitOnTrue1(listAppend(Expression.factors(e1),Expression.factors(e2)),isInverseCref,cr);
        rhs_1 = Expression.makeProductLst(Expression.inverseFactors(factors));
        false = Expression.expContains(rhs_1, crexp);
      then
        rhs_1;

    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = ExpressionSimplify.simplify(lhsder);
        true = Expression.expContains(lhsder_1, crexp);
        /*print("solve2 failed: Not linear: ");
        print(printExpStr(e1));
        print(" = ");
        print(printExpStr(e2));
        print("\nsolving for: ");
        print(printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(printExpStr(lhsder));
        print("\n");*/
      then
        fail();
    
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = ExpressionSimplify.simplify(lhsder);
        /*print("solve2 failed: ");
        print(printExpStr(e1));
        print(" = ");
        print(printExpStr(e2));
        print("\nsolving for: ");
        print(printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(printExpStr(lhsder_1));
        print("\n");*/
      then
        fail();
  end matchcontinue;
end solve2;

protected function hasOnlyFactors "help function to solve2, returns true if equation e1 == e2, has either e1 == 0 or e2 == 0 and the expression only contains
factors, e.g. a*b*c = 0. In this case we can not solve the equation"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    case(e1,e2) equation
      true = Expression.isZero(e1);
      // More than two factors
      _::_::_ = Expression.factors(e2);
      //.. and more than two crefs
      _::_::_ = Expression.extractCrefsFromExp(e2);
    then true;
      
      // Swapped args
    case(e2,e1) equation
      true = Expression.isZero(e1);
      _::_::_ = Expression.factors(e2);
      _::_::_ = Expression.extractCrefsFromExp(e2);
    then true;
    
    case(_,_) then false;      
  end matchcontinue;
end hasOnlyFactors;

protected function crOrDerCr "returns the component reference of CREF or der(CREF)"
  input DAE.Exp exp;
  output DAE.ComponentRef cr;
algorithm
  cr := matchcontinue(exp)
    case(DAE.CREF(cr,_)) then cr;
    case(DAE.CALL(path=Absyn.IDENT("der"),expLst = {DAE.CREF(cr,_)})) then cr;
  end matchcontinue;
end crOrDerCr;

protected function isInverseCref " Returns true if expression is 1/cr for a ComponentRef cr"
input DAE.Exp e;
input DAE.ComponentRef cr;
output Boolean res;
algorithm
  res := matchcontinue(e,cr)
  local DAE.ComponentRef cr2; DAE.Exp e1;
    case(DAE.BINARY(e1,DAE.DIV(_),DAE.CREF(componentRef = cr2)),cr)equation
        true = Expression.isConstOne(e1);
        true = ComponentReference.crefEqual(cr,cr2);
    then true;
    case(_,_) then false;
  end matchcontinue;
end isInverseCref;

end ExpressionSolve;

