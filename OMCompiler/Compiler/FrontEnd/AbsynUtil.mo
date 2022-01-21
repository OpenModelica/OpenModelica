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

encapsulated package AbsynUtil

protected import Absyn;
protected import Dump;
protected import Error;
protected import List;
protected import System;
protected import Util;
import MetaModelica.Dangerous.listReverseInPlace;

public constant Absyn.ClassDef dummyParts = Absyn.PARTS({},{},{},{},NONE());
public constant Absyn.Info dummyInfo = SOURCEINFO("",false,0,0,0,0,0.0);
public constant Absyn.Program dummyProgram = Absyn.PROGRAM({},Absyn.TOP());

public function traverseExp<Arg>
" Traverses all subexpressions of an Absyn.Exp expression.
  Takes a function and an extra argument passed through the traversal.
  NOTE:This function was copied from Expression.traverseExpression."
  input Absyn.Exp inExp;
  input FuncType inFunc;
  input Arg inArg;
  output Absyn.Exp outExp;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outExp,outArg) := traverseExpBidir(inExp,dummyTraverseExp,inFunc,inArg);
end traverseExp;

public function traverseExpTopDown<Arg>
" Traverses all subexpressions of an Absyn.Exp expression.
  Takes a function and an extra argument passed through the traversal."
  input Absyn.Exp inExp;
  input FuncType inFunc;
  input Arg inArg;
  output Absyn.Exp outExp;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outExp,outArg) := traverseExpBidir(inExp,inFunc,dummyTraverseExp,inArg);
end traverseExpTopDown;

public function traverseExpList<Arg>
"calls traverseExp on each element in the given list"
  input list<Absyn.Exp> inExpList;
  input FuncType inFunc;
  input Arg inArg;
  output list<Absyn.Exp> outExpList;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outExpList,outArg) := traverseExpListBidir(inExpList,dummyTraverseExp,inFunc,inArg);
end traverseExpList;

public function traverseExpListBidir<Arg>
  "Traverses a list of expressions, calling traverseExpBidir on each
  expression."
  input list<Absyn.Exp> inExpl;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output list<Absyn.Exp> outExpl;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outExpl, outArg) := List.map2FoldCheckReferenceEq(inExpl, traverseExpBidir, enterFunc, exitFunc, inArg);
end traverseExpListBidir;

public function traverseExpBidir<Arg>
  "This function takes an expression and a tuple with an enter function, an exit
  function, and an extra argument. For each expression it encounters it calls
  the enter function with the expression and the extra argument. It then
  traverses all subexpressions in the expression and calls traverseExpBidir on
  them with the updated argument. Finally it calls the exit function, again with
  the updated argument. This means that this function is bidirectional, and can
  be used to emulate both top-down and bottom-up traversal."
  input Absyn.Exp inExp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output Absyn.Exp e;
  output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (e, arg) := enterFunc(inExp, inArg);
  (e, arg) := traverseExpBidirSubExps(e, enterFunc, exitFunc, arg);
  (e, arg) := exitFunc(e, arg);
end traverseExpBidir;

public function traverseExpOptBidir<Arg>
  "Same as traverseExpBidir, but with an optional expression. Calls
  traverseExpBidir if the option is SOME(), or just returns the input if it's
  NONE()"
  input Option<Absyn.Exp> inExp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output Option<Absyn.Exp> outExp;
  output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outExp, arg) := match inExp
    local
      Absyn.Exp e1,e2;

    case SOME(e1)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, inArg);
      then
        (if referenceEq(e1,e2) then inExp else SOME(e2), arg);

    else (inExp, inArg);
  end match;
end traverseExpOptBidir;

protected function traverseExpBidirSubExps<Arg>
  "Helper function to traverseExpBidir. Traverses the subexpressions of an
  expression and calls traverseExpBidir on them."
  input output Absyn.Exp exp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (exp, arg) := match exp
    local
      Absyn.Exp e1, e1m, e2, e2m, e3, e3m;
      Option<Absyn.Exp> oe1, oe1m;
      Absyn.ComponentRef cref, crefm;
      list<tuple<Absyn.Exp, Absyn.Exp>> else_ifs1,else_ifs2;
      list<Absyn.Exp> expl1,expl2;
      list<list<Absyn.Exp>> mat_expl;
      Absyn.FunctionArgs fargs1,fargs2;
      String error_msg;
      Absyn.Ident id, enterName, exitName;
      list<Absyn.Case> match_cases;

    case Absyn.INTEGER() then (exp, arg);
    case Absyn.REAL() then (exp, arg);
    case Absyn.STRING() then (exp, arg);
    case Absyn.BOOL() then (exp, arg);

    case Absyn.CREF(componentRef = cref)
      equation
        (crefm, arg) = traverseExpBidirCref(cref, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cref,crefm) then exp else Absyn.CREF(crefm), arg);

    case Absyn.BINARY(exp1 = e1, exp2 = e2)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then exp else Absyn.BINARY(e1m, exp.op, e2m), arg);

    case Absyn.UNARY(exp = e1)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then exp else Absyn.UNARY(exp.op, e1m), arg);

    case Absyn.LBINARY(exp1 = e1, exp2 = e2)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then exp else Absyn.LBINARY(e1m, exp.op, e2m), arg);

    case Absyn.LUNARY(exp = e1)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then exp else Absyn.LUNARY(exp.op, e1m), arg);

    case Absyn.RELATION(exp1 = e1, exp2 = e2)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then exp else Absyn.RELATION(e1m, exp.op, e2m), arg);

    case Absyn.IFEXP(ifExp = e1, trueBranch = e2, elseBranch = e3, elseIfBranch = else_ifs1)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
        (e3m, arg) = traverseExpBidir(e3, enterFunc, exitFunc, arg);
        (else_ifs2, arg) = List.map2FoldCheckReferenceEq(else_ifs1, traverseExpBidirElseIf, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) and referenceEq(e3,e3m) and referenceEq(else_ifs1,else_ifs2) then exp else Absyn.IFEXP(e1m, e2m, e3m, else_ifs2), arg);

    case Absyn.CALL(function_ = cref, functionArgs = fargs1)
      equation
        (fargs2, arg) = traverseExpBidirFunctionArgs(fargs1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(fargs1,fargs2) then exp else Absyn.CALL(cref, fargs2, exp.typeVars), arg);

    case Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = fargs1)
      equation
        (fargs2, arg) = traverseExpBidirFunctionArgs(fargs1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(fargs1,fargs2) then exp else Absyn.PARTEVALFUNCTION(cref, fargs2), arg);

    case Absyn.ARRAY(arrayExp = expl1)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then exp else Absyn.ARRAY(expl2), arg);

    case Absyn.MATRIX(matrix = mat_expl)
      equation
        (mat_expl, arg) = List.map2FoldCheckReferenceEq(mat_expl, traverseExpListBidir, enterFunc, exitFunc, arg);
      then
        (Absyn.MATRIX(mat_expl), arg);

    case Absyn.RANGE(start = e1, step = oe1, stop = e2)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (oe1m, arg) = traverseExpOptBidir(oe1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) and referenceEq(oe1,oe1m) then exp else Absyn.RANGE(e1m, oe1m, e2m), arg);

    case Absyn.END() then (exp, arg);

    case Absyn.TUPLE(expressions = expl1)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then exp else Absyn.TUPLE(expl2), arg);

    case Absyn.AS(id = id, exp = e1)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then exp else Absyn.AS(id, e1m), arg);

    case Absyn.CONS(head = e1, rest = e2)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then exp else Absyn.CONS(e1m, e2m), arg);

    case Absyn.MATCHEXP(inputExp = e1, cases = match_cases)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (match_cases, arg) = List.map2FoldCheckReferenceEq(match_cases, traverseMatchCase, enterFunc, exitFunc, arg);
      then
        (Absyn.MATCHEXP(exp.matchTy, e1, exp.localDecls, match_cases, exp.comment), arg);

    case Absyn.LIST(exps = expl1)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then exp else Absyn.LIST(expl2), arg);

    case Absyn.CODE()
      then (exp, arg);

    case Absyn.DOT()
      equation
        (e1, arg) = traverseExpBidir(exp.exp, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(exp.index, enterFunc, exitFunc, arg);
      then
        (if referenceEq(exp.exp,e1) and referenceEq(exp.index,e2) then exp else Absyn.DOT(e1, e2), arg);

    else
      algorithm
        (,,enterName) := System.dladdr(enterFunc);
        (,,exitName) := System.dladdr(exitFunc);
        error_msg := "in traverseExpBidirSubExps(" + enterName + ", " + exitName + ") - Unknown expression: ";
        error_msg := error_msg + Dump.printExpStr(exp);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();

  end match;
end traverseExpBidirSubExps;

public function traverseExpBidirCref<Arg>
  "Helper function to traverseExpBidirSubExps. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input output Absyn.ComponentRef cref;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (cref, arg) := match cref
    local
      Absyn.Ident name;
      Absyn.ComponentRef cr1,cr2;
      list<Absyn.Subscript> subs1,subs2;

    case Absyn.CREF_FULLYQUALIFIED(componentRef = cr1)
      equation
        (cr2, arg) = traverseExpBidirCref(cr1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cr1,cr2) then cref else crefMakeFullyQualified(cr2), arg);

    case Absyn.CREF_QUAL(name = name, subscripts = subs1, componentRef = cr1)
      equation
        (subs2, arg) = List.map2FoldCheckReferenceEq(subs1, traverseExpBidirSubs, enterFunc, exitFunc, arg);
        (cr2, arg) = traverseExpBidirCref(cr1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cr1,cr2) and referenceEq(subs1,subs2) then cref else Absyn.CREF_QUAL(name, subs2, cr2), arg);

    case Absyn.CREF_IDENT(name = name, subscripts = subs1)
      equation
        (subs2, arg) = List.map2FoldCheckReferenceEq(subs1, traverseExpBidirSubs, enterFunc, exitFunc, arg);
      then
        (if referenceEq(subs1,subs2) then cref else Absyn.CREF_IDENT(name, subs2), arg);

    case Absyn.ALLWILD() then (cref, arg);
    case Absyn.WILD() then (cref, arg);
  end match;
end traverseExpBidirCref;

public function traverseExpBidirSubs<Arg>
  "Helper function to traverseExpBidirCref. Traverses expressions in a
  subscript."
  input output Absyn.Subscript subscript;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (subscript, arg) := match subscript
    local
      Absyn.Exp e1,e2;

    case Absyn.SUBSCRIPT(subscript = e1)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e2) then subscript else Absyn.SUBSCRIPT(e2), arg);

    case Absyn.NOSUB() then (subscript, arg);
  end match;
end traverseExpBidirSubs;

public function traverseExpBidirElseIf<Arg>
  "Helper function to traverseExpBidirSubExps. Traverses the expressions in an
  elseif branch."
  input tuple<Absyn.Exp, Absyn.Exp> inElseIf;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output tuple<Absyn.Exp, Absyn.Exp> outElseIf;
  output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
protected
  Absyn.Exp e1, e2;
algorithm
  (e1, e2) := inElseIf;
  (e1, arg) := traverseExpBidir(e1, enterFunc, exitFunc, inArg);
  (e2, arg) := traverseExpBidir(e2, enterFunc, exitFunc, arg);
  outElseIf := (e1, e2);
end traverseExpBidirElseIf;

public function traverseExpBidirFunctionArgs<Arg>
  "Helper function to traverseExpBidirSubExps. Traverses the expressions in a
  list of function argument."
  input output Absyn.FunctionArgs args;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (args, arg) := match args
    local
      Absyn.Exp e1,e2;
      list<Absyn.Exp> expl1,expl2;
      list<Absyn.NamedArg> named_args1,named_args2;
      Absyn.ForIterators iters1,iters2;
      Absyn.ReductionIterType iterType;

    case Absyn.FUNCTIONARGS(args = expl1, argNames = named_args1)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
        (named_args2, arg) = List.map2FoldCheckReferenceEq(named_args1, traverseExpBidirNamedArg, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) and referenceEq(named_args1,named_args2) then args else Absyn.FUNCTIONARGS(expl2, named_args2), arg);

    case Absyn.FOR_ITER_FARG(e1, iterType, iters1)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (iters2, arg) = List.map2FoldCheckReferenceEq(iters1, traverseExpBidirIterator, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e2) and referenceEq(iters1,iters2) then args else Absyn.FOR_ITER_FARG(e2, iterType, iters2), arg);
  end match;
end traverseExpBidirFunctionArgs;

public function traverseExpBidirNamedArg<Arg>
  "Helper function to traverseExpBidirFunctionArgs. Traverses the expressions in
  a named function argument."
  input Absyn.NamedArg inArg;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inExtra;
  output Absyn.NamedArg outArg;
  output Arg outExtra;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
protected
  Absyn.Ident name;
  Absyn.Exp value1,value2;
algorithm
  Absyn.NAMEDARG(name, value1) := inArg;
  (value2, outExtra) := traverseExpBidir(value1, enterFunc, exitFunc, inExtra);
  outArg := if referenceEq(value1,value2) then inArg else Absyn.NAMEDARG(name, value2);
end traverseExpBidirNamedArg;

public function traverseExpBidirIterator<Arg>
  "Helper function to traverseExpBidirFunctionArgs. Traverses the expressions in
  an iterator."
  input Absyn.ForIterator inIterator;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output Absyn.ForIterator outIterator;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
protected
  Absyn.Ident name;
  Option<Absyn.Exp> guardExp1,guardExp2,range1,range2;
algorithm
  Absyn.ITERATOR(name=name, guardExp=guardExp1, range=range1) := inIterator;
  (guardExp2, outArg) := traverseExpOptBidir(guardExp1, enterFunc, exitFunc, inArg);
  (range2, outArg) := traverseExpOptBidir(range1, enterFunc, exitFunc, outArg);
  outIterator := if referenceEq(guardExp1,guardExp2) and referenceEq(range1,range2) then inIterator else Absyn.ITERATOR(name, guardExp2, range2);
end traverseExpBidirIterator;

public function traverseMatchCase<Arg>
  input output Absyn.Case matchCase;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (matchCase, arg) := match matchCase
    local
      Absyn.Exp pattern, result;
      Absyn.Info info, resultInfo, pinfo;
      list<Absyn.ElementItem> ldecls;
      Absyn.ClassPart cp;
      Option<String> cmt;
      Option<Absyn.Exp> patternGuard;

    case Absyn.CASE(pattern, patternGuard, pinfo, ldecls, cp, result, resultInfo, cmt, info)
      equation
        (pattern, arg) = traverseExpBidir(pattern, enterFunc, exitFunc, arg);
        (patternGuard, arg) = traverseExpOptBidir(patternGuard, enterFunc, exitFunc, arg);
        (cp, arg) = traverseClassPartBidir(cp, enterFunc, exitFunc, arg);
        (result, arg) = traverseExpBidir(result, enterFunc, exitFunc, arg);
      then
        (Absyn.CASE(pattern, patternGuard, pinfo, ldecls, cp, result, resultInfo, cmt, info), arg);

    case Absyn.ELSE(ldecls, cp, result, resultInfo, cmt, info)
      equation
        (cp, arg) = traverseClassPartBidir(cp, enterFunc, exitFunc, arg);
        (result, arg) = traverseExpBidir(result, enterFunc, exitFunc, arg);
      then
        (Absyn.ELSE(ldecls, cp, result, resultInfo, cmt, info), arg);

  end match;
end traverseMatchCase;

protected function traverseClassPartBidir<Arg>
  input output Absyn.ClassPart cp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (cp, arg) := match cp
    local
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.EquationItem> eqs;

    case Absyn.ALGORITHMS(algs)
      algorithm
        (algs, arg) := List.map2FoldCheckReferenceEq(algs, traverseAlgorithmItemBidir, enterFunc, exitFunc, arg);
      then
        (Absyn.ALGORITHMS(algs),arg);

    case Absyn.EQUATIONS(eqs)
      algorithm
        (eqs, arg) := List.map2FoldCheckReferenceEq(eqs, traverseEquationItemBidir, enterFunc, exitFunc, arg);
      then
        (Absyn.EQUATIONS(eqs),arg);
  end match;
end traverseClassPartBidir;

protected function traverseEquationItemListBidir<Arg>
  input list<Absyn.EquationItem> inEquationItems;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output list<Absyn.EquationItem> outEquationItems;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outEquationItems, outArg) := List.map2FoldCheckReferenceEq(inEquationItems, traverseEquationItemBidir, enterFunc, exitFunc, inArg);
end traverseEquationItemListBidir;

protected function traverseAlgorithmItemListBidir<Arg>
  input list<Absyn.AlgorithmItem> inAlgs;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output list<Absyn.AlgorithmItem> outAlgs;
  output Arg outArg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  (outAlgs, outArg) := List.map2FoldCheckReferenceEq(inAlgs, traverseAlgorithmItemBidir, enterFunc, exitFunc, inArg);
end traverseAlgorithmItemListBidir;

protected function traverseAlgorithmItemBidir<Arg>
  input output Absyn.AlgorithmItem algorithmItem;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  () := match algorithmItem
    local
      Absyn.Algorithm alg;

    case Absyn.ALGORITHMITEM(algorithm_ = alg)
      algorithm
        (alg, arg) := traverseAlgorithmBidir(alg, enterFunc, exitFunc, arg);
        algorithmItem.algorithm_ := alg;
      then
        ();

    case Absyn.ALGORITHMITEMCOMMENT() then ();
  end match;
end traverseAlgorithmItemBidir;

protected function traverseEquationItemBidir<Arg>
  input output Absyn.EquationItem equationItem;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  () := match equationItem
    local
      Absyn.Equation eq;

    case Absyn.EQUATIONITEM(equation_ = eq)
      algorithm
        (eq, arg) := traverseEquationBidir(eq, enterFunc, exitFunc, arg);
        equationItem.equation_ := eq;
      then
        ();

  end match;
end traverseEquationItemBidir;

public function traverseEquationBidir<Arg>
  input output Absyn.Equation eq;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  eq := match eq
    local
      Absyn.Exp e1, e2;
      list<Absyn.EquationItem> eqil1, eqil2;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> else_branch;
      Absyn.ComponentRef cref1, cref2;
      Absyn.ForIterators iters;
      Absyn.FunctionArgs func_args;
      Absyn.EquationItem eq1;

    case Absyn.EQ_IF(ifExp = e1, equationTrueItems = eqil1, elseIfBranches = else_branch, equationElseItems = eqil2)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
        (else_branch,arg) = List.map2FoldCheckReferenceEq(else_branch, traverseEquationBidirElse, enterFunc, exitFunc, arg);
        (eqil2,arg) = traverseEquationItemListBidir(eqil2, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_IF(e1, eqil1, else_branch, eqil2);

    case Absyn.EQ_EQUALS(leftSide = e1, rightSide = e2)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_EQUALS(e1, e2);

    case Absyn.EQ_PDE(leftSide = e1, rightSide = e2, domain = cref1)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
        cref1 = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_PDE(e1, e2,cref1);

    case Absyn.EQ_CONNECT(connector1 = cref1, connector2 = cref2)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (cref2, arg) = traverseExpBidirCref(cref2, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_CONNECT(cref1, cref2);

    case Absyn.EQ_FOR(iterators = iters, forEquations = eqil1)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_FOR(iters, eqil1);

    case Absyn.EQ_WHEN_E(whenExp = e1, whenEquations = eqil1, elseWhenEquations = else_branch)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseEquationBidirElse, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_WHEN_E(e1, eqil1, else_branch);

    case Absyn.EQ_NORETCALL(functionName = cref1, functionArgs = func_args)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (func_args, arg) = traverseExpBidirFunctionArgs(func_args, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_NORETCALL(cref1, func_args);

    case Absyn.EQ_FAILURE(equ = eq1)
      equation
        (eq1, arg) = traverseEquationItemBidir(eq1, enterFunc, exitFunc, arg);
      then
        Absyn.EQ_FAILURE(eq1);

  end match;
end traverseEquationBidir;

protected function traverseEquationBidirElse<Arg>
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inElse;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output tuple<Absyn.Exp, list<Absyn.EquationItem>> outElse;
  output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
protected
  Absyn.Exp e;
  list<Absyn.EquationItem> eqil;
algorithm
  (e, eqil) := inElse;
  (e, arg) := traverseExpBidir(e, enterFunc, exitFunc, inArg);
  (eqil, arg) := traverseEquationItemListBidir(eqil, enterFunc, exitFunc, arg);
  outElse := (e, eqil);
end traverseEquationBidirElse;

protected function traverseAlgorithmBidirElse<Arg>
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inElse;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Arg inArg;
  output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> outElse;
  output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
protected
  Absyn.Exp e;
  list<Absyn.AlgorithmItem> algs;
algorithm
  (e, algs) := inElse;
  (e, arg) := traverseExpBidir(e, enterFunc, exitFunc, inArg);
  (algs, arg) := traverseAlgorithmItemListBidir(algs, enterFunc, exitFunc, arg);
  outElse := (e, algs);
end traverseAlgorithmBidirElse;

protected function traverseAlgorithmBidir<Arg>
  input output Absyn.Algorithm alg;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input output Arg arg;

  partial function FuncType
    input output Absyn.Exp exp;
    input output Arg arg;
  end FuncType;
algorithm
  alg := match alg
    local
      Absyn.Exp e1, e2;
      list<Absyn.AlgorithmItem> algs1, algs2;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> else_branch;
      Absyn.ComponentRef cref1, cref2;
      Absyn.ForIterators iters;
      Absyn.FunctionArgs func_args;

    case Absyn.ALG_ASSIGN(e1, e2)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_ASSIGN(e1, e2);

    case Absyn.ALG_IF(e1, algs1, else_branch, algs2)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseAlgorithmBidirElse, enterFunc, exitFunc, arg);
        (algs2, arg) = traverseAlgorithmItemListBidir(algs2, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_IF(e1, algs1, else_branch, algs2);

    case Absyn.ALG_FOR(iters, algs1)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_FOR(iters, algs1);

    case Absyn.ALG_PARFOR(iters, algs1)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_PARFOR(iters, algs1);

    case Absyn.ALG_WHILE(e1, algs1)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_WHILE(e1, algs1);

    case Absyn.ALG_WHEN_A(e1, algs1, else_branch)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseAlgorithmBidirElse, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_WHEN_A(e1, algs1, else_branch);

    case Absyn.ALG_NORETCALL(cref1, func_args)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (func_args, arg) = traverseExpBidirFunctionArgs(func_args, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_NORETCALL(cref1, func_args);

    case Absyn.ALG_RETURN() then alg;
    case Absyn.ALG_BREAK() then alg;
    case Absyn.ALG_CONTINUE() then alg;

    case Absyn.ALG_FAILURE(algs1)
      equation
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_FAILURE(algs1);

    case Absyn.ALG_TRY(algs1, algs2)
      equation
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (algs2, arg) = traverseAlgorithmItemListBidir(algs2, enterFunc, exitFunc, arg);
      then
        Absyn.ALG_TRY(algs1, algs2);

  end match;
end traverseAlgorithmBidir;

public function makeIdentPathFromString
  input String s;
  output Absyn.Path p;
algorithm
  p := Absyn.IDENT(s);
annotation(__OpenModelica_EarlyInline = true);
end makeIdentPathFromString;

public function makeQualifiedPathFromStrings
  input String s1;
  input String s2;
  output Absyn.Path p;
algorithm
  p := Absyn.QUALIFIED(s1,Absyn.IDENT(s2));
annotation(__OpenModelica_EarlyInline = true);
end makeQualifiedPathFromStrings;

public function className "returns the class name of a Absyn.Class as a Absyn.Path"
  input Absyn.Class cl;
  output Absyn.Path name;
protected
  String id;
algorithm
  Absyn.CLASS(name = id) := cl;
  name := Absyn.IDENT(id);
end className;

public function isClassNamed
  input String inName;
  input Absyn.Class inClass;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match inClass
    case Absyn.CLASS() then inName == inClass.name;
    else false;
  end match;
end isClassNamed;

public function elementSpecName
  "The Absyn.ElementSpec type contains the name of the element, and this function
   extracts this name."
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match (inElementSpec)
    local Absyn.Ident n;

    case Absyn.CLASSDEF(class_ = Absyn.CLASS(name = n)) then n;
    case Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n))}) then n;
  end match;
