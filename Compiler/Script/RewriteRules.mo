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

encapsulated package RewriteRules
" file:        RewriteRules.mo
  package:     RewriteRules
  description: RewriteRules applies user given rewrite rules to the Absyn expressions

  RCS: $Id: RewriteRules.mo 18167 2013-11-18 12:36:35Z perost $

"

public import Absyn;
public import Global;
public import DAE;

public uniontype Rule "rule to rewrite fromExp -> toExp, there are absyn and dae rules"
 record AST_RULE "rule to rewrite fromExp -> toExp, apply to Absyn"
   Absyn.Exp from;
   Absyn.Exp to;
 end AST_RULE;
 
 record DAE_RULE "rule to rewrite fromExp -> toExp, apply to DAE"
   Absyn.Exp from;
   Absyn.Exp to;
 end DAE_RULE;
end Rule;

public type Rules = list<Rule>;

public uniontype Bind "a bind '$1' bound to exp1"
 record BIND "a bind '$1' bound to exp1"
   Absyn.Exp slot;
   Absyn.Exp value;
 end BIND;
end Bind;

public type Binds = list<Bind>;

protected import Parser;
protected import GlobalScript;
protected import Error;
protected import Interactive;
protected import Flags;
protected import Dump;
protected import Util;
protected import System;
protected import List;

public function rewrite
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := match(inExp)
   local 
     Rules rules;
   case (_)
     equation
       rules = getRules();
       outExp = matchAndRewriteExp(inExp, rules);
     then
       outExp;
  end match;
end rewrite;

public function matchAndRewriteExp
"tries to match each of the rewrite rule
 to the input expression and bind the place
 holders to actual expression"
  input Absyn.Exp inExp;
  input Rules inRules;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inRules)
    local
      Absyn.Exp from, to;
      Rules rest;
      Binds binds;
    
    // nothing matched!
    case (_, {}) then inExp;
    
    // matches the head
    case (_, AST_RULE(from, to)::rest)
      equation
        binds = matches(inExp, from, {});
        outExp = rewriteExp(to, binds);
        print("Exp:     " +& Dump.printExpStr(inExp) +& "\n" +&
              "From:    " +& Dump.printExpStr(from) +& "\n" +&
              "To:      " +& Dump.printExpStr(to) +& "\n" +&
              "Rewrite: " +& Dump.printExpStr(outExp) +& "\n");
      then 
        outExp;
    
    // not match for the head, try next
    case (_, _::rest)
      equation
        outExp = matchAndRewriteExp(inExp, rest);
      then 
        outExp;
  end matchcontinue;
end matchAndRewriteExp;

public function rewriteExp
 input Absyn.Exp inExp;
 input Binds inBinds;
 output Absyn.Exp outExp;
algorithm
  ((outExp, _)) := Absyn.traverseExp(inExp, replaceBinds, inBinds);
end rewriteExp;

public function replaceBinds
    input tuple<Absyn.Exp, Binds> inTplExpBinds;
    output tuple<Absyn.Exp, Binds> outTplExpBinds;
algorithm
  outTplExpBinds := match(inTplExpBinds)
    local 
      Absyn.Exp e;
      Binds bnds;
    
    case ((e as Absyn.CREF(_), bnds))
      equation
        e = replaceBind(e, bnds);
      then
        ((e, bnds));
    // leave as it is
    else inTplExpBinds; 
  end match;
end replaceBinds;

public function replaceBind
  input Absyn.Exp inExp;
  input Binds inBinds;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inBinds)
    local 
      Absyn.Exp e, to;
      Binds rest;
    
    // no more bindings to check, return exp
    case (_, {}) then inExp;
    
    // found it
    case (_, BIND(e, to)::rest)
      equation
        true = Absyn.expEqual(inExp, e);
      then
        to;
    // not found it
    case (_, BIND(e, to)::rest)
      equation
        false = Absyn.expEqual(inExp, e);
        to = replaceBind(inExp, rest);
      then
        to;
  
  end matchcontinue;
end replaceBind;

