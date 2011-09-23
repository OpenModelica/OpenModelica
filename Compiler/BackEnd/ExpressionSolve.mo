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

encapsulated package ExpressionSolve
"
  file:         ExpressionSolve.mo
  package:     ExpressionSolve
  description: ExpressionSolve

  RCS: $Id$

  This file contains the module ExpressionSolve, which contains functions
  to solve a DAE.Exp for a DAE.Exp"

// public imports
public import Absyn;
public import DAE;

// protected imports
protected import ComponentReference;
protected import Debug;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import List;
protected import Util;

public function solve
"function: solve
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp crexp,crexp2,rhs,lhs,res,res_1,cr,e1,e2,e3;
      DAE.ComponentRef cr1,cr2;
      list<DAE.Statement> asserts,asserts1,asserts2;
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
        (res_1,_) = ExpressionSimplify.simplify1(rhs);
      then
        (res_1,{});

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (lhs,crexp ,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(lhs, crexp);
        (res_1,_) = ExpressionSimplify.simplify1(lhs);
      then
        (res_1,{});

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        (res,asserts) = solve2(lhs, rhs, cr, false);
        (res_1,_) = ExpressionSimplify.simplify1(res);
      then
        (res_1,asserts);
    
    case (lhs,DAE.IFEXP(e1,e2,e3),(cr as DAE.CREF(componentRef = _)))
      equation
        (rhs,asserts) = solve(lhs,e2,cr);
        (res,asserts1) = solve(lhs,e3,cr);
        (res_1,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res_1,asserts2);
    
    case (DAE.IFEXP(e1,e2,e3),rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        (lhs,asserts) = solve(rhs,e2,cr);
        (res,asserts1) = solve(rhs,e3,cr);
        (res_1,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,lhs,res));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res_1,asserts2);
        
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
"function: solve linear equation
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp crexp,crexp2,rhs,lhs,res,res_1,cr,e1,e2,e3;
      DAE.ComponentRef cr1,cr2;
      DAE.ExpType tp,tp1;
      list<DAE.Statement> asserts,asserts1,asserts2;
    
    // case(debuge1,debuge2,debuge3) // FOR DEBBUGING...
    //  local DAE.Exp debuge1,debuge2,debuge3;
    //  equation
    //    print("(Expression.mo debugging)  To solve: rhs: " +&
    //      printExpStr(debuge1) +& " lhs: " +&
    //     printExpStr(debuge2) +& " with respect to: " +&
    //      printExpStr(debuge3) +& "\n");
    //  then
    //    fail();
    
    // special case when already solved, cr1 = rhs, otherwise division by zero when dividing with derivative
    case (crexp,rhs,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(rhs, crexp);
        (res_1,_) = ExpressionSimplify.simplify1(rhs);
      then
        (res_1,{});

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (lhs,crexp ,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = ComponentReference.crefEqual(cr1, cr2);
        false = Expression.expContains(lhs, crexp);
        (res_1,_) = ExpressionSimplify.simplify1(lhs);
      then
        (res_1,{});

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        true = hasOnlyFactors(lhs,rhs);
        tp = Expression.typeof(lhs);
        e1 = Expression.makeConstOne(tp);
        lhs = Expression.makeSum({lhs,e1});
        tp1 = Expression.typeof(rhs);
        e2 = Expression.makeConstOne(tp1);
        lhs = Expression.makeSum({rhs,e2});
        (res,asserts) = solve2(lhs, rhs, cr, true);
        (res_1,_) = ExpressionSimplify.simplify1(res);
      then
        (res_1,asserts);

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        (res,asserts) = solve2(lhs, rhs, cr, true);
        (res_1,_) = ExpressionSimplify.simplify1(res);
      then
        (res_1,asserts);
    
    case (lhs,DAE.IFEXP(e1,e2,e3),(cr as DAE.CREF(componentRef = _)))
      equation
        (rhs,asserts) = solveLin(lhs,e2,cr);
        (res,asserts1) = solveLin(lhs,e3,cr);
        (res_1,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res_1,asserts2);
    
    case (DAE.IFEXP(e1,e2,e3),rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        (rhs,asserts) = solveLin(rhs,e2,cr);
        (res,asserts1) = solveLin(rhs,e3,cr);
        (res_1,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,rhs,res));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res_1,asserts2);
        
    case (e1,e2,e3)
      equation
        Debug.fprint("failtrace", "-Expression.solve failed\n");
        //print("solve ");print(ExpressionDump.printExpStr(e1));print(" = ");print(ExpressionDump.printExpStr(e2));
        //print(" w.r.t ");print(ExpressionDump.printExpStr(e3));print(" failed\n");
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
  input Boolean linearExps;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3,linearExps)
    local
      DAE.Exp lhs,lhsder,lhsder_1,lhszero,lhszero_1,rhs,rhs_1,e1,e2,crexp,e,a,z;
      DAE.ComponentRef cr;
      DAE.Exp invCr;
      list<DAE.Exp> factors;
      Boolean linExp;
      DAE.ExpType tp;
      list<DAE.Statement> asserts;
      String estr,se1,se2,sa;
    
     // e1 e2 e3 
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)),linExp)
      equation
        false = hasOnlyFactors(e1,e2);
        lhs = Expression.makeDiff(e1,e2);
        lhsder = Derive.differentiateExp(lhs, cr, linExp);
        (lhsder_1,_) = ExpressionSimplify.simplify(lhsder);
        false = Expression.isZero(lhsder_1);
        false = Expression.expContains(lhsder_1, crexp);
        tp = Expression.typeof(crexp);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        ((lhszero,_)) = Expression.replaceExp(lhs, crexp, z);
        (lhszero_1,_) = ExpressionSimplify.simplify(lhszero);
        rhs = Expression.negate(Expression.makeDiv(lhszero_1,lhsder_1));
      then
        (rhs,{});

      // a*(1/b)*c*...*n = rhs
    case(e1,e2,(crexp as DAE.CREF(componentRef = cr)),_)
      equation
        ({invCr},factors) = List.split1OnTrue(Expression.factors(e1),isInverseCref,cr);
        e2 = Expression.inverseFactors(e2);
        rhs_1 = Expression.makeProductLst(e2::factors);
        false = Expression.expContains(rhs_1, crexp);
      then (rhs_1,{});

      // lhs = a*(1/b)*c*...*n
    case(e1,e2,(crexp as DAE.CREF(componentRef = cr)),_)
      equation
        ({invCr},factors) = List.split1OnTrue(Expression.factors(e2),isInverseCref,cr);
        e1 = Expression.inverseFactors(e1);
        rhs_1 = Expression.makeProductLst(e1::factors);
        false = Expression.expContains(rhs_1, crexp);
      then (rhs_1,{});

    // 0 = a*(b-c)  solve for b    
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)),linExp)
      equation
        true = Expression.isZero(e1);
        (e,a) = solve3(e2,crexp);
        (rhs_1,asserts) = solve(e1,e,crexp);
        tp = Expression.typeof(a);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        se1 = ExpressionDump.printExpStr(e1);
        se2 = ExpressionDump.printExpStr(e2);
        sa = ExpressionDump.printExpStr(a);
        estr = stringAppendList({"Singular expression ",se1," = ",se2," because ",sa," is Zero!"});
      then
        (rhs_1,DAE.STMT_ASSERT(DAE.RELATION(a,DAE.NEQUAL(tp),z,-1,NONE()),DAE.SCONST(estr),DAE.emptyElementSource)::asserts);
       
    // swapped args: a*(b-c) = 0  solve for b     
    case (e2,e1,(crexp as DAE.CREF(componentRef = cr)),linExp)
      equation
        true = Expression.isZero(e1);
        (e,a) = solve3(e2,crexp);
        (rhs_1,asserts) = solve(e1,e,crexp);
        tp = Expression.typeof(a);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        se1 = ExpressionDump.printExpStr(e1);
        se2 = ExpressionDump.printExpStr(e2);
        sa = ExpressionDump.printExpStr(a);
        estr = stringAppendList({"Singular expression ",se1," = ",se2," because ",sa," is Zero!"});
      then
        (rhs_1,DAE.STMT_ASSERT(DAE.RELATION(a,DAE.NEQUAL(tp),z,-1,NONE()),DAE.SCONST(estr),DAE.emptyElementSource)::asserts);

    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)), linExp)
      equation
        lhs = Expression.makeDiff(e1,e2);
        lhsder = Derive.differentiateExp(lhs, cr, linExp);
        (lhsder_1,_) = ExpressionSimplify.simplify(lhsder);
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
    
    /*
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)), linExp)
      equation
        lhs = Expression.makeDiff(e1,e2);
        lhsder = Derive.differentiateExp(lhs, cr, linExp);
        (lhsder_1,_) = ExpressionSimplify.simplify(lhsder);
        print("solve2 failed: ");
        print(printExpStr(e1));
        print(" = ");
        print(printExpStr(e2));
        print("\nsolving for: ");
        print(printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(printExpStr(lhsder_1));
        print("\n");
      then
        fail();
     */
  end matchcontinue;
