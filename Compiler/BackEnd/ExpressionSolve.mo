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
protected import Inline;

public function solve
"Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
protected
  list<BackendDAE.Equation> dummy1;
  list<DAE.ComponentRef> dummy2;
  Integer dummyI;
algorithm
/*
  print("Try to solve: rhs: " +
  ExpressionDump.dumpExpStr(inExp1,0) + " lhs: " +
  ExpressionDump.dumpExpStr(inExp2,0) + " with respect to: " +
  ExpressionDump.printExpStr(inExp3) + "\n");
*/
 (outExp,outAsserts,dummy1, dummy2, dummyI) := matchcontinue(inExp1, inExp2, inExp3)
                        case(_,_,_) then  solveSimple(inExp1, inExp2, inExp3,0);
                        case(_,_,_) then  solveSimple(inExp2, inExp1, inExp3,0);
                        case(_,_,_) then  solveWork(inExp1, inExp2, inExp3, NONE(), NONE(), 0);
                        else
                          equation
                           if Flags.isSet(Flags.FAILTRACE) then
                            print("\n-ExpressionSolve.solve failed:\n");
                            print(ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2));
                            print(" with respect to: " + ExpressionDump.printExpStr(inExp3));
                           end if;
                        then fail();
                        end matchcontinue;

 (outExp,_) := ExpressionSimplify.simplify1(outExp);

end solve;


public function solve2
"Solves an equation with modelica function consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable.
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input Option<DAE.FunctionTree> functions "need for solve modelica functions";
  input Option<Integer> uniqueEqIndex "offset for tmp vars";
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
  output list<BackendDAE.Equation> eqnForNewVars "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs;
protected
  Integer dummyI;
algorithm
/*
  print("Try to solve: rhs: " +
  ExpressionDump.dumpExpStr(inExp1,0) + " lhs: " +
  ExpressionDump.dumpExpStr(inExp2,0) + " with respect to: " +
  ExpressionDump.printExpStr(inExp3) + "\n");
*/
 (outExp,outAsserts,eqnForNewVars,newVarsCrefs,dummyI) := matchcontinue(inExp1, inExp2, inExp3, functions, uniqueEqIndex)
                        case(_,_,_,_,_) then  solveSimple(inExp1, inExp2, inExp3,0);
                        case(_,_,_,_,_) then  solveSimple(inExp2, inExp1, inExp3,0);
                        case(_,_,_,_,_) then  solveWork(inExp1, inExp2, inExp3, functions, uniqueEqIndex, 0);
                        else
                          equation
                           if Flags.isSet(Flags.FAILTRACE) then
                            print("\n-ExpressionSolve.solve failed:\n");
                            print(ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2));
                            print(" with respect to: " + ExpressionDump.printExpStr(inExp3));
                           end if;
                        then fail();
                        end matchcontinue;

 (outExp,_) := ExpressionSimplify.simplify1(outExp);

end solve2;


protected function solveWork

 input DAE.Exp inExp1 "lhs";
 input DAE.Exp inExp2 "rhs";
 input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
 input Option<DAE.FunctionTree> functions;
 input Option<Integer> uniqueEqIndex "offset for tmp vars";
 input Integer idepth;
 output DAE.Exp outExp;
 output list<DAE.Statement> outAsserts;
 output list<BackendDAE.Equation> eqnForNewVars "eqn for tmp vars";
 output list<DAE.ComponentRef> newVarsCrefs;
 output Integer depth;


protected
 DAE.Exp e1, e2;
 list<BackendDAE.Equation> eqnForNewVars1;
 list<DAE.ComponentRef> newVarsCrefs1;
algorithm
 (e1, e2, eqnForNewVars, newVarsCrefs, depth) := matchcontinue(inExp1, inExp2, inExp3, functions, uniqueEqIndex)
               case(_,_,_,_,_) then preprocessingSolve(inExp1, inExp2, inExp3, functions, uniqueEqIndex, idepth);
               else
                equation
                  if Flags.isSet(Flags.FAILTRACE) then
                    Debug.trace("\n-ExpressionSolve.preprocessingSolve failed:\n");
                    Debug.trace(ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2));
                    Debug.trace(" with respect to: " + ExpressionDump.printExpStr(inExp3));
                  end if;
                then (inExp1,inExp2,{},{}, idepth);
              end matchcontinue;

 (outExp, outAsserts, eqnForNewVars1, newVarsCrefs1, depth) := matchcontinue(e1, e2, inExp3)
                          case(DAE.IFEXP(),_,_) then  solveIfExp(e1, e2, inExp3, functions, uniqueEqIndex, depth);
                          case(_,_,_) then  solveSimple(e1, e2, inExp3, depth);
                          case(_,_,_) then  solveLinearSystem(e1, e2, inExp3, depth);
                          else fail();
                         end matchcontinue;

 eqnForNewVars := List.appendNoCopy(eqnForNewVars, eqnForNewVars1);
 newVarsCrefs := List.appendNoCopy(newVarsCrefs, newVarsCrefs1);

end solveWork;

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
  (outExp,outAsserts) := matchcontinue(inExp1, inExp2, inExp3)
                         case(_,_,_) then solve(inExp1,inExp2,inExp3);
                         else
                          equation
                            if Flags.isSet(Flags.FAILTRACE) then
                              Debug.trace("\n-ExpressionSolve.solveLin failed:\n");
                              Debug.trace(ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2));
                              Debug.trace(" with respect to: " + ExpressionDump.printExpStr(inExp3));
                            end if;
                            then fail();
                        end matchcontinue;
end solveLin;

protected function solveSimple
"Solves simple equations like
  a = f(..)
  der(a) = f(..)
  -a = f(..)
  -der(a) = f(..)"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input Integer idepth;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
  output list<BackendDAE.Equation> eqnForNewVars := {} "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs := {};
  output Integer odepth := idepth;

algorithm

 /*
  print("Try to solve: rhs: " +
  ExpressionDump.dumpExpStr(inExp1,0) + " lhs: " +
  ExpressionDump.dumpExpStr(inExp2,0) + " with respect to: " +
  ExpressionDump.printExpStr(inExp3) + "\n");
*/

  (outExp,outAsserts) := match (inExp1,inExp2,inExp3)
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
        false = Expression.expHasCrefNoPreOrStart(inExp2, cr);
      then
        (inExp2,{});
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)}),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr, cr1);
        false = Expression.expHasDerCref(inExp2, cr);
      then
        (inExp2,{});

    // -cr = exp
    case (DAE.UNARY(operator = DAE.UMINUS(), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreOrStart(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(), exp = DAE.CREF(componentRef = cr1)),_,DAE.CREF(componentRef = cr))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasCrefNoPreOrStart(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS(), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
      equation
        true = ComponentReference.crefEqual(cr1,cr);
        // cr not in e2
        false = Expression.expHasDerCref(inExp2,cr);
      then
        (Expression.negate(inExp2),{});
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(), exp = DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr1)})),_,DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))
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
        false = Expression.expHasCrefNoPreOrStart(inExp2,cr);
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
  end match;
end solveSimple;


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
        estr = "Expression for " + crstr + " out of min(" + s1 + ")/max(" + sn + ") = ";
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

public function preprocessingSolve
"
preprocessing for solve1,
 sorting and split terms , with respect to the expression given as
 third argument.

 {f(x,y), g(x,y),x} -> {h(x), k(y)}

 author: Vitalij Ruge