end elementSpecName;

public function isClassdef
  input Absyn.Element inElement;
  output Boolean b;
algorithm
  b := match inElement
    case Absyn.ELEMENT(specification=Absyn.CLASSDEF()) then true;
    else false;
  end match;
end isClassdef;

public function printImportString
  "This function takes a Absyn.Import and prints it as a flat-string."
  input Absyn.Import imp;
  output String ostring;
algorithm
  ostring := match(imp)
    case Absyn.NAMED_IMPORT() then imp.name;
    case Absyn.QUAL_IMPORT() then pathString(imp.path);
    case Absyn.UNQUAL_IMPORT() then pathString(imp.path);
  end match;
end printImportString;

public function expString "returns the string of an expression if it is a string constant."
  input Absyn.Exp exp;
  output String str;
algorithm
  Absyn.STRING(str) := exp;
end expString;

public function expCref "returns the componentRef of an expression if matches."
  input Absyn.Exp exp;
  output Absyn.ComponentRef cr;
algorithm
  Absyn.CREF(cr) := exp;
end expCref;

public function crefExp "returns the componentRef of an expression if matches."
 input Absyn.ComponentRef cr;
 output Absyn.Exp exp;
algorithm
  exp := Absyn.CREF(cr);
annotation(__OpenModelica_EarlyInline = true);
end crefExp;

public function pathEqual "Returns true if two paths are equal."
  input Absyn.Path path1;
  input Absyn.Path path2;
  output Boolean equal;
algorithm
  equal := match (path1, path2)
    // fully qual vs. path
    case (Absyn.FULLYQUALIFIED(), _) then pathEqual(path1.path, path2);
    // path vs. fully qual
    case (_, Absyn.FULLYQUALIFIED()) then pathEqual(path1, path2.path);
    // ident vs. ident
    case (Absyn.IDENT(),Absyn.IDENT()) then stringEq(path1.name, path2.name);
    // qual ident vs. qual ident
    case (Absyn.QUALIFIED(),Absyn.QUALIFIED())
      then stringEq(path1.name, path2.name) and pathEqual(path1.path, path2.path);
    // other return false
    else false;
  end match;
end pathEqual;

public function pathEqualCaseInsensitive "Returns true if two paths are equal."
  input Absyn.Path path1;
  input Absyn.Path path2;
  output Boolean equal;
algorithm
  equal := match (path1, path2)
    // fully qual vs. path
    case (Absyn.FULLYQUALIFIED(), _) then pathEqualCaseInsensitive(path1.path, path2);
    // path vs. fully qual
    case (_, Absyn.FULLYQUALIFIED()) then pathEqualCaseInsensitive(path1, path2.path);
    // ident vs. ident
    case (Absyn.IDENT(),Absyn.IDENT()) then stringEq(System.tolower(path1.name), System.tolower(path2.name));
    // qual ident vs. qual ident
    case (Absyn.QUALIFIED(),Absyn.QUALIFIED())
      then stringEq(System.tolower(path1.name), System.tolower(path2.name)) and
           pathEqualCaseInsensitive(path1.path, path2.path);
    // other return false
    else false;
  end match;
end pathEqualCaseInsensitive;

public function typeSpecEqual
  "Author BZ 2009-01
   Check whether two type specs are equal or not."
  input Absyn.TypeSpec a,b;
  output Boolean ob;
algorithm
  ob := match(a,b)
    local
      Absyn.Path p1,p2;
      Option<Absyn.ArrayDim> oad1,oad2;
      list<Absyn.TypeSpec> lst1,lst2;
      Absyn.Ident i1, i2;
      Integer pos1, pos2;

    case (Absyn.TPATH(), Absyn.TPATH())
      then pathEqual(a.path, b.path) and optArrayDimEqual(a.arrayDim, b.arrayDim);

    case (Absyn.TCOMPLEX(), Absyn.TCOMPLEX())
      then pathEqual(a.path, b.path) and
           List.isEqualOnTrue(a.typeSpecs, b.typeSpecs, typeSpecEqual) and
           optArrayDimEqual(a.arrayDim, b.arrayDim);

    else false;
  end match;
end typeSpecEqual;

public function optArrayDimEqual
  "Author BZ
   helper function for typeSpecEqual"
  input Option<Absyn.ArrayDim> oad1,oad2;
  output Boolean b;
algorithm
  b:= match(oad1,oad2)
    local
      list<Absyn.Subscript> ad1,ad2;

    case(SOME(ad1),SOME(ad2))
      then List.isEqualOnTrue(ad1,ad2,subscriptEqual);
    case(NONE(),NONE()) then true;
    else false;
  end match;
end optArrayDimEqual;

public function typeSpecPathString "This function simply converts a Absyn.Path to a string."
  input Absyn.TypeSpec tp;
  output String s = pathString(typeSpecPath(tp));
end typeSpecPathString;

public function typeSpecPath
  "Converts a Absyn.TypeSpec to Absyn.Path"
  input Absyn.TypeSpec tp;
  output Absyn.Path op;
algorithm
  op := match(tp)
    case Absyn.TCOMPLEX() then tp.path;
    case Absyn.TPATH() then tp.path;
  end match;
end typeSpecPath;

public function typeSpecDimensions
  "Returns the dimensions of a Absyn.TypeSpec."
  input Absyn.TypeSpec inTypeSpec;
  output Absyn.ArrayDim outDimensions;
algorithm
  outDimensions := match(inTypeSpec)
    local
      Absyn.ArrayDim dim;

    case Absyn.TPATH(arrayDim = SOME(dim)) then dim;
    case Absyn.TCOMPLEX(arrayDim = SOME(dim)) then dim;
    else {};
  end match;
end typeSpecDimensions;

public function pathString "This function simply converts a Absyn.Path to a string."
  input Absyn.Path path;
  input String delimiter=".";
  input Boolean usefq=true;
  input Boolean reverse=false;
  output String s;
protected
  Absyn.Path p1,p2;
  Integer count=0, len=0, dlen=stringLength(delimiter);
  Boolean b;
algorithm
  // First, calculate the length of the string to be generated
  p1 :=  if usefq then path else makeNotFullyQualified(path);
  _ := match p1
    case Absyn.IDENT()
      algorithm
        // Do not allocate memory if we're just going to copy the only identifier
        s := p1.name;
        return;
      then ();
    else ();
  end match;
  p2 := p1;
  b := true;
  while b loop
    (p2,len,count,b) := match p2
      case Absyn.IDENT() then (p2,len+1,count+stringLength(p2.name),false);
      case Absyn.QUALIFIED() then (p2.path,len+1,count+stringLength(p2.name),true);
      case Absyn.FULLYQUALIFIED() then (p2.path,len+1,count,true);
    end match;
  end while;
  s := pathStringWork(p1, (len-1)*dlen+count, delimiter, dlen, reverse);
end pathString;

protected

function pathStringWork
  input Absyn.Path inPath;
  input Integer len;
  input String delimiter;
  input Integer dlen;
  input Boolean reverse;
  output String s="";
protected
  Absyn.Path p=inPath;
  Boolean b=true;
  Integer count=0;
  // Allocate a string of the exact required length
  System.StringAllocator sb=System.StringAllocator(len);
algorithm
  // Fill the string
  while b loop
    (p,count,b) := match p
      case Absyn.IDENT()
        algorithm
          System.stringAllocatorStringCopy(sb, p.name, if reverse then len-count-stringLength(p.name) else count);
        then (p,count+stringLength(p.name),false);
      case Absyn.QUALIFIED()
        algorithm
          System.stringAllocatorStringCopy(sb, p.name, if reverse then len-count-dlen-stringLength(p.name) else count);
          System.stringAllocatorStringCopy(sb, delimiter, if reverse then len-count-dlen else count+stringLength(p.name));
        then (p.path,count+stringLength(p.name)+dlen,true);
      case Absyn.FULLYQUALIFIED()
        algorithm
          System.stringAllocatorStringCopy(sb, delimiter, if reverse then len-count-dlen else count);
        then (p.path,count+dlen,true);
    end match;
  end while;
  // Return the string
  s := System.stringAllocatorResult(sb,s);
end pathStringWork;

public

function pathStringNoQual = pathString(usefq=false);

function pathStringDefault
  input Absyn.Path path;
  output String s = pathString(path);
end pathStringDefault;

public function classNameCompare
  input Absyn.Class c1,c2;
  output Integer o;
algorithm
  o := stringCompare(c1.name, c2.name);
end classNameCompare;

public function classNameGreater
  input Absyn.Class c1,c2;
  output Boolean b;
algorithm
  b := stringCompare(c1.name, c2.name) > 0;
end classNameGreater;

public function pathCompare
  input Absyn.Path ip1;
  input Absyn.Path ip2;
  output Integer o;
algorithm
  o := match (ip1,ip2)
    local
      Absyn.Path p1,p2;
      String i1,i2;
    case (Absyn.FULLYQUALIFIED(p1),Absyn.FULLYQUALIFIED(p2)) then pathCompare(p1,p2);
    case (Absyn.FULLYQUALIFIED(),_) then 1;
    case (_,Absyn.FULLYQUALIFIED()) then -1;
    case (Absyn.QUALIFIED(i1,p1),Absyn.QUALIFIED(i2,p2))
      equation
        o = stringCompare(i1,i2);
        o = if o == 0 then pathCompare(p1, p2) else o;
      then o;
    case (Absyn.QUALIFIED(),_) then 1;
    case (_,Absyn.QUALIFIED()) then -1;
    case (Absyn.IDENT(i1),Absyn.IDENT(i2))
      then stringCompare(i1,i2);
  end match;
end pathCompare;

public function pathCompareNoQual
  input Absyn.Path ip1;
  input Absyn.Path ip2;
  output Integer o;
algorithm
  o := match (ip1,ip2)
    local
      Absyn.Path p1,p2;
      String i1,i2;
    case (Absyn.FULLYQUALIFIED(p1),p2) then pathCompareNoQual(p1,p2);
    case (p1,Absyn.FULLYQUALIFIED(p2)) then pathCompareNoQual(p1,p2);
    case (Absyn.QUALIFIED(i1,p1),Absyn.QUALIFIED(i2,p2))
      equation
        o = stringCompare(i1,i2);
        o = if o == 0 then pathCompare(p1, p2) else o;
      then o;
    case (Absyn.QUALIFIED(),_) then 1;
    case (_,Absyn.QUALIFIED()) then -1;
    case (Absyn.IDENT(i1),Absyn.IDENT(i2))
      then stringCompare(i1,i2);
  end match;
end pathCompareNoQual;

public function pathHashMod "Hashes a path."
  input Absyn.Path path;
  input Integer mod;
  output Integer hash;
algorithm
// hash := valueHashMod(path,mod);
// print(pathString(path) + " => " + intString(hash) + "\n");
// hash := stringHashDjb2Mod(pathString(path),mod);
// TODO: stringHashDjb2 is missing a default value for the seed; add this once we bootstrapped omc so we can use that function instead of our own hack
  hash := intAbs(intMod(pathHashModWork(path,5381),mod));
end pathHashMod;

public function pathHashModWork "Hashes a path."
  input Absyn.Path path;
  input Integer acc;
  output Integer hash;
algorithm
  hash := match (path,acc)
    local
      Absyn.Path p;
      String s;
      Integer i,i2;
    case (Absyn.FULLYQUALIFIED(p),_) then pathHashModWork(p, acc*31 + 46 /* '.' */);
    case (Absyn.QUALIFIED(s,p),_) equation i = stringHashDjb2(s); i2 = acc*31+46; then pathHashModWork(p, i2*31 + i);
    case (Absyn.IDENT(s),_) equation i = stringHashDjb2(s); i2 = acc*31+46; then i2*31 + i;
  end match;
end pathHashModWork;

public function optPathString "Returns a path converted to string or an empty string if nothing exist"
  input Option<Absyn.Path> inPathOption;
  output String outString;
algorithm
  outString := match (inPathOption)
    local
      Absyn.Path p;
    case NONE() then "";
    case SOME(p) then pathString(p);
  end match;
end optPathString;

public function pathStringUnquoteReplaceDot
" Changes a path to string. Uses the input string as separator.
  If the separtor exists in the string then it is doubled (sep _ then
  a_b changes to a__b) before delimiting
  (Replaces dots with that separator). And also unquotes each ident.
"
  input Absyn.Path inPath;
  input String repStr;
  output String outString;
protected
  list<String> strlst;
  String rep_rep;
algorithm
  rep_rep := repStr + repStr;
  strlst := pathToStringList(inPath);
  strlst := List.map2(strlst,System.stringReplace, repStr, rep_rep);
  strlst := List.map(strlst,System.unquoteIdentifier);
  outString := stringDelimitList(strlst,repStr);
end pathStringUnquoteReplaceDot;

public function stringPath
  "Converts a string into a qualified path."
  input String str;
  output Absyn.Path qualifiedPath;

protected
  list<String> paths;
algorithm
  paths := Util.stringSplitAtChar(str, ".");
  qualifiedPath := stringListPath(paths);
end stringPath;

public function stringListPath
  "Converts a list of strings into a qualified path."
  input list<String> paths;
  output Absyn.Path qualifiedPath = stringListPathReversed(listReverse(paths));
end stringListPath;

public function stringListPathReversed
  "Converts a list of strings into a qualified path, in reverse order.
   Ex: {'a', 'b', 'c'} => c.b.a"
  input list<String> inStrings;
  output Absyn.Path outPath;
protected
  String id;
  list<String> rest_str;
  Absyn.Path path;
algorithm
  id :: rest_str := inStrings;
  outPath := Absyn.IDENT(id);

  for s in rest_str loop
    outPath := Absyn.QUALIFIED(s, outPath);
  end for;
end stringListPathReversed;

public function pathLastIdent
  "Returns the last ident (after last dot) in a path"
  input Absyn.Path path;
  output String outIdent;
algorithm
  outIdent := match path
    case Absyn.QUALIFIED() then pathLastIdent(path.path);
    case Absyn.IDENT() then path.name;
    case Absyn.FULLYQUALIFIED() then pathLastIdent(path.path);
  end match;
end pathLastIdent;

public function pathSetLastIdent
  "Replaces the last identifier in the path."
  input Absyn.Path path;
  input String ident;
  output Absyn.Path outPath;
algorithm
  outPath := match path
    case Absyn.IDENT() then Absyn.IDENT(ident);
    case Absyn.QUALIFIED()
      then Absyn.QUALIFIED(path.name, pathSetLastIdent(path.path, ident));
    case Absyn.FULLYQUALIFIED()
      then Absyn.FULLYQUALIFIED(pathSetLastIdent(path.path, ident));
  end match;
end pathSetLastIdent;

public function pathLast
  "Returns the last ident (after last dot) in a path"
  input output Absyn.Path path;
algorithm
  path := match path
    case Absyn.QUALIFIED() then pathLast(path.path);
    case Absyn.IDENT() then path;
    case Absyn.FULLYQUALIFIED() then pathLast(path.path);
  end match;
end pathLast;

public function pathFirstIdent "Returns the first ident (before first dot) in a path"
  input Absyn.Path path;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match path
    case Absyn.FULLYQUALIFIED() then pathFirstIdent(path.path);
    case Absyn.QUALIFIED() then path.name;
    case Absyn.IDENT() then path.name;
  end match;
end pathFirstIdent;

public function pathSetFirstIdent
  "Replaces the first identifier in a path."
  input Absyn.Path path;
  input String ident;
  output Absyn.Path outPath;
algorithm
  outPath := match path
    case Absyn.IDENT() then Absyn.IDENT(ident);
    case Absyn.QUALIFIED() then Absyn.QUALIFIED(ident, path.path);
    case Absyn.FULLYQUALIFIED()
      then Absyn.FULLYQUALIFIED(pathSetFirstIdent(path.path, ident));
  end match;
end pathSetFirstIdent;

public function pathFirstPath
  input Absyn.Path path;
  output Absyn.Path outPath;
algorithm
  outPath := match path
    case Absyn.IDENT() then path;
    case Absyn.QUALIFIED() then Absyn.IDENT(path.name);
    case Absyn.FULLYQUALIFIED() then pathFirstPath(path.path);
  end match;
end pathFirstPath;

public function pathSecondIdent
  input Absyn.Path inPath;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match(inPath)
    local
      Absyn.Ident n;
      Absyn.Path p;

    case Absyn.QUALIFIED(path = Absyn.QUALIFIED(name = n)) then n;
    case Absyn.QUALIFIED(path = Absyn.IDENT(name = n)) then n;
    case Absyn.FULLYQUALIFIED(path = p) then pathSecondIdent(p);

  end match;
end pathSecondIdent;

public function pathNthIdent
  "Returns the n:th identifier in a path. Fails if n is out of bounds."
  input Absyn.Path path;
  input Integer n;
  output Absyn.Ident ident;
protected
  Absyn.Path p = makeNotFullyQualified(path);
algorithm
  for i in 2:n loop
    Absyn.QUALIFIED(path = p) := p;
  end for;

  ident := pathFirstIdent(p);
end pathNthIdent;

public function pathSetNthIdent
  "Replaces the n:th identifier in a path. Fails if n is out of bounds."
  input Absyn.Path path;
  input Absyn.Ident ident;
  input Integer n;
  output Absyn.Path outPath;
algorithm
  if n == 1 then
    outPath := pathSetFirstIdent(path, ident);
  else
    outPath := match path
      case Absyn.QUALIFIED()
        then Absyn.QUALIFIED(path.name, pathSetNthIdent(path.path, ident, n - 1));
      case Absyn.FULLYQUALIFIED()
        then Absyn.FULLYQUALIFIED(pathSetNthIdent(path.path, ident, n));
    end match;
  end if;
end pathSetNthIdent;

public function pathRest
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := match inPath
    case Absyn.QUALIFIED(path = outPath) then outPath;
    case Absyn.FULLYQUALIFIED(path = outPath) then pathRest(outPath);
  end match;
end pathRest;

public function pathStripSamePrefix
  "strips the same prefix paths and returns the stripped path. e.g pathStripSamePrefix(P.M.A, P.M.B) => A"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath1, inPath2)
    local
      Absyn.Ident ident1, ident2;
      Absyn.Path path1, path2;

    case (_, _)
      equation
        ident1 = pathFirstIdent(inPath1);
        ident2 = pathFirstIdent(inPath2);
        true = stringEq(ident1, ident2);
        path1 = pathRest(inPath1);
        path2 = pathRest(inPath2);
      then
        pathStripSamePrefix(path1, path2);

    else inPath1;
  end matchcontinue;
end pathStripSamePrefix;

public function pathPrefix
  "Returns the prefix of a path, i.e. this.is.a.path => this.is.a"
  input Absyn.Path path;
  output Absyn.Path prefix;
algorithm
  prefix := match path
    case Absyn.FULLYQUALIFIED() then pathPrefix(path.path);
    case Absyn.QUALIFIED(path = Absyn.IDENT()) then Absyn.IDENT(path.name);
    case Absyn.QUALIFIED() then Absyn.QUALIFIED(path.name, pathPrefix(path.path));
  end match;
end pathPrefix;

public function prefixPath
  "Prefixes a path with an identifier."
  input Absyn.Ident prefix;
  input Absyn.Path path;
  output Absyn.Path outPath;
