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

encapsulated package RewriteRules
" file:        RewriteRules.mo
  package:     RewriteRules
  description: RewriteRules applies user given rewrite rules to the Absyn expressions

  RCS: $Id: RewriteRules.mo 18167 2013-11-18 12:36:35Z perost $

"

public import Absyn;
public import DAE;
public import Global;

public uniontype Rule
 "rule to rewrite fromExp -> toExp,
  there are FrontEnd and BackEnd rules"

 record FRONTEND_RULE "rule to rewrite fromExp -> toExp, apply to FrontEnd AST exps"
   Absyn.Exp from;
   Absyn.Exp to;
 end FRONTEND_RULE;

 record BACKEND_RULE "rule to rewrite fromExp -> toExp, apply to the BackEnd AST exps"
   Absyn.Exp from;
   Absyn.Exp to;
 end BACKEND_RULE;

end Rule;

public type Rules = list<Rule>;

public uniontype Bind "a bind '$1' bound to an exp"

 record FRONTEND_BIND "a bind '$1' bound to an exp (frontend) "
   Absyn.Exp slot;
   Absyn.Exp value;
 end FRONTEND_BIND;

 record BACKEND_BIND "a bind '$1' bound to an exp (backend) "
   DAE.Exp slot;
   DAE.Exp value;
 end BACKEND_BIND;

end Bind;

public type Binds = list<Bind>;

protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import GlobalScript;
protected import GlobalScriptDump;
protected import List;
protected import Parser;
protected import System;
protected import Util;

// frontend rewrite stuff
// ----------------------
public function rewriteFrontEnd
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
  output Boolean isChanged;
algorithm
  (outExp, isChanged) := match(inExp)
    local
      Rules rules;
      Boolean b;

    case (_)
      equation
        rules = getRulesFrontEnd(getAllRules());
        (outExp, b) = matchAndRewriteExpFrontEnd(inExp, rules);
      then
        (outExp, b);

  end match;
end rewriteFrontEnd;

public function matchAndRewriteExpFrontEnd
"tries to match each of the rewrite rule
 to the input expression and bind the place
 holders to actual expression"
  input Absyn.Exp inExp;
  input Rules inRules;
  output Absyn.Exp outExp;
  output Boolean changed;
algorithm
  (outExp, changed) := matchcontinue(inExp, inRules)
    local
      Absyn.Exp from, to;
      Rules rest;
      Binds binds;
      Boolean b;

    // nothing matched!
    case (_, {}) then (inExp, false);

    // matches the head
    case (_, FRONTEND_RULE(from, to)::_)
      equation
        (binds as _::_) = matchesFrontEnd(inExp, from, {});
        outExp = rewriteExpFrontEnd(to, binds);
        b = boolNot(referenceEq(inExp, outExp));
        print("FrontEnd Exp:     " + Dump.printExpStr(inExp) + "\n" +
              "FrontEnd From:    " + Dump.printExpStr(from) + "\n" +
              "FrontEnd To:      " + Dump.printExpStr(to) + "\n" +
              "FrontEnd Rewrite: " + Dump.printExpStr(outExp) + "\n---------\n");
      then
        (outExp, b);

    // not match for the head, try next
    case (_, _::rest)
      equation
        (outExp, b) = matchAndRewriteExpFrontEnd(inExp, rest);
      then
        (outExp, b);

  end matchcontinue;
end matchAndRewriteExpFrontEnd;

public function rewriteExpFrontEnd
 input Absyn.Exp inExp;
 input Binds inBinds;
 output Absyn.Exp outExp;
algorithm
  (outExp, _) := Absyn.traverseExp(inExp, replaceBindsFrontEnd, inBinds);
end rewriteExpFrontEnd;

public function replaceBindsFrontEnd
  input Absyn.Exp inExp;
  input Binds inBinds;
  output Absyn.Exp outExp;
  output Binds outBinds;
algorithm
  (outExp,outBinds) := match (inExp,inBinds)
    local
      Absyn.Exp e1,e2;
      Binds bnds;

    case (e1 as Absyn.CREF(_), bnds)
      equation
        e2 = replaceBindFrontEnd(e1, bnds);
      then
        (e2, bnds);

    // leave as it is
    else (inExp,inBinds);

  end match;