"

  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input Option<DAE.FunctionTree> functions;
  input Option<Integer> uniqueEqIndex "offset for tmp vars";
  input Integer idepth;
  output DAE.Exp h;
  output DAE.Exp k;
  output list<BackendDAE.Equation> eqnForNewVars := {} "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs := {};
  output Integer depth := idepth;

 protected
  DAE.Exp res;
  list<DAE.Exp> lhs, rhs, resTerms;
  list<DAE.Exp> lhsWithX, rhsWithX, lhsWithoutX, rhsWithoutX, eWithX, factorWithX, factorWithoutX;
  DAE.Exp lhsX, rhsX, lhsY, rhsY, x, y, N;
  DAE.ComponentRef cr;
  DAE.Boolean con, new_x, collect := true, inlineFun := true;
  Integer iter;

 algorithm
   (x, _) := ExpressionSimplify.simplify(inExp1);
   (y, _) := ExpressionSimplify.simplify(inExp2);
   res := Expression.expSub(x, y);
   resTerms :=  Expression.terms(res);

   // split and sort
   (lhsX, lhsY) := preprocessingSolve5(inExp1, inExp3,true);
   (rhsX, rhsY) := preprocessingSolve5(inExp2, inExp3,true);
   x := Expression.expSub(lhsX, rhsX);
   y := Expression.expSub(rhsY, lhsY);

   con := true;
   iter := 0;

   while con and iter < 1000 loop

     (x, y, con) := preprocessingSolve2(x,y, inExp3);
     (x, y, new_x) := preprocessingSolve3(x,y, inExp3);
     con := con or new_x;
     (x, y, new_x) := removeSimpleCalls(x,y, inExp3);
     con := con or new_x;
     (x, y, new_x) := preprocessingSolve4(x,y, inExp3);
     con := new_x or con;
     // TODO: use new defined function, which missing in the cpp runtime
     if not stringEqual(Config.simCodeTarget(), "Cpp") then
       (x, y, new_x, eqnForNewVars, newVarsCrefs, depth) := preprocessingSolveTmpVars(x, y, inExp3, uniqueEqIndex, eqnForNewVars, newVarsCrefs, depth);
     con := new_x or con;
     end if;

     if not con then
       (x, con) := ExpressionSimplify.simplify(x);
       // Z/N = rhs -> Z = rhs*N
       (x,N) := Expression.makeFraction(x);
       if not Expression.isOne(N) then
         //print("\nx ");print(ExpressionDump.printExpStr(x));print("\nN ");print(ExpressionDump.printExpStr(N));
         new_x := true;
         y := Expression.expMul(y,N);
       end if;

       con := new_x or con;
       iter := iter + 50;
     end if;

     if con and collect then
       (lhsX, lhsY) := preprocessingSolve5(x, inExp3, true);
       (rhsX, rhsY) := preprocessingSolve5(y, inExp3, false);
       x := Expression.expSub(lhsX, rhsX);
       y := Expression.expSub(rhsY, lhsY);
       collect := true;
       inlineFun := true;
     elseif collect then
       collect := false;
       con := true;
       iter := iter + 50;
     elseif inlineFun then
       (x,con) := solveFunCalls(x, inExp3, functions);
       collect := con;
       inlineFun := false;
     end if;

     iter := iter + 1;
     //print("\nx ");print(ExpressionDump.printExpStr(x));print("\ny ");print(ExpressionDump.printExpStr(y));
   end while;

   (k,_) := ExpressionSimplify.simplify1(y);

   // h(x) = k(y)
   (h,_) := ExpressionSimplify.simplify(x);

/*
   if not Expression.expEqual(inExp1,h) then
     print("\nIn: ");print(ExpressionDump.printExpStr(inExp1));print(" = ");print(ExpressionDump.printExpStr(inExp2));
     print("\nOut: ");print(ExpressionDump.printExpStr(h));print(" = ");print(ExpressionDump.printExpStr(k));
     print("\t w.r.t ");print(ExpressionDump.printExpStr(inExp3));
   end if;
*/

end preprocessingSolve;

protected function preprocessingSolve2
"
 helprer function for preprocessingSolve
 e.g.
   x/(x+c1) = -c2 --> x + (x+c1)*c2 = 0

 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp olhs;
  output DAE.Exp orhs;
  output Boolean con "continue";

algorithm

(olhs, orhs, con) := matchcontinue (inExp1,inExp2,inExp3)
    local
     DAE.Exp e,a, b, fb, fa, ga, lhs, rhs;
     DAE.Type tp;
     DAE.Operator op;
     list<DAE.Exp> eWithX, factorWithX, factorWithoutX;
     DAE.Exp pWithX, pWithoutX;

    // -f(a) = b => f(a) = -b
    case(DAE.UNARY(op as DAE.UMINUS(), fa),_,_)
      equation
        true = expHasCref(fa, inExp3);
        false = expHasCref(inExp2, inExp3);
        b = DAE.UNARY(op, inExp2);
    then(fa, b, true);
    case(DAE.UNARY(op as DAE.UMINUS_ARR(), fa),_,_)
      equation
        true = expHasCref(fa, inExp3);
        false = expHasCref(inExp2, inExp3);
        b = DAE.UNARY(op, inExp2);
    then(fa, b, true);

    // b/f(a) = rhs  => f(a) = b/rhs solve for a
    case(DAE.BINARY(b,DAE.DIV(_),fa), rhs, _)
      equation
        true = expHasCref(fa, inExp3);
        false = expHasCref(b, inExp3);
        false = expHasCref(rhs, inExp3);
        e = Expression.makeDiv(b, rhs);
      then(fa, e, true);

    // b*f(a) = rhs  => f(a) = rhs/b solve for a
    case(DAE.BINARY(b, DAE.MUL(_), fa), rhs, _)
      equation
        false = expHasCref(b, inExp3);
        true = expHasCref(fa, inExp3);
        false = expHasCref(rhs, inExp3);

        eWithX = Expression.expandFactors(inExp1);
        (factorWithX, factorWithoutX) = List.split1OnTrue(eWithX, expHasCref, inExp3);
        pWithX = makeProductLstSort(factorWithX);
        pWithoutX = makeProductLstSort(factorWithoutX);

        e = Expression.makeDiv(rhs, pWithoutX);

       then(pWithX, e, true);

    // b*a = rhs  => a = rhs/b solve for a
    case(DAE.BINARY(b, DAE.MUL(_), fa), rhs, _)
      equation
        false = expHasCref(b, inExp3);
        true = expHasCref(fa, inExp3);
        false = expHasCref(rhs, inExp3);
        e = Expression.makeDiv(rhs, b);
       then(fa, e, true);

    // a*b = rhs  => a = rhs/b solve for a
    case(DAE.BINARY(fa, DAE.MUL(_), b), rhs, _)
      equation
        false = expHasCref(b, inExp3);
        true = expHasCref(fa, inExp3);
        false = expHasCref(rhs, inExp3);
        e = Expression.makeDiv(rhs, b);
       then(fa, e, true);

    // f(a)/b = rhs  => f(a) = rhs*b solve for a
    case(DAE.BINARY(fa, DAE.DIV(_), b), rhs, _)
      equation
        true = expHasCref(fa, inExp3);
        false = expHasCref(b, inExp3);
        false = expHasCref(rhs, inExp3);
        e = Expression.expMul(rhs, b);
       then (fa, e, true);

    // g(a)/f(a) = rhs  => rhs*f(a) - g(a) = 0  solve for a
    case(DAE.BINARY(ga, DAE.DIV(tp), fa), rhs, _)
      equation
        true = expHasCref(fa, inExp3);
        true = expHasCref(ga, inExp3);
        false = expHasCref(rhs, inExp3);

        e = Expression.expMul(rhs, fa);
        lhs = Expression.expSub(e, ga);
        e = Expression.makeConstZero(tp);

       then(lhs, e, true);

   else (inExp1, inExp2, false);

   end matchcontinue;