algorithm
  outPath := Absyn.QUALIFIED(prefix, path);
end prefixPath;

public function suffixPath
  "Adds a suffix to a path. Ex:
     suffixPath(a.b.c, 'd') => a.b.c.d"
  input Absyn.Path inPath;
  input Absyn.Ident inSuffix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath, inSuffix)
    local
      Absyn.Ident name;
      Absyn.Path path;

    case (Absyn.IDENT(name), _)
      then Absyn.QUALIFIED(name, Absyn.IDENT(inSuffix));

    case (Absyn.QUALIFIED(name, path), _)
      equation
        path = suffixPath(path, inSuffix);
      then
        Absyn.QUALIFIED(name, path);

    case (Absyn.FULLYQUALIFIED(path), _)
      equation
        path = suffixPath(path, inSuffix);
      then
        Absyn.FULLYQUALIFIED(path);

  end match;
end suffixPath;

public function pathSuffixOf "returns true if suffix_path is a suffix of path"
  input Absyn.Path suffix_path;
  input Absyn.Path path;
  output Boolean res;
algorithm
  res := matchcontinue(suffix_path,path)
  local Absyn.Path p;
    case(_,_)
      equation
      true = pathEqual(suffix_path,path);
      then true;
    case(_,Absyn.FULLYQUALIFIED(path = p))
      then pathSuffixOf(suffix_path,p);
    case(_,Absyn.QUALIFIED(path = p))
      then pathSuffixOf(suffix_path,p);
    else false;
  end matchcontinue;
end pathSuffixOf;

public function pathSuffixOfr "returns true if suffix_path is a suffix of path"
  input Absyn.Path path;
  input Absyn.Path suffix_path;
  output Boolean res;
algorithm
  res := pathSuffixOf(suffix_path, path);
end pathSuffixOfr;

public function pathToStringList
  input Absyn.Path path;
  output list<String> outPaths;
algorithm
  outPaths := listReverse(pathToStringListWork(path,{}));
end pathToStringList;

protected function pathToStringListWork
  input Absyn.Path path;
  input list<String> acc;
  output list<String> outPaths;
algorithm
  outPaths := match(path,acc)
    local
      String n;
      Absyn.Path p;

    case (Absyn.IDENT(name = n),_) then n::acc;
    case (Absyn.FULLYQUALIFIED(path = p),_) then pathToStringListWork(p,acc);
    case (Absyn.QUALIFIED(name = n,path = p),_)
      then pathToStringListWork(p,n::acc);
  end match;
end pathToStringListWork;

public function addSubscriptsLast
  "Function for appending subscripts at end of last ident"
  input Absyn.ComponentRef icr;
  input list<Absyn.Subscript> i;
  output Absyn.ComponentRef ocr;
algorithm
  ocr := match(icr,i)
    local
      list<Absyn.Subscript> subs;
      String id;
      Absyn.ComponentRef cr;

    case (Absyn.CREF_IDENT(id,subs),_)
      then Absyn.CREF_IDENT(id, listAppend(subs, i));

    case (Absyn.CREF_QUAL(id,subs,cr),_)
      equation
        cr = addSubscriptsLast(cr,i);
      then
        Absyn.CREF_QUAL(id,subs,cr);
    case (Absyn.CREF_FULLYQUALIFIED(cr),_)
      equation
        cr = addSubscriptsLast(cr,i);
      then
        crefMakeFullyQualified(cr);
  end match;
end addSubscriptsLast;

public function crefReplaceFirst
  "Replaces the first part of a cref with another cref."
  input Absyn.ComponentRef cref;
  input Absyn.ComponentRef replacement;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match cref
    case Absyn.ComponentRef.CREF_IDENT() then replacement;
    case Absyn.ComponentRef.CREF_QUAL()
      then joinCrefs(replacement, crefStripFirst(cref));
    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      then Absyn.ComponentRef.CREF_FULLYQUALIFIED(crefReplaceFirst(cref.componentRef, replacement));
  end match;
end crefReplaceFirst;

public function crefReplaceFirstIdent "
  Replaces the first part of a cref with a replacement path:
  (a[4].b.c[3], d.e) => d.e[4].b.c[3]
  (a[3], b.c.d) => b.c.d[3]
"
  input Absyn.ComponentRef icref;
  input Absyn.Path replPath;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(icref,replPath)
    local
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr,cref;
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr),_)
      equation
        cr = crefReplaceFirstIdent(cr,replPath);
      then crefMakeFullyQualified(cr);
    case (Absyn.CREF_QUAL(componentRef = cr, subscripts = subs),_)
      equation
        cref = pathToCref(replPath);
        cref = addSubscriptsLast(cref,subs);
      then joinCrefs(cref,cr);
    case (Absyn.CREF_IDENT(subscripts = subs),_)
      equation
        cref = pathToCref(replPath);
        cref = addSubscriptsLast(cref,subs);
      then cref;
  end match;
end crefReplaceFirstIdent;

public function pathPrefixOf
  "Returns true if prefixPath is a prefix of path, false otherwise."
  input Absyn.Path prefixPath;
  input Absyn.Path path;
  output Boolean isPrefix;
algorithm
  isPrefix := match(prefixPath, path)
    local
      Absyn.Path p, p2;
      String id, id2;
    case (Absyn.FULLYQUALIFIED(p), p2) then pathPrefixOf(p, p2);
    case (p, Absyn.FULLYQUALIFIED(p2)) then pathPrefixOf(p, p2);
    case (Absyn.IDENT(id), Absyn.IDENT(id2)) then stringEq(id, id2);
    case (Absyn.IDENT(id), Absyn.QUALIFIED(name = id2)) then stringEq(id, id2);
    case (Absyn.QUALIFIED(id, p), Absyn.QUALIFIED(id2, p2))
      then stringEq(id, id2) and pathPrefixOf(p, p2);
    else false;
  end match;
end pathPrefixOf;

public function removePrefix "removes the prefix_path from path, and returns the rest of path"
  input Absyn.Path prefix_path;
  input Absyn.Path path;
  output Absyn.Path newPath;
algorithm
  newPath := match(prefix_path,path)
    local Absyn.Path p,p2; Absyn.Ident id1,id2;
    // fullyqual path
    case (p,Absyn.FULLYQUALIFIED(p2)) then removePrefix(p,p2);
    // qual
    case (Absyn.QUALIFIED(name=id1,path=p),Absyn.QUALIFIED(name=id2,path=p2))
      equation
        true = stringEq(id1, id2);
      then
        removePrefix(p,p2);
    // ids
    case(Absyn.IDENT(id1),Absyn.QUALIFIED(name=id2,path=p2))
      equation
        true = stringEq(id1, id2);
      then p2;
  end match;
end removePrefix;

public function removePartialPrefix
  "Tries to remove a given prefix from a path with removePrefix. If it fails it
  removes the first identifier in the prefix and tries again, until it either
  succeeds or reaches the end of the prefix. Ex:
    removePartialPrefix(A.B.C, B.C.D.E) => D.E
  "
  input Absyn.Path inPrefix;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue inPrefix
    case _ then removePrefix(inPrefix, inPath);
    case Absyn.QUALIFIED() then removePrefix(inPrefix.path, inPath);
    case Absyn.FULLYQUALIFIED() then removePartialPrefix(inPrefix.path, inPath);
    else inPath;
  end matchcontinue;
end removePartialPrefix;

public function getCrefsFromSubs
  "Author BZ 2009-08
   Function for getting ComponentRefs out from Subscripts"
  input list<Absyn.Subscript> isubs;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Absyn.ComponentRef> crefs;
algorithm
  crefs := match(isubs,includeSubs,includeFunctions)
    local
      list<Absyn.ComponentRef> crefs1;
      Absyn.Exp exp;
      list<Absyn.Subscript> subs;

    case({},_,_) then {};

    case(Absyn.NOSUB()::subs,_,_) then getCrefsFromSubs(subs,includeSubs,includeFunctions);

    case(Absyn.SUBSCRIPT(exp)::subs,_,_)
      equation
        crefs1 = getCrefsFromSubs(subs,includeSubs,includeFunctions);
        crefs = getCrefFromExp(exp,includeSubs,includeFunctions);
      then
        listAppend(crefs,crefs1);
  end match;
end getCrefsFromSubs;