end replaceBindsFrontEnd;

public function replaceBindFrontEnd
  input Absyn.Exp inExp;
  input Binds inBinds;
  output Absyn.Exp outExp;
protected
  Boolean found;
  Absyn.Exp e, to;
algorithm
  for bind in inBinds loop
    FRONTEND_BIND(e, outExp) := bind;

    if Absyn.expEqual(inExp, e) then
      return;
    end if;
  end for;

  // Couldn't find matching binding, return inExp.
  outExp := inExp;
end replaceBindFrontEnd;

public function matchesFrontEnd
"@author: adrpo
 unifies two absyn expressions and if they match
 binds the placeholders '$1', '$2' to actual
 expressions from inExp.
 returns a list of BIND('$1', exp1)
 or fails if the expressions cannot be unified"
  input Absyn.Exp inExp;
  input Absyn.Exp inUnifyWith;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := matchcontinue(inExp, inUnifyWith, inAcc)
    local
      Absyn.Exp e1a, e2a, e1b, e2b, cond1a, cond1b;
      Absyn.Operator op1a, op1b;
      list<tuple<Absyn.Exp, Absyn.Exp>> elseIfa, elseIfb;
      Absyn.ComponentRef cr1a, cr1b;
      Absyn.FunctionArgs fargs1a, fargs1b;
      list<Absyn.Exp> exps1a, exps1b;
      list<list<Absyn.Exp>> expsLst1a, expsLst1b;
      Option<Absyn.Exp> oe1a, oe1b;
      Absyn.Ident id1a, id1b;

    // we have a place holder
    case (_, Absyn.CREF(_), _)
      equation
        true = isPlaceHolderFrontEnd(inUnifyWith);
        outBinds = FRONTEND_BIND(inUnifyWith, inExp)::inAcc;
      then
        outBinds;

    // must be equal
    case (Absyn.INTEGER(_), _, _)
      equation
        true = Absyn.expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (Absyn.REAL(_), _, _)
      equation
        true = Absyn.expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (Absyn.STRING(_), _, _)
      equation
        true = Absyn.expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (Absyn.BOOL(_), _, _)
      equation
        true = Absyn.expEqual(inExp, inUnifyWith);
      then
        inAcc;

    // cref
    case (Absyn.CREF(_), _, _)
      equation
        true = Absyn.expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (Absyn.BINARY(e1a, op1a, e2a), Absyn.BINARY(e1b, op1b, e2b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.UNARY(op1a, e1a), Absyn.UNARY(op1b, e1b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
      then
        outBinds;

    case (Absyn.LBINARY(e1a, op1a, e2a), Absyn.LBINARY(e1b, op1b, e2b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.LUNARY(op1a, e1a), Absyn.LUNARY(op1b, e1b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
      then
        outBinds;

    case (Absyn.RELATION(e1a, op1a, e2a), Absyn.RELATION(e1b, op1b, e2b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.IFEXP(cond1a, e1a, e2a, _), Absyn.IFEXP(cond1b, e1b, e2b, _), _)
      equation
        outBinds = matchesFrontEnd(cond1a, cond1b, inAcc);
        outBinds = matchesFrontEnd(e1a, e1b, outBinds);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
        // TODO! handle elseif
        // outBinds = matchesElseIf(elseIfa, elseIfb, outBinds);
      then
        outBinds;

    case (Absyn.CALL(cr1a, fargs1a), Absyn.CALL(cr1b, fargs1b), _)
      equation
        true = Absyn.crefEqual(cr1a, cr1b);
        outBinds = matchesFargsFrontEnd(fargs1a, fargs1b, inAcc);
      then
        outBinds;

    case (Absyn.PARTEVALFUNCTION(cr1a, fargs1a), Absyn.PARTEVALFUNCTION(cr1b, fargs1b), _)
      equation
        true = Absyn.crefEqual(cr1a, cr1b);
        outBinds = matchesFargsFrontEnd(fargs1a, fargs1b, inAcc);
      then
        outBinds;

    case (Absyn.ARRAY(exps1a), Absyn.ARRAY(exps1b), _)
      equation
        outBinds = matchesExpLstFrontEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (Absyn.MATRIX(expsLst1a), Absyn.MATRIX(expsLst1b), _)
      equation
        outBinds = matchesExpLstLstFrontEnd(expsLst1a, expsLst1b, inAcc);
      then
        outBinds;

    case (Absyn.RANGE(e1a, oe1a, e2a), Absyn.RANGE(e1b, oe1b, e2b), _)
      equation
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesExpOptFrontEnd(oe1a, oe1b, outBinds);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.TUPLE(exps1a), Absyn.TUPLE(exps1b), _)
      equation
        outBinds = matchesExpLstFrontEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (Absyn.END(), Absyn.END(), _) then inAcc;

    case (Absyn.CODE(_), Absyn.CODE(_), _) then inAcc;

    case (Absyn.AS(id1a, e1a), Absyn.AS(id1b, e1b), _)
      equation
        true = stringEq(id1a, id1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
      then outBinds;

    case (Absyn.CONS(e1a, e2a), Absyn.CONS(e1b, e2b), _)
      equation
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesFrontEnd(e2a, e2b, outBinds);
      then outBinds;

    // TODO! support matchexp
    case (Absyn.MATCHEXP(), Absyn.MATCHEXP(), _)
      then inAcc;

    case (Absyn.LIST(exps1a), Absyn.LIST(exps1b), _)
      equation
        outBinds = matchesExpLstFrontEnd(exps1a, exps1b, inAcc);
      then
        outBinds;
  end matchcontinue;
end matchesFrontEnd;

public function matchesExpOptFrontEnd
  input Option<Absyn.Exp> inOExp1;
  input Option<Absyn.Exp> inOExp2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inOExp1, inOExp2, inAcc)
    local Absyn.Exp e1a, e1b;
    case (NONE(), NONE(), _) then inAcc;
    case (SOME(e1a), SOME(e1b), _)
      equation
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
      then
        outBinds;
    else fail();
  end match;
end matchesExpOptFrontEnd;

public function matchesExpLstFrontEnd
  input list<Absyn.Exp> inExps1;
  input list<Absyn.Exp> inExps2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inExps1, inExps2, inAcc)
    local
      Absyn.Exp e1a, e1b;
      list<Absyn.Exp> exps1a, exps1b;

    case ({}, {}, _) then inAcc;
    case (e1a::exps1a, e1b::exps1b, _)
      equation
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesExpLstFrontEnd(exps1a, exps1b, outBinds);
      then
        outBinds;

  end match;
end matchesExpLstFrontEnd;

public function matchesFargsFrontEnd
  input Absyn.FunctionArgs inFargs1;
  input Absyn.FunctionArgs inFargs2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inFargs1, inFargs2, inAcc)
    local
      list<Absyn.Exp> exps1a, exps1b;
      list<Absyn.NamedArg> nargs1a, nargs1b;
      Absyn.Exp e1a, e1b;

    case (Absyn.FUNCTIONARGS(exps1a, nargs1a), Absyn.FUNCTIONARGS(exps1b, nargs1b), _)
      equation
        outBinds = matchesExpLstFrontEnd(exps1a, exps1b, inAcc);
        // fargs should be equal
        true = intEq(listLength(nargs1a), listLength(nargs1b));
        // match nargs
        outBinds = matchesNargsFrontEnd(sortNargsFrontEnd(nargs1a), sortNargsFrontEnd(nargs1b), outBinds);
      then
        outBinds;

    // TODO, handle for iterators!
    case (Absyn.FOR_ITER_FARG(e1a, _, _), Absyn.FOR_ITER_FARG(e1b, _, _), _)
      equation
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
      then
        outBinds;
  end match;
end matchesFargsFrontEnd;

public function sortNargsFrontEnd
  input list<Absyn.NamedArg> inNargs;
  output list<Absyn.NamedArg> outNargs;
algorithm
  outNargs := List.sort(inNargs, inNargComp);
end sortNargsFrontEnd;

public function inNargComp
  input Absyn.NamedArg inNarg1;
  input Absyn.NamedArg inNarg2;
  output Boolean isGreater;
protected
  Absyn.Ident id1, id2;
algorithm
  Absyn.NAMEDARG(argName = id1) := inNarg1;
  Absyn.NAMEDARG(argName = id2) := inNarg2;
  isGreater := intGt(stringCompare(id1, id2), 0);
end inNargComp;

public function matchesNargsFrontEnd
  input list<Absyn.NamedArg> inNargs1;
  input list<Absyn.NamedArg> inNargs2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inNargs1, inNargs2, inAcc)
    local
      Absyn.Ident n1a, n1b;
      Absyn.Exp e1a, e1b;
      list<Absyn.NamedArg> nargs1a, nargs1b;

    case ({}, {}, _) then inAcc;

    case (Absyn.NAMEDARG(n1a, e1a)::nargs1a, Absyn.NAMEDARG(n1b, e1b)::nargs1b, _)
      equation
        true = stringEq(n1a, n1b);
        outBinds = matchesFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesNargsFrontEnd(nargs1a, nargs1b, outBinds);
      then
        outBinds;

  end match;
end matchesNargsFrontEnd;

public function matchesExpLstLstFrontEnd
  input list<list<Absyn.Exp>> inExps1;
  input list<list<Absyn.Exp>> inExps2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inExps1, inExps2, inAcc)
    local
      list<Absyn.Exp> e1a, e1b;
      list<list<Absyn.Exp>> exps1a, exps1b;

    case ({}, {}, _) then inAcc;
    case (e1a::exps1a, e1b::exps1b, _)
      equation
        outBinds = matchesExpLstFrontEnd(e1a, e1b, inAcc);
        outBinds = matchesExpLstLstFrontEnd(exps1a, exps1b, outBinds);
      then
        outBinds;

  end match;
end matchesExpLstLstFrontEnd;

public function isPlaceHolderFrontEnd
"@author: adrpo
 returns true if the expression is a cref of the form '$REST'"
 input Absyn.Exp inExp;
 output Boolean isHolder;
algorithm
 isHolder := match(inExp)
   local
     Boolean b;
     Absyn.Ident name;

   case (Absyn.CREF(Absyn.CREF_IDENT(name, _)))
     equation
       // find the string '$ at position 0
       b = intEq(System.stringFind(name, "'$"), 0);
     then
       b;
   else false;

 end match;
end isPlaceHolderFrontEnd;


// backend rewrite stuff
// ----------------------
public function rewriteBackEnd
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean isChanged;
algorithm
  (outExp, isChanged) := match(inExp)
   local
     Rules rules;
     Boolean b;

   case (_)
     equation
       rules = getRulesBackEnd(getAllRules());
       (outExp, b) = matchAndRewriteExpBackEnd(inExp, rules);
     then
       (outExp, b);

  end match;
end rewriteBackEnd;

public function matchAndRewriteExpBackEnd
"tries to match each of the rewrite rule
 to the input expression and bind the place
 holders to actual expression"
  input DAE.Exp inExp;
  input Rules inRules;
  output DAE.Exp outExp;
  output Boolean changed;
algorithm
  (outExp, changed) := matchcontinue(inExp, inRules)
    local
      Absyn.Exp afrom, ato;
      DAE.Exp from, to;
      Rules rest;
      Binds binds;
      Boolean b;

    // nothing matched!
    case (_, {}) then (inExp, false);

    // matches the head
    case (_, BACKEND_RULE(afrom, ato)::_)
      equation
        from = Expression.fromAbsynExp(afrom);
        to =  Expression.fromAbsynExp(ato);
        (binds as _::_) = matchesBackEnd(inExp, from, {});
        outExp = rewriteExpBackEnd(to, binds);
        b = boolNot(referenceEq(inExp, outExp));
        print("BackEnd Exp:     " + ExpressionDump.printExpStr(inExp) + "\n" +
              "BackEnd From:    " + ExpressionDump.printExpStr(from) + "\n" +
              "BackEnd To:      " + ExpressionDump.printExpStr(to) + "\n" +
              "BackEnd Rewrite: " + ExpressionDump.printExpStr(outExp) + "\n---------\n");
      then
        (outExp, b);

    // not match for the head, try next
    case (_, _::rest)
      equation
        (outExp, b) = matchAndRewriteExpBackEnd(inExp, rest);
      then
        (outExp, b);
  end matchcontinue;
end matchAndRewriteExpBackEnd;

public function rewriteExpBackEnd
 input DAE.Exp inExp;
 input Binds inBinds;
 output DAE.Exp outExp;
algorithm
  (outExp, _) := Expression.traverseExpBottomUp(inExp, replaceBindsBackEnd, inBinds);
end rewriteExpBackEnd;

public function replaceBindsBackEnd
  input DAE.Exp inExp;
  input Binds inBinds;
  output DAE.Exp outExp;
  output Binds outBinds;
algorithm
  (outExp,outBinds) := match (inExp,inBinds)
    local
      DAE.Exp e1,e2;
      Binds bnds;

    case (e1 as DAE.CREF(_, _), bnds)
      equation
        e2 = replaceBindBackEnd(e1, bnds);
      then
        (e2, bnds);

    // leave as it is
    else (inExp,inBinds);

  end match;
end replaceBindsBackEnd;

public function replaceBindBackEnd
  input DAE.Exp inExp;
  input Binds inBinds;
  output DAE.Exp outExp;
protected
  Boolean found;
  DAE.Exp e, to;
algorithm
  for bind in inBinds loop
    BACKEND_BIND(e, to) := bind;

    if expEqual(inExp, e) then
      outExp := to;
      return;
    end if;
  end for;

  // Couldn't find matching binding, return inExp.
  outExp := inExp;
end replaceBindBackEnd;

public function matchesBackEnd
"@author: adrpo
 unifies two absyn expressions and if they match
 binds the placeholders '$1', '$2' to actual
 expressions from inExp.
 returns a list of BIND('$1', exp1)
 or fails if the expressions cannot be unified"
  input DAE.Exp inExp;
  input DAE.Exp inUnifyWith;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := matchcontinue(inExp, inUnifyWith, inAcc)
    local
      DAE.Exp e1a, e2a, e1b, e2b, cond1a, cond1b, thenExp, elseExp;
      DAE.Operator op1a, op1b;
      DAE.ComponentRef cr1a, cr1b;
      Absyn.Path p1a, p1b;
      list<DAE.Exp> exps1a, exps1b;
      list<list<DAE.Exp>> expsLst1a, expsLst1b;
      Option<DAE.Exp> oe1a, oe1b;
      DAE.Ident id1a, id1b;

    // we have a place holder
    case (_, DAE.CREF(_, _), _)
      equation
        true = isPlaceHolderBackEnd(inUnifyWith);
        outBinds = BACKEND_BIND(inUnifyWith, inExp)::inAcc;
      then
        outBinds;

    // must be equal
    case (DAE.ICONST(_), _, _)
      equation
        true = expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (DAE.RCONST(_), _, _)
      equation
        true = expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (DAE.SCONST(_), _, _)
      equation
        true = expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (DAE.BCONST(_), _, _)
      equation
        true = expEqual(inExp, inUnifyWith);
      then
        inAcc;

    // cref
    case (DAE.CREF(_, _), _, _)
      equation
        true = expEqual(inExp, inUnifyWith);
      then
        inAcc;

    case (DAE.BINARY(e1a, op1a, e2a), DAE.BINARY(e1b, op1b, e2b), _)
      equation
        true = operatorMatches(op1a, op1b);
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (DAE.UNARY(op1a, e1a), DAE.UNARY(op1b, e1b), _)
      equation
        true = operatorMatches(op1a, op1b);
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
      then
        outBinds;

    case (DAE.LBINARY(e1a, op1a, e2a), DAE.LBINARY(e1b, op1b, e2b), _)
      equation
        true = operatorMatches(op1a, op1b);
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (DAE.LUNARY(op1a, e1a), DAE.LUNARY(op1b, e1b), _)
      equation
        true = operatorMatches(op1a, op1b);
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
      then
        outBinds;

    case (DAE.RELATION(e1a, op1a, e2a, _, _), DAE.RELATION(e1b, op1b, e2b, _, _), _)
      equation
        true = operatorMatches(op1a, op1b);
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (DAE.IFEXP(cond1a, e1a, e2a), DAE.IFEXP(cond1b, e1b, e2b), _)
      equation
        outBinds = matchesBackEnd(cond1a, cond1b, inAcc);
        outBinds = matchesBackEnd(e1a, e1b, outBinds);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (DAE.CALL(p1a, exps1a, _), DAE.CALL(p1b, exps1b, _), _)
      equation
        true = Absyn.pathEqual(p1a, p1b);
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (DAE.PARTEVALFUNCTION(p1a, exps1a, _, _), DAE.PARTEVALFUNCTION(p1b, exps1b, _, _), _)
      equation
        true = Absyn.pathEqual(p1a, p1b);
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (DAE.ARRAY(array = exps1a), DAE.ARRAY(array = exps1b), _)
      equation
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (DAE.MATRIX(matrix = expsLst1a), DAE.MATRIX(matrix = expsLst1b), _)
      equation
        outBinds = matchesExpLstLstBackEnd(expsLst1a, expsLst1b, inAcc);
      then
        outBinds;

    case (DAE.RANGE(_, e1a, oe1a, e2a), DAE.RANGE(_, e1b, oe1b, e2b), _)
      equation
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesExpOptBackEnd(oe1a, oe1b, outBinds);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then
        outBinds;

    case (DAE.TUPLE(exps1a), DAE.TUPLE(exps1b), _)
      equation
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (DAE.CONS(e1a, e2a), DAE.CONS(e1b, e2b), _)
      equation
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesBackEnd(e2a, e2b, outBinds);
      then outBinds;

    // TODO! support matchexp
    case (DAE.MATCHEXPRESSION(), DAE.MATCHEXPRESSION(), _)
      then inAcc;

    case (DAE.LIST(exps1a), DAE.LIST(exps1b), _)
      equation
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, inAcc);
      then
        outBinds;

  end matchcontinue;
end matchesBackEnd;

public function matchesExpOptBackEnd
  input Option<DAE.Exp> inOExp1;
  input Option<DAE.Exp> inOExp2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inOExp1, inOExp2, inAcc)
    local DAE.Exp e1a, e1b;
    case (NONE(), NONE(), _) then inAcc;
    case (SOME(e1a), SOME(e1b), _)
      equation
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
      then
        outBinds;
    else fail();
  end match;