end preprocessingSolve2;

protected function preprocessingSolve3
"
 helprer function for preprocessingSolve

 (r1)^f(a) = r2 => f(a)  = ln(r2)/ln(r1)
 f(a)^b = 0 => f(a) = 0
 f(a)^n = c => f(a) = c^(1/n)
 abs(x) = 0
 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp olhs;
  output DAE.Exp orhs;
  output Boolean con "continue";

algorithm
  (olhs, orhs, con) := matchcontinue(inExp1, inExp2, inExp3)
      local
       Real r, r1, r2;
       DAE.Exp e1, e2, res;

      // (r1)^f(a) = r2 => f(a)  = ln(r2)/ln(r1)
      case (DAE.BINARY(e1 as DAE.RCONST(r1),DAE.POW(_),e2), DAE.RCONST(r2), _)
       equation
         true = r2 > 0.0;
         true = r1 > 0.0;
         false = Expression.isConstOne(e1);
         true = expHasCref(e2, inExp3);
         r = realLn(r2) / realLn(r1);
         res = DAE.RCONST(r);
       then
         (e2, res, true);

      // f(a)^b = 0 => f(a) = 0
      case (DAE.BINARY(e1,DAE.POW(_),e2), DAE.RCONST(real = 0.0), _)
        equation
         false = expHasCref(e2, inExp3);
         true = expHasCref(e1, inExp3);
       then
         (e1, inExp2, true);

      // f(a)^n = c => f(a) = c^(1/n)
      // where n is odd
      case (DAE.BINARY(e1,DAE.POW(_),e2 as DAE.RCONST(r)), _, _)
        equation
          false = expHasCref(inExp2, inExp3);
          true = expHasCref(e1, inExp3);
          1.0 = realMod(r,2.0);
          res = Expression.makeDiv(DAE.RCONST(1.0),e2);
          res = Expression.expPow(inExp2,res);
       then
         (e1, res, true);

      // sqrt(f(a)) = f(a)^n = c => f(a) = c^(1/n)
      case (DAE.BINARY(e1,DAE.POW(_),e2 as DAE.RCONST(0.5)), _, _)
        equation
          false = expHasCref(inExp2, inExp3);
          true = expHasCref(e1, inExp3);
          res = Expression.expPow(inExp2,DAE.RCONST(2.0));
       then
         (e1, res, true);

      // abs(x) = 0
      case (DAE.CALL(path = Absyn.IDENT(name = "abs"),expLst = {e1}), DAE.RCONST(0.0),_)
        then (e1,inExp2,true);

      // sign(x) = 0
      case (DAE.CALL(path = Absyn.IDENT(name = "sign"),expLst = {e1}), DAE.RCONST(0.0),_)
        then (e1,inExp2,true);


      else (inExp1, inExp2, false);

  end matchcontinue;


end preprocessingSolve3;


protected function preprocessingSolve4

"
 helprer function for preprocessingSolve

 e.g.
  sqrt(f(x)) - sqrt(g(x))) = 0 = f(x) - g(x)
  exp(f(x)) - exp(g(x))) = 0 = f(x) - g(x)

 author: Vitalij Ruge
"

  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Exp oExp1;
  output DAE.Exp oExp2;
  output Boolean newX;

algorithm

  (oExp1, oExp2, newX) := matchcontinue(inExp1, inExp2, inExp3)
          local
          String s1,s2;
          DAE.Operator op;
          DAE.Exp e1,e2,e3,e4, e, e_1, e_2;
          DAE.Type tp;

          // exp(f(x)) - exp(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("exp"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("exp"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);
          // log(f(x)) - log(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("log"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("log"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);
          // log10(f(x)) - log10(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("log10"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("log10"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);
          // sinh(f(x)) - sinh(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);
          // tanh(f(x)) - tanh(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("tanh"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("tanh"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);
          // sqrt(f(x)) - sqrt(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e2})),DAE.RCONST(0.0),_)
          then (e1, e2, true);

          // sinh(f(x)) - cosh(g(x)) = 0
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("cosh"), expLst={e2})),DAE.RCONST(0.0),_)
          equation
          true = Expression.expEqual(e1,e2);
          then (e1, inExp2, true);
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("cosh"), expLst={e1}), op as DAE.SUB(tp),
                          DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e2})),DAE.RCONST(0.0),_)
          equation
          true = Expression.expEqual(e1,e2);
          then (e1, inExp2, true);



         // y*sinh(x) - z*cosh(x) = 0
          case(DAE.BINARY(DAE.BINARY(e3,DAE.MUL(),DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e1})), op as DAE.SUB(tp),
                          DAE.BINARY(e4,DAE.MUL(),DAE.CALL(path = Absyn.IDENT("cosh"), expLst={e2}))),DAE.RCONST(0.0),_)
          equation
          true = Expression.expEqual(e1,e2);
          e = Expression.makePureBuiltinCall("tanh",{e1},tp);
          then (Expression.expMul(e3,e), e4, true);
          case(DAE.BINARY(DAE.BINARY(e4,DAE.MUL(),DAE.CALL(path = Absyn.IDENT("cosh"), expLst={e2})), op as DAE.SUB(tp),
                          DAE.BINARY(e3,DAE.MUL(),DAE.CALL(path = Absyn.IDENT("sinh"), expLst={e1}))),DAE.RCONST(0.0),_)
          equation
          true = Expression.expEqual(e1,e2);
          e = Expression.makePureBuiltinCall("tanh",{e1},tp);
          then (Expression.expMul(e3,e), e4, true);



          // sqrt(x) - x = 0 -> x = x^2
          case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e1}), op as DAE.SUB(tp),e2), DAE.RCONST(0.0),_)
          then (e1, Expression.expPow(e2, DAE.RCONST(2.0)), true);
          case(DAE.BINARY(e2, op as DAE.SUB(tp),DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e1})), DAE.RCONST(0.0),_)
          equation
          then (e1, Expression.expPow(e2, DAE.RCONST(2.0)), true);

          // f(x)^n - g(x)^n = 0 -> (f(x)/g(x))^n = 1
          case(DAE.BINARY(DAE.BINARY(e1, DAE.POW(), e2), DAE.SUB(tp), DAE.BINARY(e3, DAE.POW(), e4)), DAE.RCONST(0.0),_)
          equation
            true = Expression.expEqual(e2,e4);
            true = expHasCref(e1,inExp3);
            true = expHasCref(e3,inExp3);
            e = Expression.expPow(Expression.makeDiv(e1,e3),e2);
            (e_1, e_2, _) = preprocessingSolve3(e, Expression.makeConstOne(tp), inExp3);
          then (e_1, e_2, true);


          else (inExp1, inExp2, false);

    end matchcontinue;


end preprocessingSolve4;

protected function expAddX
"
 helprer function for preprocessingSolve

 if(y,g(x),h(x)) + x => if(y, g(x) + x, h(x) + x)
 a*f(x) + b*f(x) = (a+b)*f(x)
 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp ores;