public function getCrefFromExp
  "Returns a flattened list of the
   component references in an expression"
  input Absyn.Exp inExp;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Absyn.ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := match (inExp,includeSubs,includeFunctions)
    local
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> l1,l2,res;
      Absyn.ComponentCondition e1,e2,e3;
      Absyn.Operator op;
      list<tuple<Absyn.ComponentCondition, Absyn.ComponentCondition>> e4;
      Absyn.FunctionArgs farg;
      list<Absyn.ComponentCondition> expl;
      list<list<Absyn.ComponentCondition>> expll;
      list<Absyn.Subscript> subs;
      list<list<Absyn.ComponentRef>> lstres1;
      list<list<Absyn.ComponentRef>> crefll;

    case (Absyn.INTEGER(),_,_) then {};
    case (Absyn.REAL(),_,_) then {};
    case (Absyn.STRING(),_,_) then {};
    case (Absyn.BOOL(),_,_) then {};
    case (Absyn.CREF(componentRef = Absyn.ALLWILD()),_,_) then {};
    case (Absyn.CREF(componentRef = Absyn.WILD()),_,_) then {};
    case (Absyn.CREF(componentRef = cr),false,_) then {cr};

    case (Absyn.CREF(componentRef = (cr)),true,_)
      equation
        subs = getSubsFromCref(cr,includeSubs,includeFunctions);
        l1 = getCrefsFromSubs(subs,includeSubs,includeFunctions);
      then cr::l1;

    case (Absyn.BINARY(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (Absyn.UNARY(exp = e1),_,_)
      equation
        res = getCrefFromExp(e1,includeSubs,includeFunctions);
      then
        res;

    case (Absyn.LBINARY(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (Absyn.LUNARY(exp = e1),_,_)
      equation
        res = getCrefFromExp(e1,includeSubs,includeFunctions);
      then
        res;

    case (Absyn.RELATION(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    // TODO: Handle else if-branches.
    case (Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3),_,_)
      then List.flatten({
        getCrefFromExp(e1, includeSubs, includeFunctions),
        getCrefFromExp(e2, includeSubs, includeFunctions),
        getCrefFromExp(e3, includeSubs, includeFunctions)});

    case (Absyn.CALL(function_ = cr, functionArgs = farg),_,_)
      equation
        res = getCrefFromFarg(farg,includeSubs,includeFunctions);
        res = if includeFunctions then cr::res else res;
      then
        res;
    case (Absyn.PARTEVALFUNCTION(function_ = cr, functionArgs = farg),_,_)
      equation
        res = getCrefFromFarg(farg,includeSubs,includeFunctions);
        res = if includeFunctions then cr::res else res;
      then
        res;
    case (Absyn.ARRAY(arrayExp = expl),_,_)
      equation
        lstres1 = List.map2(expl, getCrefFromExp, includeSubs, includeFunctions);
        res = List.flatten(lstres1);
      then
        res;
    case (Absyn.MATRIX(matrix = expll),_,_)
      equation
        res = List.flatten(List.flatten(List.map2List(expll, getCrefFromExp, includeSubs, includeFunctions)));
      then
        res;
    case (Absyn.RANGE(start = e1,step = SOME(e3),stop = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        l2 = listAppend(l1, l2);
        l1 = getCrefFromExp(e3,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;
    case (Absyn.RANGE(start = e1,step = NONE(),stop = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (Absyn.END(),_,_) then {};

    case (Absyn.TUPLE(expressions = expl),_,_)
      equation
        crefll = List.map2(expl,getCrefFromExp,includeSubs,includeFunctions);
        res = List.flatten(crefll);
      then
        res;

    case (Absyn.CODE(),_,_) then {};

    case (Absyn.AS(exp = e1),_,_) then getCrefFromExp(e1,includeSubs,includeFunctions);

    case (Absyn.CONS(e1,e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (Absyn.LIST(expl),_,_)
      equation
        crefll = List.map2(expl,getCrefFromExp,includeSubs,includeFunctions);
        res = List.flatten(crefll);
      then
        res;

    case (Absyn.MATCHEXP(),_,_) then fail();

    case (Absyn.DOT(),_,_)
      // inExp.index is only allowed to contain names to index the function call; not crefs that are evaluated in any way
      then getCrefFromExp(inExp.exp,includeSubs,includeFunctions);

    else
      equation
        Error.addInternalError(getInstanceName() + " failed " + Dump.printExpStr(inExp), sourceInfo());
      then fail();
  end match;
end getCrefFromExp;

public function getCrefFromFarg "Returns the flattened list of all component references
  present in a list of function arguments."
  input Absyn.FunctionArgs inFunctionArgs;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Absyn.ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := match (inFunctionArgs,includeSubs,includeFunctions)
    local
      list<list<Absyn.ComponentRef>> l1,l2;
      list<Absyn.ComponentRef> fl1,fl2,fl3,res;
      list<Absyn.ComponentCondition> expl;
      list<Absyn.NamedArg> nargl;
      Absyn.ForIterators iterators;
      Absyn.Exp exp;

    case (Absyn.FUNCTIONARGS(args = expl,argNames = nargl),_,_)
      equation
        l1 = List.map2(expl, getCrefFromExp, includeSubs, includeFunctions);
        fl1 = List.flatten(l1);
        l2 = List.map2(nargl, getCrefFromNarg, includeSubs, includeFunctions);
        fl2 = List.flatten(l2);
        res = listAppend(fl1, fl2);
      then
        res;

    case (Absyn.FOR_ITER_FARG(exp,_,iterators),_,_)
      equation
        l1 = List.map2Option(List.map(iterators,iteratorRange),getCrefFromExp,includeSubs,includeFunctions);
        l2 = List.map2Option(List.map(iterators,iteratorGuard),getCrefFromExp,includeSubs,includeFunctions);
        fl1 = List.flatten(l1);
        fl2 = List.flatten(l2);
        fl3 = getCrefFromExp(exp,includeSubs,includeFunctions);
        res = listAppend(fl1,listAppend(fl2, fl3));
      then
        res;

  end match;
end getCrefFromFarg;

public function iteratorName
  input Absyn.ForIterator iterator;
  output String name;
algorithm
  Absyn.ITERATOR(name=name) := iterator;
end iteratorName;

public function iteratorRange
  input Absyn.ForIterator iterator;
  output Option<Absyn.Exp> range;
algorithm
  Absyn.ITERATOR(range=range) := iterator;
end iteratorRange;

public function iteratorGuard
  input Absyn.ForIterator iterator;
  output Option<Absyn.Exp> guardExp;
algorithm
  Absyn.ITERATOR(guardExp=guardExp) := iterator;
end iteratorGuard;

// stefan
public function getNamedFuncArgNamesAndValues
"returns the names from a list of NamedArgs as a string list"
  input list<Absyn.NamedArg> namedArgs;
  output list<String> names = {};
  output list<Absyn.Exp> values = {};
algorithm
  for arg in listReverse(namedArgs) loop
    names := arg.argName :: names;
    values := arg.argValue :: values;
  end for;
end getNamedFuncArgNamesAndValues;

protected function getCrefFromNarg "Returns the flattened list of all component references
  present in a list of named function arguments."
  input Absyn.NamedArg inNamedArg;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Absyn.ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := getCrefFromExp(inNamedArg.argValue, includeSubs, includeFunctions);
end getCrefFromNarg;

public function joinPaths "This function joins two paths"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match (inPath1,inPath2)
    local
      Absyn.Ident str;
      Absyn.Path p2,p_1,p;
    case (Absyn.IDENT(name = str),p2) then Absyn.QUALIFIED(str,p2);
    case (Absyn.QUALIFIED(name = str,path = p),p2)
      equation
        p_1 = joinPaths(p, p2);
      then
        Absyn.QUALIFIED(str,p_1);
    case(Absyn.FULLYQUALIFIED(p),p2) then joinPaths(p,p2);
    case(p,Absyn.FULLYQUALIFIED(p2)) then joinPaths(p,p2);
  end match;
end joinPaths;

public function joinPathsOpt "This function joins two paths when the first one might be NONE"
  input Option<Absyn.Path> inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match inPath1
    local Absyn.Path p;
    case NONE() then inPath2;
    case SOME(p) then joinPaths(p, inPath2);
  end match;
end joinPathsOpt;

public function joinPathsOptSuffix
  input Absyn.Path inPath1;
  input Option<Absyn.Path> inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match inPath2
    local
      Absyn.Path p;

    case SOME(p) then joinPaths(inPath1, p);
    else inPath1;
  end match;
end joinPathsOptSuffix;

public function stripLast "Returns the path given as argument to
  the function minus the last ident."
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := match (inPath)
    local
      Absyn.Ident str;
      Absyn.Path p;

    case Absyn.QUALIFIED(name = str, path = Absyn.IDENT())
      then Absyn.IDENT(str);

    case Absyn.QUALIFIED(name = str, path = p)
      equation
        p = stripLast(p);
      then
        Absyn.QUALIFIED(str, p);

    case Absyn.FULLYQUALIFIED(p)
      equation
        p = stripLast(p);
      then
        Absyn.FULLYQUALIFIED(p);

  end match;
end stripLast;

public function crefStripLast "Returns the path given as argument to
  the function minus the last ident."
  input Absyn.ComponentRef inCref;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match (inCref)
    local
      Absyn.Ident str;
      Absyn.ComponentRef c_1, c;
      list<Absyn.Subscript> subs;

    case (Absyn.CREF_IDENT()) then fail();
    case (Absyn.CREF_QUAL(name = str,subscripts = subs, componentRef = Absyn.CREF_IDENT())) then Absyn.CREF_IDENT(str,subs);
    case (Absyn.CREF_QUAL(name = str,subscripts = subs,componentRef = c))
      equation
        c_1 = crefStripLast(c);
      then
        Absyn.CREF_QUAL(str,subs,c_1);
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = c))
      equation
        c_1 = crefStripLast(c);
      then
        crefMakeFullyQualified(c_1);
  end match;
end crefStripLast;

public function splitQualAndIdentPath "
Author BZ 2008-04
Function for splitting Absynpath into two parts,
qualified part, and ident part (all_but_last, last);
"
  input Absyn.Path inPath;
  output Absyn.Path outPath1;
  output Absyn.Path outPath2;
algorithm (outPath1,outPath2) := match(inPath)
  local
    Absyn.Path qPath,curPath,identPath;
    String s1,s2;

  case (Absyn.QUALIFIED(name = s1, path = Absyn.IDENT(name = s2)))
    then (Absyn.IDENT(s1), Absyn.IDENT(s2));

  case (Absyn.QUALIFIED(name = s1, path = qPath))
    equation
      (curPath, identPath) = splitQualAndIdentPath(qPath);
    then
      (Absyn.QUALIFIED(s1, curPath), identPath);

  case (Absyn.FULLYQUALIFIED(qPath))
    equation
      (curPath, identPath) = splitQualAndIdentPath(qPath);
    then
      (curPath, identPath);
  end match;
end splitQualAndIdentPath;

public function crefToPath "This function converts a Absyn.ComponentRef to a Absyn.Path, if possible.
  If the component reference contains subscripts, it will silently fail."
  input Absyn.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath:=
  match (inComponentRef)
    local
      Absyn.Ident i;
      Absyn.Path p;
      Absyn.ComponentRef c;
    case Absyn.CREF_IDENT(name = i,subscripts = {}) then Absyn.IDENT(i);
    case Absyn.CREF_QUAL(name = i,subscripts = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        Absyn.QUALIFIED(i,p);
    case Absyn.CREF_FULLYQUALIFIED(componentRef = c)
      equation
        p = crefToPath(c);
      then
        Absyn.FULLYQUALIFIED(p);
  end match;
end crefToPath;

public function elementSpecToPath "This function converts a Absyn.ElementSpec to a Absyn.Path, if possible.
  If the Absyn.ElementSpec is not EXTENDS, it will silently fail."
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outPath;
algorithm
  Absyn.EXTENDS(path = outPath) := inElementSpec;
end elementSpecToPath;

public function crefToPathIgnoreSubs
  "Converts a Absyn.ComponentRef to a Absyn.Path, ignoring any subscripts."
  input Absyn.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      Absyn.Ident i;
      Absyn.Path p;
      Absyn.ComponentRef c;

    case Absyn.CREF_IDENT(name = i) then Absyn.IDENT(i);

    case Absyn.CREF_QUAL(name = i, componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        Absyn.QUALIFIED(i, p);

    case Absyn.CREF_FULLYQUALIFIED(componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        Absyn.FULLYQUALIFIED(p);
  end match;
end crefToPathIgnoreSubs;

public function pathToCref "This function converts a Absyn.Path to a Absyn.ComponentRef."
  input Absyn.Path inPath;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inPath)
    local
      Absyn.Ident i;
      Absyn.ComponentRef c;
      Absyn.Path p;
    case Absyn.IDENT(name = i) then Absyn.CREF_IDENT(i,{});
    case Absyn.QUALIFIED(name = i,path = p)
      equation
        c = pathToCref(p);
      then
        Absyn.CREF_QUAL(i,{},c);
    case(Absyn.FULLYQUALIFIED(p))
      equation
        c = pathToCref(p);
      then crefMakeFullyQualified(c);
  end match;
end pathToCref;

public function pathToCrefWithSubs
  "This function converts a Absyn.Path to a Absyn.ComponentRef, and applies the given
  subscripts to the last identifier."
  input Absyn.Path inPath;
  input list<Absyn.Subscript> inSubs;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inPath, inSubs)
    local
      Absyn.Ident i;
      Absyn.ComponentRef c;
      Absyn.Path p;

    case (Absyn.IDENT(name = i), _) then Absyn.CREF_IDENT(i, inSubs);

    case (Absyn.QUALIFIED(name = i, path = p), _)
      equation
        c = pathToCrefWithSubs(p, inSubs);
      then
        Absyn.CREF_QUAL(i, {}, c);

    case (Absyn.FULLYQUALIFIED(p), _)
      equation
        c = pathToCrefWithSubs(p, inSubs);
      then
        crefMakeFullyQualified(c);
  end match;
end pathToCrefWithSubs;

public function crefLastIdent
  "Returns the last identifier in a component reference."
  input Absyn.ComponentRef cref;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match cref
    case Absyn.CREF_IDENT() then cref.name;
    case Absyn.CREF_QUAL() then crefLastIdent(cref.componentRef);
    case Absyn.CREF_FULLYQUALIFIED() then crefLastIdent(cref.componentRef);
  end match;
end crefLastIdent;

public function crefFirstIdentNoSubs
  "Returns the basename of the component reference, but fails if it encounters
  any subscripts."
  input Absyn.ComponentRef cref;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match cref
    case Absyn.CREF_IDENT(subscripts = {}) then cref.name;
    case Absyn.CREF_QUAL(subscripts = {}) then cref.name;
    case Absyn.CREF_FULLYQUALIFIED() then crefFirstIdentNoSubs(cref.componentRef);
  end match;
end crefFirstIdentNoSubs;

public function crefIsIdent
  "Returns true if the component reference is a simple identifier, otherwise false."
  input Absyn.ComponentRef inComponentRef;
  output Boolean outIsIdent;
algorithm
  outIsIdent := match(inComponentRef)
    case Absyn.CREF_IDENT() then true;
    else false;
  end match;
end crefIsIdent;

public function crefIsQual
  "Returns true if the component reference is a qualified identifier, otherwise false."
  input Absyn.ComponentRef inComponentRef;
  output Boolean outIsQual;
algorithm
  outIsQual := match(inComponentRef)
    case Absyn.CREF_QUAL() then true;
    case Absyn.CREF_FULLYQUALIFIED() then true;
    else false;
  end match;
end crefIsQual;

public function crefFirstSubs
  "Returns the subscripts on the first part of an Absyn.ComponentRef."
  input Absyn.ComponentRef cref;
  output list<Absyn.Subscript> subscripts;
algorithm
  subscripts := match cref
    case Absyn.ComponentRef.CREF_IDENT() then cref.subscripts;
    case Absyn.ComponentRef.CREF_QUAL() then cref.subscripts;
    case Absyn.ComponentRef.CREF_FULLYQUALIFIED() then crefFirstSubs(cref.componentRef);
  end match;
end crefFirstSubs;

public function crefLastSubs "Return the last subscripts of an Absyn.ComponentRef"
  input Absyn.ComponentRef cref;
  output list<Absyn.Subscript> subscripts;
algorithm
  subscripts := match (cref)
    case Absyn.CREF_IDENT() then cref.subscripts;
    case Absyn.CREF_QUAL() then crefLastSubs(cref.componentRef);
    case Absyn.CREF_FULLYQUALIFIED() then crefLastSubs(cref.componentRef);
  end match;
end crefLastSubs;

public function crefSetFirstSubs
  "Sets the subscripts of the first part of an Absyn.ComponentRef."
  input output Absyn.ComponentRef cref;
  input list<Absyn.Subscript> subscripts;
algorithm
  () := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        cref.subscripts := subscripts;
      then
        ();

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        cref.subscripts := subscripts;
      then
        ();

    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := crefSetFirstSubs(cref.componentRef, subscripts);
      then
        ();
  end match;
end crefSetFirstSubs;

public function crefSetLastSubs
  input output Absyn.ComponentRef cref;
  input list<Absyn.Subscript> inSubscripts;
algorithm
  () := match cref
    case Absyn.CREF_IDENT()
      algorithm
        cref.subscripts := inSubscripts;
      then
        ();

    case Absyn.CREF_QUAL()
      algorithm
        cref.componentRef := crefSetLastSubs(cref.componentRef, inSubscripts);
      then
        ();

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := crefSetLastSubs(cref.componentRef, inSubscripts);
      then
        ();

  end match;
end crefSetLastSubs;

public function crefHasSubscripts "This function finds if a cref has subscripts"
  input Absyn.ComponentRef cref;
  output Boolean hasSubscripts;
algorithm
  hasSubscripts := match cref
    case Absyn.CREF_IDENT() then not listEmpty(cref.subscripts);
    case Absyn.CREF_QUAL(subscripts = {}) then crefHasSubscripts(cref.componentRef);
    case Absyn.CREF_FULLYQUALIFIED() then crefHasSubscripts(cref.componentRef);
    case Absyn.WILD() then false;
    case Absyn.ALLWILD() then false;
    else true;
  end match;
end crefHasSubscripts;

public function getSubsFromCref "
Author: BZ, 2009-09
 Extract subscripts of crefs."
  input Absyn.ComponentRef cr;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Absyn.Subscript> subscripts;
algorithm
  subscripts := match(cr,includeSubs,includeFunctions)
    local
      list<Absyn.Subscript> subs2;
      Absyn.ComponentRef child;

    case(Absyn.CREF_IDENT(_,subs2), _, _) then subs2;

    case(Absyn.CREF_QUAL(_,subs2,child), _, _)
      equation
        subscripts = getSubsFromCref(child, includeSubs, includeFunctions);
        subscripts = List.unionOnTrue(subscripts,subs2, subscriptEqual);
      then
        subscripts;

    case(Absyn.CREF_FULLYQUALIFIED(child), _, _)
      equation
        subscripts = getSubsFromCref(child, includeSubs, includeFunctions);
      then
        subscripts;
  end match;
end getSubsFromCref;

public function crefGetLastIdent
  "Gets the last ident in a Absyn.ComponentRef"
  input Absyn.ComponentRef cref;
  output Absyn.Ident ident;
algorithm
  ident := match cref
    case Absyn.CREF_IDENT() then cref.name;
    case Absyn.CREF_QUAL() then crefGetLastIdent(cref.componentRef);
    case Absyn.CREF_FULLYQUALIFIED() then crefGetLastIdent(cref.componentRef);
  end match;
end crefGetLastIdent;

public function crefStripLastSubs "Strips the last subscripts of a Absyn.ComponentRef"
  input output Absyn.ComponentRef cref;
algorithm
  () := match cref
    case Absyn.CREF_IDENT()
      algorithm
        cref.subscripts := {};
      then
        ();

    case Absyn.CREF_QUAL()
      algorithm
        cref.componentRef := crefStripLastSubs(cref.componentRef);
      then
        ();

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := crefStripLastSubs(cref.componentRef);
      then
        ();
  end match;
end crefStripLastSubs;

public function joinCrefs "This function joins two ComponentRefs."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inComponentRef1,inComponentRef2)
    local
      Absyn.Ident id;
      list<Absyn.Subscript> sub;
      Absyn.ComponentRef cr2,cr_1,cr;
    case (Absyn.CREF_IDENT(name = id,subscripts = sub),cr2)
      equation
        failure(Absyn.CREF_FULLYQUALIFIED() = cr2);
      then Absyn.CREF_QUAL(id,sub,cr2);
    case (Absyn.CREF_QUAL(name = id,subscripts = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        Absyn.CREF_QUAL(id,sub,cr_1);
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        crefMakeFullyQualified(cr_1);
  end match;
end joinCrefs;

public function crefFirstIdent "Returns first ident from a Absyn.ComponentRef"
  input Absyn.ComponentRef inCref;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match inCref
    case Absyn.CREF_IDENT() then inCref.name;
    case Absyn.CREF_QUAL() then inCref.name;
    case Absyn.CREF_FULLYQUALIFIED() then crefFirstIdent(inCref.componentRef);
  end match;
end crefFirstIdent;

public function crefSetFirstIdent
  input output Absyn.ComponentRef cref;
  input Absyn.Ident ident;
algorithm
  () := match cref
    case Absyn.CREF_IDENT()
      algorithm
        cref.name := ident;
      then
        ();

    case Absyn.CREF_QUAL()
      algorithm
        cref.name := ident;
      then
        ();

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := crefSetFirstIdent(cref.componentRef, ident);
      then
        ();

    else ();
  end match;
end crefSetFirstIdent;

public function crefSecondIdent
  input Absyn.ComponentRef cref;
  output Absyn.Ident ident;
algorithm
  ident := match cref
    case Absyn.CREF_QUAL() then crefFirstIdent(cref.componentRef);
    case Absyn.CREF_FULLYQUALIFIED() then crefSecondIdent(cref.componentRef);
  end match;
end crefSecondIdent;

public function crefFirstCref
  "Returns the first part of a cref."
  input Absyn.ComponentRef inCref;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match inCref
    case Absyn.CREF_QUAL() then Absyn.CREF_IDENT(inCref.name, inCref.subscripts);
    case Absyn.CREF_FULLYQUALIFIED() then crefFirstCref(inCref.componentRef);
    else inCref;
  end match;
end crefFirstCref;

public function crefStripFirst "Strip the first ident from a Absyn.ComponentRef"
  input Absyn.ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inComponentRef)
    local Absyn.ComponentRef cr;
    case Absyn.CREF_QUAL(componentRef = cr) then cr;
    case Absyn.CREF_FULLYQUALIFIED(componentRef = cr) then crefStripFirst(cr);
  end match;
end crefStripFirst;

public function crefIsFullyQualified
  input Absyn.ComponentRef inCref;
  output Boolean outIsFullyQualified;
algorithm
  outIsFullyQualified := match inCref
    case Absyn.CREF_FULLYQUALIFIED() then true;
    else false;
  end match;
end crefIsFullyQualified;

public function crefMakeFullyQualified
  "Makes a component reference fully qualified unless it already is."
  input Absyn.ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inComponentRef)
    case Absyn.CREF_FULLYQUALIFIED() then inComponentRef;
    else Absyn.CREF_FULLYQUALIFIED(inComponentRef);
  end match;
end crefMakeFullyQualified;

public function restrString "Maps a class restriction to the corresponding string for printing"
  input Absyn.Restriction inRestriction;
  output String outString;
algorithm
  outString:=
  match (inRestriction)
    case Absyn.R_CLASS() then "CLASS";
    case Absyn.R_OPTIMIZATION() then "OPTIMIZATION";
    case Absyn.R_MODEL() then "MODEL";
    case Absyn.R_RECORD() then "RECORD";
    case Absyn.R_BLOCK() then "BLOCK";
    case Absyn.R_CONNECTOR() then "CONNECTOR";
    case Absyn.R_EXP_CONNECTOR() then "EXPANDABLE CONNECTOR";
    case Absyn.R_TYPE() then "TYPE";
    case Absyn.R_PACKAGE() then "PACKAGE";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE())) then "PURE FUNCTION";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE())) then "IMPURE FUNCTION";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())) then "FUNCTION";
    case Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()) then "OPERATOR FUNCTION";
    case Absyn.R_PREDEFINED_INTEGER() then "PREDEFINED_INT";
    case Absyn.R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case Absyn.R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case Absyn.R_PREDEFINED_BOOLEAN() then "PREDEFINED_BOOL";
    // BTH
    case Absyn.R_PREDEFINED_CLOCK() then "PREDEFINED_CLOCK";

    /* MetaModelica restriction */
    case Absyn.R_UNIONTYPE() then "UNIONTYPE";
    else "* Unknown restriction *";
  end match;
end restrString;

public function lastClassname "Returns the path (=name) of the last class in a program"
  input Absyn.Program inProgram;
  output Absyn.Path outPath;
protected
  list<Absyn.Class> lst;
  Absyn.Ident id;
algorithm
  Absyn.PROGRAM(classes = lst) := inProgram;
  Absyn.CLASS(name = id) := List.last(lst);
  outPath := Absyn.IDENT(id);
end lastClassname;

public function classFilename
  "Retrieves the filename where the class is stored."
  input Absyn.Class inClass;
  output String outFilename;
algorithm
  Absyn.CLASS(info = SOURCEINFO(fileName = outFilename)) := inClass;
end classFilename;

public function setClassFilename "Sets the filename where the class is stored."
  input Absyn.Class inClass;
  input String fileName;
  output Absyn.Class outClass;
algorithm
  outClass := match inClass
    local
      SourceInfo info;
      Absyn.Class cl;
    case cl as Absyn.CLASS(info=info as SOURCEINFO())
      equation
        info.fileName = fileName;
        cl.info = info;
      then cl;
  end match;
end setClassFilename;

public function setClassName "author: BZ
  Sets the name of the class"
  input Absyn.Class inClass;
  input String newName;
  output Absyn.Class outClass = inClass;
algorithm
  outClass := match outClass
    case Absyn.CLASS()
      algorithm
        outClass.name := newName;
      then
        outClass;
  end match;
end setClassName;

public function setClassBody
  input Absyn.Class inClass;
  input Absyn.ClassDef inBody;
  output Absyn.Class outClass = inClass;
algorithm
  outClass := match outClass
    case Absyn.CLASS()
      algorithm
        outClass.body := inBody;
      then
        outClass;
  end match;
end setClassBody;

public function crefEqual " Checks if the name of a Absyn.ComponentRef is
 equal to the name of another Absyn.ComponentRef, including subscripts.
 See also crefEqualNoSubs."
  input Absyn.ComponentRef cref1;
  input Absyn.ComponentRef cref2;
  output Boolean equal;
algorithm
  equal := match (cref1, cref2)
    case (Absyn.CREF_IDENT(), Absyn.CREF_IDENT())
      then stringEq(cref1.name, cref2.name) and
           subscriptsEqual(cref1.subscripts, cref2.subscripts);

    case (Absyn.CREF_QUAL(), Absyn.CREF_QUAL())
      then stringEq(cref1.name, cref2.name) and
           subscriptsEqual(cref1.subscripts, cref2.subscripts) and
           crefEqual(cref1.componentRef, cref2.componentRef);

    case (Absyn.CREF_FULLYQUALIFIED(), Absyn.CREF_FULLYQUALIFIED())
      then crefEqual(cref1.componentRef, cref2.componentRef);

    else false;
  end match;
end crefEqual;

public function crefFirstEqual
  "@author: adrpo
   a.b, a -> true
   b.c, a -> false"
  input Absyn.ComponentRef iCr1;
  input Absyn.ComponentRef iCr2;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(crefFirstIdent(iCr1),crefFirstIdent(iCr2));
end crefFirstEqual;

public function subscriptEqual
  input Absyn.Subscript inSubscript1;
  input Absyn.Subscript inSubscript2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inSubscript1, inSubscript2)
    local
      Absyn.Exp e1, e2;

    case (Absyn.NOSUB(), Absyn.NOSUB()) then true;
    case (Absyn.SUBSCRIPT(e1), Absyn.SUBSCRIPT(e2)) then expEqual(e1, e2);
    else false;
  end match;
end subscriptEqual;

public function subscriptsEqual
  "Checks if two subscript lists are equal."
  input list<Absyn.Subscript> inSubList1;
  input list<Absyn.Subscript> inSubList2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := List.isEqualOnTrue(inSubList1, inSubList2, subscriptEqual);
end subscriptsEqual;

public function crefEqualNoSubs
  "Checks if the name of a Absyn.ComponentRef is equal to the name
   of another Absyn.ComponentRef without checking subscripts.
   See also crefEqual."
  input Absyn.ComponentRef cr1;
  input Absyn.ComponentRef cr2;
  output Boolean equal;
algorithm
  equal := match (cr1,cr2)
    case (Absyn.CREF_IDENT(), Absyn.CREF_IDENT())
      then stringEq(cr1.name, cr2.name);
    case (Absyn.CREF_QUAL(), Absyn.CREF_QUAL())
      then stringEq(cr1.name, cr2.name) and crefEqualNoSubs(cr1.componentRef, cr2.componentRef);
    case (Absyn.CREF_FULLYQUALIFIED(), Absyn.CREF_FULLYQUALIFIED())
      then crefEqualNoSubs(cr1.componentRef, cr2.componentRef);
    else false;
  end match;
end crefEqualNoSubs;

public function isPackageRestriction "checks if the provided parameter is a package or not"
  input Absyn.Restriction inRestriction;
  output Boolean outIsPackage;
algorithm
  outIsPackage := match(inRestriction)
    case Absyn.R_PACKAGE() then true;
    else false;
  end match;
end isPackageRestriction;

public function isFunctionRestriction "checks if restriction is a function or not"
  input Absyn.Restriction inRestriction;
  output Boolean outIsFunction;
algorithm
  outIsFunction := match(inRestriction)
    case Absyn.R_FUNCTION() then true;
    else false;
  end match;
end isFunctionRestriction;

public function expEqual "Returns true if two expressions are equal"
  input Absyn.Exp exp1;
  input Absyn.Exp exp2;
  output Boolean equal;
algorithm
  equal := match (exp1, exp2)
    // real vs. integer
    case (Absyn.INTEGER(), Absyn.REAL())
      then realEq(intReal(exp1.value), System.stringReal(exp2.value));

    case (Absyn.REAL(), Absyn.INTEGER())
      then realEq(intReal(exp2.value), System.stringReal(exp1.value));

    // anything else, exact match!
    else valueEq(exp1, exp2);
  end match;
end expEqual;

public function getClassName "author: adrpo
  gets the name of the class."
  input Absyn.Class inClass;
  output String outName;
algorithm
  Absyn.CLASS(name=outName) := inClass;
end getClassName;

public type IteratorIndexedCref = tuple<Absyn.ComponentRef, Integer>;

public function findIteratorIndexedCrefs
  "Find all crefs in an expression which are subscripted with the given
   iterator, and return a list of cref-Integer tuples, where the cref is the
   index of the subscript."
  input Absyn.Exp inExp;
  input String inIterator;
  input list<IteratorIndexedCref> inCrefs = {};
  output list<IteratorIndexedCref> outCrefs;
algorithm
  (_, outCrefs) := traverseExp(inExp,
    function findIteratorIndexedCrefs_traverser(inIterator = inIterator), {});
  outCrefs := List.fold(outCrefs,
    function List.unionEltOnTrue(inCompFunc = iteratorIndexedCrefsEqual), inCrefs);
end findIteratorIndexedCrefs;

protected function findIteratorIndexedCrefs_traverser
  "Traversal function used by deduceReductionIterationRange. Used to find crefs
   which are subscripted by a given iterator."
  input Absyn.Exp inExp;
  input list<IteratorIndexedCref> inCrefs;
  input String inIterator;
  output Absyn.Exp outExp = inExp;
  output list<IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := match inExp
    case Absyn.CREF()
      then getIteratorIndexedCrefs(inExp.componentRef, inIterator, inCrefs);

    else inCrefs;
  end match;
end findIteratorIndexedCrefs_traverser;

protected function iteratorIndexedCrefsEqual
  "Checks whether two cref-index pairs are equal."
  input IteratorIndexedCref inCref1;
  input IteratorIndexedCref inCref2;
  output Boolean outEqual;
protected
  Absyn.ComponentRef cr1, cr2;
  Integer idx1, idx2;
algorithm
  (cr1, idx1) := inCref1;
  (cr2, idx2) := inCref2;
  outEqual := idx1 == idx2 and crefEqual(cr1, cr2);
end iteratorIndexedCrefsEqual;

protected function getIteratorIndexedCrefs
  "Checks if the given component reference is subscripted by the given iterator.
   Only cases where a subscript consists of only the iterator is considered.
   If so it adds a cref-index pair to the list, where the cref is the subscripted
   cref without subscripts, and the index is the subscripted dimension. E.g. for
   iterator i:
     a[i] => (a, 1), b[1, i] => (b, 2), c[i+1] => (), d[2].e[i] => (d[2].e, 1)"
  input Absyn.ComponentRef inCref;
  input String inIterator;
  input list<IteratorIndexedCref> inCrefs;
  output list<IteratorIndexedCref> outCrefs = inCrefs;
protected
  list<tuple<Absyn.ComponentRef, Integer>> crefs;
algorithm
  outCrefs := match inCref
    local
      list<Absyn.Subscript> subs;
      Integer idx;
      String name, id;
      Absyn.ComponentRef cref;

    case Absyn.CREF_IDENT(name = id, subscripts = subs)
      algorithm
        // For each subscript, check if the subscript consists of only the
        // iterator we're looking for.
        idx := 1;
        for sub in subs loop
          _ := match sub
            case Absyn.SUBSCRIPT(subscript = Absyn.CREF(componentRef =
                Absyn.CREF_IDENT(name = name, subscripts = {})))
              algorithm
                if name == inIterator then
                  outCrefs := (Absyn.CREF_IDENT(id, {}), idx) :: outCrefs;
                end if;
              then
                ();

            else ();
          end match;

          idx := idx + 1;
        end for;
      then
        outCrefs;

    case Absyn.CREF_QUAL(name = id, subscripts = subs, componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Append the prefix from the qualified cref to any matches, and add
        // them to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (Absyn.CREF_QUAL(id, subs, cref), idx) :: outCrefs;
        end for;
      then
        getIteratorIndexedCrefs(Absyn.CREF_IDENT(id, subs), inIterator, outCrefs);

    case Absyn.CREF_FULLYQUALIFIED(componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Make any matches fully qualified, and add them to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (Absyn.CREF_FULLYQUALIFIED(cref), idx) :: outCrefs;
        end for;
      then
        outCrefs;

    else inCrefs;
  end match;
end getIteratorIndexedCrefs;

public function getFileNameFromInfo
  input SourceInfo inInfo;
  output String inFileName;
algorithm
  SOURCEINFO(fileName = inFileName) := inInfo;
end getFileNameFromInfo;

public function isOuter
"@author: adrpo
  this function returns true if the given Absyn.InnerOuter
  is one of Absyn.INNER_OUTER() or Absyn.OUTER()"
  input Absyn.InnerOuter io;
  output Boolean isItAnOuter;
algorithm
  isItAnOuter := match(io)
    case (Absyn.INNER_OUTER()) then true;
    case (Absyn.OUTER()) then true;
    else false;
  end match;
end isOuter;

public function isInner
"@author: adrpo
  this function returns true if the given Absyn.InnerOuter
  is one of Absyn.INNER_OUTER() or Absyn.INNER()"
  input Absyn.InnerOuter io;
  output Boolean isItAnInner;
algorithm
  isItAnInner := match(io)
    case (Absyn.INNER_OUTER()) then true;
    case (Absyn.INNER()) then true;
    else false;
  end match;
end isInner;

public function isOnlyInner
  "Returns true if the Absyn.InnerOuter is Absyn.INNER, false otherwise."
  input Absyn.InnerOuter inIO;
  output Boolean outOnlyInner;
algorithm
  outOnlyInner := match(inIO)
    case (Absyn.INNER()) then true;
    else false;
  end match;
end isOnlyInner;

public function isOnlyOuter
  "Returns true if the Absyn.InnerOuter is Absyn.OUTER, false otherwise."
  input Absyn.InnerOuter inIO;
  output Boolean outOnlyOuter;
algorithm
  outOnlyOuter := match(inIO)
    case (Absyn.OUTER()) then true;
    else false;
  end match;
end isOnlyOuter;

public function isInnerOuter
  input Absyn.InnerOuter inIO;
  output Boolean outIsInnerOuter;
algorithm
  outIsInnerOuter := match(inIO)
    case (Absyn.INNER_OUTER()) then true;
    else false;
  end match;
end isInnerOuter;

public function isNotInnerOuter
  input Absyn.InnerOuter inIO;
  output Boolean outIsNotInnerOuter;
algorithm
  outIsNotInnerOuter := match(inIO)
    case (Absyn.NOT_INNER_OUTER()) then true;
    else false;
  end match;
end isNotInnerOuter;

public function innerOuterEqual "Returns true if two Absyn.InnerOuter's are equal"
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  output Boolean res;
algorithm
  res := match(io1,io2)
    case(Absyn.INNER(),Absyn.INNER()) then true;
    case(Absyn.OUTER(),Absyn.OUTER()) then true;
    case(Absyn.INNER_OUTER(),Absyn.INNER_OUTER()) then true;
    case(Absyn.NOT_INNER_OUTER(),Absyn.NOT_INNER_OUTER()) then true;
    else false;
  end match;
end innerOuterEqual;

public function makeFullyQualified
"Makes a path fully qualified unless it already is."
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := match inPath
    case Absyn.FULLYQUALIFIED() then inPath;
    else Absyn.FULLYQUALIFIED(inPath);
  end match;
end makeFullyQualified;

public function makeNotFullyQualified
"Makes a path not fully qualified unless it already is."
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := match inPath
    local Absyn.Path path;
    case Absyn.FULLYQUALIFIED(path) then path;
    else inPath;
  end match;
end makeNotFullyQualified;

public function importEqual "Compares two import elements. "
  input Absyn.Import im1;
  input Absyn.Import im2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (im1,im2)
    case (Absyn.NAMED_IMPORT(), Absyn.NAMED_IMPORT())
      then stringEq(im1.name, im2.name) and pathEqual(im1.path, im2.path);

    case (Absyn.QUAL_IMPORT(), Absyn.QUAL_IMPORT())
      then pathEqual(im1.path, im2.path);

    case (Absyn.UNQUAL_IMPORT(), Absyn.UNQUAL_IMPORT())
      then pathEqual(im1.path, im2.path);

    else false;
  end match;
end importEqual;

public function canonIfExp "Transforms an if-expression to canonical form (without else-if branches)"
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := match inExp
    local
      Absyn.Exp cond,tb,eb,ei_cond,ei_tb,e;
      list<tuple<Absyn.Exp,Absyn.Exp>> eib;

    case Absyn.IFEXP(elseIfBranch={}) then inExp;
    case Absyn.IFEXP(ifExp=cond,trueBranch=tb,elseBranch=eb,elseIfBranch=(ei_cond,ei_tb)::eib)
      equation
        e = canonIfExp(Absyn.IFEXP(ei_cond,ei_tb,eb,eib));
      then Absyn.IFEXP(cond,tb,e,{});
  end match;
end canonIfExp;

public function onlyLiteralsInAnnotationMod
"@author: adrpo
  This function checks if a modification only contains literal expressions"
  input list<Absyn.ElementArg> inMod;
  output Boolean onlyLiterals;
algorithm
  onlyLiterals := matchcontinue(inMod)
    local
      list<Absyn.ElementArg> dive, rest;
      Absyn.EqMod eqMod;

    case ({}) then true;

    // skip "interaction" annotation!
    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = "interaction")) :: rest)
      then onlyLiteralsInAnnotationMod(rest);


    // search inside, some(exp)
    case (Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(dive, eqMod))) :: rest)
      then onlyLiteralsInEqMod(eqMod) and
           onlyLiteralsInAnnotationMod(dive) and
           onlyLiteralsInAnnotationMod(rest);

    case (_ :: rest) then onlyLiteralsInAnnotationMod(rest);

    // failed above, return false
    else false;
  end matchcontinue;