end matchesExpOptBackEnd;

public function matchesExpLstBackEnd
  input list<DAE.Exp> inExps1;
  input list<DAE.Exp> inExps2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inExps1, inExps2, inAcc)
    local
      DAE.Exp e1a, e1b;
      list<DAE.Exp> exps1a, exps1b;

    case ({}, {}, _) then inAcc;
    case (e1a::exps1a, e1b::exps1b, _)
      equation
        outBinds = matchesBackEnd(e1a, e1b, inAcc);
        outBinds = matchesExpLstBackEnd(exps1a, exps1b, outBinds);
      then
        outBinds;

  end match;
end matchesExpLstBackEnd;

public function matchesExpLstLstBackEnd
  input list<list<DAE.Exp>> inExps1;
  input list<list<DAE.Exp>> inExps2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := match(inExps1, inExps2, inAcc)
    local
      list<DAE.Exp> e1a, e1b;
      list<list<DAE.Exp>> exps1a, exps1b;

    case ({}, {}, _) then inAcc;
    case (e1a::exps1a, e1b::exps1b, _)
      equation
        outBinds = matchesExpLstBackEnd(e1a, e1b, inAcc);
        outBinds = matchesExpLstLstBackEnd(exps1a, exps1b, outBinds);
      then
        outBinds;

  end match;