algorithm
 ores := matchcontinue(inExp1, inExp2, inExp3)
   local
     DAE.Exp e, e1, e2, e3, e4, res;

    case(DAE.IFEXP(e,e1,e2), _,_)
     equation
         false = expHasCref(e, inExp3);
         true = expHasCref(e1, inExp3);
         true = expHasCref(e2, inExp3);
         e3 = expAddX(inExp2, e1, inExp3);
         e4 = expAddX(inExp2, e2, inExp3);

         res = DAE.IFEXP(e, e3, e4);
     then res;
    case(_, DAE.IFEXP(e,e1,e2), _)
     equation
         false = expHasCref(e, inExp3);
         true = expHasCref(e1, inExp3);
         true = expHasCref(e2, inExp3);
         e3 = expAddX(inExp1, e1, inExp3);
         e4 = expAddX(inExp1, e2, inExp3);

         res = DAE.IFEXP(e, e3, e4);
     then res;

     else
      equation
       res = expAddX2(inExp1, inExp2, inExp3);
      then res;

 end matchcontinue;

end expAddX;

protected function expAddX2
"
 helprer function for preprocessingSolve
 a*f(x) + b*f(x) = (a+b)*f(x)
 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp ores;

protected
  list<DAE.Exp> f1, f2;
  DAE.Exp e0,e1,e2;
  DAE.Boolean neg;
  list<DAE.Exp> factorWithX1, factorWithoutX1,  factorWithX2, factorWithoutX2;
  DAE.Exp pWithX1, pWithoutX1, pWithX2, pWithoutX2;

algorithm
  (e0, e1, neg) := match(inExp1)
                   local DAE.Exp ee1, ee2;
                   case(DAE.BINARY(ee1,DAE.ADD(),ee2))
                    then(ee1, ee2, false);
                   case(DAE.BINARY(ee1,DAE.SUB(),ee2))
                    then(ee1, ee2, true);
                   else
                    then(DAE.RCONST(0.0), inExp1, false);
                   end match;

  f1 := Expression.expandFactors(e1);
  (factorWithX1, factorWithoutX1) := List.split1OnTrue(f1, expHasCref, inExp3);
  pWithX1 := makeProductLstSort(factorWithX1);
  pWithoutX1 := makeProductLstSort(factorWithoutX1);

  f2 := Expression.expandFactors(inExp2);
  (factorWithX2, factorWithoutX2) := List.split1OnTrue(f2, expHasCref, inExp3);
  (pWithX2,_) := ExpressionSimplify.simplify1(makeProductLstSort(factorWithX2));
  pWithoutX2 := makeProductLstSort(factorWithoutX2);
  //print("\nf1 =");print(ExpressionDump.printExpListStr(f1));
  //print("\nf2 =");print(ExpressionDump.printExpListStr(f2));

  if Expression.expEqual(pWithX2,pWithX1) then
    // e0 + a*x + b*x -> e0 + (a+b)*x
    if not neg then
      ores := Expression.expAdd(pWithoutX1, pWithoutX2);
    else
    // e0 - a*x + b*x -> e0 + (b-a)*x
      ores := Expression.expSub(pWithoutX2, pWithoutX1);
    end if;
    ores := Expression.expMul(ores, pWithX2);
  elseif Expression.expEqual(pWithX2, Expression.negate(pWithX1)) then
    // e0 + a*(-x) + b*x -> e0 + (b-a)*x
    if not neg then
      ores := Expression.expSub(pWithoutX2, pWithoutX1);
    else
    // e0 - a*(-x) + b*x -> e0 + (b-a)*x
      ores := Expression.expAdd(pWithoutX1, pWithoutX2);
    end if;
    ores := Expression.expMul(ores, pWithX2);
  else
    e1 := Expression.expMul(pWithoutX1, pWithX1);
    e2 := Expression.expMul(pWithoutX2, pWithX2);
    ores := Expression.expAdd(e1,e2);
  end if;

  ores := Expression.expAdd(e0,ores);

end expAddX2;

protected function preprocessingSolve5
"
 helprer function for preprocessingSolve
 split and sort with respect to x
 where x = cref

 f(x,y) = {h(y)*g(x,y), k(y)}

 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input DAE.Boolean expand;
  output DAE.Exp outLhs := DAE.RCONST(0.0);
  output DAE.Exp outRhs;

protected
  DAE.Exp res;
  list<DAE.Exp> lhs, rhs, resTerms;

algorithm

   //can be improve with Expression.getTermsContainingX ???

   if expHasCref(inExp1, inExp3) then
     resTerms := Expression.terms(inExp1);
     // split
     (lhs, rhs) := List.split1OnTrue(resTerms, expHasCref, inExp3);
     //print("\nlhs =");print(ExpressionDump.printExpListStr(lhs));
     //print("\nrhs =");print(ExpressionDump.printExpListStr(rhs));

     // sort
     // a*f(x)*b -> c*f(x)
     for e in lhs loop
       outLhs := expAddX(e, outLhs, inExp3); // special add
     end for;

     //rhs
     outRhs := Expression.makeSum(rhs);
     (outRhs,_) := ExpressionSimplify.simplify1(outRhs);

     if expand then
       resTerms := Expression.terms(Expression.expand(outLhs));
       (lhs, rhs) := List.split1OnTrue(resTerms, expHasCref, inExp3);
       outLhs := DAE.RCONST(0.0);
       // sort
       // a*f(x)*b -> c*f(x)
       for e in lhs loop
         outLhs := expAddX(e, outLhs, inExp3); // special add
       end for;
       //rhs
       outRhs := Expression.expAdd(outRhs,Expression.makeSum(rhs));
       (outRhs,_) := ExpressionSimplify.simplify1(outRhs);

       resTerms := Expression.allTerms(outLhs);
       (lhs, rhs) := List.split1OnTrue(resTerms, expHasCref, inExp3);
       // sort
       // a*f(x)*b -> c*f(x)
       outLhs := DAE.RCONST(0.0);
       for e in lhs loop
         outLhs := expAddX(e, outLhs, inExp3); // special add
       end for;
       //rhs
       outRhs := Expression.expAdd(outRhs,Expression.makeSum(rhs));
       (outRhs,_) := ExpressionSimplify.simplify1(outRhs);

     end if;

   else
    outRhs := inExp1;
   end if;

end preprocessingSolve5;

protected function unifyFunCalls
"
e.g.
 smooth() -> if
 semiLinear() -> if
 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Exp oExp;
  output Boolean newX;
algorithm
 (oExp,_) := Expression.traverseExpTopDown(inExp1, unifyFunCallsWork, (inExp3));
 newX := Expression.expEqual(oExp, inExp1);
end unifyFunCalls;

protected function unifyFunCallsWork
  input DAE.Exp inExp;
  input DAE.Exp iT;
  output DAE.Exp outExp;
  output Boolean cont;
  output DAE.Exp oT;
 algorithm
   (outExp,cont,oT) := matchcontinue(inExp, iT)
   local
     DAE.Exp e, e1,e2,e3, X;
     DAE.Type tp;

   case(DAE.CALL(path = Absyn.IDENT(name = "smooth"), expLst = {_, e}),X)
     equation
       true = expHasCref(e, X);
     then (e, true, iT);

   case(DAE.CALL(path = Absyn.IDENT(name = "noEvent"), expLst = {e}),X)
     equation
       true = expHasCref(e, X);
     then (e, true, iT);

   case(DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {e1, e2, e3}),X)
     equation
       false = Expression.isZero(e1);
       tp = Expression.typeof(e1);
       e = DAE.IFEXP(DAE.RELATION(e1,DAE.GREATEREQ(tp), Expression.makeConstZero(tp),-1,NONE()),Expression.expMul(e1,e2), Expression.expMul(e1,e3));
     then (e,true, iT);

   else (inExp, true, iT);
   end matchcontinue;

end unifyFunCallsWork;


