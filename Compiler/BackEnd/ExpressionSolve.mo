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
" file:        ExpressionSolve.mo
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
protected import Flags;
protected import List;

public function solve
"function: solve
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := solve_work(inExp1,inExp2,inExp3,false);
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
  (outExp,outAsserts) := solve_work(inExp1,inExp2,inExp3,true);
end solveLin;

protected function solve_work
"function: solve linear equation
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input Boolean linearExps "If true, allow differentiation of if-expressions";
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3,linearExps)
    local
      DAE.Exp rhs,lhs,res,e1,e2,e3,crexp;
      DAE.ComponentRef cr,cr1;
      list<DAE.Statement> asserts,asserts1,asserts2;
/*    
    case(_,_,_,_) // FOR DEBBUGING...
      equation
        print("Try to solve: rhs: " +&
          ExpressionDump.printExpStr(inExp1) +& " lhs: " +&
          ExpressionDump.printExpStr(inExp2) +& " with respect to: " +&
          ExpressionDump.printExpStr(inExp3) +& "\n");
      then
        fail();
*/    
    // try simple cases
    case (_,_,_,_)
      equation
        (res,asserts) = solveSimple(inExp1,inExp2,inExp3);
        (res,_) = ExpressionSimplify.simplify1(res);
      then
        (res,asserts);

    // solving linear equation system using newton iteration ( converges directly )
    case (_,_,DAE.CREF(componentRef = _),_)
      equation
        (res,asserts) = solve2(inExp1, inExp2, inExp3, linearExps);
        (res,_) = ExpressionSimplify.simplify1(res);
      then
        (res,asserts);
    case (_,_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),_)
      equation
        cr1 = ComponentReference.crefPrefixDer(cr);
        crexp = Expression.crefExp(cr1);
        ((lhs,_)) = Expression.replaceExp(inExp1, inExp3, crexp);
        ((rhs,_)) = Expression.replaceExp(inExp2, inExp3, crexp);
        (res,asserts) = solve2(lhs, rhs, crexp, linearExps);
        (res,_) = ExpressionSimplify.simplify1(res);
      then
        (res,asserts);        
    
    case (_,DAE.IFEXP(e1,e2,e3),_,_)
      equation
        (lhs,asserts) = solve_work(inExp1,e2,inExp3,linearExps);
        (rhs,asserts1) = solve_work(inExp1,e3,inExp3,linearExps);
        (res,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,lhs,rhs));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res,asserts2);
    
    case (DAE.IFEXP(e1,e2,e3),_,_,_)
      equation
        (lhs,asserts) = solve_work(e2,inExp2,inExp3,linearExps);
        (rhs,asserts1) = solve_work(e3,inExp2,inExp3,linearExps);
        (res,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,lhs,rhs));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res,asserts2);
/*
    case(_,_,_,_)
      equation
        print("solve " +& ExpressionDump.printExpStr(inExp1) +& " = " +& ExpressionDump.printExpStr(inExp2) +& " for " +& ExpressionDump.printExpStr(inExp3) +& " failed\n");
      then
        fail();
*/        
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "-ExpressionSolve.solve failed\n");
        //print("solve ");print(ExpressionDump.printExpStr(inExp1));print(" = ");print(ExpressionDump.printExpStr(inExp2));
        //print(" w.r.t ");print(ExpressionDump.printExpStr(inExp3));print(" failed\n");
      then
        fail();
  end matchcontinue;
end solve_work;