end matchesExpLstLstBackEnd;

public function isPlaceHolderBackEnd
"@author: adrpo
 returns true if the expression is a cref of the form '$REST'"
 input DAE.Exp inExp;
 output Boolean isHolder;
algorithm
 isHolder := match(inExp)
   local
     Boolean b;
     Absyn.Ident name;

   case (DAE.CREF(DAE.CREF_IDENT(ident = name), _))
     equation
       // find the string '$ at position 0
       b = intEq(System.stringFind(name, "'$"), 0);
     then
       b;
   else false;

 end match;
end isPlaceHolderBackEnd;

protected function expEqual
  input DAE.Exp e1;
  input DAE.Exp e2;
  output Boolean isEqual;
algorithm
  isEqual := matchcontinue(e1, e2)
    local
      Integer i;
      Real r;

    // we need additional rules here for int/real
    case (DAE.ICONST(i), DAE.RCONST(r))
      equation
        true = realEq(intReal(i), r);
      then
        true;

    case (DAE.RCONST(r), DAE.ICONST(i))
      equation
        true = realEq(intReal(i), r);
      then
        true;

    // all others forward to expEqual
    else Expression.expEqual(e1, e2);

  end matchcontinue;
end expEqual;

protected function operatorMatches
"@author: adrpo
 note that this unifies operators
 op1 is DAE.Operator
 op2 is Absyn.Operator translated to DAE.Operator"
  input DAE.Operator op1;
  input DAE.Operator op2;
  output Boolean b;