end onlyLiteralsInAnnotationMod;

public function onlyLiteralsInEqMod
"@author: adrpo
  This function checks if an optional expression only contains literal expressions"
  input Absyn.EqMod eqMod;
  output Boolean onlyLiterals;
algorithm
  onlyLiterals := match eqMod
    local
      list<Absyn.Exp> lst;

    case Absyn.NOMOD() then true;

    // search inside, some(exp)
    case Absyn.EQMOD()
      algorithm
        (_, lst::{}) := traverseExpBidir(eqMod.exp, onlyLiteralsInExpEnter, onlyLiteralsInExpExit, {}::{});
      then
        listEmpty(lst);
  end match;
end onlyLiteralsInEqMod;

protected function onlyLiteralsInExpEnter
"@author: adrpo
 Visitor function for checking if Absyn.Exp contains only literals, NO CREFS!
 It returns an empty list if it doesn't contain any crefs!"
  input Absyn.Exp inExp;
  input list<list<Absyn.Exp>> inLst;
  output Absyn.Exp outExp;
  output list<list<Absyn.Exp>> outLst;
algorithm
  (outExp,outLst) := match (inExp,inLst)
    local
      Boolean b;
      Absyn.Exp e;
      list<Absyn.Exp> lst;
      list<list<Absyn.Exp>> rest;
      String name;

    // first handle all graphic enumerations!
    // FillPattern.*, Smooth.*, TextAlignment.*, etc!
    case (e as Absyn.CREF(Absyn.CREF_QUAL(name=name)), lst::rest)
      equation
        b = listMember(name,{
                          "LinePattern",
                          "Arrow",
                          "FillPattern",
                          "BorderPattern",
                          "TextStyle",
                          "Smooth",
                          "TextAlignment"});
        lst = List.consOnTrue(not b,e,lst);
      then (inExp, lst::rest);

    // crefs, add to list
    case (Absyn.CREF(), lst::rest) then (inExp,(inExp::lst)::rest);

    // anything else, return the same!
    else (inExp,inLst);

  end match;
end onlyLiteralsInExpEnter;

protected function onlyLiteralsInExpExit
"@author: adrpo
 Visitor function for checking if Absyn.Exp contains only literals, NO CREFS!
 It returns an empty list if it doesn't contain any crefs!"
  input Absyn.Exp inExp;
  input list<list<Absyn.Exp>> inLst;
  output Absyn.Exp outExp;
  output list<list<Absyn.Exp>> outLst;
algorithm
  (outExp,outLst) := match (inExp,inLst)
    local
      list<list<Absyn.Exp>> lst;

    // first handle DynamicSelect; pop the stack (ignore any crefs inside DynamicSelect)
    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "DynamicSelect")), lst)
      then (inExp, lst);

    // anything else, return the same!
    else (inExp,inLst);

  end match;
end onlyLiteralsInExpExit;

public function makeCons
  input Absyn.Exp e1;
  input Absyn.Exp e2;
  output Absyn.Exp e;
algorithm
  e := Absyn.CONS(e1,e2);
annotation(__OpenModelica_EarlyInline = true);
end makeCons;

public function crefIdent
  input Absyn.ComponentRef cr;
  output String str;
algorithm
  Absyn.CREF_IDENT(str,{}) := cr;
end crefIdent;

public function unqotePathIdents
  input Absyn.Path inPath;
  output Absyn.Path path;
algorithm
  path := stringListPath(List.map(pathToStringList(inPath), System.unquoteIdentifier));
end unqotePathIdents;

public function unqualifyCref
  "If the given component reference is fully qualified this function removes the
  fully qualified qualifier, otherwise does nothing."
  input Absyn.ComponentRef inCref;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match inCref
    case Absyn.CREF_FULLYQUALIFIED() then inCref.componentRef;
    else inCref;
  end match;
end unqualifyCref;

public function pathIsFullyQualified
  input Absyn.Path inPath;
  output Boolean outIsQualified;
algorithm
  outIsQualified := match inPath
    case Absyn.FULLYQUALIFIED() then true;
    else false;
  end match;
end pathIsFullyQualified;

public function pathIsIdent
  input Absyn.Path inPath;
  output Boolean outIsIdent;
algorithm
  outIsIdent := match inPath
    case Absyn.IDENT() then true;
    else false;
  end match;
end pathIsIdent;

public function pathIsQual
  input Absyn.Path inPath;
  output Boolean outIsQual;
algorithm
  outIsQual := match inPath
    case Absyn.QUALIFIED() then true;
    else false;
  end match;
end pathIsQual;

public function withinEqual
  input Absyn.Within within1;
  input Absyn.Within within2;
  output Boolean b;
algorithm
  b := match (within1,within2)
    case (Absyn.TOP(),Absyn.TOP()) then true;
    case (Absyn.WITHIN(),Absyn.WITHIN()) then pathEqual(within1.path, within2.path);
    else false;
  end match;
end withinEqual;

public function withinEqualCaseInsensitive
  input Absyn.Within within1;
  input Absyn.Within within2;
  output Boolean b;
algorithm
  b := match (within1,within2)
    case (Absyn.TOP(),Absyn.TOP()) then true;
    case (Absyn.WITHIN(),Absyn.WITHIN()) then pathEqualCaseInsensitive(within1.path,within2.path);
    else false;
  end match;
end withinEqualCaseInsensitive;

public function withinString
  input Absyn.Within w1;
  output String str;
algorithm
  str := match (w1)
    case (Absyn.TOP()) then "within ;";
    case (Absyn.WITHIN()) then "within " + pathString(w1.path) + ";";
  end match;
end withinString;

public function joinWithinPath
  input Absyn.Within within_;
  input Absyn.Path path;
  output Absyn.Path outPath;
algorithm
  outPath := match within_
    case Absyn.TOP() then path;
    case Absyn.WITHIN() then joinPaths(within_.path,path);
  end match;
end joinWithinPath;

public function innerOuterStr
  input Absyn.InnerOuter io;
  output String str;
algorithm
  str := match io
    case Absyn.INNER_OUTER() then "inner outer ";
    case Absyn.INNER() then "inner ";
    case Absyn.OUTER() then "outer ";
    case Absyn.NOT_INNER_OUTER() then "";
  end match;
end innerOuterStr;

public function subscriptExpOpt
  input Absyn.Subscript inSub;
  output Option<Absyn.Exp> outExpOpt;
algorithm
  outExpOpt := match(inSub)
    case Absyn.SUBSCRIPT() then SOME(inSub.subscript);
    case Absyn.NOSUB() then NONE();
  end match;
end subscriptExpOpt;

public function crefInsertSubscriptLstLst
  input Absyn.Exp inExp;
  input list<list<Absyn.Subscript>> inLst;
  output Absyn.Exp outExp;
  output list<list<Absyn.Subscript>> outLst;
algorithm
  (outExp,outLst) := matchcontinue(inExp,inLst)
    local
      Absyn.ComponentRef cref,cref2;
      list<list<Absyn.Subscript>> subs;
      Absyn.Exp e;
    case (Absyn.CREF(componentRef=cref),subs)
      equation
        cref2 = crefInsertSubscriptLstLst2(cref,subs);
      then
         (Absyn.CREF(cref2),subs);
    else (inExp,inLst);
  end matchcontinue;
end crefInsertSubscriptLstLst;

public function crefInsertSubscriptLstLst2
"Helper function to crefInsertSubscriptLstLst"
  input Absyn.ComponentRef inCref;
  input list<list<Absyn.Subscript>> inSubs;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref,inSubs)
    local
      Absyn.ComponentRef cref, cref2;
      Absyn.Ident n;
      list<list<Absyn.Subscript>> subs;
      list<Absyn.Subscript> s;
      case (cref,{})
        then cref;
      case (Absyn.CREF_IDENT(name = n), {s})
        then Absyn.CREF_IDENT(n,s);
      case (Absyn.CREF_QUAL(name = n, componentRef = cref), s::subs)
        equation
          cref2 = crefInsertSubscriptLstLst2(cref, subs);
        then
          Absyn.CREF_QUAL(n,s,cref2);
      case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), subs)
        equation
          cref2 = crefInsertSubscriptLstLst2(cref, subs);
        then
          crefMakeFullyQualified(cref2);
  end matchcontinue;
end crefInsertSubscriptLstLst2;

public function isCref
  input Absyn.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case Absyn.CREF() then true;
    else false;
  end match;
end isCref;

public function isTuple
  input Absyn.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case Absyn.TUPLE(__) then true;
    else false;
  end match;
end isTuple;

public function allFieldsAreCrefs
  "@author: johti
   Returns true if all fields are crefs"
  input list<Absyn.Exp> expLst;
  output Boolean b;
algorithm
  b := List.mapAllValueBool(expLst, complexIsCref, true);
end allFieldsAreCrefs;

public function complexIsCref
  " @author: johti
    Returns true if everything contained
    in the tuple or a cons cell is a constant reference."
  input Absyn.Exp inExp;
  output Boolean b;
algorithm
  b := match inExp
    case Absyn.TUPLE(__) then allFieldsAreCrefs(inExp.expressions);
    case Absyn.CONS(__) then complexIsCref(inExp.head) and complexIsCref(inExp.rest);
    case _ then isCref(inExp);
  end match;
end complexIsCref;

public function isDerCref
  input Absyn.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case Absyn.CALL(function_ = Absyn.CREF_IDENT("der",{}),
                    functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF()},{})) then true;
    else false;
  end match;
end isDerCref;

public function isDerCrefFail
  input Absyn.Exp exp;
algorithm
  Absyn.CALL(function_ = Absyn.CREF_IDENT("der",{}),
             functionArgs = Absyn.FUNCTIONARGS({Absyn.CREF()},{})) := exp;
end isDerCrefFail;

public function getExpsFromArrayDim
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input Absyn.ArrayDim inAd;
  output Boolean hasUnknownDimensions;
  output list<Absyn.Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := getExpsFromArrayDim_tail(inAd, {});
end getExpsFromArrayDim;

public function getExpsFromArrayDimOpt
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input Option<Absyn.ArrayDim> inAdO;
  output Boolean hasUnknownDimensions;
  output list<Absyn.Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := match inAdO
    local Absyn.ArrayDim ad;

    case NONE() then (false, {});
    case SOME(ad) then getExpsFromArrayDim_tail(ad, {});
  end match;
end getExpsFromArrayDimOpt;

public function getExpsFromArrayDim_tail
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input Absyn.ArrayDim inAd;
  input list<Absyn.Exp> inAccumulator;
  output Boolean hasUnknownDimensions;
  output list<Absyn.Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := match(inAd, inAccumulator)
    local
      list<Absyn.Subscript> rest;
      Absyn.Exp e;
      list<Absyn.Exp> exps, acc;
      Boolean b;

    // handle empty list
    case ({}, acc) then (false, listReverse(acc));

    // handle Absyn.SUBSCRIPT
    case (Absyn.SUBSCRIPT(e)::rest, acc)
      equation
        (b, exps) = getExpsFromArrayDim_tail(rest, e::acc);
       then
         (b, exps);

    // handle Absyn.NOSUB
    case (Absyn.NOSUB()::rest, acc)
      equation
        (_, exps) = getExpsFromArrayDim_tail(rest, acc);
       then
         (true, exps);
  end match;
end getExpsFromArrayDim_tail;

public function isInputOrOutput
"@author: adrpo
 returns true if the given direction is input or output"
 input Absyn.Direction direction;
 output Boolean isIorO "input or output only";
algorithm
  isIorO := match(direction)
    case (Absyn.INPUT()) then true;
    case (Absyn.OUTPUT()) then true;
    case (Absyn.INPUT_OUTPUT()) then true;
    case (Absyn.BIDIR()) then false;
  end match;
end isInputOrOutput;

public function isInput
  input Absyn.Direction inDirection;
  output Boolean outIsInput;
algorithm
  outIsInput := match(inDirection)
    case Absyn.INPUT() then true;
    case Absyn.INPUT_OUTPUT() then true;
    else false;
  end match;
end isInput;

public function isOutput
  input Absyn.Direction inDirection;
  output Boolean outIsOutput;
algorithm
  outIsOutput := match(inDirection)
    case Absyn.OUTPUT() then true;
    case Absyn.INPUT_OUTPUT() then true;
    else false;
  end match;
end isOutput;

public function directionEqual
  input Absyn.Direction inDirection1;
  input Absyn.Direction inDirection2;
  output Boolean outEqual;
algorithm
  outEqual := match(inDirection1, inDirection2)
    case (Absyn.BIDIR(), Absyn.BIDIR()) then true;
    case (Absyn.INPUT(), Absyn.INPUT()) then true;
    case (Absyn.OUTPUT(), Absyn.OUTPUT()) then true;
    case (Absyn.INPUT_OUTPUT(), Absyn.INPUT_OUTPUT()) then true;
    else false;
  end match;
end directionEqual;

public function isFieldEqual
  input Absyn.IsField isField1;
  input Absyn.IsField isField2;
  output Boolean outEqual;
algorithm
  outEqual := match(isField1, isField2)
    case (Absyn.NONFIELD(), Absyn.NONFIELD()) then true;
    case (Absyn.FIELD(), Absyn.FIELD()) then true;
    else false;
  end match;
end isFieldEqual;

public function pathLt
  input Absyn.Path path1;
  input Absyn.Path path2;
  output Boolean lt;
algorithm
  lt := stringCompare(pathString(path1),pathString(path2)) < 0;
end pathLt;

public function pathGe
  input Absyn.Path path1;
  input Absyn.Path path2;
  output Boolean ge;
algorithm
  ge := not pathLt(path1,path2);
end pathGe;

public function getShortClass "Strips out long class definitions"
  input output Absyn.Class cl;
algorithm
  () := match cl
    case Absyn.CLASS(body=Absyn.PARTS()) then fail();
    case Absyn.CLASS(body=Absyn.CLASS_EXTENDS()) then fail();
    case Absyn.CLASS()
      equation
        cl.body = stripClassDefComment(cl.body);
      then
        ();
  end match;
end getShortClass;

protected function stripClassDefComment
  "Strips out class definition comments."
  input output Absyn.ClassDef cl;
algorithm
  () := match cl
    case Absyn.PARTS()         algorithm cl.comment := NONE(); then ();
    case Absyn.DERIVED()       algorithm cl.comment := NONE(); then ();
    case Absyn.ENUMERATION()   algorithm cl.comment := NONE(); then ();
    case Absyn.OVERLOAD()      algorithm cl.comment := NONE(); then ();
    case Absyn.CLASS_EXTENDS() algorithm cl.comment := NONE(); then ();
    case Absyn.PDER()          algorithm cl.comment := NONE(); then ();
    else ();
  end match;
end stripClassDefComment;

public function getFunctionInterface "Strips out the parts of a function definition that are not needed for the interface"
  input output Absyn.Class cl;
protected
  Absyn.ClassDef def;
  list<Absyn.ElementItem> elts;
algorithm
  () := match cl
    case Absyn.CLASS(restriction = Absyn.R_FUNCTION(), body = def as Absyn.PARTS())
      algorithm
        elts as _ :: _ := List.fold(listReverse(def.classParts), getFunctionInterfaceParts, {});
        cl.body := Absyn.PARTS(def.typeVars, def.classAttrs, {Absyn.PUBLIC(elts)}, {}, NONE());
      then
        ();
  end match;
end getFunctionInterface;

protected function getFunctionInterfaceParts
  input Absyn.ClassPart part;
  input list<Absyn.ElementItem> elts;
  output list<Absyn.ElementItem> oelts;
algorithm
  oelts := match (part,elts)
    local
      list<Absyn.ElementItem> elts1,elts2;
    case (Absyn.PUBLIC(elts1),elts2)
      equation
        elts1 = List.filterOnTrue(elts1,filterAnnotationItem);
      then listAppend(elts1,elts2);
    else elts;
  end match;
end getFunctionInterfaceParts;

protected function filterAnnotationItem
  input Absyn.ElementItem elt;
  output Boolean outB;
algorithm
  outB := match elt
    case Absyn.ELEMENTITEM() then true;
    else false;
  end match;
end filterAnnotationItem;

public function filterNestedClasses
  "Filter outs the nested classes from the class if any."
  input output Absyn.Class cl;
protected
  Absyn.ClassDef def;
algorithm
  () := match cl
    case Absyn.CLASS(body = def as Absyn.PARTS())
      algorithm
        def.classParts := List.fold(listReverse(def.classParts), filterNestedClassesParts, {});
        cl.body := def;
      then
        ();

    else ();
  end match;