protected function solveSimple
"function: solveSimple
  Solves simple equations like 
  a = f(..)
  der(a) = f(..)
  -a = f(..)
  -der(a) = f(..)"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp res;
      DAE.ComponentRef cr,cr1;
    
    // special case when already solved, cr1 = rhs, otherwise division by zero when dividing with derivative
    case (DAE.CREF(componentRef = cr1),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(inExp2, cr);
      then
        (inExp2,{});
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        false = Expression.expHasDerCref(inExp2, cr);
      then
        (inExp2,{});

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (_,DAE.CREF(componentRef = cr1),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(inExp1, cr);
      then
        (inExp1,{});
    case (_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        false = Expression.expHasDerCref(inExp2, cr);
      then
        (inExp1,{});
    // -cr = exp    
    case (DAE.UNARY(operator = DAE.UMINUS(ty=_), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty=_), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS(ty=_), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasDerCref(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty=_), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasDerCref(inExp2,cr);
      then
        (Expression.negate(inExp2),{});        

    // exp = -cr
    case (_,DAE.LUNARY(operator = DAE.UMINUS(ty=_), exp = DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp1,cr);
      then
        (Expression.negate(inExp1),{});
    case (_,DAE.LUNARY(operator = DAE.UMINUS_ARR(ty=_), exp = DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp1,cr);
      then
        (Expression.negate(inExp1),{});
    case (_,DAE.UNARY(operator = DAE.UMINUS(ty=_), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasDerCref(inExp1,cr);
      then
        (Expression.negate(inExp1),{});
    case (_,DAE.UNARY(operator = DAE.UMINUS_ARR(ty=_), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasDerCref(inExp1,cr);
      then
        (Expression.negate(inExp1),{});

    // !cr = exp    
    case (DAE.LUNARY(operator = DAE.NOT(ty=_), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    // exp = !cr    
    case (_,DAE.LUNARY(operator = DAE.NOT(ty=_), exp = DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp1,cr);
      then
        (Expression.negate(inExp1),{});

  end matchcontinue;
end solveSimple;


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
      DAE.Exp lhs,dere,zeroe,rhs,e,z,a;
      DAE.ComponentRef cr,cr1;
      DAE.Exp invCr;
      DAE.Type tp,tp1;
      list<DAE.Exp> factors;
      list<DAE.Statement> asserts;
    
     // cr = (e1(0)-e2(0))/(der(e1-e2,cr)) 
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        false = hasOnlyFactors(inExp1,inExp2);
        e = Expression.makeDiff(inExp1,inExp2);
        dere = Derive.differentiateExp(e, cr, linearExps, NONE());
        (dere,_) = ExpressionSimplify.simplify(dere);
        false = Expression.isZero(dere);
        false = Expression.expHasCrefNoPreorDer(dere, cr);
        tp = Expression.typeof(inExp3);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        ((zeroe,_)) = Expression.replaceExp(e, inExp3, z);
        (zeroe,_) = ExpressionSimplify.simplify(zeroe);
        rhs = Expression.negate(Expression.makeDiv(zeroe,dere));
      then
        (rhs,{});

      // a*(1/b)*c*...*n = rhs
    case(_,_,DAE.CREF(componentRef = cr),_)
      equation
        ({invCr},factors) = List.split1OnTrue(Expression.factors(inExp1),isInverseCref,cr);
        e = Expression.inverseFactors(inExp2);
        rhs = Expression.makeProductLst(e::factors);
        false = Expression.expHasCrefNoPreorDer(rhs, cr);
      then (rhs,{});

      // lhs = a*(1/b)*c*...*n
    case(_,_,DAE.CREF(componentRef = cr),_)
      equation
        ({invCr},factors) = List.split1OnTrue(Expression.factors(inExp2),isInverseCref,cr);
        e = Expression.inverseFactors(inExp1);
        rhs = Expression.makeProductLst(e::factors);
        false = Expression.expHasCrefNoPreorDer(rhs, cr);
      then (rhs,{});

    // 0 = a*(b-c)  solve for b    
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.isZero(inExp1);
        (e,a) = solve3(inExp2,inExp3);
        tp = Expression.typeof(e);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (rhs,asserts) = solve(e,z,inExp3);
        asserts = generateAssert(inExp1,inExp2,inExp3,a,asserts);
      then
        (rhs,asserts);
       
    // swapped args: a*(b-c) = 0  solve for b     
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.isZero(inExp2);
        (e,a) = solve3(inExp1,inExp3);
        tp = Expression.typeof(e);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (rhs,asserts) = solve(e,z,inExp3);
        asserts = generateAssert(inExp1,inExp2,inExp3,a,asserts);
      then
        (rhs,asserts);
        
    // a^b = f(..) -> a = sign(pre(a))*(f(...)^(1/b))   
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        e = Expression.makeDiff(inExp1,inExp2);
        ((e,(_,false,SOME(DAE.BINARY(operator=DAE.POW(tp1),exp2 = a))))) = Expression.traverseExpTopDown(e, traversingVarOnlyinPow, (cr,false,NONE()));
        tp = Expression.typeof(e);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (rhs,asserts) = solve(e,z,inExp3);
        a = Expression.expDiv(DAE.RCONST(1.0),a);
        rhs = DAE.BINARY(rhs,DAE.POW(tp1),a);
        tp = Expression.typeof(inExp3);                   
        dere = Expression.makeBuiltinCall("pre",{inExp3},tp);
        dere = Expression.makeBuiltinCall("sign",{dere},DAE.T_INTEGER_DEFAULT);
        rhs = Expression.expMul(dere,rhs);
      then
        (rhs,asserts);        
/*
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        e = Expression.makeDiff(inExp1,inExp2);
        dere = Derive.differentiateExp(e, cr, linExp, NONE());
        (dere,_) = ExpressionSimplify.simplify(dere);
        true = Expression.expContains(dere, inExp3);
        print("solve2 failed: Not linear: ");
        print(ExpressionDump.printExpStr(e1));
        print(" = ");
        print(ExpressionDump.printExpStr(e2));
        print("\nsolving for: ");
        print(ExpressionDump.printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(ExpressionDump.printExpStr(lhsder));
        print("\n");
      then
        fail();
*/    
    /*
    case (_,_,DAE.CREF(componentRef = cr), _)
      equation
        e = Expression.makeDiff(inExp1,inExp2);
        dere = Derive.differentiateExp(e, cr, linExp, NONE());
        (dere,_) = ExpressionSimplify.simplify(dere);
        print("solve2 failed: ");
        print(ExpressionDump.printExpStr(e1));
        print(" = ");
        print(ExpressionDump.printExpStr(e2));
        print("\nsolving for: ");
        print(ExpressionDump.printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(ExpressionDump.printExpStr(lhsder_1));
        print("\n");
      then
        fail();
     */
  end matchcontinue;
end solve2;

protected function traversingVarOnlyinPow "
@author: Frenkel TUD 2011-04
Returns true if in the exp the componentRef is only in pow"
  input tuple<DAE.Exp, tuple<DAE.ComponentRef,Boolean,Option<DAE.Exp>>> inExp;
  output tuple<DAE.Exp, Boolean, tuple<DAE.ComponentRef,Boolean,Option<DAE.Exp>>> outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      Boolean b;
      DAE.ComponentRef cr,cr1;
      DAE.Exp e,e1,e2;
      Option<DAE.Exp> oe;

    case ((e as DAE.BINARY(exp1 = e1 as DAE.CREF(componentRef = cr1),operator = DAE.POW(_),exp2 = e2), (cr,false,NONE())))
      equation
        true = ComponentReference.crefPrefixOf(cr1,cr);
        false = Expression.expHasCrefNoPreorDer(e2, cr);
      then
        ((e1,false,(cr,false,SOME(e))));
   
    case ((e as DAE.CREF(componentRef = cr1), (cr,false,oe)))
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
      then
        ((e,not b,(cr,b,oe)));
    
    case ((e as DAE.CREF(componentRef = cr1), (cr,false,oe)))
      equation
        b = ComponentReference.crefPrefixOf(cr1,cr);
      then
        ((e,not b,(cr,b,oe)));    
    
    case (((e,(cr,b,oe)))) then ((e,not b,(cr,b,oe)));
    
  end matchcontinue;
end traversingVarOnlyinPow;

protected function generateAssert
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input DAE.Exp a;
  input list<DAE.Statement> inAsserts;
  output list<DAE.Statement> outAsserts;
algorithm
  outAsserts := matchcontinue (inExp1,inExp2,inExp3,a,inAsserts)
    local
      DAE.Exp a,z;
      DAE.Type tp;
      list<DAE.Statement> asserts;
      String estr,se1,se2,sa;
    case (_,_,_,_,_)
      equation
        // zero check already done
        true = Expression.isConst(a);
      then
        inAsserts;
    else
      equation    
        tp = Expression.typeof(a);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        se1 = ExpressionDump.printExpStr(inExp2);
        se2 = ExpressionDump.printExpStr(inExp1);
        sa = ExpressionDump.printExpStr(a);
        estr = stringAppendList({"Singular expression ",se1," = ",se2," because ",sa," is Zero!"});
      then
        DAE.STMT_ASSERT(DAE.RELATION(a,DAE.NEQUAL(tp),z,-1,NONE()),DAE.SCONST(estr),DAE.ASSERTIONLEVEL_ERROR,DAE.emptyElementSource)::inAsserts;
  end matchcontinue;
end generateAssert;

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
      DAE.Operator op;
    
    case (DAE.BINARY(e1,op,e2),DAE.CREF(componentRef = cr))
      equation
        true = solve4(op);
        false = Expression.isZero(e1);
        false = Expression.expHasCrefNoPreorDer(e1, cr);
      then
        (e2,e1);
    // swapped arguments   
    case (DAE.BINARY(e1,op,e2),DAE.CREF(componentRef = cr))
      equation
        true = solve4(op);
        false = Expression.isZero(e2);
        false = Expression.expHasCrefNoPreorDer(e2, cr);
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
    case(_,_) 
      equation
        true = Expression.isZero(e1);
        // More than two factors
        _::_::_ = Expression.factors(e2);
        //.. and more than two crefs
        _::_::_ = Expression.extractCrefsFromExp(e2);
      then 
        true;
      
    // swapped args
    case(_,_) 
      equation
        true = Expression.isZero(e1);
        _::_::_ = Expression.factors(e2);
        _::_::_ = Expression.extractCrefsFromExp(e2);
      then 
        true;
    
    else then false;

  end matchcontinue;
end hasOnlyFactors;

protected function isInverseCref " Returns true if expression is 1/cr for a ComponentRef cr"
  input DAE.Exp e;
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(e,cr)
    local DAE.ComponentRef cr2; DAE.Exp e1;
    
    case(DAE.BINARY(e1,DAE.DIV(_),DAE.CREF(componentRef = cr2)),_)
      equation
        true = Expression.isConstOne(e1);
        true = ComponentReference.crefEqual(cr,cr2);
      then 
        true;

    case(DAE.BINARY(e1,DAE.DIV_ARR(_),DAE.CREF(componentRef = cr2)),_)
      equation
        true = Expression.isConstOne(e1);
        true = ComponentReference.crefEqual(cr,cr2);
      then 
        true;

    case(DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(_),DAE.CREF(componentRef = cr2)),_)
      equation
        true = Expression.isConstOne(e1);
        true = ComponentReference.crefEqual(cr,cr2);
      then 
        true;
    
    else then false;

  end matchcontinue;
end isInverseCref;

end ExpressionSolve;