algorithm
  b := matchcontinue(op1, op2)
    local
      Boolean res;
      Absyn.Path p1,p2;

    case (DAE.UMINUS_ARR(),DAE.UMINUS()) then true;
    case (DAE.ADD_ARR(),DAE.ADD()) then true;
    case (DAE.SUB_ARR(),DAE.SUB()) then true;
    case (DAE.MUL_ARR(),DAE.MUL()) then true;
    case (DAE.DIV_ARR(),DAE.DIV()) then true;
    case (DAE.MUL_ARRAY_SCALAR(),DAE.MUL()) then true;
    case (DAE.ADD_ARRAY_SCALAR(),DAE.ADD()) then true;
    case (DAE.SUB_SCALAR_ARRAY(),DAE.SUB()) then true;
    case (DAE.MUL_SCALAR_PRODUCT(),DAE.MUL()) then true;
    case (DAE.MUL_MATRIX_PRODUCT(),DAE.MUL()) then true;
    case (DAE.DIV_SCALAR_ARRAY(),DAE.DIV()) then true;
    case (DAE.DIV_ARRAY_SCALAR(),DAE.DIV()) then true;
    case (DAE.POW_SCALAR_ARRAY(),DAE.POW()) then true;
    case (DAE.POW_ARRAY_SCALAR(),DAE.POW()) then true;
    case (DAE.POW_ARR(),DAE.POW()) then true;
    case (DAE.POW_ARR2(),DAE.POW()) then true;

    // all other forward to Expression.operatorEqual
    else Expression.operatorEqual(op1, op2);

  end matchcontinue;