end filterNestedClasses;

protected function filterNestedClassesParts
  "Helper funciton for filterNestedClassesParts."
  input Absyn.ClassPart classPart;
  input list<Absyn.ClassPart> inClassParts;
  output list<Absyn.ClassPart> outClassPart;
algorithm
  outClassPart := match (classPart, inClassParts)
    local
      list<Absyn.ClassPart> classParts;
      list<Absyn.ElementItem> elts;
    case (Absyn.PUBLIC(elts), classParts)
      equation
        classPart.contents = List.filterOnFalse(elts, isElementItemClass);
      then classPart::classParts;
    case (Absyn.PROTECTED(elts), classParts)
      equation
        classPart.contents = List.filterOnFalse(elts, isElementItemClass);
      then classPart::classParts;
    else classPart::inClassParts;
  end match;
end filterNestedClassesParts;

public function getExternalDecl
  "@author: adrpo
   returns the Absyn.EXTERNAL form parts if there is any.
   if there is none, it fails!"
  input Absyn.Class inCls;
  output Absyn.ClassPart outExternal;
protected
  Absyn.ClassPart cp;
  list<Absyn.ClassPart> class_parts;
algorithm
  Absyn.CLASS(body = Absyn.PARTS(classParts = class_parts)) := inCls;
  outExternal := List.find(class_parts, isExternalPart);
end getExternalDecl;

protected function isExternalPart
  input Absyn.ClassPart inClassPart;
  output Boolean outFound;
algorithm
  outFound := match inClassPart
    case Absyn.EXTERNAL() then true;
    else false;
  end match;
end isExternalPart;

public function isParts
  input Absyn.ClassDef cl;
  output Boolean b;
algorithm
  b := match cl
    case Absyn.PARTS() then true;
    else false;
  end match;
end isParts;

public function makeClassElement "Makes a class into an Absyn.ElementItem"
  input Absyn.Class cl;
  output Absyn.ElementItem el;
protected
  Absyn.Info info;
  Boolean fp;
algorithm
  Absyn.CLASS(finalPrefix = fp, info = info) := cl;
  el := Absyn.ELEMENTITEM(Absyn.ELEMENT(fp,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.CLASSDEF(false,cl),info,NONE()));
end makeClassElement;

public function componentName
  input Absyn.ComponentItem c;
  output String name;
algorithm
  Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name=name)) := c;
end componentName;

public function expContainsInitial
"@author:
  returns true if expression contains initial()"
  input Absyn.Exp inExp;
  output Boolean hasInitial;
algorithm
  hasInitial := matchcontinue(inExp)
    local Boolean b;
    case (_)
      equation
        (_, b) = traverseExp(inExp, isInitialTraverseHelper, false);
      then
        b;
    else false;
  end matchcontinue;
end expContainsInitial;

protected function isInitialTraverseHelper
"@author:
  returns true if expression is initial()"
  input Absyn.Exp inExp;
  input Boolean inBool;
  output Absyn.Exp outExp;
  output Boolean outBool;
algorithm
  (outExp,outBool) := match (inExp,inBool)
    local Absyn.Exp e; Boolean b;

    // make sure we don't have not initial()
    case (Absyn.UNARY(Absyn.NOT(), _) , _) then (inExp,inBool);
    // we have initial
    case (e , _)
      equation
        b = isInitial(e);
      then (e, b);
    else (inExp,inBool);
  end match;
end isInitialTraverseHelper;

public function isInitial
"@author:
  returns true if expression is initial()"
  input Absyn.Exp inExp;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inExp)
    case (Absyn.CALL(function_ = Absyn.CREF_IDENT("initial", _))) then true;
    case (Absyn.CALL(function_ = Absyn.CREF_FULLYQUALIFIED(Absyn.CREF_IDENT("initial", _)))) then true;
    else false;
  end match;
end isInitial;

public function importPath
  "Return the path of the given import."
  input Absyn.Import inImport;
  output Absyn.Path outPath;
algorithm
  outPath := match(inImport)
    local
      Absyn.Path path;

    case Absyn.NAMED_IMPORT(path = path) then path;
    case Absyn.QUAL_IMPORT(path = path) then path;
    case Absyn.UNQUAL_IMPORT(path = path) then path;
    case Absyn.GROUP_IMPORT(prefix = path) then path;

  end match;
end importPath;

public function importName
  "Returns the import name of a named or qualified import."
  input Absyn.Import inImport;
  output Absyn.Ident outName;
algorithm
  outName := match(inImport)
    // Named import has a given name, 'import D = A.B.C' => D.
    case Absyn.NAMED_IMPORT() then inImport.name;
    // Qualified import uses the last identifier, 'import A.B.C' => C.
    case Absyn.QUAL_IMPORT() then pathLastIdent(inImport.path);
  end match;
end importName;

public function mergeAnnotations
" This function takes an old annotation as first argument and a new
   annotation as  second argument and merges the two.
   Absyn.Annotation \"parts\" that exist in both the old and the new annotation
   will be changed according to the new definition. For instance,
   merge_annotations(annotation(x=1,y=2),annotation(x=3))
   => annotation(x=3,y=2)"
  input Absyn.Annotation inAnnotation1;
  input Absyn.Annotation inAnnotation2;
  output Absyn.Annotation outAnnotation;
algorithm
  outAnnotation:=
  match (inAnnotation1,inAnnotation2)
    local
      list<Absyn.ElementArg> oldmods,newmods;
      Absyn.Annotation a;
    case (Absyn.ANNOTATION(elementArgs = {}),a) then a;

    case (Absyn.ANNOTATION(elementArgs = oldmods),Absyn.ANNOTATION(elementArgs = newmods))
      then Absyn.ANNOTATION(mergeAnnotations2(oldmods, newmods));
  end match;
end mergeAnnotations;

protected

function mergeAnnotations2
  input list<Absyn.ElementArg> oldmods;
  input list<Absyn.ElementArg> newmods;
  output list<Absyn.ElementArg> res = listReverse(oldmods);
protected
  list<Absyn.ElementArg> mods;
  Boolean b;
  Absyn.Path p;
  Absyn.ElementArg mod1,mod2;
algorithm
  for mod in newmods loop
    Absyn.MODIFICATION(path=p) := mod;
    try
      mod2 := List.find(res, function isModificationOfPath(path=p));
      mod1 := subModsInSameOrder(mod2, mod);
      (res, true) := List.replaceOnTrue(mod1, res, function isModificationOfPath(path=p));
    else
      res := mod::res;
    end try;
  end for;
  res := listReverse(res);
end mergeAnnotations2;

public function mergeCommentAnnotation
  "Merges an annotation into a Absyn.Comment option."
  input Absyn.Annotation inAnnotation;
  input Option<Absyn.Comment> inComment;
  output Option<Absyn.Comment> outComment;
algorithm
  outComment := match inComment
    local
      Absyn.Annotation ann;
      Option<String> cmt;

    // No comment, create a new one.
    case NONE()
      then SOME(Absyn.COMMENT(SOME(inAnnotation), NONE()));

    // A comment without annotation, insert the annotation.
    case SOME(Absyn.COMMENT(annotation_ = NONE(), comment = cmt))
      then SOME(Absyn.COMMENT(SOME(inAnnotation), cmt));

    // A comment with annotation, merge the annotations.
    case SOME(Absyn.COMMENT(annotation_ = SOME(ann), comment = cmt))
      then SOME(Absyn.COMMENT(SOME(mergeAnnotations(ann, inAnnotation)), cmt));

  end match;
end mergeCommentAnnotation;

function isModificationOfPath
"returns true or false if the given path is in the list of modifications"
  input Absyn.ElementArg mod;
  input Absyn.Path path;
  output Boolean yes;
algorithm
  yes := match (mod,path)
    local
      String id1,id2;
    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = id1)),Absyn.IDENT(name = id2)) then id1==id2;
    else false;
  end match;
end isModificationOfPath;

function subModsInSameOrder
  input Absyn.ElementArg oldmod;
  input Absyn.ElementArg newmod;
  output Absyn.ElementArg mod;
algorithm
  mod := match (oldmod,newmod)
    local
      list<Absyn.ElementArg> args1,args2,res;
      Absyn.ElementArg arg2;
      Absyn.EqMod eq1,eq2;
      Absyn.Path p;

    // mod1 or mod2 has no submods
    case (_, Absyn.MODIFICATION(modification=NONE())) then newmod;
    case (Absyn.MODIFICATION(modification=NONE()), _) then newmod;
    // mod1
    case (Absyn.MODIFICATION(modification=SOME(Absyn.CLASSMOD(args1,_))), arg2 as Absyn.MODIFICATION(modification=SOME(Absyn.CLASSMOD(args2,eq2))))
      algorithm
        // Delete all items from args2 that are not in args1
        res := {};
        for arg1 in args1 loop
          Absyn.MODIFICATION(path=p) := arg1;
          if List.exist(args2, function isModificationOfPath(path=p)) then
            res := arg1::res;
          end if;
        end for;
        res := listReverse(res);
        // Merge the annotations
        res := mergeAnnotations2(res, args2);
        arg2.modification := SOME(Absyn.CLASSMOD(res,eq2));
      then arg2;
  end match;
end subModsInSameOrder;

public function annotationToElementArgs
  input Absyn.Annotation ann;
  output list<Absyn.ElementArg> args;
algorithm
  Absyn.ANNOTATION(args) := ann;
end annotationToElementArgs;

public function pathToTypeSpec
  input Absyn.Path inPath;
  output Absyn.TypeSpec outTypeSpec;
algorithm
  outTypeSpec := Absyn.TPATH(inPath, NONE());
end pathToTypeSpec;

public function typeSpecString
  input Absyn.TypeSpec inTs;
  output String outStr;
algorithm
  outStr := Dump.unparseTypeSpec(inTs);
end typeSpecString;

public function crefString
  input Absyn.ComponentRef inCr;
  output String outStr;
algorithm
  outStr := Dump.printComponentRefStr(inCr);
end crefString;

public function typeSpecStringNoQualNoDims
  input Absyn.TypeSpec inTs;
  output String outStr;
algorithm
  outStr := match (inTs)
    local
      Absyn.Ident str1,str2;
      Absyn.Path path;
      list<Absyn.TypeSpec> typeSpecLst;

    case (Absyn.TPATH(path = path))
      then pathString(makeNotFullyQualified(path));

    case (Absyn.TCOMPLEX(path = path,typeSpecs = typeSpecLst))
      equation
        str1 = pathString(makeNotFullyQualified(path));
        str2 = typeSpecStringNoQualNoDimsLst(typeSpecLst);
      then
        stringAppendList({str1,"<",str2,">"});

  end match;
end typeSpecStringNoQualNoDims;

public function typeSpecStringNoQualNoDimsLst
  input list<Absyn.TypeSpec> inTypeSpecLst;
  output String outString;
algorithm
  outString := List.toString(inTypeSpecLst, typeSpecStringNoQualNoDims,
    "", "", ", ", "", false);
end typeSpecStringNoQualNoDimsLst;

public function crefStringIgnoreSubs
  input Absyn.ComponentRef inCr;
  output String outStr;
protected
  Absyn.Path p;
algorithm
  p := crefToPathIgnoreSubs(inCr);
  outStr := pathString(makeNotFullyQualified(p));
end crefStringIgnoreSubs;

public function importString
  input Absyn.Import inImp;
  output String outStr;
algorithm
  outStr := Dump.unparseImportStr(inImp);
end importString;

public function refString
"@author: adrpo
 full Absyn.Ref -> string
 cref/path full qualified, type dims, subscripts in crefs"
  input Absyn.Ref inRef;
  output String outStr;
algorithm
  outStr := match inRef
    case Absyn.RCR() then crefString(inRef.cr);
    case Absyn.RTS() then typeSpecString(inRef.ts);
    case Absyn.RIM() then importString(inRef.im);
  end match;
end refString;

public function refStringBrief
"@author: adrpo
 brief Absyn.Ref -> string
 no cref/path full qualified, no type dims, no subscripts in crefs"
  input Absyn.Ref inRef;
  output String outStr;
algorithm
  outStr := match inRef
    case Absyn.RCR() then crefStringIgnoreSubs(inRef.cr);
    case Absyn.RTS() then typeSpecStringNoQualNoDims(inRef.ts);
    case Absyn.RIM() then importString(inRef.im);
  end match;
end refStringBrief;

public function getArrayDimOptAsList
  input Option<Absyn.ArrayDim> inArrayDim;
  output Absyn.ArrayDim outArrayDim;
algorithm
  outArrayDim := match inArrayDim
    local Absyn.ArrayDim ad;
    case SOME(ad) then ad;
    else {};
  end match;
end getArrayDimOptAsList;

public function removeCrefFromCrefs
"Removes a variable from a variable list"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynComponentRefLst,inComponentRef)
    local
      String n1,n2;
      list<Absyn.ComponentRef> rest;
      Absyn.ComponentRef cr1,cr2;
    case ({},_) then {};
    case ((cr1 :: rest),cr2)
      equation
        Absyn.CREF_IDENT(name = n1,subscripts = {}) = cr1;
        Absyn.CREF_IDENT(name = n2,subscripts = {}) = cr2;
        true = stringEq(n1, n2);
      then

        removeCrefFromCrefs(rest, cr2);
    case ((cr1 :: rest),cr2) // If modifier like on comp like: T t(x=t.y) => t.y must be removed
      equation
        Absyn.CREF_QUAL(name = n1) = cr1;
        Absyn.CREF_IDENT(name = n2) = cr2;
        true = stringEq(n1, n2);
      then
        removeCrefFromCrefs(rest, cr2);

    case ((cr1 :: rest),cr2)
      equation
        rest = removeCrefFromCrefs(rest, cr2);
      then
        (cr1 :: rest);
  end matchcontinue;
end removeCrefFromCrefs;

public function getNamedAnnotationInClass<T>
  "Retrieve e.g. the documentation annotation as a string from the class passed as argument."
  input Absyn.Class inClass;
  input Absyn.Path id;
  input ModFunc f;
  output Option<T> outString;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output T docStr;
  end ModFunc;
algorithm
  outString := matchcontinue inClass
    local
      T str,res;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> annlst;
      list<Absyn.Annotation> ann;

    case Absyn.CLASS(body = Absyn.PARTS(ann = ann))
      equation
        annlst = List.flatten(List.map(ann,annotationToElementArgs));
      then
        getNamedAnnotationStr(annlst,id,f);

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(ann = ann))
      equation
        annlst = List.flatten(List.map(ann,annotationToElementArgs));
      then
        getNamedAnnotationStr(annlst,id,f);

    case Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then getNamedAnnotationStr(annlst,id,f);

    case Absyn.CLASS(body = Absyn.ENUMERATION(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then getNamedAnnotationStr(annlst,id,f);

    case Absyn.CLASS(body = Absyn.OVERLOAD(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))
      then getNamedAnnotationStr(annlst,id,f);

    else NONE();

  end matchcontinue;
end getNamedAnnotationInClass;

protected function getNamedAnnotationStr<T>
"Helper function to getNamedAnnotationInElementitemlist."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Path id;
  input ModFunc f;
  output Option<T> outString;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output T docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynElementArgLst,id,f)
    local
      T str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      Absyn.Ident id1,id2;
      Absyn.Path rest;

    case (((Absyn.MODIFICATION(path = Absyn.IDENT(name = id1),modification = mod)) :: _),Absyn.IDENT(id2),_)
      equation
        true = stringEq(id1, id2);
        str = f(mod);
      then
        SOME(str);

    case (((Absyn.MODIFICATION(path = Absyn.IDENT(name = id1),modification = SOME(Absyn.CLASSMOD(elementArgLst=xs)))) :: _),Absyn.QUALIFIED(name=id2,path=rest),_)
      equation
        true = stringEq(id1, id2);
      then getNamedAnnotationStr(xs,rest,f);

    case ((_ :: xs),_,_) then getNamedAnnotationStr(xs,id,f);
  end matchcontinue;
end getNamedAnnotationStr;

public function mapCrefParts
  "This function splits each part of a cref into CREF_IDENTs and applies the
   given function to each part. If the given cref is a qualified cref then the
   map function is expected to also return Absyn.CREF_IDENT, so that the split cref
   can be reconstructed. Otherwise the map function is free to return whatever
   it wants."
  input Absyn.ComponentRef inCref;
  input MapFunc inMapFunc;
  output Absyn.ComponentRef outCref;

  partial function MapFunc
    input Absyn.ComponentRef inCref;
    output Absyn.ComponentRef outCref;
  end MapFunc;
algorithm
  outCref := match(inCref, inMapFunc)
    local
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef rest_cref;
      Absyn.ComponentRef cref;

    case (Absyn.CREF_QUAL(name, subs, rest_cref), _)
      equation
        cref = Absyn.CREF_IDENT(name, subs);
        Absyn.CREF_IDENT(name, subs) = inMapFunc(cref);
        rest_cref = mapCrefParts(rest_cref, inMapFunc);
      then
        Absyn.CREF_QUAL(name, subs, rest_cref);

    case (Absyn.CREF_FULLYQUALIFIED(cref), _)
      equation
        cref = mapCrefParts(cref, inMapFunc);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

    else inMapFunc(inCref);
  end match;
end mapCrefParts;

public function opEqual
 input Absyn.Operator op1;
 input Absyn.Operator op2;
 output Boolean isEqual;
algorithm
  isEqual := valueEq(op1, op2);
end opEqual;

public function opIsElementWise
 input Absyn.Operator op;
 output Boolean isElementWise;
algorithm
  isElementWise := match op
    case Absyn.ADD_EW() then true;
    case Absyn.SUB_EW() then true;
    case Absyn.MUL_EW() then true;
    case Absyn.DIV_EW() then true;
    case Absyn.POW_EW() then true;
    case Absyn.UPLUS_EW() then true;
    case Absyn.UMINUS_EW() then true;
    else false;
  end match;
end opIsElementWise;

protected function dummyTraverseExp<Arg>
  input Absyn.Exp inExp;
  input Arg inArg;
  output Absyn.Exp outExp;
  output Arg outArg;
algorithm
  outExp := inExp;
  outArg := inArg;
end dummyTraverseExp;

public function getDefineUnitsInElements "retrives defineunit definitions in elements"
  input list<Absyn.ElementItem> elts;
  output list<Absyn.Element> outElts = {};
algorithm
  for i in elts loop
    outElts := match i
      case Absyn.ELEMENTITEM(element = Absyn.DEFINEUNIT()) then i.element :: outElts;
      else outElts;
    end match;
  end for;

  outElts := listReverseInPlace(outElts);
end getDefineUnitsInElements;

public function getElementItemsInClass
  "Returns the public and protected elements in a class."
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outElements;
algorithm
  outElements := match(inClass)
    local
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      then List.mapFlat(parts, getElementItemsInClassPart);

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      then List.mapFlat(parts, getElementItemsInClassPart);

    else {};

  end match;
end getElementItemsInClass;

public function getElementItemsInClassPart
  "Returns the public and protected elements in a class part."
  input Absyn.ClassPart inClassPart;
  output list<Absyn.ElementItem> outElements;
algorithm
  outElements := match(inClassPart)
    case Absyn.PUBLIC() then inClassPart.contents;
    case Absyn.PROTECTED() then inClassPart.contents;
    else {};
  end match;
end getElementItemsInClassPart;

public function traverseClassComponents<ArgT>
  input Absyn.Class inClass;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.Class outClass = inClass;
  output ArgT outArg;

  partial function FuncType
    input output list<Absyn.ComponentItem> components;
    input output ArgT arg;
    output Boolean outContinue;
  end FuncType;
algorithm
  outClass := match(outClass)
    local
      Absyn.ClassDef body;

    case Absyn.CLASS()
      algorithm
        (body, outArg) := traverseClassDef(outClass.body,
          function traverseClassPartComponents(inFunc = inFunc), inArg);
        if not referenceEq(body, outClass.body) then outClass.body := body; end if;
      then
        outClass;

  end match;
end traverseClassComponents;

protected function traverseListGeneric<T, ArgT>
  input list<T> inList;
  input FuncType inFunc;
  input ArgT inArg;
  output list<T> outList = {};
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input T inElement;
    input ArgT inArg;
    output T outElement;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
protected
  Boolean eq, changed = false;
  T e, new_e;
  list<T> rest_e = inList;
algorithm
  while not listEmpty(rest_e) loop
    e :: rest_e := rest_e;
    (new_e, outArg, outContinue) := inFunc(e, outArg);
    eq := referenceEq(new_e, e);
    outList := (if eq then e else new_e) :: outList;
    changed := changed or not eq;
    if not outContinue then break; end if;
  end while;

  if changed then
    outList := List.append_reverse(outList, rest_e);
  else
    outList := inList;
  end if;
end traverseListGeneric;

protected function traverseClassPartComponents<ArgT>
  input Absyn.ClassPart inClassPart;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ClassPart outClassPart = inClassPart;
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input list<Absyn.ComponentItem> inComponents;
    input ArgT inArg;
    output list<Absyn.ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  _ := match(outClassPart)
    local
      list<Absyn.ElementItem> items;

    case Absyn.PUBLIC()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
            function traverseElementItemComponents(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    case Absyn.PROTECTED()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
             function traverseElementItemComponents(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    else ();
  end match;
end traverseClassPartComponents;

protected function traverseElementItemComponents<ArgT>
  input Absyn.ElementItem inItem;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ElementItem outItem;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<Absyn.ComponentItem> inComponents;
    input ArgT inArg;
    output list<Absyn.ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outItem, outArg, outContinue) := match(inItem)
    local
      Absyn.Element elem;

    case Absyn.ELEMENTITEM()
      algorithm
        (elem, outArg, outContinue) := traverseElementComponents(inItem.element,
          inFunc, inArg);
        outItem := if referenceEq(elem, inItem.element) then inItem else Absyn.ELEMENTITEM(elem);
      then
        (outItem, outArg, outContinue);

    else (inItem, inArg, true);
  end match;
end traverseElementItemComponents;

protected function traverseElementComponents<ArgT>
  input Absyn.Element inElement;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.Element outElement = inElement;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<Absyn.ComponentItem> inComponents;
    input ArgT inArg;
    output list<Absyn.ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outElement, outArg, outContinue) := match(outElement)
    local
      Absyn.ElementSpec spec;

    case Absyn.ELEMENT()
      algorithm
        (spec, outArg, outContinue) := traverseElementSpecComponents(
          outElement.specification, inFunc, inArg);

        if not referenceEq(spec, outElement.specification) then
          outElement.specification := spec;
        end if;
      then
        (outElement, outArg, outContinue);

    else (inElement, inArg, true);
  end match;
end traverseElementComponents;

protected function traverseElementSpecComponents<ArgT>
  input Absyn.ElementSpec inSpec;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ElementSpec outSpec = inSpec;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<Absyn.ComponentItem> inComponents;
    input ArgT inArg;
    output list<Absyn.ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outSpec, outArg, outContinue) := match(outSpec)
    local
      Absyn.Class cls;
      list<Absyn.ComponentItem> comps;

    case Absyn.COMPONENTS()
      algorithm
        (comps, outArg, outContinue) := inFunc(outSpec.components, inArg);
        if not referenceEq(comps, outSpec.components) then
          outSpec.components := comps;
        end if;
      then
        (outSpec, outArg, outContinue);

    else (inSpec, inArg, true);
  end match;