public function matches
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
        true = isPlaceHolder(inUnifyWith);
        outBinds = BIND(inUnifyWith, inExp)::inAcc;
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
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matches(e2a, e2b, outBinds);
      then
        outBinds;
  
    case (Absyn.UNARY(op1a, e1a), Absyn.UNARY(op1b, e1b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matches(e1a, e1b, inAcc);
      then
        outBinds;
    
    case (Absyn.LBINARY(e1a, op1a, e2a), Absyn.BINARY(e1b, op1b, e2b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matches(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.LUNARY(op1a, e1a), Absyn.UNARY(op1b, e1b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matches(e1a, e1b, inAcc);
      then
        outBinds;
  
    case (Absyn.RELATION(e1a, op1a, e2a), Absyn.BINARY(e1b, op1b, e2b), _)
      equation
        true = Absyn.opEqual(op1a, op1b);
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matches(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.IFEXP(cond1a, e1a, e2a, elseIfa), Absyn.IFEXP(cond1b, e1b, e2b, elseIfb), _)
      equation
        outBinds = matches(cond1a, cond1b, inAcc);
        outBinds = matches(e1a, e1b, outBinds);
        outBinds = matches(e2a, e2b, outBinds);
        // TODO! handle elseif
        // outBinds = matchesElseIf(elseIfa, elseIfb, outBinds);
      then
        outBinds;

    case (Absyn.CALL(cr1a, fargs1a), Absyn.CALL(cr1b, fargs1b), _)
      equation
        true = Absyn.crefEqual(cr1a, cr1b);
        outBinds = matchesFargs(fargs1a, fargs1b, inAcc);
      then
        outBinds;

    case (Absyn.PARTEVALFUNCTION(cr1a, fargs1a), Absyn.PARTEVALFUNCTION(cr1b, fargs1b), _)
      equation
        true = Absyn.crefEqual(cr1a, cr1b);
        outBinds = matchesFargs(fargs1a, fargs1b, inAcc);
      then
        outBinds;

    case (Absyn.ARRAY(exps1a), Absyn.ARRAY(exps1b), _)
      equation
        outBinds = matchesExpLst(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (Absyn.MATRIX(expsLst1a), Absyn.MATRIX(expsLst1b), _)
      equation
        outBinds = matchesExpLstLst(expsLst1a, expsLst1b, inAcc);
      then
        outBinds;

    case (Absyn.RANGE(e1a, oe1a, e2a), Absyn.RANGE(e1b, oe1b, e2b), _)
      equation
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matchesExpOpt(oe1a, oe1b, outBinds);
        outBinds = matches(e2a, e2b, outBinds);
      then
        outBinds;

    case (Absyn.TUPLE(exps1a), Absyn.TUPLE(exps1b), _)
      equation
        outBinds = matchesExpLst(exps1a, exps1b, inAcc);
      then
        outBinds;

    case (Absyn.END(), Absyn.END(), _) then inAcc;

    case (Absyn.CODE(_), Absyn.CODE(_), _) then inAcc;
      
    case (Absyn.AS(id1a, e1a), Absyn.AS(id1b, e1b), _)
      equation
        true = stringEq(id1a, id1b);
        outBinds = matches(e1a, e1b, inAcc);
      then outBinds;

    case (Absyn.CONS(e1a, e2a), Absyn.CONS(e1b, e2b), _)
      equation
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matches(e2a, e2b, outBinds);
      then outBinds;
      
    // TODO! support matchexp
    case (Absyn.MATCHEXP(inputExp = _), Absyn.MATCHEXP(inputExp = _), _)
      then inAcc;
        
    case (Absyn.LIST(exps1a), Absyn.LIST(exps1b), _)
      equation
        outBinds = matchesExpLst(exps1a, exps1b, inAcc);
      then
        outBinds;
  end matchcontinue;
end matches;

public function matchesExpOpt
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
        outBinds = matches(e1a, e1b, inAcc);
      then
        outBinds;
    else fail();
  end match;
end matchesExpOpt;

public function matchesExpLst
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
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matchesExpLst(exps1a, exps1b, outBinds); 
      then
        outBinds;

  end match;
end matchesExpLst;

public function matchesFargs
  input Absyn.FunctionArgs inFargs1;
  input Absyn.FunctionArgs inFargs2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := matchcontinue(inFargs1, inFargs2, inAcc)
    local
      list<Absyn.Exp> exps1a, exps1b;
      list<Absyn.NamedArg> nargs1a, nargs1b;
      Absyn.Exp e1a, e1b; 
    
    case (Absyn.FUNCTIONARGS(exps1a, nargs1a), Absyn.FUNCTIONARGS(exps1b, nargs1b), _)
      equation
        outBinds = matchesExpLst(exps1a, exps1b, inAcc);
        // fargs should be equal
        true = intEq(listLength(nargs1a), listLength(nargs1b));
        // match nargs
        outBinds = matchesNargs(sortNargs(nargs1a), sortNargs(nargs1b), outBinds);
      then
        outBinds;
    
    // TODO, handle for iterators!
    case (Absyn.FOR_ITER_FARG(e1a, _), Absyn.FOR_ITER_FARG(e1b, _), _)
      equation
        outBinds = matches(e1a, e1b, inAcc);
      then
        outBinds;
  end matchcontinue;
end matchesFargs;

public function sortNargs
  input list<Absyn.NamedArg> inNargs;
  output list<Absyn.NamedArg> outNargs;
algorithm
  outNargs := List.sort(inNargs, inNargComp);
end sortNargs;

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

public function matchesNargs
  input list<Absyn.NamedArg> inNargs1;
  input list<Absyn.NamedArg> inNargs2;
  input Binds inAcc;
  output Binds outBinds;
algorithm
  outBinds := matchcontinue(inNargs1, inNargs2, inAcc)
    local
      Absyn.Ident n1a, n1b;
      Absyn.Exp e1a, e1b;
      list<Absyn.NamedArg> nargs1a, nargs1b; 
    
    case ({}, {}, _) then inAcc;
    
    case (Absyn.NAMEDARG(n1a, e1a)::nargs1a, Absyn.NAMEDARG(n1b, e1b)::nargs1b, _)
      equation
        true = stringEq(n1a, n1b);
        outBinds = matches(e1a, e1b, inAcc);
        outBinds = matchesNargs(nargs1a, nargs1b, outBinds);
      then
        outBinds;
  
  end matchcontinue;
end matchesNargs;

public function matchesExpLstLst
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
        outBinds = matchesExpLst(e1a, e1b, inAcc);
        outBinds = matchesExpLstLst(exps1a, exps1b, outBinds); 
      then
        outBinds;

  end match;
end matchesExpLstLst;

public function isPlaceHolder
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
end isPlaceHolder;

public function rewriteDAE
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := inExp;
end rewriteDAE;

public function loadRules
algorithm
  _ := matchcontinue()
    local
      String file;
    
    case ()
      equation
        file = Flags.getConfigString(Flags.REWRITE_RULES_FILE);
        loadRulesFromFile(file);
      then ();
  
  end matchcontinue;
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
        true = Util.isSome(oR);
      then ();
    
    // not loaded, load it
    case _ 
      equation
        NONE() = getGlobalRoot(Global.rewriteRulesIndex);
        GlobalScript.ISTMTS(stmts, _) = parse(inFile);
        rules = stmtsToRules(stmts, {});
        setGlobalRoot(Global.rewriteRulesIndex, SOME(rules));
      then 
        ();

    case _
      equation
        Error.addInternalError("Unable to parse rewrite rules file: " +& inFile);
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

public function getRules
"get the loaded rules"
  output Rules outRules;
protected
  Option<Rules> orules;
algorithm
  orules := getGlobalRoot(Global.rewriteRulesIndex);
  SOME(outRules) := orules;
end getRules;

protected function parse
  input String inFile;
  output GlobalScript.Statements outStmts;
algorithm
  outStmts := matchcontinue(inFile)
    local
      GlobalScript.Statements stmts;
    
    // parse OK
    case _
      equation
        stmts = Parser.parseexp(inFile);
      then
        stmts;
    
    // parse not OK
    case _
      equation
        failure(_ = Parser.parseexp(inFile));
      then
        fail();
  
  end matchcontinue;
end parse;

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
    
    // ast-rules  
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewrite"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("AST rule: " +& Dump.printExpStr(from) +& " -> " +& Dump.printExpStr(to) +& "\n"); 
        acc = stmtsToRules(rest, AST_RULE(from, to)::inAcc);
      then 
        acc;
    
    // dae-rules 
    case (GlobalScript.IEXP(
           Absyn.CALL(
             Absyn.CREF_IDENT(name = "rewriteDAE"),
             Absyn.FUNCTIONARGS({from, to}, {}))
           )::rest, _)
      equation
        print("DAE rule: " +& Dump.printExpStr(from) +& " -> " +& Dump.printExpStr(to) +& "\n"); 
        acc = stmtsToRules(rest, DAE_RULE(from, to)::inAcc);
      then 
        acc;
    
    case (s::rest, _)
      equation
        Error.addInternalError("Unable to parse rewrite rule: " +& 
          Interactive.printIstmtStr(GlobalScript.ISTMTS({s}, true)));
      then
        fail();
  
  end matchcontinue;
end stmtsToRules;

end RewriteRules;