end operatorMatches;

public function loadRules
algorithm
  _ := match()
    local
      String file;

    case ()
      equation
        file = Flags.getConfigString(Flags.REWRITE_RULES_FILE);
        loadRulesFromFile(file);
      then ();

  end match;
end loadRules;

public function noRewriteRules
"@author: adrpo
 return true if we have no rewrite rules"
  output Boolean noRules;
algorithm
  noRules := matchcontinue()
    case ()
      equation
        NONE() = getGlobalRoot(Global.rewriteRulesIndex);
      then
        true;
    else false;
  end matchcontinue;
end noRewriteRules;

public function noRewriteRulesFrontEnd
"@author: adrpo
 return true if we have no rewrite rules for frontend"
  output Boolean noRules;
algorithm
  noRules := matchcontinue()

    case ()
      equation
        NONE() = getGlobalRoot(Global.rewriteRulesIndex);
      then
        true;

    case ()
      equation
        {} = getRulesFrontEnd(getAllRules());
      then
        true;

    else false;

  end matchcontinue;
end noRewriteRulesFrontEnd;

public function noRewriteRulesBackEnd
"@author: adrpo
 return true if we have no rewrite rules for backend"
  output Boolean noRules;
algorithm
  noRules := matchcontinue()

    case ()
      equation
        NONE() = getGlobalRoot(Global.rewriteRulesIndex);
      then
        true;

    case ()
      equation
        {} = getRulesBackEnd(getAllRules());
      then
        true;

    else false;

  end matchcontinue;
