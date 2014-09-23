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
protected import Differentiate;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;

public function solve
"Solves an equation consisting of a right hand side (rhs) and a
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
      list<DAE.Statement> asserts,asserts1;
/*
    case(_,_,_,_) // FOR DEBBUGING...
      equation
        print("Try to solve: rhs: " +&
          ExpressionDump.dumpExpStr(inExp1,0) +& " lhs: " +&
          ExpressionDump.dumpExpStr(inExp2,0) +& " with respect to: " +&
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
        //print("\t w.r.t ");print(ExpressionDump.printExpStr(inExp3));print(" failed\n");
      then
        fail();
  end matchcontinue;
end solve_work;

protected function solveSimple
"Solves simple equations like
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
    case (_,_,_)
      equation
        (outExp,outAsserts) = solveSimple2(inExp1,inExp2,inExp3);
      then (outExp,outAsserts);
    else /* swap arguments */
      equation
        (outExp,outAsserts) = solveSimple2(inExp2,inExp1,inExp3);
      then (outExp,outAsserts);
  end matchcontinue;
end solveSimple;

protected function solveSimple2
"Solves simple equations like
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
      DAE.ComponentRef cr,cr1;
      DAE.Type tp;
      DAE.Exp e1,e2,res,e11;
      Real r, r2;
      list<DAE.Statement> asserts;

    // special case for inital system when already solved, cr1 = $_start(...)
    case (DAE.CREF(componentRef = cr1),DAE.CALL(path = Absyn.IDENT(name = "$_start")),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
      then
        (inExp2,{});
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),DAE.CALL(path = Absyn.IDENT(name = "$_start")),DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
      then
        (inExp2,{});

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

    // log10(f(a)) = g(b) => f(a) = 10^(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "log10"),expLst = {e1}),_,DAE.CREF(componentRef = cr))
       equation
         true = Expression.expHasCref(e1, cr);
         false = Expression.expHasCref(inExp2, cr);
         e2 = DAE.BINARY(DAE.RCONST(10.0),DAE.POW(DAE.T_REAL_DEFAULT),inExp2);
         (res, asserts) = solve(e1,e2,inExp3);
       then (res, asserts);
    // log(f(a)) = g(b) => f(a) = exp(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "log"),expLst = {e1}),_,DAE.CREF(componentRef = cr))
       equation
         true = Expression.expHasCref(e1, cr);
         false = Expression.expHasCref(inExp2, cr);
         e2 = Expression.makePureBuiltinCall("exp",{inExp2},DAE.T_REAL_DEFAULT);
         (res, asserts) = solve(e1,e2,inExp3);
       then (res, asserts);
    // exp(f(a)) = g(b) => f(a) = log(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "exp"),expLst = {e1}),_,DAE.CREF(componentRef = cr))
       equation
         true = Expression.expHasCref(inExp1, cr);
         false = Expression.expHasCref(inExp2, cr);
         e2 = Expression.makePureBuiltinCall("log",{inExp2},DAE.T_REAL_DEFAULT);
         (res, asserts) = solve(e1,e2,inExp3);
       then (res, asserts);
    // sqrt(f(a)) = g(b) => f(a) = (g(b))^2
    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"),expLst = {e1}),_,DAE.CREF(componentRef = cr))
       equation
         true = Expression.expHasCref(e1, cr);
         false = Expression.expHasCref(inExp2, cr);
         tp = DAE.T_REAL_DEFAULT;
         res = DAE.RCONST(2.0);
         //e2 = DAE.BINARY(inExp2,DAE.POW(tp),res);
         e2 = Expression.expPow(inExp2,res);
         (res, asserts) = solve(e1,e2,inExp3);
       then (res, asserts);
    // semiLinear(0, a, b) = 0 => a = b // rule 1
    case (DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {DAE.RCONST(real = 0.0), e1, e2}),DAE.RCONST(real = 0.0),DAE.CREF(componentRef = cr))
       equation
         (res, asserts) = solve(e1,e2,inExp3);
       then (res, asserts);
    // (r1)^f(a) = r2 => f(a)  = ln(r2)/ln(r1)
    case (DAE.BINARY(e11 as DAE.RCONST(r),DAE.POW(_),e2), DAE.RCONST(r2), DAE.CREF(componentRef = cr))
       equation
         true = r2 >. 0.0;
         true = r >. 0.0;
         false = Expression.isConstOne(e11);
         true = Expression.expHasCref(e2, cr);
         e1 = Expression.makePureBuiltinCall("log",{e11},DAE.T_REAL_DEFAULT);
         res = Expression.makePureBuiltinCall("log",{inExp2},DAE.T_REAL_DEFAULT);
         res = Expression.makeDiv(res,e1);
         (res, asserts) = solve(e2,res,inExp3);
       then
         (res,asserts);
    // f(a)^b = 0 => f(a) = 0
    case (DAE.BINARY(e1,DAE.POW(_),e2), DAE.RCONST(real = 0.0), DAE.CREF(componentRef = cr))
       equation
         false = Expression.expHasCref(e2, cr);
         true = Expression.expHasCref(e1, cr);
         (res, asserts) = solve(e1,inExp2,inExp3);
       then
         (res,asserts);
    // f(a)^n = c => f(a) = c^(1/n)
    // where n is odd
    case (DAE.BINARY(e1,DAE.POW(_),e2 as DAE.RCONST(r)), _, DAE.CREF(componentRef = cr))
       equation
         1.0 = realMod(r,2.0);
         false = Expression.expHasCref(inExp2, cr);
         true = Expression.expHasCref(e1, cr);
         res = Expression.expDiv(DAE.RCONST(1.0),e2);
         res = Expression.expPow(inExp2,res);
         (res, asserts) = solve(e1,res,inExp3);
       then
         (res,asserts);

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

    // !cr = exp
    case (DAE.LUNARY(operator = DAE.NOT(ty=_), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp2,cr);
      then
        (Expression.negate(inExp2),{});

    // Integer(enumcr) = ...
    case (DAE.CALL(path = Absyn.IDENT(name = "Integer"),expLst={DAE.CREF(componentRef = cr1)}),_,DAE.CREF(componentRef = cr,ty=tp))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        // cr not in e2
        false = Expression.expHasCrefNoPreorDer(inExp2,cr);
        asserts = generateAssertType(tp,cr,inExp3,{});
      then (DAE.CAST(tp,inExp2),asserts);
      else fail();
  end matchcontinue;
end solveSimple2;

protected function solve2
"This function solves an equation e1 = e2 with
  respect to the variable given as an expression e3"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input Boolean linearExps;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := matchcontinue (inExp1,inExp2,inExp3,linearExps)
    case (_,_,_,_)
      equation
        (outExp,outAsserts) = solve2_1(inExp1,inExp2,inExp3,linearExps);
      then (outExp,outAsserts);
    else /* swap arguments */
      equation
        (outExp,outAsserts) = solve2_1(inExp2,inExp1,inExp3,linearExps);
      then (outExp,outAsserts);

  end matchcontinue;
end solve2;

protected function solve2_1
"This function solves an equation e1 = e2 with
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
      DAE.Exp dere,e,z,a;
      DAE.ComponentRef cr;
      DAE.Exp invCr,e1,e2,e3,res,lhs,rhs;
      DAE.Type tp;
      list<DAE.Exp> factors;
      list<DAE.Statement> asserts,asserts1,asserts2;

     // cr = (e1-e2)/(der(e1-e2,cr))
    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        false = hasOnlyFactors(inExp1,inExp2);
        e = Expression.makeDiff(inExp1,inExp2);
        (e,_) = ExpressionSimplify.simplify1(e);
        ({},_) = List.split1OnTrue(Expression.factors(e),isCrefInIFEXP,cr); // check: differentiateExpSolve is allowed
        dere = Differentiate.differentiateExpSolve(e, cr);
        (dere,_) = ExpressionSimplify.simplify(dere);
        false = Expression.isZero(dere);
        false = Expression.expHasCrefNoPreorDer(dere, cr);
        tp = Expression.typeof(inExp3);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        ((e,_)) = Expression.replaceExp(e, inExp3, z);
        (e,_) = ExpressionSimplify.simplify(e);
        rhs = Expression.negate(Expression.makeDiv(e,dere));
      then
        (rhs,{});

     // a*(1/b)*c*...*n = rhs
    case(_,_,DAE.CREF(componentRef = cr),_)
      equation
        ({_},factors) = List.split1OnTrue(Expression.factors(inExp1),isInverseCref,cr);
        e = Expression.inverseFactors(inExp2);
        rhs = Expression.makeProductLst(e::factors);
        false = Expression.expHasCrefNoPreorDer(rhs, cr);
      then (rhs,{});
    // f(a) = g(a) => f(a) - g(a) = 0
    case(_,_,DAE.CREF(componentRef = cr),_)
     equation
        true = Expression.expHasCref(inExp1, cr);
        true = Expression.expHasCref(inExp2, cr);
        lhs = Expression.expSub(inExp1,inExp2);
        tp = Expression.typeof(inExp2);
        rhs = Expression.makeConstZero(tp);
        (res,asserts) = solve(lhs,rhs,inExp3);
       then (res, asserts);
    // f(a)*b = rhs  => f(a) = rhs/b solve for a
    case(DAE.BINARY(e1,DAE.MUL(_),e2),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 = Expression.makeDiv(inExp2,e2);
        (res,asserts) = solve(e1,e3,inExp3);
       then (res, asserts);
    // b*f(a) = rhs  => f(a) = rhs/b solve for a
    case(DAE.BINARY(e2,DAE.MUL(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 = Expression.makeDiv(inExp2,e2);
        (res,asserts) = solve(e1,e3,inExp3);
       then(res, asserts);
    // f(a)/b = rhs  => f(a) = rhs*b solve for a
    case(DAE.BINARY(e1,DAE.DIV(_),e2),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 = Expression.expMul(inExp2,e2);
        (res,asserts) = solve(e1,e3,inExp3);
       then (res, asserts);
    // b/f(a) = rhs  => f(a) = b/rhs solve for a
    case(DAE.BINARY(e2,DAE.DIV(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 = Expression.makeDiv(e2,inExp2);
        (res,asserts) = solve(e1,e3,inExp3);
       then(res, asserts);
    // g(a)/f(a) = rhs  => f(a)*rhs - g(a) = 0  solve for a
    case(DAE.BINARY(e2,DAE.DIV(tp),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        (e1,_) = ExpressionSimplify.simplify1(e1);
        (e2,_) = ExpressionSimplify.simplify1(e2);
        e3 = Expression.expMul(e1,inExp2);
        (e3,_) = ExpressionSimplify.simplify1(e3);
        e3 =  Expression.makeDiff(e3,e2);
        e1 = Expression.makeConstZero(tp);
        (res,asserts) = solve(e3,e1,inExp3);
       then(res, asserts);
    // f(a) + b = c => f(a) = c - b
    case(DAE.BINARY(e1,DAE.ADD(_),e2),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 =  Expression.makeDiff(inExp2,e2);
        (e3,_) = ExpressionSimplify.simplify(e3);
        (res,asserts) = solve(e1,e3,inExp3);
      then(res, asserts);
    // f(a) - b = c => f(a) = c + b
    case(DAE.BINARY(e1,DAE.SUB(_),e2),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 = Expression.expAdd(inExp2,e2);
        (res,asserts) = solve(e1,e3,inExp3);
      then(res, asserts);
    // b + f(a) = c => f(a) = c - b
    case(DAE.BINARY(e2,DAE.ADD(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        false = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 =  Expression.makeDiff(inExp2,e2);
        (e3,_) = ExpressionSimplify.simplify(e3);
        (res,asserts) = solve(e1,e3,inExp3);
      then(res, asserts);
    // b - f(a) = c => f(a) = b - c
    case(DAE.BINARY(e2,DAE.SUB(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(inExp2, cr);
        e3 =  Expression.makeDiff(e2,inExp2);
        (e3,_) = ExpressionSimplify.simplify(e3);
        (res,asserts) = solve(e1,e3,inExp3);
       then(res, asserts);
    // g(a) + f(a)/c = d => g(a)*c + f(a) = d*c
    case(DAE.BINARY(e1,DAE.ADD(_),
      DAE.BINARY(e2,DAE.DIV(_),e3)),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(e3, cr);
        false = Expression.expHasCref(inExp2, cr);
        rhs =  Expression.expMul(inExp2,e3);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.expAdd(lhs,e2);
        (res,asserts) = solve(lhs,rhs,inExp3);
      then(res, asserts);
    // f(a)/c + g(a) = d => g(a)*c + f(a) = d*c
    case(DAE.BINARY(DAE.BINARY(e2,DAE.DIV(_),e3),DAE.ADD(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(e3, cr);
        false = Expression.expHasCref(inExp2, cr);
        rhs =  Expression.expMul(inExp2,e3);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.expAdd(lhs,e2);
        (res,asserts) = solve(lhs,rhs,inExp3);
      then(res, asserts);
    // g(a) - f(a)/c = d => g(a)*c - f(a) = d*c
    case(DAE.BINARY(e1,DAE.SUB(_),DAE.BINARY(e2,DAE.DIV(_),e3)),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(e3, cr);
        false = Expression.expHasCref(inExp2, cr);
        rhs =  Expression.expMul(inExp2,e3);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.makeDiff(lhs,e2);
        (res,asserts) = solve(lhs,rhs,inExp3);
      then(res, asserts);
    // f(a)/c - g(a) = d => f(a) - g(a)*c  = d*c
    case(DAE.BINARY(DAE.BINARY(e2,DAE.DIV(_),e3),DAE.SUB(_),e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        true = Expression.expHasCref(e2, cr);
        false = Expression.expHasCref(e3, cr);
        false = Expression.expHasCref(inExp2, cr);
        rhs =  Expression.expMul(inExp2,e3);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.makeDiff(e2, lhs);
        (res,asserts) = solve(lhs,rhs,inExp3);
      then(res, asserts);
    // -f(a) = b => f(a) = -b
    case(DAE.UNARY(DAE.UMINUS(ty=tp), e1),_,DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e1, cr);
        false = Expression.expHasCref(inExp2, cr);
        e2 = DAE.UNARY(DAE.UMINUS(tp),inExp2);
        (res,asserts) = solve(e1,e2,inExp3);
      then(res, asserts);

    // 0 = a*(b-c)  solve for b
    case (_,_,DAE.CREF(componentRef = _),_)
      equation
        true = Expression.isZero(inExp1);
        (e,a) = solve3(inExp2,inExp3);
        tp = Expression.typeof(e);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (rhs,asserts) = solve(e,z,inExp3);
        asserts = generateAssertZero(inExp1,inExp2,inExp3,a,asserts);
      then
        (rhs,asserts);
    //  f(a) if(g(b)) then f1(a) else f2(a) =>
    //  lhs = solve(f(a),f1(a)) for a
    //  rhs = solve(f(a),f2(a)) for a
    //  => a = if g(b) then a1 else a2
    case (DAE.IFEXP(e1,e2,e3),_,DAE.CREF(componentRef = cr),_)
      equation
        false = Expression.expHasCref(e1, cr);
        (lhs,asserts) = solve_work(e2,inExp2,inExp3,linearExps);
        (rhs,asserts1) = solve_work(e3,inExp2,inExp3,linearExps);
        (res,_) = ExpressionSimplify.simplify1(DAE.IFEXP(e1,lhs,rhs));
        asserts2 = listAppend(asserts,asserts1);
      then
        (res,asserts2);
    // f(a) = b  => simplify1(f(a)) = b
    case(_,_,DAE.CREF(componentRef = cr),_)
     equation
        true = Expression.expHasCref(inExp1, cr);
        false = Expression.expHasCref(inExp2, cr);
        (lhs,true) = ExpressionSimplify.simplify1(inExp1);
        (rhs,_) = ExpressionSimplify.simplify1(inExp2);
        (res,asserts) = solve(lhs,rhs,inExp3);
       then (res, asserts);

    // if simplify1 fails for simplify f(a)/h(a)
    // try to expand 
    // g(.) + f(.)/h(a) = 0 => g(.)*h(a) + f(.) = 0
    case(DAE.BINARY(e1,DAE.ADD(_),
      DAE.BINARY(e2,DAE.DIV(_),e3)),DAE.RCONST(real =0.0),DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e3, cr);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.expAdd(lhs,e2);
        (res,asserts) = solve(lhs,inExp2,inExp3);
      then(res, asserts);
    // f(.)/h(a) + g(.) = 0.0 => g(.)*h(a) + f(.) = 0.0
    case(DAE.BINARY(DAE.BINARY(e2,DAE.DIV(_),e3),DAE.ADD(_),e1),DAE.RCONST(real = 0.0),DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e3, cr);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.expAdd(lhs,e2);
        (res,asserts) = solve(lhs, inExp2, inExp3);
      then(res, asserts);
    // g(.) - f(.)/h(a) = 0.0 => g(.)*h(a) - f(.) = 0.0
    case(DAE.BINARY(e1,DAE.SUB(_),DAE.BINARY(e2,DAE.DIV(_),e3)),DAE.RCONST(0.0),DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e3, cr);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.makeDiff(lhs,e2);
        (res,asserts) = solve(lhs,inExp2,inExp3);
      then(res, asserts);
    // f(.)/h(a) - g(.) = 0.0 => f(.) - g(.)*h(a)  = 0.0
    case(DAE.BINARY(DAE.BINARY(e2,DAE.DIV(_),e3),DAE.SUB(_),e1),DAE.RCONST(0.0),DAE.CREF(componentRef = cr),_)
      equation
        true = Expression.expHasCref(e3, cr);
        lhs =  Expression.expMul(e1,e3);
        lhs =  Expression.makeDiff(e2, lhs);
        (res,asserts) = solve(lhs,inExp2,inExp3);
      then(res, asserts);

    // a^b = f(..) -> a = (if pre(a)==0 then 1 else sign(pre(a)))*(f(...)^(1/b))
    // does not work because not all have pre in code generation
/*    case (_,_,DAE.CREF(componentRef = cr),_)
      equation
        e = Expression.makeDiff(inExp1,inExp2);
        ((e,(_,false,SOME(a)))) = Expression.traverseExpTopDown(e, traversingVarOnlyinPow, (cr,false,NONE()));
        DAE.BINARY(operator=DAE.POW(ty=tp1),exp2 = a) = a;
        // check if a is even number integer
        r = Expression.expReal(a);
        i = realInt(r);
        true = realEq(intReal(i),r);
        true = intEq(intMod(i,2),0);
        tp = Expression.typeof(e);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (rhs,asserts) = solve(e,z,inExp3);
        a = Expression.expDiv(DAE.RCONST(1.0),a);
        rhs = DAE.BINARY(rhs,DAE.POW(tp1),a);
        tp = Expression.typeof(inExp3);
        dere = Expression.makePureBuiltinCall("pre",{inExp3},tp);
        dere = Expression.makePureBuiltinCall("sign",{dere},DAE.T_INTEGER_DEFAULT);
        dere = DAE.IFEXP(DAE.RELATION(dere,DAE.EQUAL(tp),DAE.RCONST(0.0),-1,NONE()),DAE.RCONST(1.0),dere);
        rhs = Expression.expMul(dere,rhs);
      then
        (rhs,asserts);
*//*
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
     else fail();
  end matchcontinue;
end solve2_1;

// protected function traversingVarOnlyinPow "
// @author: Frenkel TUD 2011-04
// Returns true if in the exp the componentRef is only in pow"
//   input tuple<DAE.Exp, tuple<DAE.ComponentRef,Boolean,Option<DAE.Exp>>> inExp;
//   output tuple<DAE.Exp, Boolean, tuple<DAE.ComponentRef,Boolean,Option<DAE.Exp>>> outExp;
// algorithm
//   outExp := matchcontinue(inExp)
//     local
//       Boolean b;
//       DAE.ComponentRef cr,cr1;
//       DAE.Exp e,e1,e2;
//       Option<DAE.Exp> oe;
//
//     case ((e as DAE.BINARY(exp1 = e1 as DAE.CREF(componentRef = cr1),operator = DAE.POW(_),exp2 = e2), (cr,false,NONE())))
//       equation
//         true = ComponentReference.crefPrefixOf(cr1,cr);
//         false = Expression.expHasCrefNoPreorDer(e2, cr);
//       then
//         ((e1,false,(cr,false,SOME(e))));
//
//     case ((e as DAE.CREF(componentRef = cr1), (cr,false,oe)))
//       equation
//         b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
//       then
//         ((e,not b,(cr,b,oe)));
//
//     case ((e as DAE.CREF(componentRef = cr1), (cr,false,oe)))
//       equation
//         b = ComponentReference.crefPrefixOf(cr1,cr);
//       then
//         ((e,not b,(cr,b,oe)));
//
//     case (((e,(cr,b,oe)))) then ((e,not b,(cr,b,oe)));
//
//   end matchcontinue;
// end traversingVarOnlyinPow;

protected function generateAssertZero
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input DAE.Exp a;
  input list<DAE.Statement> inAsserts;
  output list<DAE.Statement> outAsserts;
algorithm
  outAsserts := matchcontinue (inExp1,inExp2,inExp3,a,inAsserts)
    local
      DAE.Exp z;
      DAE.Type tp;
      String estr,se1,se2,se3,sa;
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
        se3 = ExpressionDump.printExpStr(inExp3);
        sa = ExpressionDump.printExpStr(a);
        estr = stringAppendList({"Singular expression ",se1," = ",se2," because ",sa," is Zero! When solving for exp: ", se3, "."});
      then
        DAE.STMT_ASSERT(DAE.RELATION(a,DAE.NEQUAL(tp),z,-1,NONE()),DAE.SCONST(estr),DAE.ASSERTIONLEVEL_WARNING,DAE.emptyElementSource)::inAsserts;
  end matchcontinue;
end generateAssertZero;

protected function generateAssertType
  input DAE.Type tp;
  input DAE.ComponentRef cr;
  input DAE.Exp iExp;
  input list<DAE.Statement> inAsserts;
  output list<DAE.Statement> outAsserts;
algorithm
  outAsserts := match(tp,cr,iExp,inAsserts)
    local
      Absyn.Path path,p1,pn;
      list<String> names;
      Integer n;
      DAE.Exp e1,en,e,es;
      String s1,sn,se,estr,crstr;
    case (DAE.T_ENUMERATION(path=path,names=names),_,_,_)
      equation
        p1 = Absyn.suffixPath(path,listGet(names,1));
        e1 = DAE.ENUM_LITERAL(p1,1);
        n = listLength(names);
        pn = Absyn.suffixPath(path,listGet(names,n));
        en = DAE.ENUM_LITERAL(p1,n);
        s1 = Absyn.pathString(p1);
        sn = Absyn.pathString(pn);
        _ = ExpressionDump.printExpStr(iExp);
        crstr = ComponentReference.printComponentRefStr(cr);
        estr = "Expression for " +& crstr +& " out of min(" +& s1 +& ")/max(" +& sn +& ") = ";
        // iExp >= e1 and iExp <= en
        e = DAE.LBINARY(DAE.RELATION(iExp,DAE.GREATEREQ(DAE.T_INTEGER_DEFAULT),e1,-1,NONE()),DAE.AND(DAE.T_BOOL_DEFAULT),
                                     DAE.RELATION(iExp,DAE.LESSEQ(DAE.T_INTEGER_DEFAULT),en,-1,NONE()));
        es = Expression.makePureBuiltinCall("String", {iExp,DAE.SCONST("d")}, DAE.T_STRING_DEFAULT);
        es = DAE.BINARY(DAE.SCONST(estr),DAE.ADD(DAE.T_STRING_DEFAULT),es);
      then
        DAE.STMT_ASSERT(e,es,DAE.ASSERTIONLEVEL_ERROR,DAE.emptyElementSource)::inAsserts;
    else inAsserts;
  end match;
end generateAssertType;

protected function solve3
"helper for solve2
  This function checks if one part of a product expression
  does not contain inExp2"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
  output DAE.Exp outExp1;
algorithm
  (outExp,outExp1) := matchcontinue (inExp1,inExp2)
    local
      DAE.Exp e1,e2;
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
"helper for solve3
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
        true = Expression.isZero(e2);
        _::_::_ = Expression.factors(e1);
        _::_::_ = Expression.extractCrefsFromExp(e1);
      then
        true;

    else false;

  end matchcontinue;
end hasOnlyFactors;


protected function isCrefInIFEXP " Returns true if expression is DAE.IFEXP(f(cr)) or e.g. sign(f(cr)) for cr = incr"
  input DAE.Exp e;
  input DAE.ComponentRef incr;
  output Boolean res;
  algorithm
  res := isCrefInIFEXPwork(e, incr, false);
end isCrefInIFEXP;

protected function isCrefInIFEXPwork " helper for isCrefInIFEXP"
  input DAE.Exp e;
  input DAE.ComponentRef incr;
  input Boolean inres;
  output Boolean res;
  algorithm
  res := match(e,incr, inres)
  local DAE.Exp e1, e2; Boolean b;

    case(_,_,true) then true;
    case(DAE.BINARY(e1, DAE.ADD(_),e2),_,_)
      equation
        b = isCrefInIFEXPwork(e1,incr, inres);
        b = isCrefInIFEXPwork(e2,incr, b);
      then b;
    case(DAE.BINARY(e1, DAE.SUB(_),e2),_,_)
      equation
        b = isCrefInIFEXPwork(e1,incr, inres);
        b = isCrefInIFEXPwork(e2,incr, b);
      then b;
    case(DAE.IFEXP(e1,_,_),_,_) then Expression.expHasCref(e1, incr);
    case(DAE.CALL(path = Absyn.IDENT(name = "sign"),expLst = {e1}),_,_) then Expression.expHasCref(e1, incr);
    case(DAE.CALL(path = Absyn.IDENT(name = "smooth"),expLst = {_,e1}),_,_) then isCrefInIFEXPwork(e1,incr,inres);
    case(DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {e1,_,_}),_,_)then Expression.expHasCref(e1,incr);
    case(DAE.CAST(exp =e1),_,_) then isCrefInIFEXPwork(e1,incr,inres);
    case(_,_,_) then false;
  end match;
end isCrefInIFEXPwork;

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

    else false;

  end matchcontinue;
end isInverseCref;

end ExpressionSolve;