protected function solveFunCalls
"
  - inline modelica functions
  - TODO: support annotation inverse
 author: Vitalij Ruge
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  input Option<DAE.FunctionTree> functions;
  output DAE.Exp x;
  output Boolean con;
algorithm
 (x,con) := matchcontinue(functions, inExp1)
                  local DAE.Exp funX; Boolean b;
                  case(_,_)
                  equation
                    (funX,_) = Expression.traverseExpTopDown(inExp1, inlineCallX, (inExp3, functions));
                  then (funX, not Expression.expEqual(funX, inExp1));
                  else (inExp1, false);
                  end matchcontinue;
end solveFunCalls;

protected function removeSimpleCalls
"
 helprer function for preprocessingSolve

 solve e.g.
   exp(x) = y
   log(x) = y
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp outLhs;
  output DAE.Exp outRhs;
  output Boolean con "continue";
algorithm
  (outLhs, outRhs, con) := match(inExp1, inExp2, inExp3)
                            case(DAE.CALL(),_,_) then removeSimpleCalls2(inExp1, inExp2, inExp3);
                            else (inExp1, inExp2, false);
                           end match;
end removeSimpleCalls;


protected function removeSimpleCalls2
"
 helprer function for preprocessingSolve

 solve e.g.
   exp(x) = y
   log(x) = y
"
  input DAE.Exp inExp1 "lhs";
  input DAE.Exp inExp2 "rhs";
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";

  output DAE.Exp outLhs;
  output DAE.Exp outRhs;
  output Boolean con "continue";
algorithm
  (outLhs, outRhs, con) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp e1, e2, e3;


    //tanh(x) =y -> x = 1/2 * ln((1+y)/(1-y))
    case (DAE.CALL(path = Absyn.IDENT(name = "tanh"),expLst = {e1}),_,_)
       equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         true = not(Expression.isCref(inExp2) or Expression.isConst(inExp2));
         e2 = Expression.expAdd(DAE.RCONST(1.0), inExp2);
         e3 = Expression.expSub(DAE.RCONST(1.0), inExp2);
         e2 = Expression.makeDiv(e2, e3);
         e2 = Expression.makePureBuiltinCall("log",{e2},DAE.T_REAL_DEFAULT);
         e2 = Expression.expMul(DAE.RCONST(0.5), e2);
       then (e1, e2, true);
    // sinh(x) -> ln(y+(sqrt(1+y^2))
    case (DAE.CALL(path = Absyn.IDENT(name = "sinh"),expLst = {e1}),_,_)
      equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         true = not(Expression.isCref(inExp2) or Expression.isConst(inExp2));
         e2 = Expression.expPow(inExp2, DAE.RCONST(2.0));
         e3 = Expression.expAdd(e2,DAE.RCONST(1.0));
         e2 = Expression.makePureBuiltinCall("sqrt",{e3},DAE.T_REAL_DEFAULT);
         e3 = Expression.expAdd(inExp2, e2);
         e2 = Expression.makePureBuiltinCall("log",{e3},DAE.T_REAL_DEFAULT);
      then (e1,e2,true);

    // log10(f(a)) = g(b) => f(a) = 10^(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "log10"),expLst = {e1}),_,_)
       equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         e2 = Expression.expPow(DAE.RCONST(10.0), inExp2);
       then (e1, e2, true);
    // log(f(a)) = g(b) => f(a) = exp(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "log"),expLst = {e1}),_,_)
       equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         e2 = Expression.makePureBuiltinCall("exp",{inExp2},DAE.T_REAL_DEFAULT);
       then (e1, e2, true);
    // exp(f(a)) = g(b) => f(a) = log(g(b))
    case (DAE.CALL(path = Absyn.IDENT(name = "exp"),expLst = {e1}),_,_)
       equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         e2 = Expression.makePureBuiltinCall("log",{inExp2},DAE.T_REAL_DEFAULT);
       then (e1, e2, true);
    // sqrt(f(a)) = g(b) => f(a) = (g(b))^2
    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"),expLst = {e1}),_,_)
       equation
         true = expHasCref(e1, inExp3);
         false = expHasCref(inExp2, inExp3);
         e2 = DAE.RCONST(2.0);
         e2 = Expression.expPow(inExp2,e2);
       then (e1, e2, true);
    // semiLinear(0, a, b) = 0 => a = b // rule 1
    case (DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {DAE.RCONST(real = 0.0), e1, e2}),DAE.RCONST(real = 0.0),_)
       then (e1,e2,true);
    // smooth(i,f(a)) = rhs -> f(a) = rhs
    case (DAE.CALL(path = Absyn.IDENT(name = "smooth"),expLst = {e1, e2}),_,_)
       then (e2, inExp2, true);
    // noEvent(f(a)) = rhs -> f(a) = rhs
    case (DAE.CALL(path = Absyn.IDENT(name = "noEvent"),expLst = {e2}),_,_)
       then (e2, inExp2, true);

    else (inExp1, inExp2, false);
  end matchcontinue;
end removeSimpleCalls2;