end solve2;

protected function solve3
"function: solve3
  helper for solve2
  This function checks if one part of a product expression
  does not contain inExp2"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
  output DAE.Exp outExp1;
algorithm
  (outExp,outExp1) := matchcontinue (inExp1,inExp2)
    local
      DAE.Exp crexp,e1,e2;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      DAE.Operator op;
    
    case (DAE.BINARY(e1,op,e2),(crexp as DAE.CREF(componentRef = cr)))
      equation
        true = solve4(op);
        false = Expression.isZero(e1);
        crefs = Expression.extractCrefsFromExp(e1);
        false = List.isMemberOnTrue(cr,crefs,ComponentReference.crefEqualNoStringCompare);
      then
        (e2,e1);
    // swapped arguments   
    case (DAE.BINARY(e1,op,e2),(crexp as DAE.CREF(componentRef = cr)))
      equation
        true = solve4(op);
        false = Expression.isZero(e2);
        crefs = Expression.extractCrefsFromExp(e2);
        false = List.isMemberOnTrue(cr,crefs,ComponentReference.crefEqualNoStringCompare);
      then
        (e1,e2);

  end matchcontinue;
end solve3;

protected function solve4
"function: solve4
  helper for solve3
  This function checks the operator"
  input DAE.Operator inOp;
  output Boolean outBool;