end noRewriteRulesBackEnd;

public function loadRulesFromFile
"load the rewite rules in the global array with index: Global.rewriteRulesIndex"
  input String inFile;
algorithm
  _ := matchcontinue(inFile)
    local
      list<GlobalScript.Statement> stmts;
      Rules rules;
      Option<Rules> oR;

    // no file, set it to NONE
    case ""
      equation
        setGlobalRoot(Global.rewriteRulesIndex, NONE());
      then ();

    // already loaded
    case _
      equation
        oR = getGlobalRoot(Global.rewriteRulesIndex);
        true = isSome(oR);
      then ();

    // not loaded, load it
    case _
      equation
        NONE() = getGlobalRoot(Global.rewriteRulesIndex);
        GlobalScript.ISTMTS(stmts, _) = Parser.parseexp(inFile);
        rules = stmtsToRules(stmts, {});
        print("-------------\n");
        setGlobalRoot(Global.rewriteRulesIndex, SOME(rules));
      then
        ();

    else
      equation
        Error.addInternalError("Unable to parse rewrite rules file: " + inFile, sourceInfo());
        setGlobalRoot(Global.rewriteRulesIndex, NONE());
      then
        ();

  end matchcontinue;
end loadRulesFromFile;

public function clearRules
"clear the loaded rules"
algorithm
  setGlobalRoot(Global.rewriteRulesIndex, NONE());