protected function inlineCallX
"
inline function call if depends on X where X is cref oder der(cref)
DAE.Exp inExp2 DAE.CREF or 'der(DAE.CREF())'
author: vitalij
"
  input DAE.Exp inExp;
  input tuple<DAE.Exp, Option<DAE.FunctionTree>> iT;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.Exp, Option<DAE.FunctionTree>> oT;
 algorithm
   (outExp,cont,oT) := matchcontinue(inExp, iT)
   local
     DAE.Exp e, X;
     DAE.ComponentRef cr;
     Option<DAE.FunctionTree> functions;
     Boolean b;

   case(DAE.CALL(path =_),(X, functions))
     equation
       //print("\nIn: ");print(ExpressionDump.printExpStr(inExp));
       true = expHasCref(inExp, X);
       (e,_,b) = Inline.forceInlineExp(inExp,(functions,{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource);
       //print("\nOut: ");print(ExpressionDump.printExpStr(e));
     then (e, not b, iT);
   else (inExp, true, iT);
   end matchcontinue;
end inlineCallX;

protected function preprocessingSolveTmpVars
"
helper function for solveWork
creat tmp vars if needed!
e.g. for solve abs()

 author: Vitalij Ruge
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input Option<Integer> uniqueEqIndex "offset for tmp vars";
  input list<BackendDAE.Equation> ieqnForNewVars;
  input list<DAE.ComponentRef> inewVarsCrefs;
  input Integer idepth;
  output DAE.Exp x;
  output DAE.Exp y;
  output Boolean new_x;
  output list<BackendDAE.Equation> eqnForNewVars "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs;
  output Integer odepth;
algorithm
  (x, y, new_x, eqnForNewVars, newVarsCrefs, odepth) := match(uniqueEqIndex)
        local Integer i;
        case(SOME(i)) then preprocessingSolveTmpVarsWork(inExp1, inExp2, inExp3, i, ieqnForNewVars, inewVarsCrefs, idepth);
        else then (inExp1, inExp2, false, ieqnForNewVars, inewVarsCrefs, idepth);
        end match;
end preprocessingSolveTmpVars;

protected function preprocessingSolveTmpVarsWork
"
helper function for solveWork
creat tmp vars if needed!
e.g. for solve abs
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input Integer uniqueEqIndex "offset for tmp vars";
  input list<BackendDAE.Equation> ieqnForNewVars;
  input list<DAE.ComponentRef> inewVarsCrefs;
  input Integer idepth "depth of tmp var";
  output DAE.Exp x;
  output DAE.Exp y;
  output Boolean new_x;
  output list<BackendDAE.Equation> eqnForNewVars "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs;
  output Integer odepth;
algorithm
  (x, y, new_x, eqnForNewVars, newVarsCrefs, odepth) := matchcontinue(inExp1, inExp2)
  local DAE.Exp e1, e_1, e, e2, exP, lhs, e3, e4, e5, e6, rhs, a1,x1, a2,x2;
  tuple<DAE.Exp, DAE.Exp> a, c;
  DAE.ComponentRef cr;
  DAE.Type tp;
  BackendDAE.Equation eqn;
  list<BackendDAE.Equation> eqnForNewVars_;
  list<DAE.ComponentRef> newVarsCrefs_;
  Boolean b, b1, b2, b3;

  //tanh(x) =y -> x = 1/2 * ln((1+y)/(1-y))
  case (DAE.CALL(path = Absyn.IDENT(name = "tanh"),expLst = {e1}),_)
    equation
      true = expHasCref(e1, inExp3);
      false = expHasCref(inExp2, inExp3);
      b = not(Expression.isCref(inExp2) or Expression.isConst(inExp2));
      if b then
        tp = Expression.typeof(inExp2);
        cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_TANH_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
        eqn = BackendDAE.SOLVED_EQUATION(cr, inExp2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        e = Expression.crefExp(cr);
        eqnForNewVars_ = eqn::ieqnForNewVars;
        newVarsCrefs_ = cr::inewVarsCrefs;
      else
        e = inExp2;
        eqnForNewVars_ = ieqnForNewVars;
        newVarsCrefs_ = inewVarsCrefs;
      end if;
      e2 = Expression.expAdd(DAE.RCONST(1.0), e);
      e3 = Expression.expSub(DAE.RCONST(1.0), e);
      e2 = Expression.makeDiv(e2, e3);
      e2 = Expression.makePureBuiltinCall("log",{e2},DAE.T_REAL_DEFAULT);
      e2 = Expression.expMul(DAE.RCONST(0.5), e2);
     then (e1, e2, true,eqnForNewVars_,newVarsCrefs_,idepth + 1);

  // sinh(x) -> ln(y+(sqrt(1+y^2))
  case (DAE.CALL(path = Absyn.IDENT(name = "sinh"),expLst = {e1}),_)
    equation
      true = expHasCref(e1, inExp3);
      false = expHasCref(inExp2, inExp3);
      b = Expression.isCref(inExp2) or Expression.isConst(inExp2);
      if b then
        tp = Expression.typeof(inExp2);
        cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_SINH_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
        eqn = BackendDAE.SOLVED_EQUATION(cr, inExp2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        e = Expression.crefExp(cr);
        eqnForNewVars_ = eqn::ieqnForNewVars;
        newVarsCrefs_ = cr::inewVarsCrefs;
      else
        e = inExp2;
        eqnForNewVars_ = ieqnForNewVars;
        newVarsCrefs_ = inewVarsCrefs;
      end if;
      e2 = Expression.expPow(e, DAE.RCONST(2.0));
      e3 = Expression.expAdd(e2,DAE.RCONST(1.0));
      e2 = Expression.makePureBuiltinCall("sqrt",{e3},DAE.T_REAL_DEFAULT);
      e3 = Expression.expAdd(e, e2);
      e2 = Expression.makePureBuiltinCall("log",{e3},DAE.T_REAL_DEFAULT);
    then (e1,e2,true,eqnForNewVars_,newVarsCrefs_,idepth + 1);

  // cosh(x) -> ln(y +- (sqrt(y^2 - 1))
  case (DAE.CALL(path = Absyn.IDENT(name = "cosh"),expLst = {e1}),_)
    equation
      true = expHasCref(e1, inExp3);
      false = expHasCref(inExp2, inExp3);
      b1 = Expression.isPositiveOrZero(e1);
      b2 = Expression.isNegativeOrZero(e1);
      b3 = Expression.isCref(inExp2) or Expression.isConst(inExp2);
      b = not(b1 or b2);
      if b or b3 then
        tp = Expression.typeof(e1);
        cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_SIGN_COSH_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
        eqn = BackendDAE.SOLVED_EQUATION(cr, e1, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        e = Expression.crefExp(cr);
        exP = Expression.makePureBuiltinCall("$_initialGuess", {e}, tp);
        e_1 = Expression.makePureBuiltinCall("$_signNoNull", {exP}, tp);
        eqnForNewVars_ = eqn::ieqnForNewVars;
        newVarsCrefs_ = cr::inewVarsCrefs;
      else
        e = e1;
        eqnForNewVars_ = ieqnForNewVars;
        newVarsCrefs_ = inewVarsCrefs;
      end if;
      if b3 then
        tp = Expression.typeof(inExp2);
        cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_COSH_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
        eqn = BackendDAE.SOLVED_EQUATION(cr, inExp2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
        lhs = Expression.crefExp(cr);
        eqnForNewVars_ = eqn::eqnForNewVars_;
        newVarsCrefs_ = cr::newVarsCrefs_;
      else
        lhs = inExp2;
      end if;
      e2 = Expression.expPow(lhs, DAE.RCONST(2.0));
      e3 = Expression.expSub(e2,DAE.RCONST(1.0));
      e2 = Expression.makePureBuiltinCall("sqrt",{e3},DAE.T_REAL_DEFAULT);
      e3 = if b then Expression.expAdd(lhs, Expression.expMul(e_1,e2)) else Expression.expAdd(lhs, e2);
      e2 = Expression.makePureBuiltinCall("log",{e3},DAE.T_REAL_DEFAULT);
    then (e1,e2,true,eqnForNewVars_,newVarsCrefs_,idepth + 1);

  // abs(f(x)) = g(y) -> f(x) = sign(f(x))*g(y)
  case(DAE.CALL(path = Absyn.IDENT(name = "abs"),expLst = {e1}), _)
  equation
    b1 = Expression.isPositiveOrZero(e1);
    b2 = Expression.isNegativeOrZero(e1);
    b = not(b1 or b2);
    if b then
      tp = Expression.typeof(e1);
      cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_ABS_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
      eqn = BackendDAE.SOLVED_EQUATION(cr, e1, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
      e = Expression.crefExp(cr);
      exP = Expression.makePureBuiltinCall("$_initialGuess", {e}, tp);
      e_1 = Expression.makePureBuiltinCall("$_signNoNull", {exP}, tp);
      eqnForNewVars_ = eqn::ieqnForNewVars;
      newVarsCrefs_ = cr::inewVarsCrefs;
      lhs = Expression.expMul(e_1, inExp2);
    else
      lhs = inExp2;
      eqnForNewVars_ = ieqnForNewVars;
      newVarsCrefs_ = inewVarsCrefs;
    end if;
  then(e1, lhs, true, eqnForNewVars_, newVarsCrefs_, idepth + 1);

  // x^n = y -> x = y^(1/n)
  case(DAE.BINARY(e1, DAE.POW(tp), e2),_)
  equation
    b1 = Expression.isPositiveOrZero(e1);
    b2 = Expression.isNegativeOrZero(e1);
    b = not(b1 or b2);
    if b then
      cr  = ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_POW_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
      eqn = BackendDAE.SOLVED_EQUATION(cr, e1, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
      e = Expression.crefExp(cr);
      exP = Expression.makePureBuiltinCall("$_initialGuess",{e},tp);
      e_1 = Expression.makePureBuiltinCall("$_signNoNull",{exP},tp);
      eqnForNewVars_ = eqn::ieqnForNewVars;
      newVarsCrefs_ = cr ::inewVarsCrefs;
      lhs = Expression.expPow(inExp2,Expression.inverseFactors(e2));
      lhs = Expression.expMul(e_1, lhs);
    else
      lhs = Expression.expPow(inExp2,Expression.inverseFactors(e2));
      eqnForNewVars_ = ieqnForNewVars;
      newVarsCrefs_ = inewVarsCrefs;
    end if;
  then(e1, lhs, true, eqnForNewVars_, newVarsCrefs_, idepth + 1);

  //QE
  case( DAE.BINARY(DAE.BINARY(a1,DAE.MUL(),x1), DAE.ADD(),DAE.BINARY(a2,DAE.MUL(),x2)),_)
  equation
    a = simplifyBinaryMulCoeff(x1);
    c = simplifyBinaryMulCoeff(x2);
    (e2 ,e3) = a;
    (e5, e6) = c;
    (lhs, rhs, eqnForNewVars_, newVarsCrefs_) = solveQE(a1,e2,e3,a2,e5,e6,inExp2,inExp3,ieqnForNewVars,inewVarsCrefs,uniqueEqIndex,idepth);
  then(lhs, rhs, true, eqnForNewVars_, newVarsCrefs_, idepth + 1);

  else (inExp1, inExp2, false, ieqnForNewVars, inewVarsCrefs, idepth);

  end matchcontinue;

end preprocessingSolveTmpVarsWork;

protected function simplifyBinaryMulCoeff
"generalization of ExpressionSimplify.simplifyBinaryMulCoeff2"
  input DAE.Exp inExp;
  output tuple<DAE.Exp, DAE.Exp> outRes;
algorithm
  outRes := match(inExp)
    local
      DAE.Exp e,e1,e2;
      DAE.Exp coeff;

    case ((e as DAE.CREF()))
      then ((e, DAE.RCONST(1.0)));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(),exp2 = DAE.UNARY(operator = DAE.UMINUS(), exp = coeff)))
      then
        ((e1, Expression.negate(coeff)));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(),exp2 = coeff))
      then ((e1,coeff));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2))
    guard(Expression.expEqual(e1, e2))
      then
        ((e1, DAE.RCONST(2.0)));

    case (e) then ((e,DAE.RCONST(1.0)));

  end match;
end simplifyBinaryMulCoeff;

protected function solveQE
"
solve Quadratic equation with respect to inExp3
IN: a,x,n,b,y,m
where solve(a*x^n + b*y^m = inExp2) with 2*m = n or 2*n = m and y = x

author: Vitalij Ruge
"
 input DAE.Exp e1,e2,e3,e4,e5,e6;
 input DAE.Exp inExp2;
 input DAE.Exp inExp3;

 input list<BackendDAE.Equation> ieqnForNewVars "eqn for tmp vars";
 input list<DAE.ComponentRef> inewVarsCrefs "cref for tmp vars";
 input Integer uniqueEqIndex, idepth "need for tmp vars";

 output DAE.Exp rhs, lhs;
 output list<BackendDAE.Equation> eqnForNewVars;
 output list<DAE.ComponentRef> newVarsCrefs;

protected
  DAE.Exp e_1, e, exP, q, p, e7, con, invExp;
  DAE.ComponentRef cr;
  DAE.Type tp;
  BackendDAE.Equation eqn;
  Boolean b1,b2;
algorithm
    false := Expression.isZero(e1) and Expression.isZero(e2);
    true := Expression.expEqual(e2,e5);
    b1 := Expression.expEqual(e3, Expression.expMul(DAE.RCONST(2.0),e6));
    b2 := Expression.expEqual(e6, Expression.expMul(DAE.RCONST(2.0),e3));

    true := b1 or b2;
    false := expHasCref(e1, inExp3);
    true := expHasCref(e2, inExp3);
    false := expHasCref(e3, inExp3);
    false := expHasCref(e4, inExp3);
    true := expHasCref(e5, inExp3);
    false := expHasCref(e6, inExp3);
    false := expHasCref(inExp2, inExp3);


    p := if b1 then Expression.expDiv(e4,e1) else Expression.expDiv(e1,e4);
    p := Expression.expMul(DAE.RCONST(0.5),p);
    tp := Expression.typeof(p);

    con := if b1 then DAE.RELATION(e1,DAE.EQUAL(tp),DAE.RCONST(0.0),-1,NONE()) else DAE.RELATION(e4,DAE.EQUAL(tp),DAE.RCONST(0.0),-1,NONE());
    con := Expression.makeNoEvent(con);
    cr  := ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_QE_CON_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), DAE.T_BOOL_DEFAULT, {});
    eqn := BackendDAE.SOLVED_EQUATION(cr, con, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    eqnForNewVars := eqn::ieqnForNewVars;
    newVarsCrefs := cr ::inewVarsCrefs;
    con := Expression.crefExp(cr);

    (p, _) :=  ExpressionSimplify.simplify1(p);
    p := DAE.IFEXP(con, Expression.makeConstOne(tp), p);
    cr  := ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_QE_P_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
    eqn := BackendDAE.SOLVED_EQUATION(cr, p, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    p := Expression.crefExp(cr);

    eqnForNewVars := eqn::eqnForNewVars;
    newVarsCrefs := cr::newVarsCrefs;

    q := if b1 then Expression.expDiv(inExp2,e1) else Expression.expDiv(inExp2,e4);
    q := Expression.negate(q);
    (q, _) :=  ExpressionSimplify.simplify1(q);
    q := DAE.IFEXP(con, Expression.makeConstOne(tp), q);
    cr  := ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_QE_Q_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
    eqn := BackendDAE.SOLVED_EQUATION(cr, q, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    q := Expression.crefExp(cr);

    eqnForNewVars := eqn::eqnForNewVars;
    newVarsCrefs := cr ::newVarsCrefs;

    cr  := ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_QE_SIGN_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
    eqn := BackendDAE.SOLVED_EQUATION(cr, e2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    eqnForNewVars := eqn::eqnForNewVars;
    newVarsCrefs := cr ::newVarsCrefs;
    e := Expression.crefExp(cr);
    exP := Expression.makePureBuiltinCall("$_initialGuess",{e},tp);
    e_1 := Expression.makePureBuiltinCall("$_signNoNull",{exP},tp);

    e := Expression.expPow(p,DAE.RCONST(2.0));
    e := Expression.expSub(e,q);
    lhs := Expression.makePureBuiltinCall("sqrt",{e},tp);
    e := Expression.negate(p);
    lhs := Expression.expMul(e_1, lhs);
    lhs := Expression.expAdd(e, lhs);

    cr  := ComponentReference.makeCrefIdent("$TMP_VAR_SOLVE_QE_FOR_EQN_" + intString(uniqueEqIndex) + "_" + intString(idepth), tp , {});
    e := Expression.crefExp(cr);
    exP := Expression.makePureBuiltinCall("$_initialGuess",{e},tp);
    e_1 := Expression.makePureBuiltinCall("$_signNoNull",{exP},tp);
    eqn := BackendDAE.SOLVED_EQUATION(cr, e2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);

    e7 := if b1 then Expression.makeDiv(inExp2, e4) else Expression.makeDiv(inExp2, e1);
    invExp := if b1 then Expression.inverseFactors(e6) else Expression.inverseFactors(e3);
    (invExp, _) :=  ExpressionSimplify.simplify1(invExp);
    e7 := Expression.expPow(e7, invExp);

    eqnForNewVars := eqn::eqnForNewVars;
    newVarsCrefs := cr ::newVarsCrefs;

    e7 := Expression.expMul(e_1, e7);

    rhs := DAE.IFEXP(con, e7 ,lhs);
    lhs := e2;

end solveQE;

protected function solveIfExp
"
 solve:
  if(f(y), f(x), g(x) ) = h(y) w.r.t. x
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input Option<DAE.FunctionTree> functions;
  input Option<Integer> uniqueEqIndex "offset for tmp vars";
  input Integer idepth;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
  output list<BackendDAE.Equation> eqnForNewVars "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs;
  output Integer odepth;

algorithm
   (outExp,outAsserts,eqnForNewVars,newVarsCrefs,odepth) := match(inExp1,inExp2,inExp3, functions, uniqueEqIndex)
   local
      DAE.Exp e1,e2,e3,res,lhs,rhs;
      list<DAE.Statement> asserts,asserts1,asserts2;
      list<BackendDAE.Equation> eqns, eqns1;
      list<DAE.ComponentRef> var, var1;
      Integer depth;

      //  f(a) if(g(b)) then f1(a) else f2(a) =>
      //  a1 = solve(f(a),f1(a)) for a
      //  a2 = solve(f(a),f2(a)) for a
      //  => a = if g(b) then a1 else a2
      case (DAE.IFEXP(e1,e2,e3),_,_,_,_)
        equation
          false = expHasCref(e1, inExp3);

          (lhs, asserts1, eqns, var, depth) = solveWork(e2, inExp2, inExp3, functions, uniqueEqIndex, idepth);
          (rhs, asserts2, eqns1, var1, depth) = solveWork(e3, inExp2, inExp3, functions, uniqueEqIndex, depth);

          res = DAE.IFEXP(e1,lhs,rhs);
          asserts = listAppend(asserts1,asserts1);
      then
        (res,asserts,List.appendNoCopy(eqns1,eqns),  List.appendNoCopy(var1, var), depth);
      else fail();
   end match;

end solveIfExp;

protected function solveLinearSystem
"
 solve linear system with newton step

 ToDo:
  fixed is for ./simulation/modelica/equations/deriveToLog.mos
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input Integer idepth;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
  output list<BackendDAE.Equation> eqnForNewVars := {} "eqn for tmp vars";
  output list<DAE.ComponentRef> newVarsCrefs := {};
  output Integer odepth := idepth;


algorithm
   (outExp,outAsserts) := match(inExp1,inExp2,inExp3)
   local
      DAE.Exp dere,e,z;
      DAE.ComponentRef cr;
      DAE.Exp rhs;
      DAE.Type tp;

    // cr = (e1-e2)/(der(e1-e2,cr))
    case (_,_,DAE.CREF(componentRef = cr))
      equation
        false = hasOnlyFactors(inExp1,inExp2);
        e = Expression.makeDiff(inExp1,inExp2);
        (e,_) = ExpressionSimplify.simplify1(e);
        ({},_) = List.split1OnTrue(Expression.factors(e),isCrefInIFEXP,cr); // check: differentiateExpSolve is allowed
        dere = Differentiate.differentiateExpSolve(e, cr);
        (dere,_) = ExpressionSimplify.simplify(dere);
        false = Expression.isZero(dere);
        false = Expression.expHasCrefNoPreOrStart(dere, cr);
        tp = Expression.typeof(inExp3);
        (z,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        ((e,_)) = Expression.replaceExp(e, inExp3, z);
        (e,_) = ExpressionSimplify.simplify(e);
        rhs = Expression.negate(Expression.makeDiv(e,dere));
      then
        (rhs,{});

      else fail();
   end match;

end solveLinearSystem;

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


protected function expHasCref
"
helper function for solve.
case distinction for
DAE.CREF or 'der(DAE.CREF())'
Expression.expHasCrefNoPreOrStart
or
Expression.expHasDerCref
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp3 "DAE.CREF or 'der(DAE.CREF())'";
  output DAE.Boolean res;

algorithm
  res := match(inExp1, inExp3)
         local DAE.ComponentRef cr;

          case(_, DAE.CREF(componentRef = cr)) then Expression.expHasCrefNoPreOrStart(inExp1, cr);
          case(_, DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})) then Expression.expHasDerCref(inExp1, cr);
          else
           equation
            if Flags.isSet(Flags.FAILTRACE) then
              print("\n-ExpressionSolve.solve failed:");
              print(" with respect to: ");print(ExpressionDump.printExpStr(inExp3));
              print(" not support!");
              print("\n");
            end if;
          then fail();
         end match;

end expHasCref;

protected function isCrefInIFEXP
" Returns true if expression is DAE.IFEXP(f(cr)) or e.g. sign(f(cr)) for cr = incr
ToDo: fix me for all cases!!
"
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
    case(DAE.CALL(path = Absyn.IDENT(name = "sign"),expLst = {e1}),_,_) then Expression.expHasCrefNoPreOrStart(e1, incr);
    case(DAE.CALL(path = Absyn.IDENT(name = "smooth"),expLst = {_,e1}),_,_) then isCrefInIFEXPwork(e1,incr,inres);
    case(DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {e1,_,_}),_,_)then Expression.expHasCrefNoPreOrStart(e1,incr);
    case(DAE.CAST(exp =e1),_,_) then isCrefInIFEXPwork(e1,incr,inres);
    case(_,_,_) then false;
  end match;
end isCrefInIFEXPwork;

protected function makeProductLstSort
 "Takes a list of expressions an makes a product
  expression multiplying all elements in the list.

- a*if(b,c,d) -> if(b,a*c,a*d)

"
  input list<DAE.Exp> inExpLst;
  output DAE.Exp outExp;
protected
  DAE.Type tp;
  list<DAE.Exp> expLstDiv, expLst, expLst2;
  DAE.Exp e, e1, e2;
  DAE.Operator op;
algorithm
  if List.isEmpty(inExpLst) then
    outExp := DAE.RCONST(1.0);
  return;
  end if;

  tp := Expression.typeof(listGet(inExpLst,1));

  (expLstDiv, expLst) :=  List.splitOnTrue(inExpLst, Expression.isDivBinary);
  outExp := makeProductLstSort2(expLst, tp);
  if not List.isEmpty(expLstDiv) then
    expLst2 := {};
    expLst := {};

    for elem in expLstDiv loop
      DAE.BINARY(e1,op,e2) := elem;
      expLst := e1::expLst;
      expLst2 := e2::expLst2;
    end for;

    if not List.isEmpty(expLst2) then
      e := makeProductLstSort(expLst2);
      if not Expression.isOne(e) then
        outExp := Expression.makeDiv(outExp,e);
      end if;
    end if;

    if not List.isEmpty(expLst) then
      e := makeProductLstSort(expLst);
      outExp := Expression.expMul(outExp,e);
    end if;

  end if;

end makeProductLstSort;

protected function makeProductLstSort2
  input list<DAE.Exp> inExpLst;
  input DAE.Type tp;
  output DAE.Exp outExp := Expression.makeConstOne(tp);
protected
  list<DAE.Exp> rest;
algorithm
  rest := ExpressionSimplify.simplifyList(inExpLst, {});
  for elem in rest loop
    if not Expression.isOne(elem) then
    outExp := match(elem)
              local DAE.Exp e1,e2,e3;
              case(DAE.IFEXP(e1,e2,e3))
              then DAE.IFEXP(e1, Expression.expMul(outExp,e2), Expression.expMul(outExp,e3));
              else Expression.expMul(outExp, elem);
              end match;
    end if;
  end for;

end makeProductLstSort2;

annotation(__OpenModelica_Interface="backend");
end ExpressionSolve;