algorithm
  outBool := match (inOp)
    case DAE.MUL(_) then true;
    case DAE.MUL_ARR(_) then true;
    case DAE.DIV(_) then true;
    case DAE.DIV_ARR(_) then true;
  end match;
end solve4;

protected function hasOnlyFactors "help function to solve2, returns true if equation e1 == e2, has either e1 == 0 or e2 == 0 and the expression only contains
factors, e.g. a*b*c = 0. In this case we can not solve the equation"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    
    // try normal
    case(e1,e2) 
      equation
        true = Expression.isZero(e1);
        // More than two factors
        _::_::_ = Expression.factors(e2);
        //.. and more than two crefs
        _::_::_ = Expression.extractCrefsFromExp(e2);
      then 
        true;
      
    // swapped args
    case(e2,e1) 
      equation
        true = Expression.isZero(e1);
        _::_::_ = Expression.factors(e2);
        _::_::_ = Expression.extractCrefsFromExp(e2);
      then 
        true;
    
    case(_,_) then false;

  end matchcontinue;
end hasOnlyFactors;

protected function crOrDerCr "returns the component reference of CREF or der(CREF)"
  input DAE.Exp exp;
  output DAE.ComponentRef cr;
algorithm
  cr := match(exp)
    case(DAE.CREF(cr,_)) then cr;
    case(DAE.CALL(path=Absyn.IDENT("der"),expLst = {DAE.CREF(cr,_)})) then cr;
  end match;
end crOrDerCr;

protected function isInverseCref " Returns true if expression is 1/cr for a ComponentRef cr"
  input DAE.Exp e;
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(e,cr)
    local DAE.ComponentRef cr2; DAE.Exp e1;
    
    case(DAE.BINARY(e1,DAE.DIV(_),DAE.CREF(componentRef = cr2)),cr)
      equation
        true = Expression.isConstOne(e1);
        true = ComponentReference.crefEqual(cr,cr2);
      then 
        true;
    
    case(_,_) then false;

  end matchcontinue;
end isInverseCref;

end ExpressionSolve;