end clearRules;

public function getAllRules
"get the loaded rules"
  output Rules outRules;
protected
  Option<Rules> orules;
algorithm
  orules := getGlobalRoot(Global.rewriteRulesIndex);
  SOME(outRules) := orules;
end getAllRules;

public function getRulesFrontEnd
  input Rules inRules;
  output Rules outRules;
algorithm
  outRules := match(inRules)
    local
      Rules rest, lst;
      Rule r;

    case ({}) then {};

    case ((r as FRONTEND_RULE())::rest)
      equation
        lst = getRulesFrontEnd(rest);
      then r::lst;

    case (_::rest) then getRulesFrontEnd(rest);

  end match;
end getRulesFrontEnd;

public function getRulesBackEnd
  input Rules inRules;
  output Rules outRules;
algorithm
  outRules := match(inRules)
    local
      Rules rest, lst;
      Rule r;

    case ({}) then {};

    case ((r as BACKEND_RULE())::rest)
      equation
        lst = getRulesBackEnd(rest);
      then r::lst;

    case (_::rest) then getRulesBackEnd(rest);

  end match;
end getRulesBackEnd;

protected function stmtsToRules
  input list<GlobalScript.Statement> inStmts;
  input Rules inAcc;
  output Rules outRules;
algorithm
  outRules := matchcontinue(inStmts, inAcc)
    local
      list<GlobalScript.Statement> rest;
      GlobalScript.Statement s;
      Rules acc;
      Absyn.Exp from, to;

    // empty case
    case ({}, _) then listReverse(inAcc);

    // frontend-rules
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewrite"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("FrontEnd rule: " + Dump.printExpStr(from) + " -> " + Dump.printExpStr(to) + "\n");
        acc = stmtsToRules(rest, FRONTEND_RULE(from, to)::inAcc);
      then
        acc;

    // frontend-rules
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewriteFrontEnd"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("FrontEnd rule: " + Dump.printExpStr(from) + " -> " + Dump.printExpStr(to) + "\n");
        acc = stmtsToRules(rest, FRONTEND_RULE(from, to)::inAcc);
      then
        acc;

    // backend-rules
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewriteBackEnd"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("BackEnd rule: " + Dump.printExpStr(from) + " -> " + Dump.printExpStr(to) + "\n");
        acc = stmtsToRules(rest, BACKEND_RULE(from, to)::inAcc);
      then
        acc;

    case (s::_, _)
      equation
        Error.addInternalError("Unable to parse rewrite rule: " + GlobalScriptDump.printIstmtStr(s), sourceInfo());
      then
        fail();

  end matchcontinue;
end stmtsToRules;

annotation(__OpenModelica_Interface="frontend");
end RewriteRules;