end traverseElementSpecComponents;

protected function traverseClassDef<ArgT>
  input Absyn.ClassDef inClassDef;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ClassDef outClassDef = inClassDef;
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input Absyn.ClassPart inPart;
    input ArgT inArg;
    output Absyn.ClassPart outPart;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  _ := match(outClassDef)
    local
      list<Absyn.ClassPart> parts;

    case Absyn.PARTS()
      algorithm
        (parts, outArg, outContinue) :=
          traverseListGeneric(outClassDef.classParts, inFunc, inArg);
        outClassDef.classParts := parts;
      then
        ();

    case Absyn.CLASS_EXTENDS()
      algorithm
        (parts, outArg, outContinue) :=
          traverseListGeneric(outClassDef.parts, inFunc, inArg);
        outClassDef.parts := parts;
      then
        ();

    else ();
  end match;
end traverseClassDef;

public function isEmptyMod
  input Absyn.Modification inMod;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inMod
    case Absyn.CLASSMOD({}, Absyn.NOMOD()) then true;
    case Absyn.CLASSMOD({}, Absyn.EQMOD(exp = Absyn.TUPLE(expressions = {}))) then true;
    else false;
  end match;
end isEmptyMod;

public function isEmptySubMod
  input Absyn.ElementArg inSubMod;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inSubMod
    local
      Absyn.Modification mod;

    case Absyn.MODIFICATION(modification = NONE()) then true;
    case Absyn.MODIFICATION(modification = SOME(mod)) then isEmptyMod(mod);
  end match;
end isEmptySubMod;

public function elementArgName
  input Absyn.ElementArg inArg;
  output Absyn.Path outName;
algorithm
  outName := match(inArg)
    local
      Absyn.ElementSpec e;
    case Absyn.MODIFICATION(path = outName) then outName;
    case Absyn.REDECLARATION(elementSpec = e) then makeIdentPathFromString(elementSpecName(e));
  end match;
end elementArgName;

public function elementArgEqualName
  input Absyn.ElementArg inArg1;
  input Absyn.ElementArg inArg2;
  output Boolean outEqual;
protected
  Absyn.Path name1, name2;
algorithm
  outEqual := match(inArg1, inArg2)
    case (Absyn.MODIFICATION(path = name1), Absyn.MODIFICATION(path = name2))
      then pathEqual(name1, name2);

    else false;
  end match;
end elementArgEqualName;

public function optMsg
  "Creates a Absyn.Msg based on a boolean value."
  input Boolean inShowMessage;
  input SourceInfo inInfo;
  output Absyn.Msg outMsg;
algorithm
  outMsg := if inShowMessage then Absyn.MSG(inInfo) else Absyn.NO_MSG();
  annotation(__OpenModelica_EarlyInline = true);
end optMsg;

public function makeSubscript
  input Absyn.Exp inExp;
  output Absyn.Subscript outSubscript;
algorithm
  outSubscript := Absyn.SUBSCRIPT(inExp);
end makeSubscript;

public function makeIntegerSubscript
  input Integer n;
  output Absyn.Subscript sub;
algorithm
  sub := Absyn.SUBSCRIPT(Absyn.INTEGER(n));
end makeIntegerSubscript;

public function crefExplode
  "Splits a cref into parts."
  input Absyn.ComponentRef inCref;
  input list<Absyn.ComponentRef> inAccum = {};
  output list<Absyn.ComponentRef> outCrefParts;
algorithm
  outCrefParts := match inCref
    case Absyn.CREF_QUAL() then crefExplode(inCref.componentRef, crefFirstCref(inCref) :: inAccum);
    case Absyn.CREF_FULLYQUALIFIED() then crefExplode(inCref.componentRef, inAccum);
    else listReverse(inCref :: inAccum);
  end match;
end crefExplode;

public function traverseExpShallow<ArgT>
  "Calls the given function on each subexpression (non-recursively) of the given
   expression, sending in the extra argument to each call."
  input Absyn.Exp inExp;
  input ArgT inArg;
  input FuncT inFunc;
  output Absyn.Exp outExp = inExp;

  partial function FuncT
    input Absyn.Exp inExp;
    input ArgT inArg;
    output Absyn.Exp outExp;
  end FuncT;
algorithm
  _ := match outExp
    local
      Absyn.Exp e1, e2;

    case Absyn.BINARY()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case Absyn.UNARY()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case Absyn.LBINARY()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case Absyn.LUNARY()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case Absyn.RELATION()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case Absyn.IFEXP()
      algorithm
        outExp.ifExp := inFunc(outExp.ifExp, inArg);
        outExp.trueBranch := inFunc(outExp.trueBranch, inArg);
        outExp.elseBranch := inFunc(outExp.elseBranch, inArg);
        outExp.elseIfBranch := list((inFunc(Util.tuple21(e), inArg),
          inFunc(Util.tuple22(e), inArg)) for e in outExp.elseIfBranch);
      then
        ();

    case Absyn.CALL()
      algorithm
        outExp.functionArgs := traverseExpShallowFuncArgs(outExp.functionArgs,
          inArg, inFunc);
      then
        ();

    case Absyn.PARTEVALFUNCTION()
      algorithm
        outExp.functionArgs := traverseExpShallowFuncArgs(outExp.functionArgs,
          inArg, inFunc);
      then
        ();

    case Absyn.ARRAY()
      algorithm
        outExp.arrayExp := list(inFunc(e, inArg) for e in outExp.arrayExp);
      then
        ();

    case Absyn.MATRIX()
      algorithm
        outExp.matrix := list(list(inFunc(e, inArg) for e in lst) for lst in
            outExp.matrix);
      then
        ();

    case Absyn.RANGE()
      algorithm
        outExp.start := inFunc(outExp.start, inArg);
        outExp.step := Util.applyOption1(outExp.step, inFunc, inArg);
        outExp.stop := inFunc(outExp.stop, inArg);
      then
        ();

    case Absyn.TUPLE()
      algorithm
        outExp.expressions := list(inFunc(e, inArg) for e in outExp.expressions);
      then
        ();

    case Absyn.AS()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case Absyn.CONS()
      algorithm
        outExp.head := inFunc(outExp.head, inArg);
        outExp.rest := inFunc(outExp.rest, inArg);
      then
        ();

    case Absyn.LIST()
      algorithm
        outExp.exps := list(inFunc(e, inArg) for e in outExp.exps);
      then
        ();

    case Absyn.DOT()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
        outExp.index := inFunc(outExp.index, inArg);
      then
        ();

    else ();
  end match;
end traverseExpShallow;

protected function traverseExpShallowFuncArgs<ArgT>
  input Absyn.FunctionArgs inArgs;
  input ArgT inArg;
  input FuncT inFunc;
  output Absyn.FunctionArgs outArgs = inArgs;

  partial function FuncT
    input Absyn.Exp inExp;
    input ArgT inArg;
    output Absyn.Exp outExp;
  end FuncT;
algorithm
  outArgs := match outArgs
    case Absyn.FUNCTIONARGS()
      algorithm
        outArgs.args := list(inFunc(arg, inArg) for arg in outArgs.args);
      then
        outArgs;

    case Absyn.FOR_ITER_FARG()
      algorithm
        outArgs.exp := inFunc(outArgs.exp, inArg);
        outArgs.iterators := list(traverseExpShallowIterator(it, inArg, inFunc)
          for it in outArgs.iterators);
      then
        outArgs;

  end match;
end traverseExpShallowFuncArgs;

protected function traverseExpShallowIterator<ArgT>
  input Absyn.ForIterator inIterator;
  input ArgT inArg;
  input FuncT inFunc;
  output Absyn.ForIterator outIterator;

  partial function FuncT
    input Absyn.Exp inExp;
    input ArgT inArg;
    output Absyn.Exp outExp;
  end FuncT;
protected
  String name;
  Option<Absyn.Exp> guard_exp, range_exp;
algorithm
  Absyn.ITERATOR(name, guard_exp, range_exp) := inIterator;
  guard_exp := Util.applyOption1(guard_exp, inFunc, inArg);
  range_exp := Util.applyOption1(range_exp, inFunc, inArg);
  outIterator := Absyn.ITERATOR(name, guard_exp, range_exp);
end traverseExpShallowIterator;

public function isElementItemClass
  input Absyn.ElementItem inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF())) then true;
    else false;
  end match;
end isElementItemClass;

public function isElementItem
  input Absyn.ElementItem inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case Absyn.ELEMENTITEM() then true;
    else false;
  end match;
end isElementItem;

public function isAlgorithmItem
  input Absyn.AlgorithmItem inAlg;
  output Boolean outIsClass;
algorithm
  outIsClass := match inAlg
    case Absyn.ALGORITHMITEM() then true;
    else false;
  end match;
end isAlgorithmItem;

public function isElementItemClassNamed
  input String inName;
  input Absyn.ElementItem inElement;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match inElement
    local
      String name;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(
      class_ = Absyn.CLASS(name = name)))) then name == inName;
    else false;
  end match;
end isElementItemClassNamed;

public function isEmptyClassPart
  input Absyn.ClassPart inClassPart;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inClassPart
    case Absyn.PUBLIC(contents = {}) then true;
    case Absyn.PROTECTED(contents = {}) then true;
    case Absyn.CONSTRAINTS(contents = {}) then true;
    case Absyn.EQUATIONS(contents = {}) then true;
    case Absyn.INITIALEQUATIONS(contents = {}) then true;
    case Absyn.ALGORITHMS(contents = {}) then true;
    case Absyn.INITIALALGORITHMS(contents = {}) then true;
    else false;
  end match;
end isEmptyClassPart;

public function isInvariantExpNoTraverse "For use with traverseExp"
  input output Absyn.Exp e;
  input output Boolean b;
algorithm
  if not b then
    return;
  end if;
  b := match e
    case Absyn.INTEGER() then true;
    case Absyn.REAL() then true;
    case Absyn.STRING() then true;
    case Absyn.BOOL() then true;
    case Absyn.BINARY() then true;
    case Absyn.UNARY() then true;
    case Absyn.LBINARY() then true;
    case Absyn.LUNARY() then true;
    case Absyn.RELATION() then true;
    case Absyn.IFEXP() then true;
    // case Absyn.CREF(Absyn.CREF_FULLYQUALIFIED()) then true;
    case Absyn.CALL(function_=Absyn.CREF_FULLYQUALIFIED()) then true;
    case Absyn.PARTEVALFUNCTION(function_=Absyn.CREF_FULLYQUALIFIED()) then true;
    case Absyn.ARRAY() then true;
    case Absyn.MATRIX() then true;
    case Absyn.RANGE() then true;
    case Absyn.CONS() then true;
    case Absyn.LIST() then true;
    else false;
  end match;
end isInvariantExpNoTraverse;

function pathPartCount
  "Returns the number of parts a path consists of, e.g. A.B.C gives 3."
  input Absyn.Path path;
  input Integer partsAccum = 0;
  output Integer parts;
algorithm
  parts := match path
    case Absyn.IDENT() then partsAccum + 1;
    case Absyn.QUALIFIED() then pathPartCount(path.path, partsAccum + 1);
    case Absyn.FULLYQUALIFIED() then pathPartCount(path.path, partsAccum);
  end match;
end pathPartCount;

public function getAnnotationsFromConstraintClass
  input Option<Absyn.ConstrainClass> inCC;
  output list<Absyn.ElementArg> elementArgs;
algorithm
  elementArgs := match(inCC)
    case SOME(Absyn.CONSTRAINCLASS(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs))))))
      then elementArgs;
    else {};
  end match;
end getAnnotationsFromConstraintClass;

public function getAnnotationsFromItems
  input list<Absyn.ComponentItem> inComponentItems;
  input list<Absyn.ElementArg> ccAnnotations;
  output list<list<Absyn.ElementArg>> outLst = {};
protected
  list<Absyn.ElementArg> annotations;
  list<String> res;
  String str;
algorithm
  for comp in listReverse(inComponentItems) loop
    annotations := match comp
      case Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(annotation_ =
          SOME(Absyn.ANNOTATION(annotations)))))
        then listAppend(annotations, ccAnnotations);
      else ccAnnotations;
    end match;

    outLst := annotations :: outLst;
  end for;
end getAnnotationsFromItems;

public function stripGraphicsAndInteractionModification
" This function strips out the `graphics\' modification from an Absyn.ElementArg
   list and return two lists, one with the other modifications and the
   second with the `graphics\' modification"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst1;
  output list<Absyn.ElementArg> outAbsynElementArgLst2;
algorithm
  (outAbsynElementArgLst1,outAbsynElementArgLst2) := matchcontinue inAbsynElementArgLst
    local
      Absyn.ElementArg mod;
      list<Absyn.ElementArg> rest,l1,l2;

    // handle empty
    case {} then ({},{});

    // adrpo: remove interaction annotations as we don't handle them currently
    case Absyn.MODIFICATION(path = Absyn.IDENT(name = "interaction")) :: rest
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,l2);

    // adrpo: remove empty annotations, to handle bad Dymola annotations, for example: Diagram(graphics)
    case Absyn.MODIFICATION(modification = NONE(), path = Absyn.IDENT(name = "graphics")) :: rest
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,l2);

    // add graphics to the second tuple
    case (mod as Absyn.MODIFICATION(modification = SOME(_), path = Absyn.IDENT(name = "graphics"))) :: rest
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,mod::l2);

    // add choice to the second tuple
    case (mod as Absyn.MODIFICATION(modification = SOME(_), path = Absyn.IDENT(name = "choice"))) :: rest
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,mod::l2);

    // collect in the first tuple
    case (mod as Absyn.MODIFICATION()) :: rest
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        ((mod :: l1),l2);

  end matchcontinue;
end stripGraphicsAndInteractionModification;

public function traverseClasses<Arg>
" This function traverses all classes of a program and applies a function
   to each class. The function takes the Absyn.Class, Absyn.Path option
   and an additional argument and returns an updated class and the
   additional values. The Absyn.Path option contains the path to the class
   that is traversed.
   inputs:  (Absyn.Program,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option  \'a)),  /* rel-ation to apply */
            \'a, /* extra value passed to re-lation */
            bool) /* true = traverse protected elements */
   outputs: (Absyn.Program   Absyn.Path option  \'a)"
  input Absyn.Program inProgram;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Arg inArg;
  input Boolean inVisitProtected;
  output tuple<Absyn.Program, Option<Absyn.Path>, Arg> outTpl;

  partial function FuncType
    input output tuple<Absyn.Class, Option<Absyn.Path>, Arg> tpl;
  end FuncType;
algorithm
  outTpl := match inProgram
    local
      list<Absyn.Class> classes;
      Option<Absyn.Path> pa;
      Arg arg;
      Absyn.Program p;

    case p as Absyn.PROGRAM()
      equation
        ((classes,pa,arg)) = traverseClasses2(p.classes, inPath, inFunc, inArg, inVisitProtected);
        p.classes = classes;
      then
        (p,pa,arg);
  end match;
end traverseClasses;

protected function traverseClasses2<Arg>
" Helperfunction to traverseClasses."
  input list<Absyn.Class> inClasses;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Arg inArg "extra argument";
  input Boolean inVisitProtected "visit protected elements";
  output tuple<list<Absyn.Class>, Option<Absyn.Path>, Arg> outTpl;

  partial function FuncType
    input output tuple<Absyn.Class, Option<Absyn.Path>, Arg> tpl;
  end FuncType;
algorithm
  outTpl := matchcontinue (inClasses, inPath, inFunc, inArg, inVisitProtected)
    local
      Option<Absyn.Path> pa,pa_1,pa_2,pa_3;
      FuncType visitor;
      Arg args,args_1,args_2,args_3;
      Absyn.Class class_1,class_2,class_;
      list<Absyn.Class> classes_1,classes;
      Boolean traverse_prot;

    case ({},pa,_,args,_) then (({},pa,args));

    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_1,_,args_1)) = visitor((class_,pa,args));
        ((class_2,_,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, traverse_prot);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, but class contains inner classes after traversal, i.e. those inner classes didn't fail, and thus
    the class must be included also */
    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_2,_,args_2)) = traverseInnerClass(class_, pa, visitor, args, traverse_prot);
        true = classHasLocalClasses(class_2);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, remove class */
    case ((_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args, traverse_prot);
      then
        ((classes_1,pa_3,args_3));

    case ((class_ :: _),_,_,_,_)
      equation
        print("-traverse_classes2 failed on class:");
        print(AbsynUtil.pathString(AbsynUtil.className(class_)));
        print("\n");
      then
        fail();

  end matchcontinue;
end traverseClasses2;

protected function classHasLocalClasses
"Returns true if class contains a local class"
  input Absyn.Class cl;
  output Boolean res;
algorithm
  res := match(cl)
    local
      list<Absyn.ClassPart> parts;

    // A class with parts.
    case (Absyn.CLASS(body= Absyn.PARTS(classParts = parts)))
      then partsHasLocalClass(parts);

    // An extended class with parts: model extends M end M;
    case (Absyn.CLASS(body= Absyn.CLASS_EXTENDS(parts = parts)))
      then partsHasLocalClass(parts);

  end match;
end classHasLocalClasses;

protected function partsHasLocalClass
"Help function to classHasLocalClass"
  input list<Absyn.ClassPart> inParts;
  output Boolean res;
algorithm
  res := matchcontinue(inParts)
    local
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> parts;

    case Absyn.PUBLIC(elts) :: _
      equation
        true = eltsHasLocalClass(elts);
      then
        true;

    case Absyn.PROTECTED(elts) :: _
      equation
        true = eltsHasLocalClass(elts);
      then
        true;

    case _ :: parts then partsHasLocalClass(parts);
    else false;
  end matchcontinue;
end partsHasLocalClass;

protected function eltsHasLocalClass
"help function to partsHasLocalClass"
  input list<Absyn.ElementItem> inElts;
  output Boolean res;
algorithm
  res := matchcontinue(inElts)
    local
      list<Absyn.ElementItem> elts;

    case Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF())) :: _ then true;
    case _ :: elts then eltsHasLocalClass(elts);
    else false;
  end matchcontinue;
end eltsHasLocalClass;

protected function traverseInnerClass<Arg>
" Helperfunction to traverseClasses2. This function traverses all inner classes of a class."
  input Absyn.Class inClass;
  input Option<Absyn.Path> path;
  input FuncType visitor;
  input Arg arg "extra value";
  input Boolean visitProtected "if true, traverse protected elts";
  output tuple<Absyn.Class, Option<Absyn.Path>, Arg> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Arg> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Arg> outTpl;
  end FuncType;
protected
  Absyn.Class cls = inClass;
  Absyn.ClassDef cdef = inClass.body;
  Absyn.Path pa;
  Option<Absyn.Path> opt_pa;
  list<Absyn.ClassPart> parts;
  Arg args;
algorithm
  (cdef, opt_pa, args) := matchcontinue(cdef, path)
    /* a class with parts */
    case (Absyn.PARTS(), SOME(pa))
      algorithm
        pa := AbsynUtil.joinPaths(pa, Absyn.IDENT(cls.name));
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.classParts, SOME(pa), visitor, arg, visitProtected);
        cdef.classParts := parts;
      then
        (cdef, opt_pa, args);

    case (Absyn.PARTS(), NONE())
      algorithm
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.classParts, SOME(Absyn.IDENT(cls.name)), visitor, arg, visitProtected);
        cdef.classParts := parts;
      then
        (cdef, opt_pa, args);

    case (Absyn.PARTS(), opt_pa)
      algorithm
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.classParts, opt_pa, visitor, arg, visitProtected);
        cdef.classParts := parts;
      then
        (cdef, opt_pa, args);

    /* adrpo: handle also an extended class with parts: model extends M end M; */
    case (Absyn.CLASS_EXTENDS(), SOME(pa))
      algorithm
        pa := AbsynUtil.joinPaths(pa, Absyn.IDENT(cls.name));
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.parts, SOME(pa), visitor, arg, visitProtected);
        cdef.parts := parts;
      then
        (cdef, opt_pa, args);

    case (Absyn.CLASS_EXTENDS(), NONE())
      algorithm
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.parts, SOME(Absyn.IDENT(cls.name)), visitor, arg, visitProtected);
        cdef.parts := parts;
      then
        (cdef, opt_pa, args);

    case (Absyn.CLASS_EXTENDS(), opt_pa)
      algorithm
        ((parts, opt_pa, args)) := traverseInnerClassParts(cdef.parts, opt_pa, visitor, arg, visitProtected);
        cdef.parts := parts;
      then
        (cdef, opt_pa, args);

    /* otherwise */
    else (cdef, path, arg);
  end matchcontinue;

  cls.body := cdef;
  outTpl := (cls, opt_pa, args);
end traverseInnerClass;

protected function traverseInnerClassParts<Arg>
  "Helper function to traverseInnerClass"
  input list<Absyn.ClassPart> inClassParts;
  input Option<Absyn.Path> inPath;
  input FuncType visitor;
  input Arg inArg "extra argument";
  input Boolean visitProtected "visist protected elts";
  output tuple<list<Absyn.ClassPart>, Option<Absyn.Path>, Arg> outTpl;

  partial function FuncType
    input output tuple<Absyn.Class, Option<Absyn.Path>, Arg> tpl;
  end FuncType;
protected
  list<Absyn.ClassPart> parts = {};
  list<Absyn.ElementItem> elts;
  Arg arg = inArg;
algorithm
  parts := list(
      match p
        case Absyn.PUBLIC()
          algorithm
            ((elts, _, arg)) := traverseInnerClassElements(p.contents, inPath, visitor, arg, visitProtected);
          then
            Absyn.PUBLIC(elts);

        case Absyn.PROTECTED()
          guard visitProtected
          algorithm
            ((elts, _, arg)) := traverseInnerClassElements(p.contents, inPath, visitor, arg, true);
          then
            Absyn.PROTECTED(elts);

        else p;
      end match
    for p in inClassParts);

  outTpl := (parts, inPath, arg);
end traverseInnerClassParts;

protected function traverseInnerClassElements<Arg>
  "Helper function to traverseInnerClassParts"
  input list<Absyn.ElementItem> inElements;
  input Option<Absyn.Path> inPath;
  input FuncType visitor;
  input Arg inArg;
  input Boolean visitProtected "visit protected elts";
  output tuple<list<Absyn.ElementItem>, Option<Absyn.Path>, Arg> outTpl;

  partial function FuncType
    input output tuple<Absyn.Class, Option<Absyn.Path>, Arg> tpl;
  end FuncType;
protected
  list<Absyn.ElementItem> elts = {};
  Absyn.Element el;
  Arg arg = inArg;
  Absyn.ElementSpec spec;
  Absyn.Class cl;
algorithm
  for e in inElements loop
    elts := match e
      case Absyn.ELEMENTITEM(element = el as Absyn.ELEMENT(specification = spec))
        algorithm
          ((spec, _, arg)) := traverseInnerClassElementspec(spec, inPath, visitor, arg, visitProtected);
          el.specification := spec;
          e.element := el;
        then
          e :: elts;

      /* Visitor failed in elementspec, but inner classes succeeded, include class */
      case Absyn.ELEMENTITEM(element = el as Absyn.ELEMENT(specification = spec as Absyn.CLASSDEF()))
        algorithm
          ((cl, _, arg)) := traverseInnerClass(spec.class_, inPath, visitor, arg, visitProtected);
          spec.class_ := cl;
          el.specification := spec;
          e.element := el;
        then
          e :: elts;

      /* Visitor failed in elementspec, remove class */
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT())
        then elts;

      else e :: elts;
    end match;
  end for;

  elts := listReverseInPlace(elts);
  outTpl := (elts, inPath, arg);
end traverseInnerClassElements;


protected function traverseInnerClassElementspec<Arg>
" Helperfunction to traverseInnerClassElements"
  input Absyn.ElementSpec inElementSpec;
  input Option<Absyn.Path> inPath;
  input FuncType visitor;
  input Arg inArg;
  input Boolean visitProtected "visit protected elts";
  output tuple<Absyn.ElementSpec, Option<Absyn.Path>, Arg> outTpl;
  partial function FuncType
    input output tuple<Absyn.Class, Option<Absyn.Path>, Arg> tpl;
  end FuncType;
algorithm
  outTpl := match(inElementSpec, inPath, inArg)
    local
      Absyn.Class cl;
      Option<Absyn.Path> pa;
      Arg args;
      Boolean repl;

    case (Absyn.CLASSDEF(repl, cl),pa,args)
      equation
        ((cl,_,args)) = visitor((cl,pa,args));
        ((cl,pa,args)) = traverseInnerClass(cl, pa, visitor, args, visitProtected);
      then
        ((Absyn.CLASSDEF(repl, cl),pa,args));

    case (Absyn.EXTENDS(),pa,args) then ((inElementSpec,pa,args));
    case (Absyn.IMPORT(),pa,args) then ((inElementSpec,pa,args));
    case (Absyn.COMPONENTS(),pa,args) then ((inElementSpec,pa,args));
  end match;
end traverseInnerClassElementspec;

public function getTypeSpecFromElementItemOpt
"@auhtor: johti
 Get the typespec path in an Absyn.ElementItem if it has one"
  input Absyn.ElementItem inElementItem;
  output Option<Absyn.TypeSpec> outTypeSpec;
algorithm
  outTypeSpec := match inElementItem
    local
      Absyn.TypeSpec ty_spec;
    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = ty_spec)))
      then SOME(ty_spec);
    else NONE();
  end match;
end getTypeSpecFromElementItemOpt;

public function getElementSpecificationFromElementItemOpt
  "@auhtor: johti
     Get a Absyn.ComponentItem from an Absyn.ElementItem if it has one"
  input Absyn.ElementItem inElementItem;
  output Option<Absyn.ElementSpec> outSpec;
algorithm
  outSpec := match inElementItem
    local
      Absyn.ElementSpec spec;
    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = spec)) then SOME(spec);
    else NONE();
  end match;
end getElementSpecificationFromElementItemOpt;

public function getComponentItemsFromElementSpec
"@auhtor: johti
 Get the componentItems from a given elemSpec otherwise returns an empty list"
  input Absyn.ElementSpec elemSpec;
  output list<Absyn.ComponentItem> componentItems;
algorithm
  componentItems := match elemSpec
    case Absyn.COMPONENTS() then elemSpec.components;
    else {};
  end match;
end getComponentItemsFromElementSpec;

public function getComponentItemsFromElementItem
"@author: johti
 Get the componentItems from a given elementItem"
  input Absyn.ElementItem inElementItem;
  output list<Absyn.ComponentItem> componentItems;
algorithm
  componentItems := match getElementSpecificationFromElementItemOpt(inElementItem)
    local Absyn.ElementSpec elementSpec;
    case SOME(elementSpec) then getComponentItemsFromElementSpec(elementSpec);
    else {};
  end match;
end getComponentItemsFromElementItem;

public function getDirection
"@author johti
  Get the direction if one exists otherwise returns Absyn.BIDIR()"
  input Absyn.ElementItem elementItem;
  output Absyn.Direction oDirection;
algorithm
  oDirection := match elementItem
    case Absyn.ELEMENTITEM(element =
        Absyn.ELEMENT(specification =
          Absyn.COMPONENTS(attributes =
            Absyn.ATTR(direction = oDirection))))
      then oDirection;

    else Absyn.BIDIR();
  end match;
end getDirection;

function isNamedPathIdent
  input Absyn.Path path;
  input String name;
  output Boolean res;
algorithm
  res := match path
    case Absyn.IDENT() then path.name == name;
    else false;
  end match;
end isNamedPathIdent;

function isUniontype
" @author johti17: Returns true if the class is of type uniontype
"
input Absyn.Class cls;
output Boolean b;
algorithm
  b := match cls.restriction
    case Absyn.R_UNIONTYPE(__) then true;
    else false;
 end match;
end isUniontype;

public function traverseClassElements<ArgT>
  input Absyn.Class inClass;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.Class outClass = inClass;
  output ArgT outArg;

  partial function FuncType
    input Absyn.Element inElement;
    input ArgT inArg;
    output Absyn.Element outElement;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  outClass := match(outClass)
    local
      Absyn.ClassDef body;

    case Absyn.CLASS()
      algorithm
        (body, outArg) := traverseClassDef(outClass.body,
          function traverseClassPartElements(inFunc = inFunc), inArg);
        if not referenceEq(body, outClass.body) then outClass.body := body; end if;
      then
        outClass;

  end match;
end traverseClassElements;

protected function traverseClassPartElements<ArgT>
  input Absyn.ClassPart inClassPart;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ClassPart outClassPart = inClassPart;
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input Absyn.Element inElement;
    input ArgT inArg;
    output Absyn.Element outElement;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  _ := match(outClassPart)
    local
      list<Absyn.ElementItem> items;

    case Absyn.PUBLIC()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
            function traverseElementItem(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    case Absyn.PROTECTED()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
             function traverseElementItem(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    else ();
  end match;
end traverseClassPartElements;

protected function traverseElementItem<ArgT>
  input Absyn.ElementItem inItem;
  input FuncType inFunc;
  input ArgT inArg;
  output Absyn.ElementItem outItem;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input Absyn.Element inElement;
    input ArgT inArg;
    output Absyn.Element outElement;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outItem, outArg, outContinue) := match(inItem)
    local
      Absyn.Element elem;

    case Absyn.ELEMENTITEM()
      algorithm
        (elem, outArg, outContinue) := inFunc(inItem.element, inArg);
        outItem := if referenceEq(elem, inItem.element) then inItem else Absyn.ELEMENTITEM(elem);
      then
        (outItem, outArg, outContinue);

    else (inItem, inArg, true);
  end match;
end traverseElementItem;

public function elementSpec
  input Absyn.Element el;
  output Absyn.ElementSpec elSpec;
algorithm
  Absyn.ELEMENT(specification = elSpec) := el;
end elementSpec;

public function isClassOrComponentElementSpec
  "The Absyn.ElementSpec type contains the name of the element, and this function
   extracts this name."
  input Absyn.ElementSpec inElementSpec;
  output Boolean yes = false;
algorithm
  yes := match (inElementSpec)
    case Absyn.CLASSDEF(class_ = Absyn.CLASS()) then true;
    case Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM()}) then true;
    else false;
  end match;
end isClassOrComponentElementSpec;

public function isPartial
"Return true if Class is a partial."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  Absyn.CLASS(partialPrefix = outBoolean) := inClass;
end isPartial;

public function isNotPartial
"Return true if Class is a partial."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := not isPartial(inClass);
end isNotPartial;

public function crefIsWild
  input Absyn.ComponentRef cref;
  output Boolean wild;
algorithm
  wild := match cref
    case Absyn.WILD() then true;
    case Absyn.ALLWILD() then true;
    else false;
  end match;
end crefIsWild;

public function makeCall
  input Absyn.ComponentRef name;
  input list<Absyn.Exp> posArgs;
  input list<Absyn.NamedArg> namedArgs = {};
  output Absyn.Exp callExp;
algorithm
  callExp := Absyn.Exp.CALL(name, Absyn.FunctionArgs.FUNCTIONARGS(posArgs, namedArgs), {});
end makeCall;

public function pathReplaceFirst
  "Replaces the first identifier of a path with another path. Ex:
    pathReplaceFirst(A.B.C, X.Y.Z) => X.Y.Z.B.C"
  input Absyn.Path path;
  input Absyn.Path prefix;
  output Absyn.Path outPath;
algorithm
  outPath := match path
    case Absyn.Path.IDENT() then prefix;
    case Absyn.Path.QUALIFIED() then joinPaths(prefix, path.path);
    case Absyn.Path.FULLYQUALIFIED() then Absyn.Path.FULLYQUALIFIED(pathReplaceFirst(path.path, prefix));
  end match;
end pathReplaceFirst;

function pathContains
  input Absyn.Path path;
  input Absyn.Ident name;
  output Boolean res;
algorithm
  res := match path
    case Absyn.Path.IDENT() then path.name == name;
    case Absyn.Path.QUALIFIED()
      then path.name == name or pathContains(path.path, name);
    case Absyn.Path.FULLYQUALIFIED() then pathContains(path.path, name);
  end match;
end pathContains;

function getClassAnnotation
  "Returns the optional annotation for a class. Some classes may have multiple
   annotations because Modelica 2 allowed it, in that case only the first
   annotation is returned."
  input Absyn.Class cls;
  output Option<Absyn.Annotation> ann;
algorithm
  ann := getClassDefAnnotation(cls.body);
end getClassAnnotation;

function getClassDefAnnotation
  "Returns the optional annotation for a class definition."
  input Absyn.ClassDef cdef;
  output Option<Absyn.Annotation> ann;
algorithm
  ann := match cdef
    case Absyn.ClassDef.PARTS()
      then if listEmpty(cdef.ann) then NONE() else SOME(listHead(cdef.ann));
    case Absyn.ClassDef.DERIVED(comment = SOME(Absyn.Comment.COMMENT(annotation_ = ann))) then ann;
    case Absyn.ClassDef.ENUMERATION(comment = SOME(Absyn.Comment.COMMENT(annotation_ = ann))) then ann;
    case Absyn.ClassDef.OVERLOAD(comment = SOME(Absyn.Comment.COMMENT(annotation_ = ann))) then ann;
    case Absyn.ClassDef.CLASS_EXTENDS()
      then if listEmpty(cdef.ann) then NONE() else SOME(listHead(cdef.ann));
    case Absyn.ClassDef.PDER(comment = SOME(Absyn.Comment.COMMENT(annotation_ = ann))) then ann;
    else NONE();
  end match;
end getClassDefAnnotation;

function setClassAnnotation
  "Overwrites the annotation for a class with a given annotation. If the class
   has multiple annotations only the first is overwritten, similarly to how
   getClassAnnotation ignores other annotations than the first."
  input output Absyn.Class cls;
  input Option<Absyn.Annotation> ann;
algorithm
  cls.body := setClassDefAnnotation(cls.body, ann);
end setClassAnnotation;

function setClassDefAnnotation
  "Overwrites the annotation for a class definition with a given annotation."
  input output Absyn.ClassDef cdef;
  input Option<Absyn.Annotation> ann;
algorithm
  () := match cdef
    case Absyn.ClassDef.PARTS()
      algorithm
        if not listEmpty(cdef.ann) then
          cdef.ann := listRest(cdef.ann);
        end if;

        if isSome(ann) then
          cdef.ann := Util.getOption(ann) :: cdef.ann;
        end if;
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        cdef.comment := setCommentAnnotation(cdef.comment, ann);
      then
        ();

    case Absyn.ClassDef.ENUMERATION()
      algorithm
        cdef.comment := setCommentAnnotation(cdef.comment, ann);
      then
        ();

    case Absyn.ClassDef.OVERLOAD()
      algorithm
        cdef.comment := setCommentAnnotation(cdef.comment, ann);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        if not listEmpty(cdef.ann) then
          cdef.ann := listRest(cdef.ann);
        end if;

        if isSome(ann) then
          cdef.ann := Util.getOption(ann) :: cdef.ann;
        end if;
      then
        ();

    case Absyn.ClassDef.PDER()
      algorithm
        cdef.comment := setCommentAnnotation(cdef.comment, ann);
      then
        ();

    else ();
  end match;
end setClassDefAnnotation;

function setCommentAnnotation
  "Overwrites the annotation in an optional comment."
  input output Option<Absyn.Comment> comment;
  input Option<Absyn.Annotation> ann;
protected
  Option<String> cmt;
algorithm
  comment := match (comment, ann)
    // No comment, no annotation => no comment
    case (NONE(), NONE()) then comment;
    // No comment, some annotation => new comment
    case (NONE(), _) then SOME(Absyn.Comment.COMMENT(ann, NONE()));
    // Some comment => overwrite annotation in comment
    case (SOME(Absyn.Comment.COMMENT(_, cmt)), _)
      then SOME(Absyn.Comment.COMMENT(ann, cmt));
  end match;
end setCommentAnnotation;

function mapAnnotationBinding
  "Updates the binding expression for the element specificed by the given path
   in an annotation using the given function. found will be true if the element
   was found and updated, otherwise false."
  input output Absyn.Annotation ann;
  input Absyn.Path path;
  input MapFunc func;
        output Boolean found;

  partial function MapFunc
    input output Absyn.Exp exp;
  end MapFunc;
protected
  list<Absyn.ElementArg> args = ann.elementArgs;
algorithm
  (args, found) := List.findMap(args, function mapAnnotationBindingInArg(path = path, func = func));
  ann.elementArgs := args;
end mapAnnotationBinding;

function mapAnnotationBindingInArg
  "Helper function to mapAnnotationBinding."
  input output Absyn.ElementArg arg;
  input Absyn.Path path;
  input MapFunc func;
        output Boolean found = false;

  partial function MapFunc
    input output Absyn.Exp exp;
  end MapFunc;
protected
  Absyn.Modification mod;
  list<Absyn.ElementArg> mod_args;
  Absyn.EqMod mod_eq;
  Absyn.Path rest_path;
  Integer arg_path_len;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION(modification = SOME(mod))
      algorithm
        if pathPrefixOf(arg.path, path) then
          arg_path_len := pathPartCount(arg.path);

          if arg_path_len == pathPartCount(path) then
            mod_eq := mapAnnotationBindingInEqMod(mod.eqMod, func);
            mod.eqMod := mod_eq;
            found := true;
          else
            rest_path := Util.foldcallN(arg_path_len, AbsynUtil.pathRest, path);
            (mod_args, found) := List.findMap(mod.elementArgLst,
              function mapAnnotationBindingInArg(path = rest_path, func = func));
            mod.elementArgLst := mod_args;
          end if;

          if found then
            arg.modification := SOME(mod);
          end if;
        end if;
      then
        ();

    else ();
  end match;
end mapAnnotationBindingInArg;

function mapAnnotationBindingInEqMod
  "Helper function to mapAnnotationBinding."
  input output Absyn.EqMod eqMod;
  input MapFunc func;

  partial function MapFunc
    input output Absyn.Exp exp;
  end MapFunc;
algorithm
  () := match eqMod
    case Absyn.EqMod.EQMOD()
      algorithm
        eqMod.exp := func(eqMod.exp);
      then
        ();

    else ();
  end match;
end mapAnnotationBindingInEqMod;

public function createChoiceArray
"translates
  choices(choice(mod1),choice(mod2),choice(mod3)) -> choices(choice={\"mod1\", \"mod2\", \"mod3\"})
  choices(choice = mod1, choice = mod2, choice = mod3) -> choices(choice={\"mod1\", \"mod2\", \"mod3\"})"
  input Absyn.ElementArg inChoices;
  output Absyn.ElementArg outChoices = inChoices;
protected
   Absyn.ElementArg choices;
   list<Absyn.ElementArg> choice, acc_choice = {}, acc = {}, args;
   Absyn.ElementArg c, el;
   Absyn.Info info1, info2;
   Option<String> cmt1, cmt2;
   Boolean fp1, fp2;
   Absyn.Each ep1, ep2;
   list<String> choiceArray = {};
   String s;
   Absyn.Exp e;
algorithm
  outChoices := match(inChoices)
    case Absyn.MODIFICATION(
          finalPrefix = fp1,
          eachPrefix = ep1,
          path = Absyn.IDENT("choices"),
          modification = SOME(Absyn.CLASSMOD(choice, Absyn.NOMOD())),
          comment = cmt1,
          info = info1)
      algorithm
        for m in choice loop
          (choiceArray, acc) := match m
          // if is a choice, remember it and put it in an array of strings
          case Absyn.MODIFICATION(fp2, ep2, Absyn.IDENT("choice"), SOME(Absyn.CLASSMOD({el}, Absyn.NOMOD())), cmt2, info2)
            algorithm
              s := Dump.unparseElementArgStr(el);
            then
              (s::choiceArray, acc);
          // if is a choice, remember it and put it in an array of strings
          case Absyn.MODIFICATION(fp2, ep2, Absyn.IDENT("choice"), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(exp = e))), cmt2, info2)
            algorithm
              s := Dump.printExpStr(e);
            then
              (s::choiceArray, acc);
          // otherwise put it in any other arguments except choice
          else
             (choiceArray, m::acc);
          end match;
        end for;
        if not listEmpty(choiceArray) then
          e := Absyn.ARRAY(list(Absyn.STRING(s) for s in listReverse(choiceArray)));
          c := Absyn.MODIFICATION(fp2, ep2, Absyn.IDENT("choice"), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(e, info2))), cmt2, info2);
          args := listReverse(c::acc);
        else
          args := listReverse(acc);
        end if;
        choices := Absyn.MODIFICATION(fp1, ep1, Absyn.IDENT("choices"), SOME(Absyn.CLASSMOD(args, Absyn.NOMOD())), cmt1, info1);
      then
        choices;
    else then inChoices;
  end match;
end createChoiceArray;

function mapCrefExps
  "Applies a function to the expressions in an Absyn.ComponentRef, i.e. in its subscripts."
  input output Absyn.ComponentRef cref;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  () := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        cref.subscripts := list(mapSubscriptExp(s, func) for s in cref.subscripts);
      then
        ();

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        cref.subscripts := list(mapSubscriptExp(s, func) for s in cref.subscripts);
      then
        ();

    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := mapCrefExps(cref.componentRef, func);
      then
        ();

    else ();
  end match;
end mapCrefExps;

function mapSubscriptExp
  input output Absyn.Subscript sub;
  input Func func;

  partial function Func
    input output Absyn.Exp exp;
  end Func;
algorithm
  () := match sub
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        sub.subscript := func(sub.subscript);
      then
        ();

    else ();
  end match;
end mapSubscriptExp;

annotation(__OpenModelica_Interface="frontend");
end AbsynUtil;
