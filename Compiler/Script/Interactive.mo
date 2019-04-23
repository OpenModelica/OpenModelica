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

encapsulated package Interactive
" file:        Interactive.mo
  package:     Interactive
  description: This module contain functionality for model management,
               expression evaluation, etc. in the interactive environment.

  $Id: Interactive.mo 25580 2015-04-16 14:04:16Z jansilar $

  This module contain functionality for model management, expression evaluation, etc.
  in the interactive environment.
  The module defines a symboltable used in the interactive environment containing:
  - Modelica models (described using Absyn AST)
  - GlobalScript.Variable bindings
  - Compiled functions (so they do not need to be recompiled)
  - Instantiated classes (that can be reused, not impl. yet)
  - Modelica models in SCode form (to speed up instantiation. not impl. yet)"

//public imports
import Absyn;
import ConnectionGraph;
import DAE;
import FCore;
import Global;
import SCode;
import SCodeUtil;
import Settings;
import Values;

// protected imports
protected

import AbsynUtil;
import Ceval;
import CevalScript;
import ClassInf;
import ClockIndexes;
import Config;
import Connect;
import Constants;
import DAEDump;
import DAEUtil;
import Debug;
import DoubleEndedList;
import Dump;
import Error;
import ErrorExt;
import ExpressionDump;
import ExpressionSimplify;
import FBuiltin;
import Flags;
import FGraph;
import GC;
import GlobalScriptDump;
import GlobalScriptUtil;
import InnerOuter;
import Inst;
import InstUtil;
import InstTypes;
import List;
import Lookup;
import MetaUtil;
import Mod;
import Parser;
import Prefix;
import Print;
import Refactor;
import StackOverflow;
import Static;
import StaticScript;
import StringUtil;
import SymbolTable;
import System;
import Types;
import UnitAbsyn;
import Util;
import ValuesUtil;
import MetaModelica.Dangerous;

protected uniontype AnnotationType
  record ICON_ANNOTATION end ICON_ANNOTATION;
  record DIAGRAM_ANNOTATION end DIAGRAM_ANNOTATION;
end AnnotationType;

protected uniontype GraphicEnvCache
  "Used by buildEnvForGraphicProgram to avoid excessive work."
  record GRAPHIC_ENV_NO_CACHE
    Absyn.Program program;
    Absyn.Path modelPath;
  end GRAPHIC_ENV_NO_CACHE;

  record GRAPHIC_ENV_PARTIAL_CACHE
    Absyn.Program program;
    Absyn.Path modelPath;
    FCore.Cache cache;
    FCore.Graph env;
  end GRAPHIC_ENV_PARTIAL_CACHE;

  record GRAPHIC_ENV_FULL_CACHE
    FCore.Cache cache;
    FCore.Graph env;
  end GRAPHIC_ENV_FULL_CACHE;
end GraphicEnvCache;

public function evaluate
"This function evaluates expressions or statements feed interactively to the compiler.
  inputs:   (GlobalScript.Statements, bool /* verbose */)
  outputs:   string:
                     The resulting string after evaluation. If an error has occurred, this string
                     will be empty. The error messages can be retrieved by calling print_messages_str()
                     in Error.mo."
  input GlobalScript.Statements inStatements;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := matchcontinue (inStatements,inBoolean)
    local
      String res,res_1,res2,res_2;
      Boolean echo,semicolon,verbose;
      GlobalScript.Statement x;
      list<GlobalScript.Statement> xs;

    case (GlobalScript.ISTMTS(interactiveStmtLst = {x},semicolon = semicolon),verbose)
      equation
        showStatement(x, semicolon, true);
        res = evaluate2(GlobalScript.ISTMTS({x},verbose));
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        showStatement(x, semicolon, false);
      then res_1;

    case (GlobalScript.ISTMTS(interactiveStmtLst = (x :: xs),semicolon = semicolon),verbose)
      equation
        showStatement(x, semicolon, true);
        res = evaluate2(GlobalScript.ISTMTS({x},semicolon));
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        showStatement(x, semicolon, false);

        res2 = evaluate(GlobalScript.ISTMTS(xs,semicolon), verbose);
        res_2 = stringAppendList({res_1,res2});
      then res_2;
  end matchcontinue;
end evaluate;

public function evaluateToStdOut
"This function evaluates expressions or statements feed interactively to the compiler.
  The resulting string after evaluation is printed.
  If an error has occurred, this string will be empty.
  The error messages can be retrieved by calling print_messages_str() in Error.mo."
  input GlobalScript.Statements statements;
  input Boolean verbose;
protected
  GlobalScript.Statement x;
  list<GlobalScript.Statement> xs;
  Boolean semicolon;
  String res;
algorithm
  xs := statements.interactiveStmtLst;
  semicolon := statements.semicolon;
  while not listEmpty(xs) loop
    x::xs := xs;
    showStatement(x, semicolon, true);
    res := evaluate2(GlobalScript.ISTMTS({x},if listEmpty(xs) then verbose else semicolon));
    print(selectResultstr(res, semicolon, verbose, getEcho()));
    showStatement(x, semicolon, false);
  end while;
end evaluateToStdOut;

public function evaluateFork
"As evaluateToStdOut, but takes the inputs as a tuple of mos-script file and symbol table.
As it is supposed to work in a thread without output, it also flushes the error-buffer since that will otherwise be lost to the void."
  input tuple<String,SymbolTable> inTpl;
  output Boolean b;
algorithm
  b := matchcontinue inTpl
    local
      String mosfile;
      GlobalScript.Statements statements;
      SymbolTable st;
      Absyn.Program ast;
      Option<SCode.Program> explodedAst;

    case ((mosfile,st))
      equation
        SymbolTable.reset();
        SymbolTable.setAbsyn(st.ast);
        SymbolTable.setSCode(st.explodedAst);
        setGlobalRoot(Global.instOnlyForcedFunctions,  NONE()); // thread-local root that has to be set!
        statements = Parser.parseexp(mosfile);
        evaluateToStdOut(statements,true);
        print(Error.printMessagesStr(false));
      then true;
    else
      equation
        print(Error.printMessagesStr(false));
      then false;
  end matchcontinue;
end evaluateFork;

protected function showStatement
  input GlobalScript.Statement s;
  input Boolean semicolon;
  input Boolean start;
protected
  Boolean testsuite;
algorithm
  if not Flags.isSet(Flags.SHOW_STATEMENT) then
    return;
  end if;

  testsuite := Config.getRunningTestsuite();

  _ := matchcontinue(start, testsuite)

    // running testsuite
    case (true, true)
      equation
        print("Evaluating: " + printIstmtStr(GlobalScript.ISTMTS({s}, semicolon)) + "\n");
        System.fflush();
      then
        ();

    case (false, true) then ();

    // not running testsuite, show more!
    case (true, false)
      equation
        System.realtimeTick(ClockIndexes.RT_CLOCK_SHOW_STATEMENT);
        print("Evaluating:   > " + printIstmtStr(GlobalScript.ISTMTS({s}, semicolon)) + "\n");
        System.fflush();
      then
        ();

    case (false, false)
      equation
        print("Evaluated:    < " + realString(System.realtimeTock(ClockIndexes.RT_CLOCK_SHOW_STATEMENT)) + " / " + printIstmtStr(GlobalScript.ISTMTS({s}, semicolon)) + "\n");
        System.fflush();
      then
        ();

    else ();

  end matchcontinue;
end showStatement;

protected function selectResultstr
"Returns result string depending on three boolean variables
  - semicolon
  - verbose
  - echo"
  input String inString;
  input Boolean inSemicolon "semicolon";
  input Boolean inVerbose "verbose";
  input Boolean inEcho "echo";
  output String outString;
algorithm
  outString := match (inString,inSemicolon,inVerbose,inEcho)
    local String str;
    case (_,_,_,false) then "";  // echo off always empty string
    case (str,_,true,_) then str;  // .. verbose on always return str
    case (_,true,_,_) then "";   // ... semicolon, no resultstr
    case (str,false,_,_) then str; // no semicolon
  end match;
end selectResultstr;

protected function getEcho
"Return echo variable, which determines
  if result should be printed or not."
  output Boolean outBoolean;
algorithm
  outBoolean := 0 <> Settings.getEcho();
end getEcho;

public function evaluate2
"Helper function to evaluate."
  input GlobalScript.Statements inStatements;
  output String outString;
protected
  GlobalScript.Statement stmt;
  String str, str_1;
algorithm
  GlobalScript.ISTMTS(interactiveStmtLst = {stmt}) := inStatements;
  try /* Stack overflow */
  outString := matchcontinue stmt
    local
      Absyn.AlgorithmItem algitem;
      Boolean outres;
      Absyn.Exp exp;
      Boolean partialInst, gen, evalfunc, keepArrays;
      SourceInfo info;

    // evaluate graphical API
    case GlobalScript.IEXP(exp = Absyn.CALL())
      equation
        // adrpo: always evaluate the graphicalAPI with these options so instantiation is faster!
        partialInst = System.getPartialInstantiation();
        System.setPartialInstantiation(true);
        gen = Flags.set(Flags.GEN, false);
        evalfunc = Flags.set(Flags.EVAL_FUNC, false);
        keepArrays = Flags.getConfigBool(Flags.KEEP_ARRAYS);
        Flags.setConfigBool(Flags.KEEP_ARRAYS, false);
        Inst.initInstHashTable();
        str = evaluateGraphicalApi(stmt, partialInst, gen, evalfunc, keepArrays);
        str_1 = stringAppend(str, "\n");
      then str_1;

    // Evaluate algorithm statements in evaluateAlgStmt()
    case GlobalScript.IALG(algItem = (algitem as Absyn.ALGORITHMITEM()))
      equation
        Inst.initInstHashTable();
        str = evaluateAlgStmt(algitem);
        str_1 = stringAppend(str, "\n");
      then str_1;

    // Evaluate expressions in evaluate_exprToStr()
    case GlobalScript.IEXP(exp = exp, info = info)
      equation
        Inst.initInstHashTable();
        str = evaluateExprToStr(exp, info);
        str_1 = stringAppend(str, "\n");
      then str_1;
  end matchcontinue;
  else
    str := "";
    str_1 := "";
    GC.gcollect();
    str := StackOverflow.getReadableMessage();
    if Config.getRunningTestsuite() then
      /* It's useful to print the name of the component we failed on.
       * But we crash in different places, so for the testsuite we skip this.
       */
      Error.clearCurrentComponent();
    end if;
    Error.addMessage(Error.STACK_OVERFLOW_DETAILED, {GlobalScriptDump.printIstmtStr(stmt), str});
    Error.clearCurrentComponent();
    outString := "\n";
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
end evaluate2;

protected function evaluateAlgStmt
"This function takes an AlgorithmItem, i.e. a statement located in an
  algorithm section, and a symboltable as input arguments. The statements
  are recursivly evalutated and a new interactive symbol table is returned."
  input Absyn.AlgorithmItem inAlgorithmItem;
  output String outString;
algorithm
  outString := matchcontinue inAlgorithmItem
    local
      FCore.Graph env;
      DAE.Exp econd,msg_1,sexp,srexp;
      DAE.Properties prop,rprop;
      Absyn.Exp cond,msg,exp,rexp;
      Absyn.Program p;
      String str,ident;
      DAE.Type t;
      Values.Value value;
      list<DAE.Type> types;
      list<String> idents;
      list<Values.Value> values,valList;
      list<Absyn.Exp> crefexps;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> cond1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> cond2,cond3,elseifexpitemlist;
      list<Absyn.AlgorithmItem> algitemlist,elseitemlist;
      list<GlobalScript.Variable> vars;
      String iter,estr;
      list<Absyn.AlgorithmItem> algItemList;
      Values.Value startv, stepv, stopv;
      Absyn.Exp starte, stepe, stope;
      Absyn.ComponentRef cr;
      FCore.Cache cache;
      SourceInfo info;
      Absyn.FunctionArgs fargs;
      list<Absyn.Subscript> asubs;
      list<DAE.Subscript> dsubs;
      list<DAE.ComponentRef> crefs;

    case Absyn.ALGORITHMITEM(info=info,
          algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {cond,_})))
      equation
        env = SymbolTable.buildEnv();
        (cache,econd,_) = StaticScript.elabExp(FCore.emptyCache(), env, cond, true, true, Prefix.NOPRE(), info);
        (_,Values.BOOL(true)) = CevalScript.ceval(cache,env, econd, true, Absyn.MSG(info), 0);
      then "";

    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {_,msg})))
      equation
        env = SymbolTable.buildEnv();
        (cache,msg_1,_) = StaticScript.elabExp(FCore.emptyCache(), env, msg, true, true, Prefix.NOPRE(), info);
        (_,Values.STRING(str)) = CevalScript.ceval(cache,env, msg_1, true, Absyn.MSG(info), 0);
      then str;

    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs))
      equation
        env = SymbolTable.buildEnv();
        exp = Absyn.CALL(cr,fargs);
        (cache,sexp,_) = StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, Prefix.NOPRE(), info);
        (_,_) = CevalScript.ceval(cache, env, sexp, true, Absyn.MSG(info), 0);
      then "";

    // Special case to lookup fields of records.
    // SimulationResult, etc are not in the environment,
    // but it's nice to be able to script them anyway
    case Absyn.ALGORITHMITEM(algorithm_ =
          Absyn.ALG_ASSIGN(assignComponent =
          Absyn.CREF(Absyn.CREF_IDENT(name = ident,subscripts = {})),value = Absyn.CREF(cr)))
      equation
        value = getVariableValueLst(Absyn.pathToStringList(Absyn.crefToPath(cr)), SymbolTable.getVars());
        str = ValuesUtil.valString(value);
        t = Types.typeOfValue(value);
        SymbolTable.addVar(DAE.CREF_IDENT(ident, t, {}), value, FGraph.empty());
      then str;

    case
      Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_ASSIGN(assignComponent =
        Absyn.CREF(Absyn.CREF_IDENT(name = ident,subscripts = asubs)),value = exp))
      equation
        env = SymbolTable.buildEnv();
        (cache,sexp,DAE.PROP(_,_)) = StaticScript.elabExp(FCore.emptyCache(),env, exp, true, true,Prefix.NOPRE(),info);
        (_,value) = CevalScript.ceval(cache,env, sexp, true,Absyn.MSG(info),0);
        (_, dsubs, _) = Static.elabSubscripts(cache, env, asubs, true,Prefix.NOPRE(), info);

        t = Types.typeOfValue(value) "This type can be more specific than the elaborated type; if the dimensions are unknown...";
        str = ValuesUtil.valString(value);
        SymbolTable.addVar(DAE.CREF_IDENT(ident, t, dsubs), value, env);
      then str;

    // Since expressions cannot be tuples an empty string is returned
    case
      Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_ASSIGN(assignComponent =
        Absyn.TUPLE(expressions = crefexps),value = rexp))
      equation
        env = SymbolTable.buildEnv();
        (cache,srexp,rprop) = StaticScript.elabExp(FCore.emptyCache(),env, rexp, true, true,Prefix.NOPRE(),info);
        DAE.T_TUPLE(types = types) = Types.getPropType(rprop);
        crefs = makeTupleCrefs(crefexps, types, env, cache, info);
        (_,Values.TUPLE(values)) = CevalScript.ceval(cache, env, srexp, true, Absyn.MSG(info),0);
        SymbolTable.addVars(crefs, values, env);
      then "";

    // if statement
    case
      Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_IF(
        ifExp = exp,
        trueBranch = algitemlist,
        elseIfAlgorithmBranch = elseifexpitemlist,
        elseBranch = elseitemlist))
      equation
        cond1 = (exp,algitemlist);
        cond2 = (cond1 :: elseifexpitemlist);
        cond3 = listAppend(cond2, {(Absyn.BOOL(true), elseitemlist)});
        evaluateIfStatementLst(cond3,info);
      then "";

    // while-statement
    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_WHILE(boolExpr = exp,whileBody = algitemlist))
      equation
        value = evaluateExpr(exp, info);
        evaluateWhileStmt(value, exp, algitemlist, info);
      then "";

    // for-statement, optimized case, e.g.: for i in 1:1000 loop
    case Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(Absyn.RANGE(start=starte,step=NONE(), stop=stope)))},
        forBody = algItemList))
      equation
        startv = evaluateExpr(starte, info);
        stopv = evaluateExpr(stope, info);
        evaluateForStmtRangeOpt(iter, startv, Values.INTEGER(1), stopv, algItemList);
     then "";

    // for-statement, optimized case, e.g.: for i in 7.3:0.4:1000.3 loop
    case Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(Absyn.RANGE(start=starte, step=SOME(stepe), stop=stope)))},
        forBody = algItemList))
      equation
        startv = evaluateExpr(starte, info);
        stepv = evaluateExpr(stepe, info);
        stopv = evaluateExpr(stope, info);
        evaluateForStmtRangeOpt(iter, startv, stepv, stopv, algItemList);
      then "";

    // for-statement, general case
    case Absyn.ALGORITHMITEM(info=info,algorithm_ =
        Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(iter, NONE(), SOME(exp))},forBody = algItemList))
      equation
        Values.ARRAY(valueLst = valList) = evaluateExpr(exp, info);
        evaluateForStmt(iter, valList, algItemList);
      then "";

    // for-statement - not an array type
    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(range = SOME(exp))}))
      equation
        estr = stringRepresOfExpr(exp);
        Error.addSourceMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {estr}, info);
      then fail();

  end matchcontinue;
end evaluateAlgStmt;

protected function evaluateForStmt
"evaluates a for-statement in an algorithm section"
  input String iter "The iterator variable which will be assigned different values";
  input list<Values.Value> valList "List of values that the iterator later will be assigned to";
  input list<Absyn.AlgorithmItem> algItemList;
algorithm
  for val in valList loop
    SymbolTable.appendVar(iter, val, Types.typeOfValue(val));
    evaluateAlgStmtLst(algItemList);
    SymbolTable.deleteVarFirstEntry(iter);
  end for;
end evaluateForStmt;

protected function evaluateForStmtRangeOpt
  "Optimized version of for statement. In this case, we do not create a large array if
  a range expression is given. E.g. for i in 1:10000 loop"
  input String iter "The iterator variable which will be assigned different values";
  input Values.Value startVal;
  input Values.Value stepVal;
  input Values.Value stopVal;
  input list<Absyn.AlgorithmItem> algItems;
protected
  Values.Value val;
algorithm
  val := startVal;
  try
    while ValuesUtil.safeLessEq(val, stopVal) loop
      SymbolTable.appendVar(iter, val, Types.typeOfValue(val));
      evaluateAlgStmtLst(algItems);
      SymbolTable.deleteVarFirstEntry(iter);
      val := ValuesUtil.safeIntRealOp(val, stepVal, Values.ADDOP());
    end while;
  else
    // Just... ignore errors and stop the loop. Really bad, I know...
  end try;
end evaluateForStmtRangeOpt;

protected function evaluateWhileStmt
"Recursively evaluates the while statement.
  Note that it is tail-recursive, so we should result
  in a iterative implementation."
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input SourceInfo info;
algorithm
  _ :=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,info)
    local
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      String estr,tstr;
      DAE.Type vtype;

    case (Values.BOOL(boolean = false),_,_,_) then ();

    case (Values.BOOL(boolean = true),exp,algitemlst,_)
      equation
        evaluateAlgStmtLst(algitemlst);
        value = evaluateExpr(exp, info);
        evaluateWhileStmt(value, exp, algitemlst, info); /* Tail recursive */
      then ();

    // An error occured when evaluating the algorithm items
    case (Values.BOOL(_), _,_,_)
      then ();

    // The condition value was not a boolean
    case (value,exp,_,_)
      equation
        estr = stringRepresOfExpr(exp);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseTypeNoAttr(vtype);
        Error.addSourceMessage(Error.WHILE_CONDITION_TYPE_ERROR, {estr,tstr}, info);
      then fail();

  end matchcontinue;
end evaluateWhileStmt;

protected function evaluatePartOfIfStatement
"Evaluates one part of a if statement, i.e. one \"case\". If the condition is true, the algorithm items
  associated with this condition are evaluated. The first argument returned is set to true if the
  condition was evaluated to true. Fails if the value is not a boolean.
  Note that we are sending the expression as an value, so that it does not need to be evaluated twice."
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input SourceInfo info;
algorithm
  _ :=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inTplAbsynExpAbsynAlgorithmItemLstLst,info)
    local
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      String estr,tstr;
      DAE.Type vtype;
      Values.Value value;
      Absyn.Exp exp;

    case (Values.BOOL(boolean = true),_,algitemlst,_,_)
      equation
        evaluateAlgStmtLst(algitemlst);
      then ();

    case (Values.BOOL(boolean = false),_,_,algrest,_)
      equation
        evaluateIfStatementLst(algrest, info);
      then ();

    // Report type error
    case (value,exp,_,_,_)
      equation
        estr = stringRepresOfExpr(exp);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseTypeNoAttr(vtype);
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {estr,tstr}, info);
      then fail();

  end matchcontinue;
end evaluatePartOfIfStatement;

protected function evaluateIfStatementLst
"Evaluates all parts of a if statement
  (i.e. a list of exp  statements)"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input SourceInfo info;
algorithm
  _ :=
  match (inTplAbsynExpAbsynAlgorithmItemLstLst,info)
    local
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;

    case ({},_) then ();

    case (((exp,algitemlst) :: algrest),_)
      equation
        value = evaluateExpr(exp, info);
        evaluatePartOfIfStatement(value, exp, algitemlst, algrest, info);
      then ();

  end match;
end evaluateIfStatementLst;

protected function evaluateAlgStmtLst
" Evaluates a list of algorithm statements"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
algorithm
  for algitem in inAbsynAlgorithmItemLst loop
    evaluateAlgStmt(algitem);
  end for;
end evaluateAlgStmtLst;

protected function evaluateExpr
" Evaluates an expression and returns its value.
   We need to return the symbol table, since the command loadFile()
   reads in data to the interactive environment.
   Note that this function may fail.

   Input:  Absyn.Exp - Expression to be evaluated
   Output: Values.Value - Resulting value of the expression"
  input Absyn.Exp inExp;
  input SourceInfo info;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inExp,info)
    local
      FCore.Graph env;
      DAE.Exp sexp;
      DAE.Properties prop;
      Values.Value value;
      Absyn.Exp exp;
      Absyn.Program p;
      FCore.Cache cache;
      list<GlobalScript.Variable> vars;
      Absyn.ComponentRef cr;

    // Special case to lookup fields of records.
    // SimulationResult, etc are not in the environment, but it's nice to be able to script them anyway */
    case (Absyn.CREF(cr),_)
      then getVariableValueLst(Absyn.pathToStringList(Absyn.crefToPath(cr)), SymbolTable.getVars());

    case (exp,_)
      equation
        env = SymbolTable.buildEnv();
        (cache,sexp,_) = StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, Prefix.NOPRE(), info);
        (_,value) = CevalScript.ceval(cache, env, sexp, true, Absyn.MSG(info),0);
      then value;

  end matchcontinue;
end evaluateExpr;

protected function stringRepresOfExpr
" This function returns a string representation of an expression. For example expression
   33+22 will result in \"55\" and expression: \"my\" + \"string\" will result in  \"\"my\"+\"string\"\". "
  input Absyn.Exp exp;
  output String estr;
protected
  FCore.Graph env;
  DAE.Exp sexp;
  DAE.Properties prop;
algorithm
  env := SymbolTable.buildEnv();
  (_, sexp, prop) := StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, Prefix.NOPRE(), Absyn.dummyInfo);
  (_, sexp, prop) := Ceval.cevalIfConstant(FCore.emptyCache(), env, sexp, prop, true, Absyn.dummyInfo);
  estr := ExpressionDump.printExpStr(sexp);
end stringRepresOfExpr;

protected function evaluateExprToStr
" This function is similar to evaluateExpr, with the difference that it returns a string
   and that it never fails. If the expression contain errors, an empty string will be returned
   and the errors will be stated using Error.mo

   Input:  Absyn.Exp - Expression to be evaluated
   Output: string - The resulting value represented as a string"
  input Absyn.Exp inExp;
  input SourceInfo info;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp,info)
    local
      Values.Value value;
      String str;
      Absyn.Exp exp;

    case (exp,_)
      equation
        value = evaluateExpr(exp, info);
        str = ValuesUtil.valString(value);
      then str;

    else "";

  end matchcontinue;
end evaluateExprToStr;

protected function makeTupleCrefs
  input list<Absyn.Exp> inCrefs;
  input list<DAE.Type> inTypes;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  input SourceInfo inInfo;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := List.threadMap3(inCrefs, inTypes, makeTupleCref, inEnv, inCache, inInfo);
end makeTupleCrefs;

protected function makeTupleCref
  "Translates an Absyn.CREF to a DAE.CREF_IDENT."
  input Absyn.Exp inCref;
  input DAE.Type inType;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  input SourceInfo inInfo;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inType, inEnv, inCache, inInfo)
    local
      Absyn.Ident id;
      list<Absyn.Subscript> asubs;
      list<DAE.Subscript> dsubs;
      String str;

    case (Absyn.CREF(componentRef = Absyn.CREF_IDENT(id, asubs)), _, _, _, _)
      equation
        (_, dsubs, _) = Static.elabSubscripts(inCache, inEnv, asubs, true, Prefix.NOPRE(), inInfo);
      then
        DAE.CREF_IDENT(id, inType, dsubs);

    else
      equation
        str = Dump.printExpStr(inCref);
        Error.addMessage(Error.INVALID_TUPLE_CONTENT, {str});
      then
        fail();

  end match;
end makeTupleCref;

public function getTypeOfVariable
"Return the type of an interactive variable,
  given a list of variables and a variable identifier."
  input Absyn.Ident inIdent;
  input list<GlobalScript.Variable> inVariableLst;
  output DAE.Type outType;
protected
  String id;
  DAE.Type tp;
algorithm
  for var in inVariableLst loop
    GlobalScript.IVAR(varIdent = id,type_ = tp) := var;
    if stringEq(inIdent, id) then
      outType := tp;
      return;
    end if;
  end for;
  // did not find a type
  fail();
end getTypeOfVariable;

protected function getApiFunctionNameInfo
  "Returns the name of the called API function."
  input GlobalScript.Statement inStmt;
  output String outName;
  output SourceInfo outInfo;
algorithm
  GlobalScript.IEXP(
      exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = outName)),
      info = outInfo
    ) := inStmt;
end getApiFunctionNameInfo;

protected function getApiFunctionArgs
  "Returns a list of arguments to the function in the interactive statement list."
  input GlobalScript.Statement inStmt;
  output list<Absyn.Exp> outArgs;
algorithm
  outArgs := match(inStmt)
    local
      list<Absyn.Exp> args;

    case GlobalScript.IEXP(exp = Absyn.CALL(functionArgs =
      Absyn.FUNCTIONARGS(args = args))) then args;
    else {};
  end match;
end getApiFunctionArgs;

protected function getApiFunctionNamedArgs
  "Returns a list of named arguments to the function in the interactive statement list."
  input GlobalScript.Statement inStmt;
  output list<Absyn.NamedArg> outArgs;
algorithm
  GlobalScript.IEXP(exp = Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(argNames = outArgs))) := inStmt;
end getApiFunctionNamedArgs;

protected function evaluateGraphicalApi
"Evaluating graphical api.
  NOTE: the graphical API is always evaluated with checkModel ON and -d=nogen,noevalfunc ON"
  input GlobalScript.Statement inStatement;
  input Boolean isPartialInst;
  input Boolean flagGen;
  input Boolean flagEvalFunc;
  input Boolean flagKeepArrays;
  output String outResult;
protected
  String fn_name;
  SourceInfo info;
  Boolean failed = false;
algorithm
  try
    outResult := evaluateGraphicalApi_dispatch(inStatement);
  else
    failed := true;
  end try;

  // Reset the flags!
  System.setPartialInstantiation(isPartialInst);
  Flags.set(Flags.GEN, flagGen);
  Flags.set(Flags.EVAL_FUNC, flagEvalFunc);
  Flags.setConfigBool(Flags.KEEP_ARRAYS, flagKeepArrays);

  if failed then fail(); end if;
end evaluateGraphicalApi;

protected function evaluateGraphicalApi_dispatch
"This function evaluates all primitives in the graphical api."
  input GlobalScript.Statement inStatement;
  output String outResult;
protected
  String fn_name, name;
  Absyn.Program old_p, p, p_1;
  SCode.Program s;
  list<Absyn.Exp> args, expl;
  Absyn.ComponentRef cr, cr1, cr2, tp, model_, class_, old_cname, new_cname;
  Absyn.ComponentRef crident, subident;
  Absyn.Path path;
  list<Absyn.NamedArg> nargs;
  Integer n, access;
  String cmt, variability, causality/*, isField*/;
  Absyn.Class cls;
  Absyn.Modification mod;
  Boolean finalPrefix, flowPrefix, streamPrefix, protected_, repl, dref1, dref2, evalParamAnn;
  Boolean addFunctions, graphicsExpMode;
  FCore.Graph env;
  Absyn.Exp exp;
  list<Absyn.Exp> dimensions;
algorithm
  fn_name := getApiFunctionNameInfo(inStatement);
  p := SymbolTable.getAbsyn();
  args := getApiFunctionArgs(inStatement);

  outResult := match(fn_name)
    case "setComponentModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))} := args;
        (p, outResult) := setComponentModifier(class_, cr, mod, p);
      then
        outResult;

    case "setParameterValue"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = crident), exp} := args;
        (p, outResult) := setParameterValue(class_, crident, exp, p);
      then
        outResult;

    case "setComponentDimensions"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.ARRAY(dimensions)} := args;
        (p, outResult) := setComponentDimensions(class_, cr, dimensions, p);
      then
        outResult;

    case "createModel"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        p := createModel(cr, p);
      then
        "true";

    case "newModel"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = cr)} := args;
        path := Absyn.crefToPath(cr);
        p := updateProgram(
          Absyn.PROGRAM({
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),Absyn.dummyParts,Absyn.dummyInfo)
          }, Absyn.WITHIN(path)), p);
      then
        "true";

    // Not moving this yet as it could break things...
    case "deleteClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        (outResult, p) := deleteClass(cr, p);
      then
        outResult;

    case "addComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
        p := addComponent(name, tp, model_, nargs, p);
        Print.clearBuf();
      then
        "true";

    case "updateComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
        (p, outResult) := updateComponent(name, tp, model_, nargs, p);
      then
        outResult;

    case "deleteComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = model_)} := args;
        {} := getApiFunctionNamedArgs(inStatement);
        p := deleteOrUpdateComponent(name, model_, p, NONE());
        Print.clearBuf();
      then "true";

    case "deleteComponent"
      then "false";

    case "getComponentCount"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        intString(getComponentCount(cr, p));

    case "getNthComponent"
      algorithm
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} := args;
      then
        getNthComponent(cr, p, n);

    case "getComponents"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := checkAccessAnnotationAndEncryption(Absyn.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          nargs := getApiFunctionNamedArgs(inStatement);
          outResult := getComponents(cr, useQuotes(nargs));
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getComponentAnnotations"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := checkAccessAnnotationAndEncryption(Absyn.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          ErrorExt.setCheckpoint("getComponentAnnotations");
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := getComponentAnnotations(cr, p);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          ErrorExt.rollBack("getComponentAnnotations");
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getNthComponentAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        ErrorExt.setCheckpoint("getNthComponentAnnotation");
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := getNthComponentAnnotation(cr, p, n);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        ErrorExt.rollBack("getNthComponentAnnotation");
      then
        outResult;

    case "getNthComponentModification"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        getNthComponentModification(cr, p, n);

    case "getNthComponentCondition"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        getNthComponentCondition(cr, p, n);

    case "getInheritanceCount"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        intString(getInheritanceCount(cr, p));

    case "getNthInheritedClass"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        outResult := getNthInheritedClass(cr, n);
      then
        outResult;

    case "setConnectionComment"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.STRING(value = cmt)} := args;
        (p, outResult) := setConnectionComment(cr, cr1, cr2, cmt, p);
      then
        outResult;

    case "addConnection"
      algorithm
        {Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.CREF(componentRef = cr)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
        (outResult, p) := addConnection(cr, cr1, cr2, nargs, p);
      then
        outResult;

    case "deleteConnection"
      algorithm
        {Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.CREF(componentRef = cr)} := args;
        (outResult, p) := deleteConnection(cr, cr1, cr2, p);
      then
        outResult;

    case "getNthConnectionAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        Values.ENUM_LITERAL(index=access) := checkAccessAnnotationAndEncryption(Absyn.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          ErrorExt.setCheckpoint("getNthConnectionAnnotation");
          path := Absyn.crefToPath(cr);
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := getNthConnectionAnnotation(path, p, n);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          ErrorExt.rollBack("getNthConnectionAnnotation");
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getConnectorCount"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        getConnectorCount(cr, p);

    case "getNthConnector"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        getNthConnector(Absyn.crefToPath(cr), p, n);

    case "getNthConnectorIconAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        ErrorExt.setCheckpoint("getNthConnectorIconAnnotation");
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := getNthConnectorIconAnnotation(Absyn.crefToPath(cr), p, n);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        ErrorExt.rollBack("getNthConnectorIconAnnotation");
      then
        outResult;

    case "getIconAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := checkAccessAnnotationAndEncryption(Absyn.crefToPath(cr), p);
        if (access >= 2) then // i.e., Access.icon
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          graphicsExpMode := Config.getGraphicsExpMode();
          Config.setEvaluateParametersInAnnotations(true);
          Config.setGraphicsExpMode(true);
          outResult := getIconAnnotation(Absyn.crefToPath(cr), p);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          Config.setGraphicsExpMode(graphicsExpMode);
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getDiagramAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := checkAccessAnnotationAndEncryption(Absyn.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          ErrorExt.setCheckpoint("getDiagramAnnotation");
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := getDiagramAnnotation(Absyn.crefToPath(cr), p);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          ErrorExt.rollBack("getDiagramAnnotation");
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getNthInheritedClassIconMapAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        ErrorExt.setCheckpoint("getNthInheritedClassIconMapAnnotation");
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := getNthInheritedClassMapAnnotation(Absyn.crefToPath(cr), n, p, "IconMap");
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        ErrorExt.rollBack("getNthInheritedClassIconMapAnnotation");
      then
        outResult;

    case "getNthInheritedClassDiagramMapAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        ErrorExt.setCheckpoint("getNthInheritedClassDiagramMapAnnotation");
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := getNthInheritedClassMapAnnotation(Absyn.crefToPath(cr), n, p, "DiagramMap");
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        ErrorExt.rollBack("getNthInheritedClassDiagramMapAnnotation");
      then
        outResult;

    case "getNamedAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = Absyn.CREF_IDENT(name, {}))} := args;
        ErrorExt.setCheckpoint("getNamedAnnotation");
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := getNamedAnnotation(Absyn.crefToPath(cr), p,
            Absyn.IDENT(name), SOME("{}"), getAnnotationValue);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        ErrorExt.rollBack("getNamedAnnotation");
      then
        outResult;

    case "refactorClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;

        try
          cls := getPathedClassInProgram(Absyn.crefToPath(cr), p);
          cls := Refactor.refactorGraphicalAnnotation(p, cls);
          p := updateProgram(Absyn.PROGRAM({cls}, Absyn.TOP()), p);
          outResult := Dump.unparseStr(Absyn.PROGRAM({cls}, Absyn.TOP()), false);
        else
          outResult := "Failed in translating " + Dump.printComponentRefStr(cr)
                     + " to Modelica v2.0 graphical annotations";
        end try;
      then
        outResult;

    case "refactorIconAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := Absyn.crefToPath(cr);
        cls := getPathedClassInProgram(path, p);
        cls := Refactor.refactorGraphicalAnnotation(p, cls);
      then
        getAnnotationInClass(cls, ICON_ANNOTATION(), p, path);

    case "refactorDiagramAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := Absyn.crefToPath(cr);
        cls := getPathedClassInProgram(path, p);
        cls := Refactor.refactorGraphicalAnnotation(p, cls);
      then
        getAnnotationInClass(cls, DIAGRAM_ANNOTATION(), p, path);

    case "getShortDefinitionBaseClassInformation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        getShortDefinitionBaseClassInformation(cr, p);

    case "getExternalFunctionSpecification"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        getExternalFunctionSpecification(cr, p);

    case "isPrimitive"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(isPrimitive(cr, p));

    case "isParameter"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(isParameter(cr, class_, p));

    case "isProtected"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(isProtected(cr, class_, p));

    case "isConstant"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(isConstant(cr, class_, p));

    case "isReplaceable"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.STRING(value = name)} := args;
      then
        boolString(isReplaceable(class_, name, p));

    case "getEnumerationLiterals"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := Absyn.crefToPath(cr);
        cls := getPathedClassInProgram(path, p);
      then
        getEnumLiterals(cls);

    case "existClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(existClass(cr, p));

    case "existModel"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := Absyn.crefToPath(cr);
      then
        boolString(existClass(cr, p) and isModel(path, p));

    case "existPackage"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(existClass(cr, p) and isPackage(Absyn.crefToPath(cr), p));

    case "renameClass"
      algorithm
        {Absyn.CREF(componentRef = old_cname), Absyn.CREF(componentRef = new_cname)} := args;
        // For now, renaming a class clears all caches...
        // Substantial analysis required to find out what to keep in cache and what must be thrown out
        (outResult, p) := renameClass(p, old_cname, new_cname);
      then
        outResult;

    case "renameComponent"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = old_cname),
         Absyn.CREF(componentRef = new_cname)} := args;
        (outResult, p) := renameComponent(p, cr, old_cname, new_cname);
      then outResult;

    case "renameComponentInClass"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = old_cname),
         Absyn.CREF(componentRef = new_cname)} := args;
        (outResult, p) := renameComponentOnlyInClass(p, cr, old_cname, new_cname);
      then outResult;

    case "getCrefInfo"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        getCrefInfo(cr, p);

    case "setExtendsModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))} := args;
        (p, outResult) := setExtendsModifierValue(class_, crident, subident, mod, p);
      then
        outResult;

    case "getExtendsModifierNames"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = cr)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
      then
        getExtendsModifierNames(class_, cr, useQuotes(nargs), p);

    case "getExtendsModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident)} := args;
      then
        getExtendsModifierValue(class_, crident, subident, p);

    case "isExtendsModifierFinal"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident)} := args;
      then
        isExtendsModifierFinal(class_, crident, subident, p);

    case "getDefaultComponentName"
      algorithm
        {Absyn.CREF(componentRef = class_)} := args;
      then
        getDefaultComponentName(Absyn.crefToPath(class_), p);

    case "getDefaultComponentPrefixes"
      algorithm
        {Absyn.CREF(componentRef = class_)} := args;
      then
        getDefaultComponentPrefixes(Absyn.crefToPath(class_), p);

    case "getComponentComment"
      algorithm
        {Absyn.CREF(componentRef = class_),Absyn.CREF(componentRef = cr)} := args;
        outResult := getComponentComment(class_, cr, p);
        outResult := stringAppendList({"\"", outResult, "\""});
      then
        outResult;

    case "setComponentComment"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.STRING(value = cmt)} := args;
        (outResult, p) := setComponentComment(class_, cr, cmt, p);
      then
        outResult;

    case "setComponentProperties"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.ARRAY(arrayExp = expl),
         // Absyn.ARRAY(arrayExp = {Absyn.STRING(value = parallelism)}),
         Absyn.ARRAY(arrayExp = {Absyn.STRING(value = variability)}),
         Absyn.ARRAY(arrayExp = {Absyn.BOOL(value = dref1),Absyn.BOOL(value = dref2)}),
         Absyn.ARRAY(arrayExp = {Absyn.STRING(value = causality)})/*,
         Absyn.ARRAY(arrayExp = {Absyn.STRING(value = isField)})*/} := args;

        if listLength(expl) == 5 then
          {Absyn.BOOL(value = finalPrefix),
           Absyn.BOOL(value = flowPrefix),
           Absyn.BOOL(value = streamPrefix),
           Absyn.BOOL(value = protected_),
           Absyn.BOOL(value = repl)} := expl;
        else // Old version of setComponentProperties, without stream.
          {Absyn.BOOL(value = finalPrefix),
           Absyn.BOOL(value = flowPrefix),
           Absyn.BOOL(value = protected_),
           Absyn.BOOL(value = repl)} := expl;
          streamPrefix := false;
        end if;

        (outResult, p) := setComponentProperties(Absyn.crefToPath(class_), cr,
            finalPrefix, flowPrefix, streamPrefix, protected_, repl,
            /*parallelism,*/ variability, {dref1,dref2}, causality, p/*, isField*/);
      then
        outResult;

    case "getElementsInfo"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        getElementsInfo(cr, p);

    case "getElementsOfVisType"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        (_, outResult) := getElementsOfVisType(Absyn.crefToPath(cr), p);
      then
        outResult;

    case "getDefinitions"
      algorithm
        {Absyn.BOOL(addFunctions)} := args;
      then
        getDefinitions(p, addFunctions);

    case "getLocalVariables"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
        path := Absyn.crefToPath(cr);
        cls := getPathedClassInProgram(path, p);
        env := SymbolTable.buildEnv();
      then
        getLocalVariables(cls, useQuotes(nargs), env);

    // adrpo added 2006-10-16
    // - i think this function is needed here!
    case "getErrorString"
      algorithm
        {} := args;
        outResult := Error.printMessagesStr(false);
      then
        stringAppendList({"\"", outResult, "\""});

  end match;

  SymbolTable.setAbsyn(p);
end evaluateGraphicalApi_dispatch;

protected function listClass
"Unparse a class definition and return it in a String"
  input Absyn.ComponentRef cr "Class name as a ComponentRef";
  input Absyn.Program p "AST - Program";
  output String classStr "Class defintition";
protected
  Absyn.Path path;
  Absyn.Class cl;
algorithm
   path := Absyn.crefToPath(cr);
   cl := getPathedClassInProgram(path, p);
   classStr := Dump.unparseStr(Absyn.PROGRAM({cl},Absyn.TOP()),false);
end listClass;

protected function extractAllComponentreplacements
"author: x02lucpo
  extracts all the componentreplacementrules from program.
  This is done by extracting all the components and then
  extracting the rules"
  input Absyn.Program p;
  input Absyn.ComponentRef class_;
  input Absyn.ComponentRef cref1;
  input Absyn.ComponentRef cref2;
  output GlobalScript.ComponentReplacementRules comp_reps;
algorithm
  comp_reps := matchcontinue(p,class_,cref1,cref2)
    local
      GlobalScript.Components comps;
      Absyn.Path class_path;
      GlobalScript.ComponentReplacementRules comp_repsrules;

    case(_,_,_,_)
      equation
        ErrorExt.setCheckpoint("Interactive.extractAllComponentreplacements");
        comps = extractAllComponents(p, Absyn.crefToPath(class_)) "class in package" ;
        // rollback errors if we succeed
        ErrorExt.rollBack("Interactive.extractAllComponentreplacements");
        false = isClassReadOnly(getPathedClassInProgram(Absyn.crefToPath(class_),p));
        class_path = Absyn.crefToPath(class_);
        comp_repsrules = GlobalScript.COMPONENTREPLACEMENTRULES({GlobalScript.COMPONENTREPLACEMENT(class_path,cref1,cref2)},1);
        comp_reps = getComponentreplacementsrules(comps, comp_repsrules, 0);
      then comp_reps;

    else
      equation
        // keep errors if we fail!
        ErrorExt.delCheckpoint("Interactive.extractAllComponentreplacements");
      then
        fail();
  end matchcontinue;
end extractAllComponentreplacements;

protected function isClassReadOnly
"Returns the readonly attribute of a class."
input Absyn.Class cl;
output Boolean readOnly;
algorithm
  readOnly := match(cl)
    case(Absyn.CLASS(info = SOURCEINFO(isReadOnly=readOnly))) then readOnly;
  end match;
end isClassReadOnly;

protected function renameComponent
"author: x02lucpo
  This function renames a component in a class
  inputs:  (Absyn.Program,
              Absyn.ComponentRef, /* old class as qualified name */
              Absyn.ComponentRef) /* new class, as identifier */
  outputs:  Absyn.Program"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.ComponentRef inComponentRef4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3,inComponentRef4)
    local
      Absyn.Path class_path;
      GlobalScript.ComponentReplacementRules comp_reps;
      Absyn.Program p_1,p;
      list<String> paths;
      String paths_1,paths_2;
      Absyn.ComponentRef class_,old_comp,new_comp;
      Absyn.Path model_path;
      String str;

    case (p,class_,_,_)
      equation
        model_path = Absyn.crefToPath(class_);
        true = isClassReadOnly(getPathedClassInProgram(model_path,p));
        str = Absyn.pathString(model_path);
        str = "Error: class: " + str + " is in a read only file!";
      then
        (str, p);

    case (p,class_,old_comp,new_comp)
      equation
        comp_reps = extractAllComponentreplacements(p, class_, old_comp, new_comp);
        p_1 = renameComponentFromComponentreplacements(p, comp_reps);
        paths = extractRenamedClassesAsStringList(comp_reps);
        paths_1 = stringDelimitList(paths, ",");
        paths_2 = stringAppendList({"{",paths_1,"}"});
      then
        (paths_2,p_1);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("rename_component failed\n");
        end if;
      then
        ("Error",inProgram1);
  end matchcontinue;
end renameComponent;

protected function renameComponentOnlyInClass
"@author: adrpo
  This function renames a component ONLY in the given class"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.ComponentRef inComponentRef4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3,inComponentRef4)
    local
      Absyn.Program p;
      String paths_2;
      Absyn.ComponentRef class_,old_comp,new_comp;
      Absyn.Class cl;
      Absyn.Path model_path;
      String str;
      Absyn.Within w;

    case (p,class_,_,_)
      equation
        model_path = Absyn.crefToPath(class_);
        true = isClassReadOnly(getPathedClassInProgram(model_path,p));
        str = Absyn.pathString(model_path);
        str = "Error: class: " + str + " is in a read only file!";
      then
        (str, p);

    case (p,class_,old_comp,new_comp)
      equation
        model_path = Absyn.crefToPath(class_) "class in package" ;
        cl = getPathedClassInProgram(model_path, p);
        cl = renameComponentInClass(cl, old_comp, new_comp);
        w = buildWithin(Absyn.makeFullyQualified(model_path));
        p = updateProgram(Absyn.PROGRAM({cl}, w), p);
        str = Absyn.pathString(model_path);
        paths_2 = stringAppendList({"{",str,"}"});
      then
        (paths_2,p);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("renameComponentOnlyInClass failed\n");
        end if;
      then
        ("Error",inProgram1);
  end matchcontinue;
end renameComponentOnlyInClass;

protected function extractRenamedClassesAsStringList
"author: x02lucpo
  this iterates through the Componentreplacementrules and
  returns the string list with all the changed classes"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inComponentReplacementRules)
    local
      GlobalScript.ComponentReplacementRules comp_reps,res;
      Absyn.Path path;
      String path_str;
      list<String> res_1,res_2;
    case (comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        {};
    case (comp_reps)
      equation
        GlobalScript.COMPONENTREPLACEMENT(path,_,_) = firstComponentReplacement(comp_reps);
        path_str = Absyn.pathString(path);
        res = restComponentReplacementRules(comp_reps);
        res_1 = extractRenamedClassesAsStringList(res);
        res_2 = List.union({path_str}, res_1);
      then
        res_2;
    else
      equation
        print("-extract_renamed_classes_as_string_list failed\n");
      then
        fail();
  end matchcontinue;
end extractRenamedClassesAsStringList;

protected function renameComponentFromComponentreplacements
"author: x02lucpo
  this iterates through the Componentreplacementrules and
  renames the componentes by traversing all the classes"
  input Absyn.Program inProgram;
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inProgram,inComponentReplacementRules)
    local
      Absyn.Program p,p_1,p_2;
      GlobalScript.ComponentReplacementRules comp_reps,res;
      GlobalScript.ComponentReplacement comp_rep;
    case (p,comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        p;
    case (p,comp_reps)
      equation
        comp_rep = firstComponentReplacement(comp_reps);
        ((p_1,_,_)) = AbsynUtil.traverseClasses(p,NONE(), renameComponentVisitor, comp_rep, true) "traverse protected" ;
        res = restComponentReplacementRules(comp_reps);
        p_2 = renameComponentFromComponentreplacements(p_1, res);
      then
        p_2;
    else
      equation
        print("-rename_component_from_componentreplacements failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentFromComponentreplacements;

protected function renameComponentVisitor
"author: x02lucpo
  this is a visitor for traverse class in rename components"
  input tuple<Absyn.Class, Option<Absyn.Path>, GlobalScript.ComponentReplacement> inTplAbsynClassAbsynPathOptionComponentReplacement;
  output tuple<Absyn.Class, Option<Absyn.Path>, GlobalScript.ComponentReplacement> outTplAbsynClassAbsynPathOptionComponentReplacement;
algorithm
  outTplAbsynClassAbsynPathOptionComponentReplacement:=
  matchcontinue (inTplAbsynClassAbsynPathOptionComponentReplacement)
    local
      Absyn.Path path_1,pa,class_id;
      Absyn.Class class_1,class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      SourceInfo file_info;
      Absyn.ComponentRef old_comp,new_comp;
      GlobalScript.ComponentReplacement args;
      Option<Absyn.Path> opath;
    case (((class_ as Absyn.CLASS(name = id)),SOME(pa),GlobalScript.COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = Absyn.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,SOME(pa),
          GlobalScript.COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case (((class_ as Absyn.CLASS(name = id)),NONE(),GlobalScript.COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation
        path_1 = Absyn.IDENT(id);
        true = Absyn.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,NONE(),
          GlobalScript.COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case ((class_,opath,args)) then ((class_,opath,args));
  end matchcontinue;
end renameComponentVisitor;

protected function renameComponentInClass
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,baseClassName;
      Boolean partialPrefix,finalPrefix,encapsulatedPrefix;
      Absyn.Restriction restriction;
      Option<String> a,c;
      SourceInfo file_info;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.ElementArg> b;
      Absyn.Class class_;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    /* the class with the component the old name for the component */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
          body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = a),info = file_info),old_comp,new_comp)
      equation
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,a),file_info);

    /* the class with the component the old name for the component for model extends X end X; */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = b,comment = c,parts = parts,ann=ann),
                      info = file_info),old_comp,new_comp)
      equation
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction, Absyn.CLASS_EXTENDS(baseClassName,b,c,parts_1,ann),file_info);

    else inClass1;
  end matchcontinue;
end renameComponentInClass;

protected function renameComponentInParts
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> res_1,res;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.EquationItem> equations_1,equations;
      list<Absyn.AlgorithmItem> algorithms_1,algorithms;
      Absyn.ExternalDecl external_decl_1,external_decl;
      Option<Absyn.Annotation> ano;
      Absyn.ClassPart a;

    case ({},_,_) then {};  /* the old name for the component */

    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PUBLIC(elements_1) :: res_1);

    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PROTECTED(elements_1) :: res_1);

    case ((Absyn.EQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.EQUATIONS(equations_1) :: res_1);

    case ((Absyn.INITIALEQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.INITIALEQUATIONS(equations_1) :: res_1);

    case ((Absyn.ALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.ALGORITHMS(algorithms_1) :: res_1);

    case ((Absyn.INITIALALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.INITIALALGORITHMS(algorithms_1) :: res_1);

    case ((Absyn.EXTERNAL(externalDecl = external_decl,annotation_ = ano) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        external_decl_1 = renameComponentInExternalDecl(external_decl, old_comp, new_comp);
      then
        (Absyn.EXTERNAL(external_decl_1,ano) :: res_1);

    case ((a :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInParts(res, old_comp, new_comp);
      then
        (a :: res_1);
  end matchcontinue;
end renameComponentInParts;

protected function renameComponentInElements
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst := matchcontinue (inAbsynElementItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ElementItem> res_1,res;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,
                    specification = elementspec,info = info,constrainClass = constrainClass)) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,elementspec_1,info,
          constrainClass));
      then
        (element_1 :: res_1);
    case ((element :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        element_1 = element;
      then
        (element_1 :: res_1);
  end matchcontinue;
end renameComponentInElements;

protected function renameComponentInElementSpec
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec := matchcontinue (inElementSpec1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ComponentItem> comps_1,comps;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec path;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.ElementSpec elementspec;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = path,components = comps),old_comp,new_comp) /* the old name for the component */
      equation
        comps_1 = renameComponentInComponentitems(comps, old_comp, new_comp);
      then
        Absyn.COMPONENTS(attr,path,comps_1);
    else inElementSpec1;
  end matchcontinue;
end renameComponentInElementSpec;

protected function renameComponentInComponentitems
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := matchcontinue (inAbsynComponentItemLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path old_comp_path,new_comp_path;
      String old_comp_string,new_comp_string,name;
      list<Absyn.ComponentItem> res_1,res;
      Absyn.ComponentItem comp_1,comp;
      list<Absyn.Subscript> arrayDim;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> comment;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case (((Absyn.COMPONENTITEM(component =
      Absyn.COMPONENT(name = name,arrayDim = arrayDim,modification = mod),condition = cond,comment = comment)) :: res),old_comp,new_comp)
      equation
        old_comp_path = Absyn.crefToPath(old_comp);
        old_comp_string = Absyn.pathString(old_comp_path);
        true = stringEq(name, old_comp_string);
        new_comp_path = Absyn.crefToPath(new_comp);
        new_comp_string = Absyn.pathString(new_comp_path);
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
        comp_1 = Absyn.COMPONENTITEM(Absyn.COMPONENT(new_comp_string,arrayDim,mod),cond,comment);
      then
        (comp_1 :: res_1);
    case (((comp as Absyn.COMPONENTITEM(component =
      Absyn.COMPONENT())) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
      then
        (comp :: res_1);
    else
      equation
        print("-Interactive.renameComponentInComponentitems failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInComponentitems;

protected function renameComponentInEquationList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> res_1,res;
      Absyn.Equation equation_1,equation_;
      Option<Absyn.Comment> cmt;
      SourceInfo info;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.EquationItem equation_item;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.EQUATIONITEM(equation_ = equation_,comment = cmt,info=info) :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
        equation_1 = renameComponentInEquation(equation_, old_comp, new_comp);
      then
        (Absyn.EQUATIONITEM(equation_1,cmt,info) :: res_1);
    case ((equation_item :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
      then
        (equation_item :: res_1);
  end matchcontinue;
end renameComponentInEquationList;

protected function renameComponentInExpEquationitemList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> outTplAbsynExpAbsynEquationItemLstLst;
algorithm
  outTplAbsynExpAbsynEquationItemLstLst := matchcontinue (inTplAbsynExpAbsynEquationItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp1;
      list<Absyn.EquationItem> eqn_item_1,eqn_item;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp1,eqn_item) :: res),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        eqn_item_1 = renameComponentInEquationList(eqn_item, old_comp, new_comp);
        res_1 = renameComponentInExpEquationitemList(res, old_comp, new_comp);
      then
        ((exp1_1,eqn_item_1) :: res_1);
    else
      equation
        print("-rename_component_in_exp_equationitem_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpEquationitemList;

protected function renameComponentInEquation
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Equation inEquation1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.EquationItem> true_items_1,elses_1,true_items,elses,equations_1,equations;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> exp_elseifs_1,exp_elseifs,exp_equations_1,exp_equations;
      Absyn.ComponentRef old_comp,new_comp,cref1_1,cref2_1,cref1,cref2,cref;
      String ident;
      Absyn.FunctionArgs function_args;
    /* the old name for the component */
    case (Absyn.EQ_IF(ifExp = exp,equationTrueItems = true_items,elseIfBranches = exp_elseifs,equationElseItems = elses),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        true_items_1 = renameComponentInEquationList(true_items, old_comp, new_comp);
        exp_elseifs_1 = renameComponentInExpEquationitemList(exp_elseifs, old_comp, new_comp);
        elses_1 = renameComponentInEquationList(elses, old_comp, new_comp);
      then
        Absyn.EQ_IF(exp_1,true_items_1,exp_elseifs_1,elses_1);
    case (Absyn.EQ_EQUALS(leftSide = exp1,rightSide = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.EQ_EQUALS(exp1_1,exp2_1);
    case (Absyn.EQ_PDE(leftSide = exp1,rightSide = exp2,domain = cref1),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        cref1_1 = replaceStartInComponentRef(cref1, old_comp, new_comp);
      then
        Absyn.EQ_PDE(exp1_1,exp2_1,cref1_1);
    case (Absyn.EQ_CONNECT(connector1 = cref1,connector2 = cref2),old_comp,new_comp)
      equation
        cref1_1 = replaceStartInComponentRef(cref1, old_comp, new_comp);
        cref2_1 = replaceStartInComponentRef(cref2, old_comp, new_comp) "print \"-rename_component_in_equation EQ_CONNECT not implemented yet\\n\"" ;
      then
        Absyn.EQ_CONNECT(cref1_1,cref2_1);
    case (Absyn.EQ_FOR(iterators = {Absyn.ITERATOR(ident,NONE(),SOME(exp))},forEquations = equations),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        Absyn.EQ_FOR({Absyn.ITERATOR(ident,NONE(),SOME(exp_1))},equations_1);
    case (Absyn.EQ_WHEN_E(whenExp = exp,whenEquations = equations,elseWhenEquations = exp_equations),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
        exp_equations_1 = renameComponentInExpEquationitemList(exp_equations, old_comp, new_comp);
      then
        Absyn.EQ_WHEN_E(exp_1,equations_1,exp_equations_1);
    case (Absyn.EQ_NORETCALL(functionName = cref,functionArgs = function_args),_,_)
      equation
        print("-rename_component_in_equation EQ_NORETCALL not implemented yet\n");
      then
        Absyn.EQ_NORETCALL(cref,function_args);
    else
      equation
        print("-rename_component_in_equation failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInEquation;

protected function renameComponentInExpList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.Exp> inAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  outAbsynExpLst := matchcontinue (inAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.Exp> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((exp :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInExpList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    else
      equation
        print("-rename_component_in_exp_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpList;

protected function renameComponentInExpListList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<list<Absyn.Exp>> inAbsynExpLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm
  outAbsynExpLstLst := matchcontinue (inAbsynExpLstLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exp_1,exp;
      list<list<Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((exp :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExpList(exp, old_comp, new_comp);
        res_1 = renameComponentInExpListList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    else
      equation
        print("-rename_component_in_exp_list_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpListList;

protected function renameComponentInExpTupleList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm
  outTplAbsynExpAbsynExpLst := matchcontinue (inTplAbsynExpAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp2_1,exp1,exp2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp1,exp2) :: res),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        res_1 = renameComponentInExpTupleList(res, old_comp, new_comp);
      then
        ((exp1_1,exp2_1) :: res_1);
    else
      equation
        print("-rename_component_in_exp_tuple_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpTupleList;

protected function renameComponentInElementArgList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.ElementArg> inAbsynElementArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst := matchcontinue (inAbsynElementArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.ElementArg element_arg_1,element_arg;
      list<Absyn.ElementArg> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((element_arg :: res),old_comp,new_comp)
      equation
        element_arg_1 = renameComponentInElementArg(element_arg, old_comp, new_comp);
        res_1 = renameComponentInElementArgList(res, old_comp, new_comp);
      then
        (element_arg_1 :: res_1);
    else
      equation
        print("-rename_component_in_element_arg_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInElementArgList;

protected function renameComponentInElementArg
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ElementArg inElementArg1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg := match (inElementArg1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.Path p,p_1;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
      Boolean b;
      Absyn.Each each_;
      Option<String> str;
      Absyn.ElementSpec element_spec_1,element_spec2_1,element_spec,element_spec2;
      Absyn.RedeclareKeywords redecl;
      Option<Absyn.Comment> c;
      SourceInfo info, mod_info;
    /* the old name for the component */
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,path = p,modification = SOME(Absyn.CLASSMOD(element_args,Absyn.EQMOD(exp,info))),comment = str,info = mod_info),old_comp,new_comp)
      equation
        p_1 = Absyn.crefToPath(replaceStartInComponentRef(Absyn.pathToCref(p), old_comp, new_comp));
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,p_1,
          SOME(Absyn.CLASSMOD(element_args_1,Absyn.EQMOD(exp_1,info))),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,path = p,modification = SOME(Absyn.CLASSMOD(element_args,Absyn.NOMOD())),comment = str, info = mod_info),old_comp,new_comp)
      equation
        p_1 = Absyn.crefToPath(replaceStartInComponentRef(Absyn.pathToCref(p), old_comp, new_comp));
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,p_1,SOME(Absyn.CLASSMOD(element_args_1,Absyn.NOMOD())),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,path = p,modification = NONE(),comment = str, info = mod_info),old_comp,new_comp)
      equation
        p_1 = Absyn.crefToPath(replaceStartInComponentRef(Absyn.pathToCref(p), old_comp, new_comp));
      then
        Absyn.MODIFICATION(b,each_,p_1,NONE(),str,mod_info);
    case (Absyn.REDECLARATION(finalPrefix = b,redeclareKeywords = redecl,eachPrefix = each_,elementSpec = element_spec,constrainClass = SOME(Absyn.CONSTRAINCLASS(element_spec2,c)),info = info),old_comp,new_comp)
      equation
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
        element_spec2_1 = renameComponentInElementSpec(element_spec2, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,
          SOME(Absyn.CONSTRAINCLASS(element_spec2_1,c)),info);
    case (Absyn.REDECLARATION(finalPrefix = b,redeclareKeywords = redecl,eachPrefix = each_,elementSpec = element_spec,constrainClass = NONE(),info=info),old_comp,new_comp)
      equation
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,NONE(),info);
  end match;
end renameComponentInElementArg;

protected function renameComponentInCode
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.CodeNode inCode1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.CodeNode outCode;
algorithm
  outCode := match (inCode1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path path;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr;
      list<Absyn.EquationItem> eqn_items_1,eqn_items;
      Boolean b,finalPrefix;
      list<Absyn.AlgorithmItem> algs_1,algs;
      Absyn.ElementSpec elementspec_1,elementspec;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
    case (Absyn.C_TYPENAME(path = path),_,_) then Absyn.C_TYPENAME(path);  /* the old name for the component */
    case (Absyn.C_VARIABLENAME(componentRef = cr),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.C_VARIABLENAME(cr_1);
    case (Absyn.C_EQUATIONSECTION(boolean = b,equationItemLst = eqn_items),old_comp,new_comp)
      equation
        eqn_items_1 = renameComponentInEquationList(eqn_items, old_comp, new_comp);
      then
        Absyn.C_EQUATIONSECTION(b,eqn_items_1);
    case (Absyn.C_ALGORITHMSECTION(boolean = b,algorithmItemLst = algs),old_comp,new_comp)
      equation
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.C_ALGORITHMSECTION(b,algs_1);
    case (Absyn.C_ELEMENT(element = Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,specification = elementspec,info = info,constrainClass = constrainClass)),old_comp,new_comp)
      equation
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
      then
        Absyn.C_ELEMENT(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,elementspec_1,info,
          constrainClass));
    case (Absyn.C_EXPRESSION(exp = exp),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.C_EXPRESSION(exp_1);
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,eqMod = Absyn.EQMOD(exp,info))),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,Absyn.EQMOD(exp_1,info)));
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,eqMod = Absyn.NOMOD())),old_comp,new_comp)
      equation
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,Absyn.NOMOD()));
  end match;
end renameComponentInCode;

protected function renameComponentInExp
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Exp inExp1;
  input Absyn.ComponentRef oldPrefix;
  input Absyn.ComponentRef newPrefix;
  output Absyn.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1, oldPrefix, newPrefix)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr,cref;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2,exp_1,exp,exp3_1,exp3;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> exp_tuple_list_1,exp_tuple_list;
      Absyn.FunctionArgs func_args;
      list<Absyn.Exp> exp_list_1,exp_list;
      list<list<Absyn.Exp>> exp_list_list_1,exp_list_list;
      Absyn.CodeNode code_1,code;
    case (Absyn.INTEGER(),_,_) then inExp1;
    case (Absyn.REAL(),_,_) then inExp1;
    case (Absyn.CREF(componentRef = cr),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.CREF(cr_1);
    case (Absyn.STRING(),_,_) then inExp1;
    case (Absyn.BOOL(),_,_) then inExp1;
    case (Absyn.BINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.BINARY(exp1_1,op,exp2_1);
    case (Absyn.UNARY(op = op,exp = exp),old_comp,new_comp)
      equation
        exp = renameComponentInExp(exp, old_comp, new_comp); // TODO: Update the expression?
      then
        Absyn.UNARY(op,exp);
    case (Absyn.LBINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.LBINARY(exp1_1,op,exp2_1);
    case (Absyn.LUNARY(op = op,exp = exp),old_comp,new_comp)
      equation
        exp = renameComponentInExp(exp, old_comp, new_comp); // TODO: Update the expression?
      then
        Absyn.LUNARY(op,exp);
    case (Absyn.RELATION(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.RELATION(exp1_1,op,exp2_1);
    case (Absyn.IFEXP(ifExp = exp1,trueBranch = exp2,elseBranch = exp3,elseIfBranch = exp_tuple_list),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
        exp_tuple_list_1 = renameComponentInExpTupleList(exp_tuple_list, old_comp, new_comp);
      then
        Absyn.IFEXP(exp1_1,exp2_1,exp3_1,exp_tuple_list_1);
    case (Absyn.CALL(function_ = cref,functionArgs = func_args), old_comp, new_comp)
      equation
        cref = replaceStartInComponentRef(cref, old_comp, new_comp);
        func_args = renameComponentInFunctionArgs(func_args, old_comp, new_comp);
      then
        Absyn.CALL(cref,func_args);
    case (Absyn.ARRAY(arrayExp = exp_list),old_comp,new_comp)
      equation
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.ARRAY(exp_list_1);
    case (Absyn.MATRIX(matrix = exp_list_list),old_comp,new_comp)
      equation
        exp_list_list_1 = renameComponentInExpListList(exp_list_list, old_comp, new_comp);
      then
        Absyn.MATRIX(exp_list_list_1);
    case (Absyn.RANGE(start = exp1,step = SOME(exp2),stop = exp3),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,SOME(exp2_1),exp3_1);
    case (Absyn.RANGE(start = exp1,step = NONE(),stop = exp3),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,NONE(),exp3_1);
    case (Absyn.TUPLE(expressions = exp_list),old_comp,new_comp)
      equation
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.TUPLE(exp_list_1);
    case (Absyn.END(),_,_) then Absyn.END();
    case (Absyn.CODE(code = code),old_comp,new_comp)
      equation
        code_1 = renameComponentInCode(code, old_comp, new_comp);
      then
        Absyn.CODE(code_1);
    else
      equation
        print("-rename_component_in_exp failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExp;

protected function renameComponentInAlgorithms
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.AlgorithmItem> outAbsynAlgorithmItemLst;
algorithm
  outAbsynAlgorithmItemLst:=
  match (inAbsynAlgorithmItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.AlgorithmItem> res_1,res;
      Absyn.AlgorithmItem algorithm_1,algorithm_;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((algorithm_ :: res),old_comp,new_comp)
      equation
        res_1 = renameComponentInAlgorithms(res, old_comp, new_comp);
        algorithm_1 = algorithm_;
      then
        (algorithm_1 :: res_1);
  end match;
end renameComponentInAlgorithms;

protected function renameComponentInAlgorithm
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.Algorithm inAlgorithm1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Algorithm outAlgorithm;
algorithm
  outAlgorithm:=
  match (inAlgorithm1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef cr_1,cr,old_comp,new_comp;
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.AlgorithmItem> algs1_1,algs2_1,algs1,algs2,algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> exp_algs_list_1,exp_algs_list;
      String id;
      Absyn.FunctionArgs func_args_1,func_args;
    case (Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cr),value = exp),old_comp,new_comp) /* the old name for the component */
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.ALG_ASSIGN(Absyn.CREF(cr_1),exp_1);
    case (Absyn.ALG_ASSIGN(assignComponent = exp1 as Absyn.TUPLE(_),value = exp2),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.ALG_ASSIGN(exp1_1, exp2_1);
    case (Absyn.ALG_IF(ifExp = exp,trueBranch = algs1,elseIfAlgorithmBranch = exp_algs_list,elseBranch = algs2),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs1_1 = renameComponentInAlgorithms(algs1, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
        algs2_1 = renameComponentInAlgorithms(algs2, old_comp, new_comp);
      then
        Absyn.ALG_IF(exp_1,algs1_1,exp_algs_list_1,algs2_1);
    case (Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(id,NONE(),SOME(exp))},forBody = algs),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(exp_1))},algs_1);
    case (Absyn.ALG_WHILE(boolExpr = exp,whileBody = algs),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_WHILE(exp_1,algs_1);
    case (Absyn.ALG_WHEN_A(boolExpr = exp,whenBody = algs,elseWhenAlgorithmBranch = exp_algs_list),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
      then
        Absyn.ALG_WHEN_A(exp_1,algs_1,exp_algs_list_1);
    case (Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = func_args),old_comp,new_comp)
      equation
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        func_args_1 = renameComponentInFunctionArgs(func_args, old_comp, new_comp);
      then
        Absyn.ALG_NORETCALL(cr_1,func_args_1);
  end match;
end renameComponentInAlgorithm;

protected function renameComponentInExpAlgoritmsList
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> outTplAbsynExpAbsynAlgorithmItemLstLst;
algorithm
  outTplAbsynExpAbsynAlgorithmItemLstLst:=
  matchcontinue (inTplAbsynExpAbsynAlgorithmItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.AlgorithmItem> algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};
    case (((exp,algs) :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        res_1 = renameComponentInExpAlgoritmsList(res, old_comp, new_comp);
      then
        ((exp_1,algs_1) :: res_1);
    else
      equation
        print("-rename_component_in_exp_algoritms_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpAlgoritmsList;

protected function renameComponentInFunctionArgs
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.FunctionArgs inFunctionArgs1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs:=
  matchcontinue (inFunctionArgs1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exps_1,exps;
      list<Absyn.NamedArg> namedArg_1,namedArg;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2, exp;
      String id;
      Absyn.ForIterators iterators, iteratorsRenamed;
      Absyn.ReductionIterType iterType;
    case (Absyn.FUNCTIONARGS(args = exps,argNames = namedArg),old_comp,new_comp) /* the old name for the component */
      equation
        exps_1 = renameComponentInExpList(exps, old_comp, new_comp);
        namedArg_1 = renameComponentInNamedArgs(namedArg, old_comp, new_comp);
      then
        Absyn.FUNCTIONARGS(exps_1,namedArg_1);
    case (Absyn.FOR_ITER_FARG(exp, iterType, iterators),old_comp,new_comp)
      equation
        exp1_1 = renameComponentInExp(exp, old_comp, new_comp);
        iteratorsRenamed = renameComponentInIterators(iterators, old_comp, new_comp);
      then
        Absyn.FOR_ITER_FARG(exp1_1, iterType, iteratorsRenamed);
    else
      equation
        print("-rename_component_in_function_args failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInFunctionArgs;

protected function renameComponentInIterators
"@author adrpo
 renames the components from expression present in iterators:
 i in exp1, j in exp2, etc"
  input Absyn.ForIterators iterators;
  input Absyn.ComponentRef oldComp;
  input Absyn.ComponentRef newComp;
  output Absyn.ForIterators iteratorsRenamed;
algorithm
  iteratorsRenamed := list(match (it)
      local
        Absyn.Exp exp; String i;
      case (Absyn.ITERATOR(i, NONE(), SOME(exp)))
        equation
          exp = renameComponentInExp(exp, oldComp, newComp);
        then Absyn.ITERATOR(i, NONE(), SOME(exp));
      case (Absyn.ITERATOR(i, NONE(), NONE()))
        then Absyn.ITERATOR(i, NONE(), NONE());
    end match for it in iterators);
end renameComponentInIterators;

protected function renameComponentInNamedArgs
"author: x02lucpo
  helper function to renameComponentVisitor"
  input list<Absyn.NamedArg> inAbsynNamedArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.NamedArg> outAbsynNamedArgLst;
algorithm
  outAbsynNamedArgLst:=
  matchcontinue (inAbsynNamedArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.NamedArg> res_1,res;
      String id;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */
    case ((Absyn.NAMEDARG(argName = id,argValue = exp) :: res),old_comp,new_comp)
      equation
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInNamedArgs(res, old_comp, new_comp);
      then
        (Absyn.NAMEDARG(id,exp_1) :: res_1);
    else
      equation
        print("-rename_component_in_namedArgs failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInNamedArgs;

protected function renameComponentInExternalDecl
"author: x02lucpo
  helper function to renameComponentVisitor"
  input Absyn.ExternalDecl external_;
  input Absyn.ComponentRef old_comp;
  input Absyn.ComponentRef new_comp;
  output Absyn.ExternalDecl external_1;
algorithm
  print("-rename_component_in_external_decl not implemented yet\n");
  external_1 := external_;
end renameComponentInExternalDecl;

protected function replaceStartInComponentRef
"ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
  input Absyn.ComponentRef cr1;
  input Absyn.ComponentRef cr2;
  input Absyn.ComponentRef cr3;
  output Absyn.ComponentRef res;
algorithm
  res := replaceStartInComponentRef2(cr1, cr2, cr3)
  "Dump.print_component_ref_str(cr1) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(cr2) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(cr3) => cref_str_tmp &
  print \" \" & print cref_str_tmp &
  Dump.print_component_ref_str(res) => cref_str_tmp &
  print \" res \" & print cref_str_tmp & print \"\\n\"" ;
end replaceStartInComponentRef;

protected function replaceStartInComponentRef2
"ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3)
    local
      String id,id2,id3;
      Absyn.ComponentRef res,cr1,cr,cr2,cr3,orig_cr;
      list<Absyn.Subscript> a;
    case (Absyn.CREF_IDENT(name = id),Absyn.CREF_IDENT(name = id2),(res as Absyn.CREF_IDENT()))
      equation
        true = stringEq(id, id2);
      then
        res;
    case (Absyn.CREF_QUAL(name = id,subscripts = a,componentRef = cr1),Absyn.CREF_IDENT(name = id2),Absyn.CREF_IDENT(name = id3))
      equation
        true = stringEq(id, id2);
      then
        Absyn.CREF_QUAL(id3,a,cr1);
    case (Absyn.CREF_QUAL(name = id,subscripts = a,componentRef = cr1),Absyn.CREF_QUAL(name = id2,componentRef = cr2),Absyn.CREF_QUAL(name = id3,componentRef = cr3))
      equation
        true = stringEq(id, id2);
        cr = replaceStartInComponentRef2(cr1, cr2, cr3);
      then
        Absyn.CREF_QUAL(id3,a,cr);
    else inComponentRef1;
  end matchcontinue;
end replaceStartInComponentRef2;

protected function getComponentreplacementsrules
"author: x02lucpo
  this extracts all the componentreplacementrules by
  searching for new rules until the list-size does not
  grow any more"
  input GlobalScript.Components inComponents;
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  input Integer inInteger;
  output GlobalScript.ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules := matchcontinue (inComponents,inComponentReplacementRules,inInteger)
    local
      Integer len,old_len;
      GlobalScript.Components comps;
      GlobalScript.ComponentReplacementRules comp_reps,comp_reps_1,comp_reps_2,comp_reps_res;
    case (_,comp_reps,old_len)
      equation
        len = lengthComponentReplacementRules(comp_reps);
        (len == old_len) = true;
      then
        comp_reps;
    case (comps,comp_reps,_)
      equation
        old_len = lengthComponentReplacementRules(comp_reps);
        comp_reps_1 = getNewComponentreplacementsrulesForEachRule(comps, comp_reps);
        comp_reps_2 = joinComponentReplacementRules(comp_reps_1, comp_reps);
        comp_reps_res = getComponentreplacementsrules(comps, comp_reps_2, old_len);
      then
        comp_reps_res;
    else
      equation
        print("-get_componentreplacementsrules failed\n");
      then
        fail();
  end matchcontinue;
end getComponentreplacementsrules;

protected function getNewComponentreplacementsrulesForEachRule
"author: x02lucpo
 extracts the replacement rules from the components:
 {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},{REP_RULE(path_2,cr_1a,cr_1b)}
           => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}"
  input GlobalScript.Components inComponents;
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output GlobalScript.ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  matchcontinue (inComponents,inComponentReplacementRules)
    local
      GlobalScript.Components comps,comps_1;
      GlobalScript.ComponentReplacementRules comp_reps,comp_reps_1,res,comp_reps_2,comp_reps_3;
      Absyn.Path path;
      Absyn.ComponentRef cr1,cr2;
    case (_,comp_reps)
      equation
        true = emptyComponentReplacementRules(comp_reps);
      then
        comp_reps;
    case (comps,comp_reps)
      equation
        GlobalScript.COMPONENTREPLACEMENT(path,cr1,cr2) = firstComponentReplacement(comp_reps);
        comps_1 = getComponentsWithType(comps, path);
        comp_reps_1 = makeComponentsReplacementRulesFromComponents(comps_1, cr1, cr2);
        res = restComponentReplacementRules(comp_reps);
        comp_reps_2 = getNewComponentreplacementsrulesForEachRule(comps, res);
        comp_reps_3 = joinComponentReplacementRules(comp_reps_1, comp_reps_2);
      then
        comp_reps_3;
    else
      equation
        print(
          "-get_new_componentreplacementsrules_for_each_rule failed\n");
      then
        fail();
  end matchcontinue;
end getNewComponentreplacementsrulesForEachRule;

protected function makeComponentsReplacementRulesFromComponents
"author: x02lucpo

  this makes the replacementrules from each component in the first parameter:
  {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},cr_1a,cr_1b
            => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}"
  input GlobalScript.Components inComponents1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output GlobalScript.ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  matchcontinue (inComponents1,inComponentRef2,inComponentRef3)
    local
      GlobalScript.Components comps,res;
      Absyn.ComponentRef cr_from,cr_to,cr,cr_from_1,cr_to_1;
      Absyn.Path path_class,path_type;
      GlobalScript.ComponentReplacement comp_rep;
      GlobalScript.ComponentReplacementRules comps_1,comp_reps_res;
    case (comps,_,_)
      equation
        true = emptyComponents(comps);
      then
        GlobalScript.COMPONENTREPLACEMENTRULES({},0);
    case (comps,cr_from,cr_to)
      equation
        GlobalScript.COMPONENTITEM(path_class,_,cr) = firstComponent(comps);
        cr_from_1 = Absyn.joinCrefs(cr, cr_from);
        cr_to_1 = Absyn.joinCrefs(cr, cr_to);
        comp_rep = GlobalScript.COMPONENTREPLACEMENT(path_class,cr_from_1,cr_to_1);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, GlobalScript.COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    case (comps,cr_from,cr_to)
      equation
        GlobalScript.EXTENDSITEM(path_class,_) = firstComponent(comps);
        comp_rep = GlobalScript.COMPONENTREPLACEMENT(path_class,cr_from,cr_to);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, GlobalScript.COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    else
      equation
        print("-make_componentsReplacementRules_from_components failed\n");
      then
        fail();
  end matchcontinue;
end makeComponentsReplacementRulesFromComponents;

protected function emptyComponentReplacementRules
"author: x02lucpo
  returns true if the componentReplacementRules are empty"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inComponentReplacementRules)
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then true;
    else false;
  end match;
end emptyComponentReplacementRules;

protected function joinComponentReplacementRules
" author: x02lucpo
 joins two componentReplacementRules lists by union"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules1;
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules2;
  output GlobalScript.ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  match (inComponentReplacementRules1,inComponentReplacementRules2)
    local
      list<GlobalScript.ComponentReplacement> comps,comps1,comps2;
      Integer len,len1,len2;
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = comps1),GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = comps2))
      equation
        comps = List.union(comps1, comps2);
        len = listLength(comps);
      then
        GlobalScript.COMPONENTREPLACEMENTRULES(comps,len);
  end match;
end joinComponentReplacementRules;

protected function lengthComponentReplacementRules
"author: x02lucpo
  return the number of the componentReplacementRules"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inComponentReplacementRules)
    local Integer len;
    case (GlobalScript.COMPONENTREPLACEMENTRULES(the = len)) then len;
  end match;
end lengthComponentReplacementRules;

protected function firstComponentReplacement
"author: x02lucpo
 extract the first componentReplacement in
 the componentReplacementReplacementRules"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output GlobalScript.ComponentReplacement outComponentReplacement;
algorithm
  outComponentReplacement:=
  match (inComponentReplacementRules)
    local
      GlobalScript.ComponentReplacement comp;
      list<GlobalScript.ComponentReplacement> res;
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = {}))
      equation
        print("-first_componentReplacement failed: no componentReplacementReplacementRules\n");
      then
        fail();
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = (comp :: _))) then comp;
  end match;
end firstComponentReplacement;

protected function restComponentReplacementRules
"author: x02lucpo
 extract the rest componentReplacementRules from the components"
  input GlobalScript.ComponentReplacementRules inComponentReplacementRules;
  output GlobalScript.ComponentReplacementRules outComponentReplacementRules;
algorithm
  outComponentReplacementRules:=
  match (inComponentReplacementRules)
    local
      Integer len_1,len;
      GlobalScript.ComponentReplacement comp;
      list<GlobalScript.ComponentReplacement> res;
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then GlobalScript.COMPONENTREPLACEMENTRULES({},0);
    case (GlobalScript.COMPONENTREPLACEMENTRULES(componentReplacementLst = (_ :: res),the = len))
      equation
        len_1 = len - 1;
      then
        GlobalScript.COMPONENTREPLACEMENTRULES(res,len_1);
  end match;
end restComponentReplacementRules;

protected function getDependencyOnClass
"author:x02lucpo
 returns _all_ the GlobalScript.Components that the class depends on. It can be components or extends
  i.e if a class b has a component of type a and this is called with (<components>,\"a\")
  the it will also return b"
  input GlobalScript.Components inComponents;
  input Absyn.Path inPath;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      GlobalScript.Components comps_types,comps_types2,comps2,comps;
      String str;
      Absyn.Path path;
    case (comps,path)
      equation
        comps_types = getComponentsFromClass(comps, path);
        comps_types2 = getDependencyWithType(comps, comps_types, 0);
        str = dumpComponentsToString(comps_types);
        print("---------comps_types----------\n");
        print(str);
        print("===================\n");
        str = dumpComponentsToString(comps_types2);
        print("---------DEPENDENCIES----------\n");
        print(str);
        print("===================\n");
        comps2 = joinComponents(comps_types, comps_types2);
      then
        comps2;
    else
      equation
        print("-get_dependency_on_class failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyOnClass;

protected function getDependencyWithType
"author: x02lucpo
 helper function to get_dependency_on_class
 extracts all the components that have the
 dependency on type"
  input GlobalScript.Components inComponents1;
  input GlobalScript.Components inComponents2;
  input Integer inInteger3;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2,inInteger3)
    local
      Integer len,old_len;
      GlobalScript.Components comps,in_comps,in_comps_1,comps_1,out_comps;
    case (_,in_comps,old_len)
      equation
        len = lengthComponents(in_comps);
        (old_len == len) = true;
      then
        in_comps;
    case (comps,in_comps,_)
      equation
        len = lengthComponents(in_comps);
        in_comps_1 = getComponentsWithComponentsClass(comps, in_comps) "get_components_with_components_type(comps,in_comps) => in_comps\' &" ;
        comps_1 = joinComponents(in_comps_1, in_comps);
        out_comps = getDependencyWithType(comps, comps_1, len);
      then
        out_comps;
    else
      equation
        print("-get_dependency_with_type failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyWithType;

protected function getComponentsWithComponentsClass
"author x02lucpo
  extracts all the components with class == the class
  of the components in the second list from first list
  of GlobalScript.Components "
  input GlobalScript.Components inComponents1;
  input GlobalScript.Components inComponents2;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      GlobalScript.Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      GlobalScript.Component comp;
      Absyn.Path comp_path;
    case (_,in_comps)
      equation
        true = emptyComponents(in_comps);
      then
        GlobalScript.COMPONENTS({},0);
    case (comps,in_comps)
      equation
        GlobalScript.COMPONENTITEM(comp_path,_,_) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation
        GlobalScript.EXTENDSITEM(comp_path,_) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    else
      equation
        print("-get_components_with_components_class failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsClass;

protected function getComponentsWithComponentsType
"author x02lucpo
 extracts all the components with class == the type
 of the components in the second list from first list
 of Components"
  input GlobalScript.Components inComponents1;
  input GlobalScript.Components inComponents2;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      GlobalScript.Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      GlobalScript.Component comp;
      Absyn.Path comp_path;
    case (_,in_comps)
      equation
        true = emptyComponents(in_comps);
      then
        GlobalScript.COMPONENTS({},0);
    case (comps,in_comps)
      equation
        GlobalScript.COMPONENTITEM(_,comp_path,_) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation
        GlobalScript.EXTENDSITEM(_,comp_path) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    else
      equation
        print("-get_components_with_components_type failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsType;

protected function getComponentsFromClass
"author: x02lucpo
 extracts all the components that are in the class"
  input GlobalScript.Components inComponents;
  input Absyn.Path inPath;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      GlobalScript.Components comps,res,comps_1,comps_2;
      GlobalScript.Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_from_class(comps,path) => comps */
      equation
        true = emptyComponents(comps);
      then
        GlobalScript.COMPONENTS({},0);
    case (comps,path)
      equation
        ((comp as GlobalScript.COMPONENTITEM(comp_path,_,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        ((comp as GlobalScript.EXTENDSITEM(comp_path,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
      then
        comps_1;
    else
      equation
        print("-get_components_from_class failed\n");
      then
        GlobalScript.COMPONENTS({},0);
  end matchcontinue;
end getComponentsFromClass;

protected function getComponentsWithType
"author: x02lucpo
 extracts all the components that have the type"
  input GlobalScript.Components inComponents;
  input Absyn.Path inPath;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      GlobalScript.Components comps,res,comps_1,comps_2;
      GlobalScript.Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_with_type(comps,path) => comps */
      equation
        true = emptyComponents(comps);
      then
        GlobalScript.COMPONENTS({},0);
    case (comps,path)
      equation
        ((comp as GlobalScript.COMPONENTITEM(_,comp_path,_))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        ((comp as GlobalScript.EXTENDSITEM(_,comp_path))) = firstComponent(comps);
        true = Absyn.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
      then
        comps_1;
    else
      equation
        print("-get_components_with_type failed\n");
      then
        GlobalScript.COMPONENTS({},0);
  end matchcontinue;
end getComponentsWithType;

protected function extractAllComponents
"author: x02lucpo
 this traverse all the classes and
 extracts all the components and \"extends\""
  input Absyn.Program p;
  input Absyn.Path path;
  output GlobalScript.Components comps;
algorithm
  comps := match(p, path)
    local
        SCode.Program p_1;
        FCore.Graph env;

    // if we have a qualified class, a modification into it can affect any other
    case (_, _)
      equation
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(p_1);
        ((_,_,(comps,_,_))) = AbsynUtil.traverseClasses(p, NONE(), extractAllComponentsVisitor,(GlobalScript.COMPONENTS({},0),p,env), true) "traverse protected";
      then
        comps;
  end match;
end extractAllComponents;

protected function extractAllComponentsVisitor
"author: x02lucpo
  the visitor for traverse-classes that extracts all
  the components and extends from all classes"
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<GlobalScript.Components, Absyn.Program, FCore.Graph>> inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<GlobalScript.Components, Absyn.Program, FCore.Graph>> outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
algorithm
  outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv)
    local
      Absyn.Path path_1,pa_1,pa;
      Option<Absyn.Path> paOpt;
      FCore.Graph cenv,env;
      GlobalScript.Components comps_1,comps;
      Absyn.Class class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      SourceInfo file_info;
      Absyn.Program p;
    case (((class_ as Absyn.CLASS(name = id,info = file_info)),SOME(pa),(comps,p,env)))
      equation
        false = isReadOnly(file_info);
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(FCore.emptyCache(), cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,SOME(pa),(comps_1,p,env)));
    case (((class_ as Absyn.CLASS(name = id,info = file_info)),NONE(),(comps,p,env)))
      equation
        false = isReadOnly(file_info);
        path_1 = Absyn.IDENT(id);

        cenv = getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(FCore.emptyCache(),cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,NONE(),(comps_1,p,env)));
    case ((class_ ,paOpt,(comps,p,env))) then   ((class_,paOpt,(comps,p,env)));
  end matchcontinue;
end extractAllComponentsVisitor;

protected function isReadOnly
  input SourceInfo file_info;
  output Boolean res;
algorithm
  res := match(file_info)
    case(SOURCEINFO(isReadOnly = res)) then res;
  end match;
end isReadOnly;

protected function extractComponentsFromClass
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inClass,inPath,inComponents,inEnv)
    local
      GlobalScript.Components comps_1,comps;
      String id;
      Absyn.ClassDef classdef;
      SourceInfo info;
      Absyn.Path pa;
      FCore.Graph env;
    case (Absyn.CLASS(body = classdef),pa,comps,env) /* the QUALIFIED path */
      equation
        comps_1 = extractComponentsFromClassdef(pa, classdef, comps, env);
      then
        comps_1;
    else
      equation
        print("-extract_components_from_class failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromClass;

protected function extractComponentsFromClassdef
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input Absyn.ClassDef inClassDef;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:= matchcontinue (inPath,inClassDef,inComponents,inEnv)
    local
      GlobalScript.Components comps_1,comps;
      Absyn.Path pa,path;
      list<Absyn.ClassPart> parts;
      FCore.Graph env;
      list<Absyn.ElementArg> elementargs,elementarg;
      String id_ex;
    case (pa,Absyn.PARTS(classParts = parts),comps,env) /* the QUALIFIED path for the class */
      equation
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    case (pa,Absyn.DERIVED(typeSpec=Absyn.TPATH(_,_),arguments = elementargs),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env)
        "& print \"extract_components_from_classdef for DERIVED not implemented yet\\n\"" ;
      then
        comps_1;
    case (pa,Absyn.CLASS_EXTENDS(parts = parts),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    else inComponents;
  end matchcontinue;
end extractComponentsFromClassdef;

protected function extractComponentsFromClassparts
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:= matchcontinue (inPath,inAbsynClassPartLst,inComponents,inEnv)
    local
      GlobalScript.Components comps,comps_1,comps_2;
      FCore.Graph env;
      Absyn.Path pa;
      list<Absyn.ElementItem> elements;
      list<Absyn.ClassPart> res;

    case (_,{},comps,_) then comps;  /* the QUALIFIED path for the class */

    case (pa,(Absyn.PUBLIC(contents = elements) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;

    case (pa,(Absyn.PROTECTED(contents = elements) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;

    else inComponents;

  end matchcontinue;
end extractComponentsFromClassparts;

protected function extractComponentsFromElements
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inAbsynElementItemLst,inComponents,inEnv)
    local
      GlobalScript.Components comps,comps_1,comps_2;
      FCore.Graph env;
      Absyn.Path pa;
      Absyn.ElementSpec elementspec;
      list<Absyn.ElementItem> res;
      Absyn.ElementItem element;
    case (_,{},comps,_) then comps;  /* the QUALIFIED path for the class */
    case (pa,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = elementspec)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElements(pa, res, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec, comps_1, env);
      then
        comps_2;
    case (pa,(_ :: res),comps,env)
      equation
        comps = extractComponentsFromElements(pa, res, comps, env);
      then
        comps;
  end matchcontinue;
end extractComponentsFromElements;

protected function extractComponentsFromElementspec
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath;
  input Absyn.ElementSpec inElementSpec;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inElementSpec,inComponents,inEnv)
    local
      String id;
      FCore.Graph cenv,env;
      Absyn.Path path_1,path,pa;
      GlobalScript.Components comps_1,comps,comps_2;
      list<Absyn.ComponentItem> comp_items;
      GlobalScript.Component comp;
      list<Absyn.ElementArg> elementargs;
      FCore.Cache cache;

    case (pa,Absyn.COMPONENTS(typeSpec = Absyn.TPATH(path_1,_),components = comp_items),comps,env) /* the QUALIFIED path for the class */
      equation
        (cache,SCode.CLASS(name=id),cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1);
        path_1 = Absyn.IDENT(id);
        (cache,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        comps_1 = extractComponentsFromComponentitems(pa, path, comp_items, comps, env);
      then
        comps_1;
    case (pa,Absyn.EXTENDS(path = path_1,elementArg = elementargs),comps,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1)
        "print \"extract_components_from_elementspec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        comp = GlobalScript.EXTENDSITEM(pa,path);
        comps_1 = addComponentToComponents(comp, comps);
        comps_2 = extractComponentsFromElementargs(pa, elementargs, comps_1, env);
      then
        comps_2;
    else inComponents;
      /* rule  extract_components_from_class(class,pa,comps,env) => comps\'
         -------------------------------
         extract_components_from_elementspec(pa,Absyn.CLASSDEF(_,class), comps,env) => comps\' */
  end matchcontinue;
end extractComponentsFromElementspec;

protected function extractComponentsFromComponentitems
"author: x02lucpo
  help function to extractAllComponentsVisitor"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst3;
  input GlobalScript.Components inComponents4;
  input FCore.Graph inEnv5;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath1,inPath2,inAbsynComponentItemLst3,inComponents4,inEnv5)
    local
      GlobalScript.Components comps,comps_1,comps_2,comps_3;
      FCore.Graph env;
      Absyn.ComponentRef comp;
      Absyn.Path pa,path;
      String id;
      Option<Absyn.Modification> mod_opt;
      list<Absyn.ComponentItem> res;
    case (_,_,{},comps,_) then comps;  /* the QUALIFIED path for the class the fully qualifired path for the type of the component */
    case (pa,path,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,modification = mod_opt)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromComponentitems(pa, path, res, comps, env);
        comp = Absyn.CREF_IDENT(id,{});
        comps_2 = addComponentToComponents(GlobalScript.COMPONENTITEM(pa,path,comp), comps_1);
        comps_3 = extractComponentsFromModificationOption(pa, mod_opt, comps_2, env);
      then
        comps_3;
    else
      equation
        print("-extract_components_from_componentitems failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromComponentitems;

protected function extractComponentsFromElementargs
  input Absyn.Path inPath;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  matchcontinue (inPath,inAbsynElementArgLst,inComponents,inEnv)
    local
      Absyn.Path pa;
      GlobalScript.Components comps,comps_1,comps_2,comps_3;
      FCore.Graph env;
      Absyn.ElementSpec elementspec,elementspec2;
      list<Absyn.ElementArg> res;
      Absyn.ConstrainClass constrainclass;
      Option<Absyn.Modification> mod_opt;
      Absyn.ElementArg a;
    case (_,{},comps,_) then comps;  /* the QUALIFIED path for the class */
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(Absyn.CONSTRAINCLASS(elementspec2,_))) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec2, comps_1, env);
        comps_3 = extractComponentsFromElementargs(pa, res, comps_2, env);
      then
        comps_3;
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(_)) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(Absyn.MODIFICATION(modification = mod_opt) :: res),comps,env)
      equation
        comps_1 = extractComponentsFromModificationOption(pa, mod_opt, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(_ :: res),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, res, comps, env);
      then
        comps_1;
  end matchcontinue;
end extractComponentsFromElementargs;

protected function extractComponentsFromModificationOption
  input Absyn.Path inPath;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input GlobalScript.Components inComponents;
  input FCore.Graph inEnv;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  match (inPath,inAbsynModificationOption,inComponents,inEnv)
    local
      Absyn.Path pa;
      GlobalScript.Components comps,comps_1;
      FCore.Graph env;
      list<Absyn.ElementArg> elementargs;
    case (_,NONE(),comps,_) then comps;  /* the QUALIFIED path for the class */
    case (pa,SOME(Absyn.CLASSMOD(elementargs,_)),comps,env)
      equation
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env);
      then
        comps_1;
  end match;
end extractComponentsFromModificationOption;

protected function joinComponents
"author: x02lucpo
 joins two components lists by union"
  input GlobalScript.Components inComponents1;
  input GlobalScript.Components inComponents2;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  match (inComponents1,inComponents2)
    local
      list<GlobalScript.Component> comps,comps1,comps2;
      Integer len,len1,len2;
    case (GlobalScript.COMPONENTS(componentLst = comps1),GlobalScript.COMPONENTS(componentLst = comps2))
      equation
        comps = List.union(comps1, comps2);
        len = listLength(comps);
      then
        GlobalScript.COMPONENTS(comps,len);
  end match;
end joinComponents;

protected function existsComponentInComponents
"author: x02lucpo
 checks if a component exists in the components"
  input GlobalScript.Components inComponents;
  input GlobalScript.Component inComponent;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponents,inComponent)
    local
      GlobalScript.Component comp;
      Absyn.Path a,b,ap,bp;
      Absyn.ComponentRef c,cr;
      GlobalScript.Components comps;
      Boolean res;
    case (GlobalScript.COMPONENTS(componentLst = {}),_) then false;
    case (comps,GlobalScript.COMPONENTITEM(the1 = ap,the2 = bp,the3 = cr))
      equation
        GlobalScript.COMPONENTITEM(a,b,c) = firstComponent(comps);
        true = Absyn.pathEqual(a, ap);
        true = Absyn.pathEqual(b, bp);
        true = Absyn.crefEqual(c, cr);
      then
        true;
    case (comps,GlobalScript.EXTENDSITEM(the1 = ap,the2 = bp))
      equation
        GlobalScript.EXTENDSITEM(a,b) = firstComponent(comps);
        true = Absyn.pathEqual(a, ap);
        true = Absyn.pathEqual(b, bp);
      then
        true;
    case (comps,comp)
      equation
        res = existsComponentInComponents(comps, comp);
      then
        res;
  end matchcontinue;
end existsComponentInComponents;

protected function emptyComponents
"author: x02lucpo
  returns true if the components are empty"
  input GlobalScript.Components inComponents;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inComponents)
    case (GlobalScript.COMPONENTS(componentLst = {})) then true;
    else false;
  end match;
end emptyComponents;

protected function firstComponent
"author: x02lucpo
 extract the first component in the components"
  input GlobalScript.Components inComponents;
  output GlobalScript.Component outComponent;
algorithm
  outComponent:=
  match (inComponents)
    local
      GlobalScript.Component comp;
      list<GlobalScript.Component> res;
    case (GlobalScript.COMPONENTS(componentLst = {}))
      equation
        print("-first_component failed: no components\n");
      then
        fail();
    case (GlobalScript.COMPONENTS(componentLst = (comp :: _))) then comp;
  end match;
end firstComponent;

protected function restComponents
"author: x02lucpo
 extract the rest components from the compoents"
  input GlobalScript.Components inComponents;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  match (inComponents)
    local
      Integer len_1,len;
      GlobalScript.Component comp;
      list<GlobalScript.Component> res;
    case (GlobalScript.COMPONENTS(componentLst = {})) then GlobalScript.COMPONENTS({},0);
    case (GlobalScript.COMPONENTS(componentLst = (_ :: res),the = len))
      equation
        len_1 = len - 1;
      then
        GlobalScript.COMPONENTS(res,len_1);
  end match;
end restComponents;

protected function lengthComponents
"author: x02lucpo
  return the number of the components"
  input GlobalScript.Components inComponents;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inComponents)
    local Integer len;
    case (GlobalScript.COMPONENTS(the = len)) then len;
  end match;
end lengthComponents;

protected function addComponentToComponents
"author: x02lucpo
  add a component to components"
  input GlobalScript.Component inComponent;
  input GlobalScript.Components inComponents;
  output GlobalScript.Components outComponents;
algorithm
  outComponents:=
  match (inComponent,inComponents)
    local
      Integer len_1,len;
      GlobalScript.Component comp;
      list<GlobalScript.Component> comps;
    case (comp,GlobalScript.COMPONENTS(componentLst = comps,the = len))
      equation
        len_1 = len + 1;
      then
        GlobalScript.COMPONENTS((comp :: comps),len_1);
  end match;
end addComponentToComponents;

protected function dumpComponentsToString
"author: x02lucpo
  dumps all the components to string"
  input GlobalScript.Components inComponents;
  output String outString;
algorithm
  outString:=
  match (inComponents)
    local
      GlobalScript.Components res,comps;
      String s1,pa_str,path_str,cr_str,res_str;
      Absyn.Path cr_pa,pa,path;
      Absyn.ComponentRef cr;
    case (GlobalScript.COMPONENTS(componentLst = {})) then "";
    case ((comps as GlobalScript.COMPONENTS(componentLst = (GlobalScript.COMPONENTITEM(the1 = pa,the2 = path,the3 = cr) :: _))))
      equation
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        cr_pa = Absyn.crefToPath(cr);
        cr_str = Absyn.pathString(cr_pa);
        res_str = stringAppendList({s1,"cl: ",pa_str,"\t type: ",path_str,"\t\t name: ",cr_str,"\n"});
      then
        res_str;
    case ((comps as GlobalScript.COMPONENTS(componentLst = (GlobalScript.EXTENDSITEM(the1 = pa,the2 = path) :: _))))
      equation
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        res_str = stringAppendList({s1,"ex: ",pa_str,"\t exte: ",path_str,"\n"});
      then
        res_str;
  end match;
end dumpComponentsToString;

protected function isParameterElement
" Returns true if Element is a component of
   variability parameter, false otherwise."
  input Absyn.Element inElement;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inElement)
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.PARAM())))) then true;
    else false;
  end match;
end isParameterElement;

public function getParameterNames
 "Retrieves the names of all parameters in the class"
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output list<String> outList;
algorithm
  outList:=
  matchcontinue (path,inProgram)
    local
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<String> names;
      Absyn.Program p;
    case (_,p)
      equation
        cdef = getPathedClassInProgram(path, p);
        comps = getComponentsInClass(cdef);
        compelts = list(getComponentitemsInElement(c) for c guard isParameterElement(c) in comps);
        compelts_1 = List.flatten(compelts);
        names = List.map(compelts_1, getComponentitemName);
      then
        names;
    else {};
  end matchcontinue;
end getParameterNames;

public function getClassEnv
"Retrieves the environment of the class, including the
 frame of the class itself by partially instantiating it.
 It uses a LRU cache as to remember and speed things up"
  input Absyn.Program p;
  input Absyn.Path p_class;
  output FCore.Graph env_2;
protected
   Option<list<tuple<Absyn.Program, Absyn.Path, FCore.Graph>>> ocache;
   list<tuple<Absyn.Program, Absyn.Path, FCore.Graph>> cache, lcache = {};
   Absyn.Program po;
   Absyn.Path patho;
   FCore.Graph envo;
   Boolean invalidate = false;
algorithm
  // see if we have it already
  ocache := getGlobalRoot(Global.interactiveCache);
  if isSome(ocache) then
    SOME(cache) := ocache;
    for x in cache loop
      (po, patho, envo) := x;
      // found the path
      if Absyn.pathEqual(patho, p_class) then
        // make sure the program did not change
        if referenceEq(po, p) then
          //print("Got it from cache: " + Absyn.pathString(patho) + "\n");
          env_2 := envo;
          return;
        else // program not the same, invalidate cache
          //print("Invalidating: " + Absyn.pathString(patho) + "\n");
          invalidate := true;
          break;
        end if;
      end if;
    end for;

    // remove the entry if the program is not the same!
    if invalidate then
      SOME(cache) := ocache;
      cache := List.deleteMemberOnTrue(p_class, cache, matchPath);
      setGlobalRoot(Global.interactiveCache, SOME(cache));
    end if;

  end if;

  env_2 := getClassEnv_dispatch(p, p_class);

  // update cache
  ocache := getGlobalRoot(Global.interactiveCache);
  if isSome(ocache) then
    SOME(cache) := ocache;
    setGlobalRoot(Global.interactiveCache, SOME((p, p_class, env_2)::cache));
  else // is NONE, have our first one in
    setGlobalRoot(Global.interactiveCache, SOME((p, p_class, env_2)::{}));
  end if;
end getClassEnv;

function matchPath
  input Absyn.Path p;
  input tuple<Absyn.Program, Absyn.Path, FCore.Graph> entry;
  output Boolean matches;
protected
  Absyn.Path po;
algorithm
  (_, po, _) := entry;
  matches := Absyn.pathEqual(po, p);
end matchPath;

public function getClassEnv_dispatch
" Retrieves the environment of the class,
   including the frame of the class itself
   by partially instantiating it."
  input Absyn.Program p;
  input Absyn.Path p_class;
  output FCore.Graph env_2;
protected
  list<SCode.Element> p_1;
  FCore.Graph env,env_1,env2;
  SCode.Element cl;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  ClassInf.State ci_state;
  FCore.Cache cache;
algorithm
  p_1 := SCodeUtil.translateAbsyn2SCode(p);
  (cache,env) := Inst.makeEnvFromProgram(p_1);
  (cache, cl, env_1) := Lookup.lookupClass(cache,env, p_class);

  env_2 := matchcontinue (cl)
    local
      Absyn.Path tp;

    // Special case for derived classes. When instantiating a derived class, the environment
    // of the derived class is returned, which can be a totally different scope.
    case (SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr,classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(_,_))))
      then env_1;

    case (SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr))
      equation
        env2 = FGraph.openScope(env_1, encflag, id, FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
        (_,env_2,_,_,_) =
          Inst.partialInstClassIn(cache,env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, cl, SCode.PUBLIC(), {}, 0);
      then env_2;

    else FGraph.empty();
  end matchcontinue;
end getClassEnv_dispatch;

protected function setComponentProperties
"Sets the following \"properties\" of a component.
  - final
  - flow
  - stream
  - protected(true) or public(false)
  - replaceable
  - variablity: \"constant\" or \"discrete\" or \"parameter\" or \"\"
  - dynamic_ref: {inner, outer} - two boolean values.
  - causality: \"input\" or \"output\" or \"\"

  inputs:  (Absyn.Path, /* class */
            Absyn.ComponentRef, /* component_ref */
            bool, /* final = true */
            bool, /* flow = true */
            bool, /* stream = true */
            bool, /* protected = true, public=false */
            bool,  /* replaceable = true */
            string, /* parallelism */
            string, /* variability */
            bool list, /* dynamic_ref, two booleans */
            string, /* causality */
            Absyn.Program,
            //string, /*isField*/)
  outputs: (string, Absyn.Program)"
  input Absyn.Path inPath1;
  input Absyn.ComponentRef inComponentRef2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  // input String inString6;  //parallelism removed for now
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  input Absyn.Program inProgram10;
  // input String inString11;  //isField also removed
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inPath1,inComponentRef2,inFinal,inFlow,inStream,inProtected,inReplaceable,/*inString6,*/inString7,inBooleanLst8,inString9,inProgram10/*,inString11*/)
    local
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.Path p_class;
      String varname,variability,causality,isField;
      Boolean finalPrefix,flowPrefix,streamPrefix,prot,repl;
      list<Boolean> dyn_ref;
    case (p_class,Absyn.CREF_IDENT(name = varname),finalPrefix,flowPrefix,streamPrefix,prot,repl, /*parallelism,*/ variability,dyn_ref,causality,p as Absyn.PROGRAM()/*,isField*/)
      equation
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentPropertiesInClass(cdef, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, "" /*parallelism*/, variability, dyn_ref, causality, "" /*isField*/);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        ("Ok",newp);
    else ("Error",inProgram10);
  end matchcontinue;
end setComponentProperties;

protected function setComponentPropertiesInClass
"Helper function to setComponentProperties.
  inputs:  (Absyn.Class,
              string, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* prot */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs: Absyn.Class "
  input Absyn.Class inClass1;
  input String inString2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  input String inString6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  input String inString10; /*isField*/
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inString2,inFinal,inFlow,inStream,inProtected,inReplaceable,inString6,inString7,inBooleanLst8,inString9, inString10)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,varname,parallelism,variability,causality,bcname,isField;
      Boolean p,f,e,finalPrefix,flowPrefix,streamPrefix,prot,repl;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      list<Boolean> dyn_ref;
      list<Absyn.ElementArg> mod;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    /* a class with parts! */
    case (Absyn.CLASS(name = id,
                      partialPrefix = p,
                      finalPrefix = f,
                      encapsulatedPrefix = e,
                      restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),
                      info = file_info),varname,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality,isField)
      equation
        parts_1 = setComponentPropertiesInClassparts(parts, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality, isField);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,cmt),file_info);

    /* adrpo: handle also an extended class with parts! */
    case (Absyn.CLASS(name = id,
                      partialPrefix = p,
                      finalPrefix = f,
                      encapsulatedPrefix = e,
                      restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname, modifications=mod, parts = parts,ann = ann,comment = cmt),
                      info = file_info),varname,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality,isField)
      equation
        parts_1 = setComponentPropertiesInClassparts(parts, varname, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality, isField);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,mod,cmt,parts_1,ann),file_info);

  end match;
end setComponentPropertiesInClass;

protected function setComponentPropertiesInClassparts
" Helper function to setComponentPropertiesInClass.
   inputs: (Absyn.ClassPart list,
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* prot */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
   outputs: Absyn.ClassPart list"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inProtected;
  input Boolean inReplaceable;
  input String inString6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  input String inString10; /*isField*/
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inIdent2,inFinal,inFlow,inStream,inProtected,inReplaceable,inString6,inString7,inBooleanLst8,inString9,inString10)
    local
      list<Absyn.ElementItem> publst,publst_1,protlst,protlst_1,elts_1,elts;
      Absyn.Element elt,elt_1;
      list<Absyn.ClassPart> parts_1,parts_2,parts,rest,rest_1;
      String cr,parallelism,variability,causality,isField;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl,prot;
      list<Boolean> dyn_ref;
      Absyn.ClassPart part;

    case ({},_,_,_,_,_,_,_,_,_,_,_) then {};
    case (parts,cr,finalPrefix,flowPrefix,streamPrefix,true,repl,parallelism,variability,dyn_ref,causality,isField) /* public moved to protected protected moved to public */
      equation
        publst = getPublicList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), publst);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality, isField);
        publst_1 = deleteOrUpdateComponentFromElementitems(cr, publst, NONE()); // TODO: Do not move the component...
        protlst = getProtectedList(parts);
        protlst_1 = listAppend(protlst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replaceProtectedList(parts, protlst_1);
        parts_2 = replacePublicList(parts_1, publst_1);
      then
        parts_2;

    case (parts,cr,finalPrefix,flowPrefix,streamPrefix,false,repl,parallelism,variability,dyn_ref,causality,isField) /* protected moved to public protected attr not changed. */
      equation
        protlst = getProtectedList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), protlst);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality, isField);
        protlst_1 = deleteOrUpdateComponentFromElementitems(cr, protlst, NONE()); // TODO: Do not move the component...
        publst = getPublicList(parts);
        publst_1 = listAppend(publst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replacePublicList(parts, publst_1);
        parts_2 = replaceProtectedList(parts_1, protlst_1);
      then
        parts_2;

    case ((Absyn.PUBLIC(contents = elts) :: rest),cr,finalPrefix,flowPrefix,streamPrefix,prot,repl,parallelism,variability,dyn_ref,causality,isField) /* protected attr not changed. protected attr not changed, 2. */
      equation
        rest = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality,isField);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality,isField);
      then
        (Absyn.PUBLIC(elts_1) :: rest);

    case ((Absyn.PROTECTED(contents = elts) :: rest),cr,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality,isField) /* protected attr not changed, 2. */
      equation
        rest = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality, isField);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, finalPrefix, flowPrefix, streamPrefix, repl, parallelism, variability, dyn_ref, causality, isField);
      then
        (Absyn.PROTECTED(elts_1) :: rest);

    case ((part :: rest),cr,finalPrefix,flowPrefix,streamPrefix, prot,repl,parallelism,variability,dyn_ref,causality,isField) /* protected attr not changed, 3. */
      equation
        rest_1 = setComponentPropertiesInClassparts(rest, cr, finalPrefix, flowPrefix, streamPrefix, prot, repl, parallelism, variability, dyn_ref, causality, isField);
      then
        (part :: rest_1);

  end matchcontinue;
end setComponentPropertiesInClassparts;

protected function setComponentPropertiesInElementitems
"Helper function to setComponentPropertiesInClassparts.
  inputs:  (Absyn.ElementItem list,
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string, /* causality */
              string) /* isField */
  outputs:  Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inReplaceable;
  input String inString5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  input String inString9; /*isfield*/
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst1,inIdent2,inFinal,inFlow,inStream,inReplaceable,inString5,inString6,inBooleanLst7,inString8,inString9)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String cr,prl,va,cau,isf;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl;
      list<Boolean> dr;
      Absyn.ElementItem elitem;

    case ({},_,_,_,_,_,_,_,_,_,_) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),cr,finalPrefix,flowPrefix,streamPrefix, repl,prl,va,dr,cau, isf)
      equation
        res = setComponentPropertiesInElementitems(rest, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau, isf);
        elt_1 = setComponentPropertiesInElement(elt, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau, isf);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);

    case ((elitem :: rest),cr,finalPrefix,flowPrefix,streamPrefix,repl,prl,va,dr,cau,isf)
      equation
        res = setComponentPropertiesInElementitems(rest, cr, finalPrefix, flowPrefix, streamPrefix, repl, prl, va, dr, cau, isf);
      then
        (elitem :: res);
  end matchcontinue;
end setComponentPropertiesInElementitems;

protected function setComponentPropertiesInElement
"Helper function to e.g. setComponentPropertiesInElementitems.
  inputs:  (Absyn.Element,
              Absyn.Ident,
              bool, /* final */
              bool, /* flow */
              bool, /* stream */
              bool, /* repl */
              string, /* parallelism */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string,  /* causality */
              string)  /* isField */
  outputs: Absyn.Element"
  input Absyn.Element inElement1;
  input Absyn.Ident inIdent2;
  input Boolean inFinal;
  input Boolean inFlow;
  input Boolean inStream;
  input Boolean inReplaceable;
  input String inString5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  input String inString9; /* isField*/
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement1,inIdent2,inFinal,inFlow,inStream,inReplaceable,inString5,inString6,inBooleanLst7,inString8,inString9)
    local
      Option<Absyn.RedeclareKeywords> redeclkw_1,redeclkw;
      Absyn.InnerOuter inout_1,inout;
      Absyn.ElementSpec spec_1,spec;
      String cr,va,cau,prl,isf;
      list<Absyn.ComponentItem> ellst;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      Boolean finalPrefix,flowPrefix,streamPrefix,repl;
      list<Boolean> dr;
      Absyn.Element elt;
    case (Absyn.ELEMENT(redeclareKeywords = redeclkw,
          specification = (spec as Absyn.COMPONENTS(components = ellst)),info = info,constrainClass = constr),
          cr,finalPrefix,flowPrefix,streamPrefix,repl,prl,va,dr,cau,isf)
      equation
        getCompitemNamed(Absyn.CREF_IDENT(cr,{}), ellst);
        redeclkw_1 = setReplaceableKeywordAttributes(redeclkw, repl);
        inout_1 = setInnerOuterAttributes(dr);
        spec_1 = setComponentPropertiesInElementspec(spec, cr, flowPrefix, streamPrefix, prl, va, cau, isf);
      then
        Absyn.ELEMENT(finalPrefix,redeclkw_1,inout_1,spec_1,info,constr);
    else inElement1;
  end matchcontinue;
end setComponentPropertiesInElement;

protected function setReplaceableKeywordAttributes
"Sets The RedeclareKeywords of an Element given a boolean \'replaceable\'.
  inputs:  (Absyn.RedeclareKeywords option,
              bool /* repl */)
  outputs: Absyn.RedeclareKeywords option ="
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  input Boolean inBoolean;
  output Option<Absyn.RedeclareKeywords> outAbsynRedeclareKeywordsOption;
algorithm
  outAbsynRedeclareKeywordsOption:=
  match (inAbsynRedeclareKeywordsOption,inBoolean)
    case (NONE(),false) then NONE();  /* false */
    case (SOME(Absyn.REPLACEABLE()),false) then NONE();
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),false) then SOME(Absyn.REDECLARE());
    case (SOME(Absyn.REDECLARE()),false) then SOME(Absyn.REDECLARE());
    case (NONE(),true) then SOME(Absyn.REPLACEABLE());  /* true */
    case (SOME(Absyn.REDECLARE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE());
    case (SOME(Absyn.REPLACEABLE()),true) then SOME(Absyn.REPLACEABLE());
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE());
  end match;
end setReplaceableKeywordAttributes;

protected function setInnerOuterAttributes
"Sets InnerOuter according to a list of two booleans, {inner, outer}."
  input list<Boolean> inBooleanLst;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  outInnerOuter:=
  match (inBooleanLst)
    case ({false,false}) then Absyn.NOT_INNER_OUTER();
    case ({true,false}) then Absyn.INNER();
    case ({false,true}) then Absyn.OUTER();
    case ({true,true}) then Absyn.INNER_OUTER();
  end match;
end setInnerOuterAttributes;

protected function setComponentPropertiesInElementspec
"Sets component attributes on an elements spec if identifier matches.
  inputs:  (Absyn.ElementSpec,
              Absyn.Ident,
              bool, /* flow */
              bool, /* stream */
              string, /* parallelism */
              string, /* variability */
              string /* causality */
              string /* IsField */
  outputs:  Absyn.ElementSpec"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Ident inIdent2;
  input Boolean inFlow;
  input Boolean inStream;
  input String inString3;
  input String inString4;
  input String inString5;
  input String inString6;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  matchcontinue (inElementSpec1,inIdent2,inFlow,inStream,inString3,inString4,inString5,inString6)
    local
      Absyn.ElementAttributes attr_1,attr;
      Absyn.TypeSpec path;
      list<Absyn.ComponentItem> items;
      String cr,va,cau,prl,isf;
      Boolean flowPrefix,streamPrefix;
      Absyn.ElementSpec spec;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = path,components = items),cr,flowPrefix,streamPrefix,prl,va,cau,isf)
      equation
        itemsContainCompname(items, cr);
        attr_1 = setElementAttributes(attr, flowPrefix, streamPrefix, prl, va, cau, isf);
      then
        Absyn.COMPONENTS(attr_1,path,items);

    else inElementSpec1;
  end matchcontinue;
end setComponentPropertiesInElementspec;

protected function itemsContainCompname
"Checks if a list of ElementItems contain a component named \'cr\'."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
algorithm
  _:=
  matchcontinue (inAbsynComponentItemLst,inIdent)
    local
      String cr1,cr2,cr;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = cr1)) :: _),cr2)
      equation
        true = stringEq(cr1, cr2);
      then
        ();
    case ((_ :: rest),cr)
      equation
        itemsContainCompname(rest, cr);
      then
        ();
  end matchcontinue;
end itemsContainCompname;

protected function setElementAttributes
"Sets  attributes associated with ElementAttribues.
  inputs: (Absyn.ElementAttributes,
             bool, /* flow */
             bool, /* stream */
             string, /* parallelism */
             string, /* variability */
             string, /* causality */
             string) /* nonfield/field */
  outputs: Absyn.ElementAttributes"
  input Absyn.ElementAttributes inElementAttributes1;
  input Boolean inFlow;
  input Boolean inStream;
  input String inString2;
  input String inString3;
  input String inString4;
  input String inString5;
  output Absyn.ElementAttributes outElementAttributes;
algorithm
  outElementAttributes:=
  match (inElementAttributes1,inFlow,inStream,inString2,inString3,inString4,inString5)
    local
      Absyn.Parallelism pa_1;
      Absyn.Variability va_1;
      Absyn.Direction cau_1;
      Absyn.IsField fi_1;
      list<Absyn.Subscript> dim;
      Boolean flowPrefix,streamPrefix;
      String va,cau,prl,fi;
    case (Absyn.ATTR(arrayDim = dim),flowPrefix,streamPrefix,prl,va,cau,fi)
      equation
        pa_1 = setElementParallelism(prl);
        va_1 = setElementVariability(va);
        cau_1 = setElementCausality(cau);
        fi_1 = setElementIsField(fi);
      then
        Absyn.ATTR(flowPrefix,streamPrefix,pa_1,va_1,cau_1,fi_1,dim);
  end match;
end setElementAttributes;

protected function setElementParallelism
"Sets Parallelism according to string value."
  input String inString;
  output Absyn.Parallelism outParallelism;
algorithm
  outParallelism:=
  match (inString)
    case ("") then Absyn.NON_PARALLEL();
    case ("parglobal") then Absyn.PARGLOBAL();
    case ("parlocal") then Absyn.PARLOCAL();
  end match;
end setElementParallelism;

protected function setElementVariability
"Sets Variability according to string value."
  input String inString;
  output Absyn.Variability outVariability;
algorithm
  outVariability:=
  match (inString)
    case ("") then Absyn.VAR();
    case ("discrete") then Absyn.DISCRETE();
    case ("parameter") then Absyn.PARAM();
    case ("constant") then Absyn.CONST();
  end match;
end setElementVariability;

protected function setElementCausality
"Sets Direction (causality) according to string value."
  input String inString;
  output Absyn.Direction outDirection;
algorithm
  outDirection:=
  match (inString)
    case ("") then Absyn.BIDIR();
    case ("input") then Absyn.INPUT();
    case ("output") then Absyn.OUTPUT();
  end match;
end setElementCausality;

protected function setElementIsField
"Sets isField attribute according to string value."
  input String inString;
  output Absyn.IsField outIsField;
algorithm
  outIsField:=
  match (inString)
    case ("") then Absyn.NONFIELD();
    case ("nonfield") then Absyn.NONFIELD();
    case ("field")
      equation
        if not Flags.getConfigEnum(Flags.GRAMMAR) == Flags.PDEMODELICA then
          Error.addMessage(Error.PDEModelica_ERROR,
            {"Fields not supported in standard modelica. Enable PDEModelica usign flag --grammar=\"PDEModelica\"."});
          fail();
        end if;
      then Absyn.FIELD();
  end match;
end setElementIsField;

protected function selectString
" author: adrpo@ida
   date  : 2006-02-05
   if bool is true select first string, otherwise the second one"
  input Boolean inSelector;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  match (inSelector,inString2,inString3)
    local String s1,s2;
    case (true,s1,_) then s1;
    case (false,_,s2) then s2;
  end match;
end selectString;

protected function getCrefInfo
" author: adrpo@ida
   date  : 2005-11-03, changed 2006-02-05 to match new SOURCEINFO
   Retrieves the Info attribute of a Class.
   When parsing classes, the source:
   file name + isReadOnly + start lineno + start columnno + end lineno + end columnno is added to the Class
   definition and to all Elements, see SourceInfo. This function retrieves the
   Info contents.
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.Program)
   outputs:   string"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String id,filename,str_sline,str_scol,str_eline,str_ecol,s,str_readonly;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        Absyn.CLASS(info = SOURCEINFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)) = cdef;
        filename = Util.testsuiteFriendly(filename);
        str_sline = intString(sline);
        str_scol = intString(scol);
        str_eline = intString(eline);
        str_ecol = intString(ecol);
        str_readonly = selectString(isReadOnly, "readonly", "writable");
        s = stringAppendList({
               "{",
               filename, ",",
               str_readonly, ",",
               str_sline, ",",
               str_scol, ",",
               str_eline, ",",
               str_ecol,
               "}"});
      then
        s;
    else "Error";
  end matchcontinue;
end getCrefInfo;

protected function getImportString
" author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementType "
  input Absyn.Import inImport;
  output String outString;
algorithm
  outString:=
  match (inImport)
    local
      String path_str,str,id;
      Absyn.Path path;
    case (Absyn.NAMED_IMPORT(name = id,path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=named, id=",id,", path=",path_str});
      then
        str;
    case (Absyn.QUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=qualified, path=",path_str});
      then
        str;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"kind=unqualified, path=",path_str});
      then
        str;
  end match;
end getImportString;

protected function getElementType
" author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementInfo"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString:=
  match (inElementSpec)
    local
      String path_str,str,import_str,typename,flowPrefixstr,streamPrefixstr,variability_str,dir_str,names_str;
      Absyn.Path path;
      Absyn.TypeSpec typeSpec;
      Absyn.Import import_;
      list<String> names;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
    case (Absyn.EXTENDS(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation
        import_str = getImportString(import_);
        str = stringAppendList({"elementtype=import, ",import_str});
      then
        str;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = typeSpec,components = lst))
      equation
        typename = Dump.unparseTypeSpec(typeSpec);
        names = getComponentItemsNameAndComment(lst,false);
        flowPrefixstr = attrFlowStr(attr);
        streamPrefixstr = attrStreamStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        names_str = stringDelimitList(names, ", ");
        str = stringAppendList({"elementtype=component, typename=",typename,", names={", names_str,"}, flow=",flowPrefixstr,
        ", stream=",streamPrefixstr,", variability=",variability_str,", direction=", dir_str});
      then
        str;
  end match;
end getElementType;

protected function getElementInfo
" author: adrpo@ida
   date  : 2005-11-11
   helperfunction to constructElementInfo & getElementsInfo"
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementItem)
    local
      String finalPrefix,repl,inout_str,str_restriction,element_str,sline_str,scol_str,eline_str,ecol_str,readonly_str,str,id,file;
      Boolean r_1,f,p,fi,e,isReadOnly;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.Restriction restr;
      Integer sline,scol,eline,ecol;
      Absyn.ElementSpec elementSpec;
      SourceInfo info;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,restriction = restr,info = SOURCEINFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))))) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = innerOuterStr(inout);
        str_restriction = Absyn.restrString(restr) "compile the classdef string" ;
        element_str = stringAppendList(
          {"elementtype=classdef, classname=",id,
          ", classrestriction=",str_restriction});
        file = Util.testsuiteFriendly(file);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = elementSpec,info = SOURCEINFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))) /* if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = innerOuterStr(inout);
        element_str = getElementType(elementSpec);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        file = Util.testsuiteFriendly(file);
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (Absyn.LEXER_COMMENT()) then "elementtype=comment";
    else "elementtype=annotation";  /* for annotations we don\'t care */
  end matchcontinue;
end getElementInfo;

protected function constructElementsInfo
" author: adrpo@ida
   date  : 2005-11-11
   helperfunction to getElementsInfo
   inputs:  (string /* \"public\" or \"protected\" */, Absyn.ElementItem list)
   outputs:  string"
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString,inAbsynElementItemLst)
    local
      String visibility_str,s1,element_str,res,s2;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;
    case (_,{}) then "";
    case (visibility_str,(current :: {})) /* deal with the last element */
      equation
        s1 = getElementInfo(current);
        element_str = stringAppendList({"{ rec(elementvisibility=",visibility_str,", ",s1,") }"});
        res = stringAppendList({element_str,"\n"});
      then
        res;
    case (visibility_str,(current :: rest))
      equation
        s1 = getElementInfo(current);
        element_str = stringAppendList({"{ rec(elementvisibility=",visibility_str,", ",s1,") }"});
        s2 = constructElementsInfo(visibility_str, rest);
        res = stringAppendList({element_str,",\n",s2});
      then
        res;
  end matchcontinue;
end constructElementsInfo;

protected function appendNonEmptyStrings
" author: adrpo@ida
   date  : 2005-11-11
   helper to get_elements_info
   input: \"\", \"\", \",\" => \"\"
          \"some\", \"\", \",\" => \"some\"
          \"some\", \"some\", \",\" => \"some, some\""
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  match (inString1,inString2,inString3)
    local String s1,s2,str,delimiter;
    case ("","",_) then "";
    case (s1,"",_) then s1;
    case ("",s2,_) then s2;
    case (s1,s2,delimiter)
      equation
        str = stringAppendList({s1,delimiter,s2});
      then
        str;
  end match;
end appendNonEmptyStrings;

protected function getElementsInfo
" author: adrpo@ida
   date  : 2005-11-11, changed 2006-02-06 to mirror the new SOURCEINFO
   Retrieves the Info attribute of an element.
   When parsing elements of the class composition, the source:
    -> file name + readonly + start lineno + start columnno + end lineno + end columnno is added to the Element
   and to the Class definition, see SourceInfo.
   This function retrieves the Info contents of the elements of a class."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      String i,public_str,protected_str,elements_str,str;
      Boolean f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list,protected_elementitem_list;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    /* a class with parts */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_str = constructElementsInfo("public", public_elementitem_list);
        protected_str = constructElementsInfo("protected", protected_elementitem_list);
        elements_str = appendNonEmptyStrings(public_str, protected_str, ", ");
        str = stringAppendList({"{ ",elements_str," }"});
      then
        str;
    /* an extended class with parts: model extends M end M; */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,Absyn.CLASS_EXTENDS(parts=parts),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_str = constructElementsInfo("public", public_elementitem_list);
        protected_str = constructElementsInfo("protected", protected_elementitem_list);
        elements_str = appendNonEmptyStrings(public_str, protected_str, ", ");
        str = stringAppendList({"{ ",elements_str," }"});
      then
        str;
    /* otherwise */
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(_,_,_,_,_,_,_) = getPathedClassInProgram(modelpath, p) "there are no elements in DERIVED, ENUMERATION, OVERLOAD, CLASS_EXTENDS and PDER
        maybe later we can give info about that also" ;
      then
        "{ }";
    else "Error";
  end matchcontinue;
end getElementsInfo;

public function getSourceFile
" author: PA
   Retrieves the Source file attribute of a Class.
   When parsing classes, the source file name is added to the Class
   definition and to all Elements, see Absyn. This function retrieves the
   source file of the Class.
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.Program)
   outputs: string"
  input Absyn.Path p_class;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (p_class,inProgram)
    local
      Absyn.Class cdef;
      String filename;
      Absyn.Program p;
    case (_,p) /* class */
      equation
        cdef = getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
      then filename;
    else "";
  end matchcontinue;
end getSourceFile;

public function setSourceFile
" author: PA
   Sets the source file of a Class. Is for instance used
   when adding a new class to an aldready stored package.
   The class should then have the same file as the package.
   inputs:   (Absyn.ComponentRef, /* class */
                string, /* filename */
                Absyn.Program)
   outputs: (string, Absyn.Program)"
  input Absyn.Path path;
  input String inString;
  input Absyn.Program inProgram;
  output Boolean success;
  output Absyn.Program outProgram;
algorithm
  (success,outProgram):=
  matchcontinue (path,inString,inProgram)
    local
      Absyn.Class cdef,cdef_1;
      Absyn.Within within_;
      Absyn.Program newp,p;
      String filename;

    case (_,filename,p as Absyn.PROGRAM())
      equation
        cdef = getPathedClassInProgram(path, p);
        within_ = buildWithin(path);
        cdef_1 = Absyn.setClassFilename(cdef, filename);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (true,newp);
    else (false,inProgram);
  end matchcontinue;
end setSourceFile;

public function removeExtendsModifiers
"Removes the extends modifiers of a class."
  input Absyn.Path inClassPath;
  input Absyn.Path inBaseClassPath;
  input Absyn.Program inProgram;
  input Boolean keepRedeclares;
  output Absyn.Program outProgram;
  output Boolean outResult;
algorithm
  (outProgram,outResult) := matchcontinue (inClassPath,inBaseClassPath,inProgram)
    local
      Absyn.Path p_class,inherit_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      FCore.Graph env;
      Absyn.Program newp,p;

    case (p_class,inherit_class,p as Absyn.PROGRAM())
      equation
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        cdef_1 = removeExtendsModifiersInClass(cdef, inherit_class, env, keepRedeclares);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp, true);
    else (inProgram, false);
  end matchcontinue;
end removeExtendsModifiers;

protected function removeExtendsModifiersInClass
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input FCore.Graph inEnv;
  input Boolean keepRedeclares = false;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass,inPath,inEnv)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.Path inherit_name;
      FCore.Graph env;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),info = file_info),
          inherit_name,env)
      equation
        parts_1 = removeExtendsModifiersInClassparts(parts, inherit_name, env, keepRedeclares);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,cmt),file_info);
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,parts = parts,modifications=modif,ann=ann,comment = cmt),info = file_info),
          inherit_name,env)
      equation
        parts_1 = removeExtendsModifiersInClassparts(parts, inherit_name, env, keepRedeclares);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1,ann),file_info);
  end match;
end removeExtendsModifiersInClass;

protected function removeExtendsModifiersInClassparts
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Path inPath;
  input FCore.Graph inEnv;
  input Boolean keepRedeclares;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inPath,inEnv, keepRedeclares)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      Absyn.Path inherit;
      FCore.Graph env;
      Absyn.ClassPart elt;

    case ({},_,_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),inherit,env,_)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env, keepRedeclares);
        elts_1 = removeExtendsModifiersInElementitems(elts, inherit, env, keepRedeclares);
      then
        (Absyn.PUBLIC(elts_1) :: res);

    case ((Absyn.PROTECTED(contents = elts) :: rest),inherit,env,_)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env, keepRedeclares);
        elts_1 = removeExtendsModifiersInElementitems(elts, inherit, env, keepRedeclares);
      then
        (Absyn.PROTECTED(elts_1) :: res);

    case ((elt :: rest),inherit,env,_)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env,  keepRedeclares);
      then
        (elt :: res);

  end matchcontinue;
end removeExtendsModifiersInClassparts;

protected function removeExtendsModifiersInElementitems
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Path inPath;
  input FCore.Graph inEnv;
  input Boolean keepRedeclares;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inPath,inEnv,keepRedeclares)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      Absyn.Path inherit;
      FCore.Graph env;
      Absyn.ElementItem elitem;

    case ({},_,_,_) then {};

    case ((Absyn.ELEMENTITEM(element = elt) :: rest),inherit,env,_)
      equation
        res = removeExtendsModifiersInElementitems(rest, inherit, env, keepRedeclares);
        elt_1 = removeExtendsModifiersInElement(elt, inherit, env, keepRedeclares);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);

    case ((elitem :: rest),inherit,env,_)
      equation
        res = removeExtendsModifiersInElementitems(rest, inherit, env, keepRedeclares);
      then
        (elitem :: res);
  end matchcontinue;
end removeExtendsModifiersInElementitems;

protected function removeExtendsModifiersInElement
  input Absyn.Element inElement;
  input Absyn.Path inPath;
  input FCore.Graph inEnv;
  input Boolean keepRedeclares;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement,inPath,inEnv)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      Absyn.Path path,inherit,path_1;
      list<Absyn.ElementArg> eargs,eargs_1;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      FCore.Graph env;
      Absyn.Element elt;
      Option<Absyn.Annotation> annOpt;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs,annotationOpt=annOpt),info = info,constrainClass = constr),
      inherit,env)
      equation
        (_,path_1) = Inst.makeFullyQualified(FCore.emptyCache(),env, path);
        true = Absyn.pathEqual(inherit, path_1);
        eargs = if not keepRedeclares then {} else list(e for e guard(match e case Absyn.REDECLARATION() then true; else false; end match) in eargs);
      then
        Absyn.ELEMENT(f,r,i,Absyn.EXTENDS(path,eargs,annOpt),info,constr);
    else inElement;
  end matchcontinue;
end removeExtendsModifiersInElement;

protected function setExtendsModifierValue
" This function sets the submodifier value of an
   extends clause in a Class. For instance,
   model test extends A(p1=3,p2(z=3));end test;
   setExtendsModifierValue(test,A,p1,Code(=4)) => OK
   => model test extends A(p1=4,p2(z=3));end test;
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.ComponentRef, /* inherit class */
                Absyn.ComponentRef, /* subident */
                Absyn.Modification,
                Absyn.Program)
   outputs:  (Absyn.Program,string)"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Modification inModification4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inModification4,inProgram5)
    local
      Absyn.Path p_class,inherit_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      FCore.Graph env;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,inheritclass,subident;
      Absyn.Modification mod;

    case (class_,inheritclass,subident,mod,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        inherit_class = Absyn.crefToPath(inheritclass);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        cdef_1 = setExtendsSubmodifierInClass(cdef, inherit_class, subident, mod, env);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    else (inProgram5,"Error");
  end matchcontinue;
end setExtendsModifierValue;

protected function setExtendsSubmodifierInClass
" author: PA
   Sets a modifier of an extends clause for a given subcomponent.
   For instance,
   extends A(b=4); // b is subcomponent
   inputs:  (Absyn.Class,
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               FCore.Graph)
   outputs: Absyn.Class"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input FCore.Graph inEnv;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.Path inherit_name;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      FCore.Graph env;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),info = file_info),
          inherit_name,submod,mod,env)
      equation
        parts_1 = setExtendsSubmodifierInClassparts(parts, inherit_name, submod, mod, env);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,cmt),file_info);
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,parts = parts,modifications=modif,ann=ann,comment = cmt),info = file_info),
          inherit_name,submod,mod,env)
      equation
        parts_1 = setExtendsSubmodifierInClassparts(parts, inherit_name, submod, mod, env);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1,ann),file_info);
  end match;
end setExtendsSubmodifierInClass;

protected function setExtendsSubmodifierInClassparts
" Helper function to setExtendsSubmodifierInClass
   inputs:   (Absyn.ClassPart list,
                Absyn.Path, /* inherit_name */
                Absyn.ComponentRef, /* submodifier */
                Absyn.Modification,
                FCore.Graph)
   outputs:  Absyn.ClassPart list"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input FCore.Graph inEnv;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      FCore.Graph env;
      Absyn.ClassPart elt;

    case ({},_,_,_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PUBLIC(elts_1) :: res);

    case ((Absyn.PROTECTED(contents = elts) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PROTECTED(elts_1) :: res);

    case ((elt :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
      then
        (elt :: res);

  end matchcontinue;
end setExtendsSubmodifierInClassparts;

protected function setExtendsSubmodifierInElementitems
" Helper function to setExtendsSubmodifierInClassparts
   inputs:  (Absyn.ElementItem list,
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               FCore.Graph)
   outputs:  Absyn.ElementItem list"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input FCore.Graph inEnv;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      FCore.Graph env;
      Absyn.ElementItem elitem;
    case ({},_,_,_,_) then {};
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
        elt_1 = setExtendsSubmodifierInElement(elt, inherit, submod, mod, env);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elitem :: rest),inherit,submod,mod,env)
      equation
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
      then
        (elitem :: res);
  end matchcontinue;
end setExtendsSubmodifierInElementitems;

protected function setExtendsSubmodifierInElement
" Helper function to setExtendsSubmodifierInElementitems
   inputs: (Absyn.Element,
              Absyn.Path, /* inherit_name */
              Absyn.ComponentRef, /* submodifier */
              Absyn.Modification,
              FCore.Graph)
   outputs:  Absyn.Element"
  input Absyn.Element inElement;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input FCore.Graph inEnv;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inElement,inPath,inComponentRef,inModification,inEnv)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      Absyn.Path path,inherit,path_1;
      list<Absyn.ElementArg> eargs,eargs_1;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ComponentRef submod;
      FCore.Graph env;
      Absyn.Modification mod;
      Absyn.Element elt;
      Option<Absyn.Annotation> annOpt;
      /* special case for clearing modifications */
   /* case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs),info = info,constrainClass = constr),
      inherit,submod,Absyn.CLASSMOD(elementArgLst = {},expOption = NONE()),env)

      then Absyn.ELEMENT(f,r,i,n,Absyn.EXTENDS(path,{}),info,constr); */

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs,annotationOpt=annOpt),info = info,constrainClass = constr),
      inherit,submod,mod,env)
      equation
        (_,path_1) = Inst.makeFullyQualified(FCore.emptyCache(),env, path);
        true = Absyn.pathEqual(inherit, path_1);
        eargs_1 = setSubmodifierInElementargs(eargs, Absyn.crefToPath(submod), mod);
      then
        Absyn.ELEMENT(f,r,i,Absyn.EXTENDS(path,eargs_1,annOpt),info,constr);
    else inElement;
  end matchcontinue;
end setExtendsSubmodifierInElement;

protected function getExtendsModifierValue
" Return the submodifier value of an extends clause
   for instance,
   model test extends A(p1=3,p2(z=3));end test;
   getExtendsModifierValue(test,A,p1) => =3
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.ComponentRef, /* subident */
               Absyn.Program)
   outputs:  string"
  input Absyn.ComponentRef classRef;
  input Absyn.ComponentRef extendsRef;
  input Absyn.ComponentRef varRef;
  input Absyn.Program program;
  output String valueStr;
protected
  Absyn.Path cls_path, name;
  Absyn.Class cls;
  list<Absyn.ElementArg> args;
  FCore.Graph env;
  list<Absyn.ElementSpec> exts;
algorithm
  try
    cls_path := Absyn.crefToPath(classRef);
    name := Absyn.crefToPath(extendsRef);
    cls := getPathedClassInProgram(cls_path, program);
    env := getClassEnv(program, cls_path);
    exts := list(makeExtendsFullyQualified(e, env) for e in getExtendsElementspecInClass(cls));
    {Absyn.EXTENDS(elementArg = args)} := List.select1(exts, extendsElementspecNamed, name);
    valueStr := Dump.printExpStr(getModificationValue(args, Absyn.crefToPath(varRef)));
  else
    valueStr := "";
  end try;
end getExtendsModifierValue;

protected function isExtendsModifierFinal
" Return true if the modifier of an extends clause has final prefix.
   for instance,
   model test extends A(final p1=3);end test;
   isExtendsModifierFinal(test,A,p1) => true
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.ComponentRef, /* subident */
               Absyn.Program)
   outputs:  boolean"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      FCore.Graph env;
      list<Absyn.ElementSpec> exts,exts_1;
      list<Absyn.ElementArg> extmod;
      Absyn.Modification mod;
      String res;
      Boolean finalPrefix;
      Absyn.ComponentRef class_,inherit_name,subident;
      Absyn.Program p;
    case (class_,inherit_name,subident,p)
      equation
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        exts = getExtendsElementspecInClass(cdef);
        exts_1 = List.map1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(_,extmod,_)} = List.select1(exts_1, extendsElementspecNamed, name);
        finalPrefix = isModifierfinal(extmod, Absyn.crefToPath(subident));
        res = boolString(finalPrefix);
      then
        res;
    else "Error";
  end matchcontinue;
end isExtendsModifierFinal;

public function isModifierfinal
" Helper function to isExtendsModifierFinal."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inAbsynElementArgLst,inPath)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.Path p1,p2;
      Absyn.Modification mod;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      String name1,name2;
    case ((Absyn.MODIFICATION(finalPrefix = f,path = p1,modification = SOME(_)) :: _),p2) guard Absyn.pathEqual(p1, p2)
      then
        f;
    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = name1),modification = SOME(Absyn.CLASSMOD(elementArgLst=args))) :: _),Absyn.QUALIFIED(name = name2,path = p2)) guard stringEq(name1, name2)
      equation
        f = isModifierfinal(args, p2);
      then
        f;
    case ((_ :: rest),_)
      equation
        f = isModifierfinal(rest, inPath);
      then
        f;
    else false;
  end match;
end isModifierfinal;

protected function makeExtendsFullyQualified
" Makes an EXTENDS ElementSpec having a
   fully qualified extends path."
  input Absyn.ElementSpec inElementSpec;
  input FCore.Graph inEnv;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElementSpec,inEnv)
    local
      Absyn.Path path_1,path;
      list<Absyn.ElementArg> earg;
      FCore.Graph env;
      Option<Absyn.Annotation> annOpt;

    case (Absyn.EXTENDS(path = path,elementArg = earg,annotationOpt=annOpt),env)
      equation
        (_,path_1) = Inst.makeFullyQualified(FCore.emptyCache(),env, path);
      then
        Absyn.EXTENDS(path_1,earg,annOpt);
  end match;
end makeExtendsFullyQualified;

protected function getExtendsModifierNames
" Return the modifier names of a
   modification on an extends clause.
   For instance,
     model test extends A(p1=3,p2(z=3));end test;
     getExtendsModifierNames(test,A) => {p1,p2.z}
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* inherited class */
               Absyn.Program)
   outputs: (string)"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Boolean inBoolean;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inBoolean,inProgram3)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      list<Absyn.ElementSpec> exts,exts_1;
      FCore.Graph env;
      list<Absyn.ElementArg> extmod;
      list<String> res,res1;
      String res_1,res_2;
      Boolean b;
      Absyn.ComponentRef class_,inherit_name;
      Absyn.Program p;
    case (class_,inherit_name,b,p)
      equation
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        exts = getExtendsElementspecInClass(cdef);
        env = getClassEnv(p, p_class);
        exts_1 = List.map1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(_,extmod,_)} = List.select1(exts_1, extendsElementspecNamed, name);
        res = getModificationNames(extmod);
        res1 = if b then insertQuotesToList(res) else res;
        res_1 = stringDelimitList(res1, ", ");
        res_2 = stringAppendList({"{",res_1,"}"});
      then
        res_2;
    else "Error";
  end matchcontinue;
end getExtendsModifierNames;

protected function extendsElementspecNamed
"the name given as path, false otherwise."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inElementSpec,inPath)
    local
      Boolean res;
      Absyn.Path extpath,path;
    case (Absyn.EXTENDS(path = extpath),path)
      equation
        res = Absyn.pathEqual(path, extpath);
      then
        res;
  end match;
end extendsElementspecNamed;

protected function extendsName
"Return the class name of an EXTENDS element spec."
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outPath;
algorithm
  outPath:=
  match (inElementSpec)
    local Absyn.Path path;
    case (Absyn.EXTENDS(path = path)) then path;
  end match;
end extendsName;

protected function getExtendsElementspecInClass
"Retrieve all ElementSpec of a class that are EXTENDS."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementSpec> ext;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> eltArg;
      Absyn.Path tp;
    /* a class with parts */
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* adrpo: handle also model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    /* a derived class */
    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(tp,_), arguments=eltArg)))
      then
        {Absyn.EXTENDS(tp,eltArg,NONE())};
        // Note: the array dimensions of DERIVED are lost. They must be
        // queried by another api-function
    else {};
  end matchcontinue;
end getExtendsElementspecInClass;

protected function getExtendsElementspecInClassparts
"Helper function to getExtendsElementspecInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart elt;

    case ({}) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;

    case ((_ :: rest))
      equation
        res = getExtendsElementspecInClassparts(rest);
      then
        res;

  end matchcontinue;
end getExtendsElementspecInClassparts;

protected function getExtendsElementspecInElementitems
"Helper function to getExtendsElementspecInClassparts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.Element el;
      Absyn.ElementSpec elt;
      list<Absyn.ElementSpec> res;
      list<Absyn.ElementItem> rest;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = el) :: rest))
      equation
        elt = getExtendsElementspecInElement(el) "Bug in MetaModelica Compiler (MMC). If the two premisses below are in swapped order
    the compiler enters infinite loop (but no stack overflow)" ;
        res = getExtendsElementspecInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation
        res = getExtendsElementspecInElementitems(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInElementitems;

protected function getExtendsElementspecInElement
"Helper function to getExtendsElementspecInElementitems."
  input Absyn.Element inElement;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElement)
    local Absyn.ElementSpec ext;
    case (Absyn.ELEMENT(specification = (ext as Absyn.EXTENDS()))) then ext;
  end match;
end getExtendsElementspecInElement;

public function removeComponentModifiers
  "Removes all the modifiers of a component."
  input Absyn.Path path;
  input String inComponentName;
  input Absyn.Program inProgram;
  input Boolean keepRedeclares;
  output Absyn.Program outProgram;
  output Boolean outResult;
protected
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    within_ := buildWithin(path);
    cls := getPathedClassInProgram(path, inProgram);
    cls := clearComponentModifiersInClass(cls, inComponentName, keepRedeclares);
    outProgram := updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := true;
  else
    outProgram := inProgram;
    outResult := false;
  end try;
end removeComponentModifiers;

protected function clearComponentModifiersInClass
  input Absyn.Class inClass;
  input String inComponentName;
  input Boolean keepRedeclares;
  output Absyn.Class outClass = inClass;
algorithm
  (outClass, true) := Absyn.traverseClassComponents(inClass,
    function clearComponentModifiersInCompitems(inComponentName =
      inComponentName, keepRedeclares = keepRedeclares), false);
end clearComponentModifiersInClass;

protected function clearComponentModifiersInCompitems
  "Helper function to clearComponentModifiersInClass. Clears the modifiers in a ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input String inComponentName;
  input Boolean keepRedeclares = false;
  output list<Absyn.ComponentItem> outComponents = {};
  output Boolean outFound;
  output Boolean outContinue;
protected
  Absyn.ComponentItem item;
  list<Absyn.ComponentItem> rest_items = inComponents;
  Absyn.Component comp;
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
algorithm
  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if Absyn.componentName(item) == inComponentName then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.modification := if not keepRedeclares then NONE() else stripModifiersKeepRedeclares(comp.modification);
            item.component := comp;
          then
            ();
      end match;

      // Reassemble the item list and return.
      outComponents := List.append_reverse(outComponents, item :: rest_items);
      outFound := true;
      outContinue := false;
      return;
    end if;
    outComponents := item :: outComponents;
  end while;

  // Component not found, continue looking.
  outComponents := inComponents;
  outFound := false;
  outContinue := true;
end clearComponentModifiersInCompitems;

protected function stripModifiersKeepRedeclares
  input Option<Absyn.Modification> inMod;
  output Option<Absyn.Modification> outMod;
algorithm
  outMod := match(inMod)
    local
      Absyn.Modification m;
      list<Absyn.ElementArg> ea;
      Absyn.EqMod em;
    case NONE() then NONE();
    case SOME(Absyn.CLASSMOD(ea, _))
      algorithm
        ea := list(e for e guard(match e case Absyn.REDECLARATION() then true; else false; end match) in ea);
        m := Absyn.CLASSMOD(ea, Absyn.NOMOD());
      then
        SOME(m);
  end match;
end stripModifiersKeepRedeclares;

protected function setComponentModifier
  "Sets a submodifier of a component."
  input Absyn.ComponentRef inClass;
  input Absyn.ComponentRef inComponentName;
  input Absyn.Modification inMod;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outResult;
protected
  Absyn.Path p_class;
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    p_class := Absyn.crefToPath(inClass);
    within_ := buildWithin(p_class);
    cls := getPathedClassInProgram(p_class, inProgram);
    cls := setComponentSubmodifierInClass(cls, inComponentName, inMod);
    outProgram := updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := "Ok";
  else
    outProgram := inProgram;
    outResult := "Error";
  end try;
end setComponentModifier;

protected function setComponentSubmodifierInClass
" Sets a sub modifier on a component in a class.
   inputs: (Absyn.Class,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.Class"
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentName;
  input Absyn.Modification inMod;
  output Absyn.Class outClass = inClass;
algorithm
  (outClass, true) := Absyn.traverseClassComponents(inClass,
    function setComponentSubmodifierInCompitems(inComponentName =
      inComponentName, inMod = inMod), false);
end setComponentSubmodifierInClass;

protected function setComponentSubmodifierInCompitems
  "Helper function to setComponentSubmodifierInClass. Sets the modifier in a
   ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input Absyn.ComponentRef inComponentName;
  input Absyn.Modification inMod;
  output list<Absyn.ComponentItem> outComponents = {};
  output Boolean outFound;
  output Boolean outContinue;
protected
  Absyn.ComponentItem item;
  list<Absyn.ComponentItem> rest_items = inComponents;
  Absyn.Component comp;
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
  String comp_id;
algorithm
  comp_id := Absyn.crefFirstIdent(inComponentName);

  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if Absyn.componentName(item) == comp_id then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.modification := propagateMod(Absyn.crefToPath(inComponentName),
              inMod, comp.modification);
            item.component := comp;
          then
            ();
      end match;

      // Reassemble the item list and return.
      outComponents := List.append_reverse(outComponents, item :: rest_items);
      outFound := true;
      outContinue := false;
      return;
    end if;
    outComponents := item :: outComponents;
  end while;

  // Component not found, continue looking.
  outComponents := inComponents;
  outFound := false;
  outContinue := true;
end setComponentSubmodifierInCompitems;

protected function propagateMod
  input Absyn.Path inComponentName;
  input Absyn.Modification inNewMod;
  input Option<Absyn.Modification> inOldMod;
  output Option<Absyn.Modification> outMod;
protected
  list<Absyn.ElementArg> new_args, old_args;
  Absyn.EqMod new_eqmod, old_eqmod;
  Absyn.Modification mod;
algorithm
  if isSome(inOldMod) then
    SOME(Absyn.CLASSMOD(elementArgLst = old_args, eqMod = old_eqmod)) := inOldMod;
  else
    old_args := {};
    old_eqmod := Absyn.NOMOD();
  end if;

  if Absyn.pathIsIdent(inComponentName) then
    Absyn.CLASSMOD(elementArgLst = new_args, eqMod = new_eqmod) := inNewMod;

    // If we have no eqmod but a list of submods, keep the old eqmod.
    if valueEq(new_eqmod, Absyn.NOMOD()) and not listEmpty(new_args) then
      new_eqmod := old_eqmod;
    end if;

    new_args := mergeElementArgs(old_args, new_args);
    mod := Absyn.CLASSMOD(new_args, new_eqmod);
  else
    new_args := propagateMod2(inComponentName, old_args, inNewMod);
    mod := Absyn.CLASSMOD(new_args, old_eqmod);
  end if;

  outMod := if Absyn.isEmptyMod(mod) then NONE() else SOME(mod);
end propagateMod;

protected function mergeElementArgs
  input list<Absyn.ElementArg> inOldArgs;
  input list<Absyn.ElementArg> inNewArgs;
  output list<Absyn.ElementArg> outArgs = inOldArgs;
protected
  Boolean found;
algorithm
  if listEmpty(inOldArgs) then
    outArgs := inNewArgs;
  elseif listEmpty(inNewArgs) then
    outArgs := inOldArgs;
  else
    for narg in inNewArgs loop
      (outArgs, found) := List.replaceOnTrue(narg, outArgs,
        function Absyn.elementArgEqualName(inArg2 = narg));

      if not found then
        outArgs := narg :: outArgs;
      end if;
    end for;
  end if;
end mergeElementArgs;

protected function propagateMod2
  input Absyn.Path inComponentName;
  input list<Absyn.ElementArg> inSubMods;
  input Absyn.Modification inNewMod;
  output list<Absyn.ElementArg> outSubMods = {};
protected
  Absyn.ElementArg submod;
  list<Absyn.ElementArg> rest_submods = inSubMods;
  Absyn.Modification new_mod;
  Absyn.Path comp_name, comp_rest;
algorithm
  // Search through the submods to see if one matches the component name.
  while not listEmpty(rest_submods) loop
    submod :: rest_submods := rest_submods;
    comp_name := Absyn.pathRest(inComponentName);
    comp_rest := comp_name;

    // Try to find the submod whose path matches the best. If the have a
    // component name a.b.c, then first check a.b.c, then a.b, then a.
    while true loop
      if Absyn.pathEqual(comp_name, Absyn.elementArgName(submod)) then
        // Found matching submod, propagate the modifier to it.
        _ := match(submod)
          case Absyn.MODIFICATION()
            algorithm
              if not Absyn.pathIsIdent(comp_name) then
                comp_name := Absyn.pathPrefix(comp_name);
                comp_rest := Absyn.removePrefix(comp_name, comp_rest);
              end if;

              submod.modification := propagateMod(comp_rest, inNewMod, submod.modification);

              if isSome(submod.modification) then
                rest_submods := submod :: rest_submods;
              end if;
            then
              ();
          else ();
        end match;

        outSubMods := List.append_reverse(outSubMods, rest_submods);
        return;
      end if;

      if Absyn.pathIsIdent(comp_name) then
        // Nothing left of the path, break and continue with next submod.
        break;
      else
        // Remove the last part of the component name and see if that matches
        // instead.
        comp_name := Absyn.pathPrefix(comp_name);
      end if;
    end while;

    outSubMods := submod :: outSubMods;
  end while;

  if not Absyn.isEmptyMod(inNewMod) then
    // No matching submod was found, create a new submod and insert it into the list.
    submod := createNestedSubMod(Absyn.pathRest(inComponentName), inNewMod);
    outSubMods := listReverse(submod :: outSubMods);
  else
    outSubMods := inSubMods;
  end if;
end propagateMod2;

protected function createNestedSubMod
  input Absyn.Path inComponentName;
  input Absyn.Modification inMod;
  output Absyn.ElementArg outSubMod;
algorithm
  if Absyn.pathIsIdent(inComponentName) then
    outSubMod := Absyn.MODIFICATION(false, Absyn.NON_EACH(), inComponentName,
        SOME(inMod), NONE(), Absyn.dummyInfo);
  else
    outSubMod := createNestedSubMod(Absyn.pathRest(inComponentName), inMod);
    outSubMod := Absyn.MODIFICATION(false, Absyn.NON_EACH(),
                   Absyn.pathFirstPath(inComponentName),
                   SOME(Absyn.CLASSMOD({outSubMod}, Absyn.NOMOD())), NONE(),
                   Absyn.dummyInfo);
  end if;
end createNestedSubMod;

protected function setSubmodifierInElementargs
" Helper function to setComponentSubmodifierInCompitems
   inputs:  (Absyn.ElementArg list,
               Absyn.ComponentRef, /* subcomponent name */
               Absyn.Modification)
   outputs:  Absyn.ElementArg list"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Path inPath;
  input Absyn.Modification inModification;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementArgLst,inPath,inModification)
    local
      Absyn.Modification mod;
      Option<Absyn.Modification> mod2;
      Boolean f;
      Absyn.Each each_;
      String name,submodident,name1,name2;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args_1,args,res,submods;
      Absyn.ElementArg m;
      Absyn.EqMod eqMod;
      SourceInfo info;
      Absyn.Path p,p1,p2;

    case ({},_,Absyn.CLASSMOD({},Absyn.NOMOD())) then {}; // Empty modification.
    case ({},_,mod) then {Absyn.MODIFICATION(false,Absyn.NON_EACH(),inPath,SOME(mod),NONE(),Absyn.dummyInfo)};

    // Clear modification m(...)
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = (p as Absyn.IDENT(name = name)),comment = cmt,modification=SOME(Absyn.CLASSMOD((submods as _::_),_)), info = info) :: rest),Absyn.IDENT(name = submodident),(Absyn.CLASSMOD( {},Absyn.NOMOD())))
      equation
        true = stringEq(name, submodident);
      then
        Absyn.MODIFICATION(f,each_,p,SOME(Absyn.CLASSMOD(submods,Absyn.NOMOD())),cmt,info)::rest;

    // Clear modification, m with no submodifiers
    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = name),modification=SOME(Absyn.CLASSMOD({},_))) :: rest),Absyn.IDENT(name = submodident),(Absyn.CLASSMOD( {},Absyn.NOMOD())))
      equation
        true = stringEq(name, submodident);
      then
        rest;

    // modfication, m=e
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = Absyn.IDENT(name = name),modification=SOME(Absyn.CLASSMOD(submods,_)),comment = cmt, info = info) :: rest),Absyn.IDENT(name = submodident),(Absyn.CLASSMOD({},eqMod as Absyn.EQMOD()))) /* update modification */
      equation
        true = stringEq(name, submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.IDENT(name),SOME(Absyn.CLASSMOD(submods,eqMod)),cmt,info) :: rest);

    // modfication, m(...)=e
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = Absyn.IDENT(name = name),comment = cmt, info = info) :: rest),Absyn.IDENT(name = submodident),mod) /* update modification */
      equation
        true = stringEq(name, submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.IDENT(name),SOME(mod),cmt,info) :: rest);

    // Clear modification, m.n
     case ((Absyn.MODIFICATION(path = (p1 as Absyn.QUALIFIED())) :: rest),p2,Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = Absyn.pathEqual(p1, p2);
      then
        (rest);

    // Clear modification m.n first part matches. Check that m is not present in rest of list.
    case ((Absyn.MODIFICATION(path = Absyn.QUALIFIED(name = name1)) :: rest),p as Absyn.IDENT(name = name2),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        false = findPathModification(p,rest);
      then
        (rest);

    // Clear modification m(...)
    case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = (p as Absyn.IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())),comment = cmt, info = info) :: rest),Absyn.QUALIFIED(name = name1,path = p1),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        {} = setSubmodifierInElementargs(args, p1, Absyn.CLASSMOD({},Absyn.NOMOD()));
      then
        (Absyn.MODIFICATION(f,each_,p,NONE(),cmt,info) :: rest);

   // Clear modification m(...)=expr
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = (p as Absyn.IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,eqMod as Absyn.EQMOD())),comment = cmt,info = info) :: rest),Absyn.QUALIFIED(name = name1,path = p1),Absyn.CLASSMOD({},Absyn.NOMOD()))
      equation
        true = stringEq(name1, name2);
        {} = setSubmodifierInElementargs(args, p1, Absyn.CLASSMOD({},Absyn.NOMOD()));
      then
        (Absyn.MODIFICATION(f,each_,p,SOME(Absyn.CLASSMOD({},eqMod)),cmt,info) :: rest);

   // modification, m for m.n
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = (p as Absyn.IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,eqMod)),comment = cmt,info = info) :: rest),Absyn.QUALIFIED(name = name1,path = p1),mod)
      equation
        true = stringEq(name1, name2);
        args_1 = setSubmodifierInElementargs(args, p1, mod);
      then
        (Absyn.MODIFICATION(f,each_,p,SOME(Absyn.CLASSMOD(args_1,eqMod)),cmt,info) :: rest);

   // modification, m.n for m.n
   case ((Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = p1,modification = SOME(Absyn.CLASSMOD()),comment = cmt,info = info) :: rest),p2,mod)
      equation
        true = Absyn.pathEqual(p1,p2);
      then
        (Absyn.MODIFICATION(f,each_,p1,SOME(mod),cmt,info) :: rest);

    // next element
    case ((m :: rest),p,mod)
      equation
        res = setSubmodifierInElementargs(rest, p, mod);
      then
        (m :: res);

    else
      equation
        print("-set_submodifier_in_elementargs failed\n");
      then
        fail();
  end matchcontinue;
end setSubmodifierInElementargs;

protected function findPathModification
  input Absyn.Path path;
  input list<Absyn.ElementArg> lst;
  output Boolean found;
algorithm
  found := match(path,lst)
    local
      Absyn.Path p;
      list<Absyn.ElementArg> rest;
    case (_,Absyn.MODIFICATION(path = p)::_) guard Absyn.pathEqual(path,p) then true;
    case (_,_::rest) then findPathModification(path,rest);
    case (_,{}) then false;
  end match;
end findPathModification;

public function getComponentModifierValue
  input Absyn.ComponentRef classRef;
  input Absyn.ComponentRef varRef;
  input Absyn.ComponentRef subModRef;
  input Absyn.Program program;
  output String valueStr;
protected
  Absyn.Path cls_path;
  String name;
  Absyn.Class cls;
  list<Absyn.ElementArg> args;
algorithm
  try
    cls_path := Absyn.crefToPath(classRef);
    name := Absyn.crefIdent(varRef);
    cls := getPathedClassInProgram(cls_path, program);
    Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification =
      SOME(Absyn.CLASSMOD(elementArgLst = args)))) := getComponentInClass(cls, name);
    valueStr := Dump.printExpStr(getModificationValue(args, Absyn.crefToPath(subModRef)));
  else
    valueStr := "";
  end try;
end getComponentModifierValue;

public function getModificationValue
  "Looks up a modifier in a list of element args and returns its binding
   expression, or fails if no modifier is found."
  input list<Absyn.ElementArg> args;
  input Absyn.Path path;
  output Absyn.Exp value;
protected
  String name;
  list<Absyn.ElementArg> rest_args = args;
  Absyn.ElementArg arg;
  Boolean found = false;
algorithm
  while not found loop
    arg :: rest_args := rest_args;

    found := match arg
      case Absyn.MODIFICATION() guard Absyn.pathEqual(arg.path, path)
        algorithm
          SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = value))) := arg.modification;
        then
          true;

      case Absyn.MODIFICATION(path = Absyn.IDENT(name = name))
          guard name == Absyn.pathFirstIdent(path)
        algorithm
          SOME(Absyn.CLASSMOD(elementArgLst = rest_args)) := arg.modification;
          value := getModificationValue(rest_args, Absyn.pathRest(path));
        then
          true;

      else false;
    end match;
  end while;
end getModificationValue;

public function getComponentModifierValues
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.Modification mod;
      Absyn.ComponentRef class_,ident,subident;
      Absyn.Program p;
      list<Absyn.ElementArg> elementArgLst;

    case (class_,ident,subident,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(component=Absyn.COMPONENT(modification=SOME(Absyn.CLASSMOD(elementArgLst=elementArgLst))))} = List.select1(compelts_1, componentitemNamed, name);
        mod = getModificationValues(elementArgLst, Absyn.crefToPath(subident));
        res = Dump.unparseModificationStr(mod);
      then
        res;
    else "Error";
  end matchcontinue;
end getComponentModifierValues;

protected function getModificationValues
  "Helper function to getComponentModifierValues
   Investigates modifications to find submodifier."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.Path inPath;
  output Absyn.Modification outModification;
algorithm
  outModification:=
  match (inAbsynElementArgLst,inPath)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.Path p1,p2;
      Absyn.Modification mod,res;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      String name1,name2;
    case ((Absyn.MODIFICATION(path = p1,modification = SOME(mod)) :: _),p2) guard Absyn.pathEqual(p1, p2)
      then
        mod;
    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = name1),modification = SOME(Absyn.CLASSMOD(elementArgLst=args))) :: _),Absyn.QUALIFIED(name = name2,path = p2))
      guard stringEq(name1, name2)
      equation
        res = getModificationValues(args, p2);
      then
        res;
    case ((_ :: rest),_)
      equation
        mod = getModificationValues(rest, inPath);
      then
        mod;
  end match;
end getModificationValues;

public function getComponentModifierNames
 "Return the modifiernames of a component"
  input Absyn.Path path;
  input String inComponentName;
  input Absyn.Program inProgram3;
  output list<String> outList;
algorithm
  outList:=
  matchcontinue (path,inComponentName,inProgram3)
    local
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<Absyn.ElementArg> mod;
      list<String> res;
      Absyn.Program p;
    case (_,_,p)
      equation
        cdef = getPathedClassInProgram(path, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,SOME(Absyn.CLASSMOD(mod,_))),_,_)} = List.select1(compelts_1, componentitemNamed, inComponentName);
        res = getModificationNames(mod);
      then
        res;
    else {};
  end matchcontinue;
end getComponentModifierNames;

protected function getModificationNames
"Helper function to getComponentModifierNames"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<String> names,names2,names2_1,names2_2,res;
      Boolean f;
      Absyn.Each each_;
      String name;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      Absyn.Path p;
    case ({}) then {};
    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = name),modification = NONE()) :: rest))
      equation
        names = getModificationNames(rest);
      then
        (name :: names);
    case ((Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD({},_))) :: rest))
      equation
        name = Absyn.pathString(p);
        names = getModificationNames(rest);
      then
        (name :: names);
        // modifier with submodifiers -and- binding, e.g. m(...)=2, add also m to list
    case ((Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,Absyn.EQMOD()))) :: rest))
      equation
        name = Absyn.pathString(p);
        names2 = list(stringAppend(stringAppend(name, "."), n) for n in getModificationNames(args));
        names = getModificationNames(rest);
        res = listAppend(names2, names);
      then
        name::res;
      // modifier with submodifiers, e.g. m(...)
    case ((Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,_))) :: rest))
      equation
        name = Absyn.pathString(p);
        names2 = list(stringAppend(stringAppend(name, "."), n) for n in getModificationNames(args));
        names = getModificationNames(rest);
        res = listAppend(names2, names);
      then
        res;
    case ((_ :: rest))
      equation
        names = getModificationNames(rest);
      then
        names;
  end matchcontinue;
end getModificationNames;

public function getComponentBinding
" Returns the value of a component in a class.
   For example, the component
     Real x=1;
     returns 1.
   This can be used for both parameters, constants and variables."
  input Absyn.Path path;
  input String parameterName;
  input Absyn.Program program;
  output String bindingStr;
protected
  Absyn.Class cls;
  Absyn.ComponentItem component;
algorithm
  try
    cls := getPathedClassInProgram(path, program);
    component := getComponentInClass(cls, parameterName);
    bindingStr := Dump.printExpStr(getVariableBindingInComponentitem(component));
  else
    bindingStr := "";
  end try;
end getComponentBinding;

public function getComponentInClass
  "Returns the component with the given name in the given class, or fails if no
   such component exists."
  input Absyn.Class cls;
  input Absyn.Ident componentName;
  output Absyn.ComponentItem component;
protected
  Absyn.ClassDef body;
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> elements;
  list<Absyn.ComponentItem> components;
  Boolean found = false;
algorithm
  Absyn.CLASS(body = body) := cls;

  parts := match body
    case Absyn.PARTS() then body.classParts;
    case Absyn.CLASS_EXTENDS() then body.parts;
  end match;

  for part in parts loop
    elements := match part
      case Absyn.PUBLIC() then part.contents;
      case Absyn.PROTECTED() then part.contents;
      else {};
    end match;

    for e in elements loop
      components := match e
        case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
          Absyn.COMPONENTS(components = components))) then components;
        else {};
      end match;

      for c in components loop
        if Absyn.componentName(c) == componentName then
          component := c;
          return;
        end if;
      end for;
    end for;

  end for;

  fail();
end getComponentInClass;

protected function getVariableBindingInComponentitem
" Retrieve the variable binding from an ComponentItem"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Exp outExp;
algorithm
  outExp := match (inComponentItem)
    local Absyn.Exp e;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=e)))))) then e;
  end match;
end getVariableBindingInComponentitem;

protected function setParameterValue
" Sets the parameter value of a class and returns the updated program.
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.Exp,          /* exp */
               Absyn.Program)
   outputs: (Absyn.Program,string)"
  input Absyn.ComponentRef inComponentRefClass;
  input Absyn.ComponentRef inComponentRefComponentName;
  input Absyn.Exp inBindingExp;
  input Absyn.Program inFullProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inComponentRefClass,inComponentRefComponentName,inBindingExp,inFullProgram)
    local
      Absyn.Path p_class;
      String varname, str;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,name;
      Absyn.Exp exp;
      Boolean b;

    case (class_,name,exp,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(varname) = Absyn.crefToPath(name);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        (cdef_1, b) = setVariableBindingInClass(cdef, varname, exp);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
        str = if b then "Ok" else ("Error: component with name: " + varname + " in class: " + Absyn.pathString(p_class) + " not found.");
      then
        (newp,str);

    case (class_,name,_,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(_) = Absyn.crefToPath(name);
        failure(_ = getPathedClassInProgram(p_class, p));
        str = "Error: class: " + Absyn.pathString(p_class) + " not found.";
      then
        (p,str);

    else (inFullProgram,"Error");
  end matchcontinue;
end setParameterValue;

protected function setVariableBindingInClass
" Takes a class and an identifier and value an
   sets the variable binding to the passed expression."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Class outClass;
  output Boolean outChangeMade;
algorithm
  (outClass, outChangeMade) := match (inClass,inIdent,inExp)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,id2,bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.Exp exp;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      Boolean b;
      list<Absyn.Annotation> ann;

    // a class with parts
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),info = file_info),
          id2,exp)
      equation
        (parts_1, b) = setVariableBindingInClassparts(parts, id2, exp);
      then
        (Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,cmt),file_info), b);

    // adrpo: handle also model extends M end M;
    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,ann = ann,comment = cmt),info = file_info),
          id2,exp)
      equation
        (parts_1,b) = setVariableBindingInClassparts(parts, id2, exp);
      then
        (Absyn.CLASS(id,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1,ann),file_info), b);
  end match;
end setVariableBindingInClass;

protected function setVariableBindingInClassparts
" Sets a binding of a variable in a ClassPart
   list, named by the passed argument."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynClassPartLst, outChangeMade) := matchcontinue (inAbsynClassPartLst,inIdent,inExp)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      String id;
      Absyn.Exp exp;
      Absyn.ClassPart elt;
      Boolean b1, b2, b;

    case ({},_,_) then ({}, false);

    case ((Absyn.PUBLIC(contents = elts) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInClassparts(rest, id, exp);
        (elts_1, b2) = setVariableBindingInElementitems(elts, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.PUBLIC(elts_1) :: res, b);

    case ((Absyn.PROTECTED(contents = elts) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInClassparts(rest, id, exp);
        (elts_1, b2) = setVariableBindingInElementitems(elts, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.PROTECTED(elts_1) :: res, b);

    case ((elt :: rest),id,exp)
      equation
        (res, b) = setVariableBindingInClassparts(rest, id, exp);
      then
        (elt :: res, b);
  end matchcontinue;
end setVariableBindingInClassparts;

protected function setVariableBindingInElementitems
" Sets a variable binding in a list of ElementItems"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynElementItemLst, outChangeMade) :=
  matchcontinue (inAbsynElementItemLst,inIdent,inExp)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String id;
      Absyn.Exp exp;
      Absyn.ElementItem elitem;
      Boolean b1, b2, b;

    case ({},_,_) then ({}, false);

    case ((Absyn.ELEMENTITEM(element = elt) :: rest),id,exp)
      equation
        (res, b1) = setVariableBindingInElementitems(rest, id, exp);
        (elt_1, b2) = setVariableBindingInElement(elt, id, exp);
        b = boolOr(b1, b2);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res, b);

    case ((elitem :: rest),id,exp)
      equation
        (res, b) = setVariableBindingInElementitems(rest, id, exp);
      then
        (elitem :: res, b);
  end matchcontinue;
end setVariableBindingInElementitems;

protected function setVariableBindingInElement
" Sets a variable binding in an Element."
  input Absyn.Element inElement;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Element outElement;
  output Boolean outChangeMade;
algorithm
  (outElement, outChangeMade) :=
  matchcontinue (inElement,inIdent,inExp)
    local
      list<Absyn.ComponentItem> compitems_1,compitems;
      Boolean f,b;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String id;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.Exp exp;
      Absyn.Element elt;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = compitems),info = info,constrainClass = constr),id,exp)
      equation
        (compitems_1, b) = setVariableBindingInCompitems(compitems, id, exp);
      then
        (Absyn.ELEMENT(f,r,i,Absyn.COMPONENTS(attr,tp,compitems_1),info,constr), b);

    else (inElement, false);
  end matchcontinue;
end setVariableBindingInElement;

protected function setVariableBindingInCompitems
" Sets a variable binding in a ComponentItem list
   and returns true if it found it"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
  output Boolean outChangeMade;
algorithm
  (outAbsynComponentItemLst,outChangeMade) := match (inAbsynComponentItemLst,inIdent,inExp)
    local
      String id,id2;
      list<Absyn.Subscript> dim;
      list<Absyn.ElementArg> arg;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      list<Absyn.ComponentItem> rest,res;
      Absyn.Exp exp;
      Absyn.ComponentItem item;
      Boolean b;

    case ({},_,_) then ({}, false);

    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(arg,_))),condition = cond,comment = cmt) :: rest),id2,exp)
      guard
        stringEq(id, id2)
      then
        ((Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD(arg,Absyn.EQMOD(exp,Absyn.dummyInfo)))),cond,cmt) :: rest), true);

    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE()),condition = cond,comment = cmt) :: rest),id2,exp)
      guard
        stringEq(id, id2)
      then
        ((Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,Absyn.dummyInfo)))),cond,cmt) :: rest), true);

    case (item :: rest,id,exp)
      equation
        (res, b) = setVariableBindingInCompitems(rest, id, exp);
      then
        (item :: res, b);
  end match;
end setVariableBindingInCompitems;

public function buildWithin
" From a fully qualified model name, build a suitable within clause"
  input Absyn.Path inPath;
  output Absyn.Within outWithin;
algorithm
  outWithin := match inPath
    local Absyn.Path w_path,path;
    case (Absyn.IDENT()) then Absyn.TOP();
    case (Absyn.FULLYQUALIFIED(path)) // handle fully qual also!
      then
        buildWithin(path);
    case (path)
      equation
        w_path = Absyn.stripLast(path);
      then
        Absyn.WITHIN(w_path);
  end match;
end buildWithin;

protected function componentitemNamed
" Returns true if the component item has
   the name matching the second argument."
  input Absyn.ComponentItem inComponentItem;
  input Absyn.Ident inIdent;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inComponentItem,inIdent)
    local String id1,id2;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id1)),id2)
      guard
        stringEq(id1, id2)
      then
        true;
    else false;
  end match;
end componentitemNamed;

protected function getComponentitemName
" Returns the name of a ComponentItem"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Ident outIdent;
algorithm
  outIdent := match (inComponentItem)
    local String id;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id))) then id;
  end match;
end getComponentitemName;

protected function getComponentitemsInElement
" Retrieves the ComponentItems of a component Element.
   If Element is not a component, empty list is returned."
  input Absyn.Element inElement;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst := match (inElement)
    local list<Absyn.ComponentItem> l;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = l))) then l;
    else {};
  end match;
end getComponentitemsInElement;

protected function renameClass
" This function renames a class (given as a qualified path name) to a
   new name -in the same scope-. All references to the class name in the
   program is updated to the new name. Thefunction does not allow a
   renaming that will move the class to antoher package. To do this, the
   class must be copied.
   inputs:  (Absyn.Program,
               Absyn.ComponentRef, /* old class as qualified name A.B.C */
               Absyn.ComponentRef) /* new class, as identifier D */
   outputs:  Absyn.Program"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inProgram1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path new_path,old_path,new_path_1,old_path_no_last;
      String tmp_str,path_str_lst_no_empty,res;
      Absyn.Program p,p_1;
      Absyn.ComponentRef old_class,new_name;
      list<SCode.Element> pa_1;
      FCore.Graph env;
      list<String> path_str_lst;
    case (p,_,(new_name as Absyn.CREF_QUAL()))
      equation
        new_path = Absyn.crefToPath(new_name) "class in package" ;
        tmp_str = Absyn.pathString(new_path);
        print(tmp_str);
        print("\n") "the path is qualified so it cannot be renamed" ;
      then
        ("error",p);
    case (p,(old_class as Absyn.CREF_IDENT()),new_name)
      equation
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path = Absyn.crefToPath(new_name);
        pa_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(pa_1);
        ((p_1,_,(_,_,_,path_str_lst,_))) = AbsynUtil.traverseClasses(p, NONE(), renameClassVisitor, (old_path,new_path,p,{},env),
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNonEmptyElts(path_str_lst, ",");
        res = stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
    case (p,(old_class as Absyn.CREF_QUAL()),new_name)
      equation
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path_1 = Absyn.crefToPath(new_name);
        old_path_no_last = Absyn.stripLast(old_path);
        new_path = Absyn.joinPaths(old_path_no_last, new_path_1);
        pa_1 = SCodeUtil.translateAbsyn2SCode(p);
        (_,env) = Inst.makeEnvFromProgram(pa_1);
        ((p_1,_,(_,_,_,path_str_lst,_))) = AbsynUtil.traverseClasses(p,NONE(), renameClassVisitor, (old_path,new_path,p,{},env),
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNonEmptyElts(path_str_lst, ",");
        res = stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
  end matchcontinue;
end renameClass;

protected function renameClassVisitor
" This visitor renames a class given a new name.
   It returns a list of strings of renamed classes.
   The 'traversal-tuple' is therefore
   tuple<oldname, newname, program, string list, env>."
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, FCore.Graph>> inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, FCore.Graph>> outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
algorithm
  outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv)
    local
      Absyn.Path path_1,pa,old_class_path,new_class_path;
      String new_name,path_str,id,path_str_1;
      Boolean a,b,c,changed;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      SourceInfo file_info;
      Absyn.Program p;
      list<String> path_str_lst;
      FCore.Graph env,cenv;
      Absyn.Class class_1,class_;
      tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, FCore.Graph> args;
      Option<Absyn.Path> opath;

    // Skip readonly classes.
    case ((class_ as Absyn.CLASS(info = file_info),opath,args))
      equation
        true = isReadOnly(file_info);
      then
        ((class_,opath,args));

    case ((Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = Absyn.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));

    case ((Absyn.CLASS(name = id,partialPrefix = a,finalPrefix = b,encapsulatedPrefix = c,restriction = d,body = e,info = file_info),NONE(),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.IDENT(id);
        true = Absyn.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),NONE(),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));

    case (((class_ as Absyn.CLASS(name = id)),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str = if changed then Absyn.pathString(path_1) else "";
      then
        ((class_1,SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));

    case (((class_ as Absyn.CLASS(name = id)),NONE(),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation
        path_1 = Absyn.IDENT(id);
        cenv = getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str = if changed then Absyn.pathString(path_1) else "";
      then
        ((class_1,NONE(),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));

    case ((class_,opath,args))
      then
        ((class_,opath,args));
  end matchcontinue;
end renameClassVisitor;

protected function renameClassInClass
"author: x02lucpo
  helper function to renameClassVisitor
  renames all the references to a class to another"
  input Absyn.Class inClass1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input FCore.Graph inEnv4;
  output Absyn.Class outClass;
  output Boolean outBoolean;
algorithm
  (outClass,outBoolean):=
  matchcontinue (inClass1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      Boolean changed,partialPrefix,finalPrefix,encapsulatedPrefix;
      String name, baseClassName;
      Absyn.Restriction restriction;
      Option<String> comment;
      SourceInfo file_info;
      Absyn.Path old_comp,new_comp,path_1,path,new_path;
      FCore.Graph env,cenv;
      list<Absyn.ElementArg> modifications,elementarg;
      Option<Absyn.Comment> co;
      Absyn.Class class_;
      Option<list<Absyn.Subscript>> subscripts;
      Absyn.ElementAttributes attrs;
      FCore.Cache cache;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    /* the class with the component the old name for the component signal if something in class have been changed */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = comment),info = file_info),old_comp,new_comp,env)
      equation
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,comment),file_info),changed);
    /* model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = modifications,ann=ann,comment = comment,parts = parts),
                      info = file_info),old_comp,new_comp,env)
      equation
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.CLASS_EXTENDS(baseClassName,modifications,comment,parts_1,ann),file_info),changed);
    /* a derived class */
    case (Absyn.CLASS(name = name,partialPrefix = partialPrefix,finalPrefix = finalPrefix,encapsulatedPrefix = encapsulatedPrefix,restriction = restriction,
                      body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path_1,subscripts),attributes = attrs,arguments = elementarg,comment = co),
                      info = file_info),old_comp,new_comp,env)
      equation
        (cache,SCode.CLASS(name=name),cenv) = Lookup.lookupClass(FCore.emptyCache(), env, path_1);
        path_1 = Absyn.IDENT(name);
        (_,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,Absyn.DERIVED(Absyn.TPATH(new_path,subscripts),attrs,elementarg,co),file_info),true);
    /* otherwise */
    else (inClass1,false);

  end matchcontinue;
end renameClassInClass;

protected function renameClassInParts
"author: x02lucpo
  helper function to renameClassVisitor"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input FCore.Graph inEnv4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
  output Boolean outBoolean;
algorithm
  (outAbsynClassPartLst,outBoolean):=
  matchcontinue (inAbsynClassPartLst1,inPath2,inPath3,inEnv4)
    local
      FCore.Graph env;
      list<Absyn.ClassPart> res_1,res;
      Boolean changed1,changed2,changed;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.Path old_comp,new_comp;
      Absyn.ClassPart a;

    case ({},_,_,_) then ({},false);  // the old name for the component signal if something in class have been changed rule

    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = boolOr(changed1,changed2);
      then
        ((Absyn.PUBLIC(elements_1) :: res_1),changed);

    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = boolOr(changed1,changed2);
      then
        ((Absyn.PROTECTED(elements_1) :: res_1),changed);

    case ((a :: res),old_comp,new_comp,env)
      equation
        (res_1,changed) = renameClassInParts(res, old_comp, new_comp, env);
      then
        ((a :: res_1),changed);

  end matchcontinue;
end renameClassInParts;

protected function renameClassInElements
"author: x02lucpo
  helper function to renameClassVisitor"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input FCore.Graph inEnv4;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean outBoolean;
algorithm
  (outAbsynElementItemLst,outBoolean):=
  matchcontinue (inAbsynElementItemLst1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ElementItem> res_1,res;
      Boolean changed1,changed2,changed,finalPrefix;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.Path old_comp,new_comp;
      FCore.Graph env;
    case ({},_,_,_) then ({},false);  /* the old name for the component signal if something in class have been changed */
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = redeclare_,innerOuter = inner_outer,specification = elementspec,info = info,constrainClass = constrainClass)) :: res),old_comp,new_comp,env)
      equation
        (res_1,changed1) = renameClassInElements(res, old_comp, new_comp, env);
        (elementspec_1,changed2) = renameClassInElementSpec(elementspec, old_comp, new_comp, env);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(finalPrefix,redeclare_,inner_outer,elementspec_1,info,
          constrainClass));
        changed = boolOr(changed1,changed2);
      then
        ((element_1 :: res_1),changed);
    case ((element :: res),old_comp,new_comp,env)
      equation
        (res_1,changed) = renameClassInElements(res, old_comp, new_comp, env);
        element_1 = element;
      then
        ((element_1 :: res_1),changed);
  end matchcontinue;
end renameClassInElements;

protected function renameClassInElementSpec
"author: x02lucpo
  helper function to renameClassVisitor"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input FCore.Graph inEnv4;
  output Absyn.ElementSpec outElementSpec;
  output Boolean outBoolean;
algorithm
  (outElementSpec,outBoolean):=
  matchcontinue (inElementSpec1,inPath2,inPath3,inEnv4)
    local
      String id;
      FCore.Graph cenv,env;
      Absyn.Path path_1,path,new_path,old_comp,new_comp,comps;
      Absyn.ElementAttributes a;
      list<Absyn.ComponentItem> comp_items;
      Absyn.Import import_1,import_;
      Boolean changed;
      Option<Absyn.ArrayDim> x;
      Option<Absyn.Annotation> annOpt;
      FCore.Cache cache;
      Absyn.ElementSpec spec;
      Option<Absyn.Comment> cmt;
      list<Absyn.ElementArg> elargs;
      SourceInfo info;

    case (Absyn.COMPONENTS(attributes = a,typeSpec = Absyn.TPATH(path_1,x),components = comp_items),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed rule */
      equation
        (cache,SCode.CLASS(name=id),cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1);
        path_1 = Absyn.IDENT(id);
        (_,path) = Inst.makeFullyQualified(cache, cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path, new_comp);
      then
        (Absyn.COMPONENTS(a,Absyn.TPATH(new_path,x),comp_items),true);
    case (Absyn.EXTENDS(path = path_1,elementArg = elargs, annotationOpt=annOpt),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1) "print \"rename_class_in_element_spec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.EXTENDS(new_path,elargs,annOpt),true);
    case (Absyn.IMPORT(import_ = import_,comment = cmt, info = info),old_comp,new_comp,env)
      equation
        (import_1,changed) = renameClassInImport(import_, old_comp, new_comp, env);
      then
        (Absyn.IMPORT(import_1,cmt,info),changed);
    else (inElementSpec1,false);
  end matchcontinue;
end renameClassInElementSpec;

protected function renameClassInImport
"author: x02lucpo
  helper function to renameClassVisitor"
  input Absyn.Import inImport1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input FCore.Graph inEnv4;
  output Absyn.Import outImport;
  output Boolean outBoolean;
algorithm
  (outImport,outBoolean):=
  matchcontinue (inImport1,inPath2,inPath3,inEnv4)
    local
      FCore.Graph cenv,env;
      Absyn.Path path,new_path,path_1,old_comp,new_comp;
      String id;
      Absyn.Import import_;
      FCore.Cache cache;

    case (Absyn.NAMED_IMPORT(name = id,path = path_1),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed */
      equation
        (cache,_,cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.NAMED_IMPORT(id,new_path),true);
    case (Absyn.QUAL_IMPORT(path = path_1),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.QUAL_IMPORT(new_path),true);
    case (Absyn.NAMED_IMPORT(path = path_1),old_comp,new_comp,env)
      equation
        (cache,_,cenv) = Lookup.lookupClass(FCore.emptyCache(),env, path_1);
        (_,path) = Inst.makeFullyQualified(cache,cenv, path_1);
        true = Absyn.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.UNQUAL_IMPORT(new_path),true);
    else (inImport1,false);
  end matchcontinue;
end renameClassInImport;

protected function changeLastIdent
"author: x02lucpo
  chages the last ident of the first path to the last path ident ie:
  (A.B.CC,C.DD) => (A.B.DD)"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath:=
  match (inPath1,inPath2)
    local
      String a,b,b_1;
      Absyn.Path a_1,res,p1,p2;
    case (Absyn.IDENT(),Absyn.IDENT(name = b)) then Absyn.IDENT(b);
    case ((Absyn.IDENT()),(p2 as Absyn.QUALIFIED()))
      equation
        b_1 = Absyn.pathLastIdent(p2);
      then
        Absyn.IDENT(b_1);
    case ((p1 as Absyn.QUALIFIED()),(p2 as Absyn.IDENT()))
      equation
        a_1 = Absyn.stripLast(p1);
        res = Absyn.joinPaths(a_1, p2);
      then
        res;
    case ((p1 as Absyn.QUALIFIED()),(p2 as Absyn.QUALIFIED()))
      equation
        a_1 = Absyn.stripLast(p1);
        b_1 = Absyn.pathLastIdent(p2);
        res = Absyn.joinPaths(a_1, Absyn.IDENT(b_1));
      then
        res;
  end match;
end changeLastIdent;

public function isPrimitive
"Thisfunction takes a component reference and a program.
  It returns the true if the refrenced type is a primitive
  type, otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.Class class_;
      Boolean res;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (Absyn.CREF_IDENT(name = "Real"),_) then true;  /* Instead of elaborating and lookup these in env, we optimize a bit and just return true for these */
    case (Absyn.CREF_IDENT(name = "Integer"),_) then true;
    case (Absyn.CREF_IDENT(name = "String"),_) then true;
    case (Absyn.CREF_IDENT(name = "Boolean"),_) then true;
    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        class_ = getPathedClassInProgram(path, p);
        res = isPrimitiveClass(class_, p);
      then
        res;
    else false;
  end match;
end isPrimitive;

protected function createModel
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
protected
  Absyn.Ident name;
  Absyn.Within w;
  Absyn.Path wp;
algorithm
  if Absyn.crefIsIdent(inComponentRef) then
    name := Absyn.crefFirstIdent(inComponentRef);
    w := Absyn.TOP();
  else
    wp := Absyn.crefToPath(inComponentRef);
    (wp, Absyn.IDENT(name)) := Absyn.splitQualAndIdentPath(wp);
    w := Absyn.WITHIN(wp);
  end if;

  outProgram := updateProgram(Absyn.PROGRAM({
    Absyn.CLASS(name, false, false, false, Absyn.R_MODEL(), Absyn.dummyParts,
        Absyn.dummyInfo)}, w), inProgram);
end createModel;

protected function deleteClass
" This function takes a component reference and a program.
   It deletes the class specified by the component reference from the
   given program."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram) := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path cpath,parentcpath,parentparentcpath;
      Absyn.Class cdef,parentcdef,parentcdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      list<Absyn.Class> clist,clist_1;
      Absyn.Within w;

    case (class_,(p as Absyn.PROGRAM()))
      equation
        cpath = Absyn.crefToPath(class_) "Class inside another class, inside another class" ;
        parentcpath = Absyn.stripLast(cpath);
        parentparentcpath = Absyn.stripLast(parentcpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.WITHIN(parentparentcpath)), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM()))
      equation
        cpath = Absyn.crefToPath(class_) "Class inside other class" ;
        parentcpath = Absyn.stripLast(cpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.TOP()), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM()))
      equation
        cpath = Absyn.crefToPath(class_) "Top level class" ;
        cdef = getPathedClassInProgram(cpath, p);
        p.classes = deleteClassFromList(cdef, p.classes);
      then
        ("true",p);
    else ("false",inProgram);
  end matchcontinue;
end deleteClass;

protected function deleteClassFromList
"Helper function to deleteClass."
  input Absyn.Class inClass;
  input list<Absyn.Class> inAbsynClassLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst := match (inClass,inAbsynClassLst)
    local
      String name1,name2;
      list<Absyn.Class> xs,res;
      Absyn.Class cdef,x;

    case (_,{}) then {};  /* Empty list */

    case (Absyn.CLASS(name = name1),(Absyn.CLASS(name = name2) :: xs)) guard stringEq(name1, name2)
      then
        xs;

    case ((cdef as Absyn.CLASS()),(x :: xs))
      equation
        res = deleteClassFromList(cdef, xs);
      then
        (x :: res);
  end match;
end deleteClassFromList;

public function setClassComment
"author: PA
  Sets the class comment."
  input Absyn.Path path;
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output Boolean success;
algorithm
  (outProgram,success) := matchcontinue (path,inString,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      String str;

    case (p_class,str,p as Absyn.PROGRAM())
      equation
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setClassCommentInClass(cdef, str);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,true);

    else (inProgram,false);
  end matchcontinue;
end setClassComment;

protected function setClassCommentInClass
"author: PA
  Helper function to setClassComment"
  input Absyn.Class inClass;
  input String inString;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass,inString)
    local
      Absyn.ClassDef cdef_1,cdef;
      String id,cmt;
      Boolean p,f,e;
      Absyn.Restriction r;
      SourceInfo info;

    case (Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = cdef,info = info),cmt)
      equation
        cdef_1 = setClassCommentInClassdef(cdef, cmt);
      then
        Absyn.CLASS(id,p,f,e,r,cdef_1,info);
  end match;
end setClassCommentInClass;

protected function setClassCommentInClassdef
"author: PA
  Helper function to setClassCommentInClass"
  input Absyn.ClassDef inClassDef;
  input String inString;
  output Absyn.ClassDef outClassDef;
algorithm
  outClassDef:=
  matchcontinue (inClassDef,inString)
    local
      list<Absyn.ClassPart> p;
      String strcmt,id;
      Option<Absyn.Comment> cmt_1;
      Option<list<Absyn.Subscript>> ad;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> arg,args;
      Absyn.EnumDef edef;
      list<Absyn.Path> plst;
      Absyn.ClassDef c;
      Absyn.Path path;
      Option<Absyn.Comment> cmt;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    case (Absyn.PARTS(typeVars=typeVars,classAttrs=classAttrs,classParts = p,ann=ann),"") then Absyn.PARTS(typeVars,classAttrs,p,ann,NONE());
    case (Absyn.PARTS(typeVars=typeVars,classAttrs=classAttrs,classParts = p,ann=ann),strcmt) then Absyn.PARTS(typeVars,classAttrs,p,ann,SOME(strcmt));
    case (Absyn.DERIVED(typeSpec = Absyn.TPATH(path,ad),attributes = attr,arguments = arg,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.DERIVED(Absyn.TPATH(path,ad),attr,arg,cmt_1);
    case (Absyn.ENUMERATION(enumLiterals = edef,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.ENUMERATION(edef,cmt_1);
    case (Absyn.OVERLOAD(functionNames = plst,comment = cmt),strcmt)
      equation
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.OVERLOAD(plst,cmt_1);
    case (Absyn.CLASS_EXTENDS(baseClassName = id,modifications = args,ann = ann,parts = p),"") then Absyn.CLASS_EXTENDS(id,args,NONE(),p,ann);
    case (Absyn.CLASS_EXTENDS(baseClassName = id,modifications = args,ann = ann,parts = p),strcmt) then Absyn.CLASS_EXTENDS(id,args,SOME(strcmt),p,ann);
    else inClassDef;
  end matchcontinue;
end setClassCommentInClassdef;

protected function setClassCommentInCommentOpt
"author: PA
  Sets the string comment in an Comment option."
  input Option<Absyn.Comment> inAbsynCommentOption;
  input String inString;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm
  outAbsynCommentOption:=
  match (inAbsynCommentOption,inString)
    local
      Option<Absyn.Annotation> ann;
      String cmt;
    case (SOME(Absyn.COMMENT(ann,_)),"") then SOME(Absyn.COMMENT(ann,NONE()));
    case (SOME(Absyn.COMMENT(ann,_)),cmt) then SOME(Absyn.COMMENT(ann,SOME(cmt)));
    case (NONE(),cmt) then SOME(Absyn.COMMENT(NONE(),SOME(cmt)));
  end match;
end setClassCommentInCommentOpt;

protected function getShortDefinitionBaseClassInformation
"author: adrpo
  Returns all the prefixes of the base class and the base class array dimensions.
  {{bool,bool,bool}}"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
algorithm
  res_1 := matchcontinue(cr, p)
    local
      Absyn.Path path, baseClassPath;
      String name,strFlow,strStream,strVariability,strDirection,str,dim_str,strBaseClassPath;
      Boolean flowPrefix,streamPrefix;
      Absyn.Variability variability;
      Absyn.Direction direction;
      Absyn.ArrayDim arrayDim;
      Absyn.ClassDef cdef;
      Absyn.ElementAttributes attr;
      Absyn.Parallelism parallelism;

    case (_, _)
      equation
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(

          body = cdef as Absyn.DERIVED(typeSpec = Absyn.TPATH(baseClassPath, _),
                                       attributes = attr as Absyn.ATTR(flowPrefix, streamPrefix, _, _, _, _)) )
        = getPathedClassInProgram(path, p);
        dim_str = getClassDimensions(cdef);
        strBaseClassPath = Absyn.pathString(baseClassPath);
        strFlow = if flowPrefix then "\"flow\"" else "\"\"";
        strStream = if streamPrefix then "\"stream\"" else "\"\"";
        strVariability = attrVariabilityStr(attr);
        strDirection = attrDirectionStr(attr);
        str = stringAppendList({"{",strBaseClassPath, ",", strFlow,",", strStream, ",", strVariability, ",", strDirection, ",", dim_str,"}"});
      then
        str;

    else "{}";

  end matchcontinue;
end getShortDefinitionBaseClassInformation;

protected function getExternalFunctionSpecification
"author: adrpo
  Returns the external declaration from the function definition"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
algorithm
  res_1 := matchcontinue(cr, p)
    local
      Absyn.Path path;
      String strLanguage,strFuncName,strOutput,strArguments,strAnn1,strAnn2,str;
      Absyn.Class cls;
      Option<Absyn.Ident> funcName "The name of the external function" ;
      Option<String>      lang     "Language of the external function" ;
      Option<Absyn.ComponentRef> output_  "output parameter as return value" ;
      list<Absyn.Exp>            args     "only positional arguments, i.e. expression list" ;
      Option<Absyn.Annotation>   ann1, ann2;

    case (_, _)
      equation
        path = Absyn.crefToPath(cr);
        cls = getPathedClassInProgram(path, p);
        Absyn.EXTERNAL(Absyn.EXTERNALDECL(funcName, lang, output_, args, ann1), ann2) = Absyn.getExternalDecl(cls);
        strLanguage  = "\"" + Util.getOptionOrDefault(lang, "") + "\"";
        strOutput  = "\"" + Absyn.printComponentRefStr(
                                Util.getOptionOrDefault(
                                  output_,
                                  Absyn.CREF_IDENT("", {}))) + "\"";
        strFuncName  = "\"" + Util.getOptionOrDefault(funcName, "") + "\"";
        strArguments = "\"" + Dump.printExpLstStr(args) + "\"";
        strAnn1 = "\"" + Dump.unparseAnnotationOption(ann1) + "\"";
        strAnn2 = "\"" + Dump.unparseAnnotationOption(ann2) + "\"";
        str = stringAppendList({"{", strLanguage, ",", strOutput, ",", strFuncName, ",", strArguments, ",", strAnn1, ",", strAnn2, "}"});
      then
        str;

    else "{}";

  end matchcontinue;
end getExternalFunctionSpecification;

protected function getClassDimensions
"return the dimensions of a class
 as vector of dimension sizes in a string.
 Note: A class can only have dimensions if it is a short class definition."
  input Absyn.ClassDef cdef;
  output String str;
algorithm
  str := matchcontinue(cdef)
  local Absyn.ArrayDim ad;
    case(Absyn.DERIVED(typeSpec=Absyn.TPATH(arrayDim=SOME(ad)))) equation
      str = "{"+ stringDelimitList(List.map(ad,Dump.printSubscriptStr),",")
      + "}";
    then str;
    else "{}";
  end matchcontinue;
end getClassDimensions;

public function getClassRestriction
"author: PA
  Returns the class restriction of a class as a string."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output String outRestriction;
algorithm
  outRestriction:=
  matchcontinue (path,inProgram)
    local
      Absyn.Program p;
      Absyn.Restriction restr;
      String res;
    case (_,p)
      equation
        Absyn.CLASS(_,_,_,_,restr,_,_) = getPathedClassInProgram(path, p);
        res = Dump.unparseRestrictionStr(restr);
      then
        res;
    else "";
  end matchcontinue;
end getClassRestriction;

public function isType
"This function takes a component reference and a program.
  It returns true if the refrenced class has the restriction
  \"type\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_TYPE(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isType;

public function isConnector
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"connector\" or \"expandable connector\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isConnector;

public function isModel
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"model\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_MODEL(),_,_) = getPathedClassInProgram(path, inProgram);
      then true;
    else false;
  end matchcontinue;
end isModel;

public function isOperator
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"operator\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_OPERATOR(),_,_) = getPathedClassInProgram(path, inProgram);
      then true;
    else false;
  end matchcontinue;
end isOperator;

public function isOperatorRecord
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"operator record\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_OPERATOR_RECORD(),_,_) = getPathedClassInProgram(path, inProgram);
      then true;
    else false;
  end matchcontinue;
end isOperatorRecord;

public function isOperatorFunction
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"operator function\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()),_,_) = getPathedClassInProgram(path, inProgram);
      then true;
    else false;
  end matchcontinue;
end isOperatorFunction;

public function isRecord
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"record\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_RECORD(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isRecord;

public function isBlock
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"block\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_BLOCK(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isBlock;

public function isOptimization
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"Optimization\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_OPTIMIZATION(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isOptimization;

public function isFunction
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"function\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(_)),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isFunction;

public function isPackage
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"package\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_PACKAGE(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isPackage;

public function isClass
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"class\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_CLASS(),_,_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isClass;

public function isPartial
" This function takes a component reference and a program.
   It returns true if the refrenced class has the restriction
   \"class\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(partialPrefix=true) = getPathedClassInProgram(path, inProgram);
      then true;
    else false;
  end matchcontinue;
end isPartial;

protected function isParameter
" This function takes a class and a component reference and a program
   and returns true if the component referenced is a parameter."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      String i;
      Boolean f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
   /* a class with parts */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* an extended class: model extends M end M; */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(_,_,_,_,_,Absyn.CLASS_EXTENDS(parts=parts),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.PARAM(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* otherwise */
    else false;
  end matchcontinue;
end isParameter;

protected function isProtected
" This function takes a class and a component reference and a program
   and returns true if the component referenced is in a protected section."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst,protlst;
      Absyn.ComponentRef cr,classname;
    /* a class with parts */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        getComponentsContainsName(cr, publst);
      then
        false;
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        protlst = getProtectedList(parts);
        getComponentsContainsName(cr, protlst);
      then
        true;
    /* an extended class with parts: model extends M end M; */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        getComponentsContainsName(cr, publst);
      then
        false;
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(path, p);
        protlst = getProtectedList(parts);
        getComponentsContainsName(cr, protlst);
      then
        true;
    /* otherwise return false */
    else false;
  end matchcontinue;
end isProtected;

protected function isConstant
" This function takes a class and a component reference and a program
   and returns true if the component referenced is a constant."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program p;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,p)
    local
      Absyn.Path path;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
    /* a class with parts */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.CONST(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* an extended class with parts: model extends M end M; */
    case (cr,classname,_)
      equation
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.CONST(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    /* otherwise return false */
    else false;
  end matchcontinue;
end isConstant;

public function isEnumeration
" It returns true if the refrenced class has the restriction
   \"type\" and is an \"Enumeration\", otherwise it returns false."
  input Absyn.Path path;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:= matchcontinue (inProgram)
    case (_)
      equation
        Absyn.CLASS(_,_,_,_,Absyn.R_TYPE(),Absyn.ENUMERATION(_,_),_) = getPathedClassInProgram(path, inProgram);
      then
        true;
    else false;
  end matchcontinue;
end isEnumeration;

protected function isReplaceable
"Returns true if the class referenced by inString within inComponentRef1 is replaceable.
  Only look to Element Items of inComponentRef1 for components use getComponents."
  input Absyn.ComponentRef inComponentRef1;
  input String inString;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inString,inProgram)
    local
      Absyn.Path modelpath;
      Boolean res, public_res, protected_res;
      String str;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list, protected_elementitem_list;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    /* a class with parts - public elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        res = isReplaceableInElements(public_elementitem_list, str);
      then res;
    /* a class with parts - protected elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(modelpath, p);
        protected_elementitem_list = getProtectedList(parts);
        res = isReplaceableInElements(protected_elementitem_list, str);
      then res;
    /* an extended class with parts: model extends M end M; public elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        res = isReplaceableInElements(public_elementitem_list, str);
      then res;
    /* an extended class with parts: model extends M end M; protected elements */
    case (model_,str,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(modelpath, p);
        protected_elementitem_list = getProtectedList(parts);
        res = isReplaceableInElements(protected_elementitem_list, str);
      then res;
    else false;
  end matchcontinue;
end isReplaceable;

protected function isReplaceableInElements
"Helper function to isReplaceable."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAbsynElementItemLst, inString)
    local
      String str, id;
      Boolean res;
      list<Absyn.ElementItem> rest;
      Option<Absyn.RedeclareKeywords> r;
    case ({}, _) then false;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(redeclareKeywords = r,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id)))) :: _), str) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        true = stringEq(id,str);
        res = keywordReplaceable(r);
      then
        res;
    case ((_ :: rest), str)
      equation
        res = isReplaceableInElements(rest, str);
      then
        res;
  end matchcontinue;
end isReplaceableInElements;

public function isProtectedClass
"Returns true if the class referenced by inString within path is protected.
  Only look to Element Items of inComponentRef1 for components use getComponents."
  input Absyn.Path path;
  input String inString;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (path,inString,inProgram)
    local
      Boolean res, protected_res;
      String str;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> protected_elementitem_list;
      Absyn.Program p;
    /* a class with parts - protected elements */
    case (_,str,p)
      equation
        Absyn.CLASS(body=Absyn.PARTS(classParts=parts)) = getPathedClassInProgram(path, p);
        protected_elementitem_list = getProtectedList(parts);
        res = isProtectedClassInElements(protected_elementitem_list, str);
      then res;
    /* an extended class with parts: model extends M end M; protected elements */
    case (_,str,p)
      equation
        Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)) = getPathedClassInProgram(path, p);
        protected_elementitem_list = getProtectedList(parts);
        res = isProtectedClassInElements(protected_elementitem_list, str);
      then res;
    else false;
  end matchcontinue;
end isProtectedClass;

protected function isProtectedClassInElements
"Helper function to isProtectedClass."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input String inString;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inAbsynElementItemLst, inString)
    local
      String str, id;
      Boolean res;
      list<Absyn.ElementItem> rest;
    case ({}, _) then false;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id)))) :: _), str) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        true = stringEq(id,str);
      then
        true;
    case ((_ :: rest), str)
      equation
        res = isProtectedClassInElements(rest, str);
      then
        res;
    else false;
  end matchcontinue;
end isProtectedClassInElements;

protected function getEnumLiterals
"Returns the enum literals as a list of string."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString:= match (inClass)
    local
      list<Absyn.EnumLiteral> literals;
      String str;
      list<String> enumList;
    case (Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = literals))))
      equation
        enumList = List.map(literals, getEnumerationLiterals);
        str = stringDelimitList(enumList, ",");
        str = stringAppendList({"{",str,"}"});
      then
        str;
    case (_) then "{}";
  end match;
end getEnumLiterals;

public function getDerivedClassModifierNames
"Returns the derived class modifier names."
  input Absyn.Class inClass;
  output list<String> outString;
algorithm
  outString:= match (inClass)
    local
      list<Absyn.ElementArg> args;
      list<String> modifierNames;
    case (Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.DERIVED(arguments = args)))
      equation
        modifierNames = getModificationNames(args);
      then
        modifierNames;
    case (_) then {};
  end match;
end getDerivedClassModifierNames;

public function getDerivedClassModifierValue
  "Returns the derived class modifier value."
  input Absyn.Class cls;
  input Absyn.Path path;
  output String value;
protected
  list<Absyn.ElementArg> args;
algorithm
  try
    Absyn.CLASS(body = Absyn.DERIVED(arguments = args)) := cls;
    value := Dump.printExpStr(getModificationValue(args, path));
  else
    value := "";
  end try;
end getDerivedClassModifierValue;

protected function getElementitemContainsName
"Returns the element that has the component name given as argument."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementItem outElementItem;
algorithm
  outElementItem:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementItem elt,res;
      list<Absyn.ElementItem> rest;
    case (cr,(elt :: _))
      equation
        getComponentsContainsName(cr, {elt});
      then
        elt;
    case (cr,(_ :: rest))
      equation
        res = getElementitemContainsName(cr, rest);
      then
        res;
  end matchcontinue;
end getElementitemContainsName;

protected function getComponentsContainsName
"Return the ElementSpec containing the name
  given as argument from a list of ElementItems"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementSpec res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (res as Absyn.COMPONENTS(components = ellst)))) :: _))
      equation
        getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(_ :: xs))
      equation
        res = getComponentsContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getComponentsContainsName;

protected function getElementContainsName
"Return the Element containing the component name
  given as argument from a list of ElementItems."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.Element res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = (res as Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = ellst)))) :: _))
      equation
        getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(_ :: xs))
      equation
        res = getElementContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getElementContainsName;

protected function getCompitemNamed
"Helper function to getComponentsContainsName."
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output Absyn.ComponentItem outComponentItem;
algorithm
  outComponentItem := matchcontinue (inComponentRef,inAbsynComponentItemLst)
    local
      String id1,id2;
      Absyn.ComponentItem x,res;
      list<Absyn.ComponentItem> xs;
      Absyn.ComponentRef cr;

    case (Absyn.CREF_IDENT(name = id1),((x as Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id2))) :: _))
      equation
        true = stringEq(id1, id2);
      then
        x;

    case (cr,(_ :: xs))
      equation
        res = getCompitemNamed(cr, xs);
      then
        res;
  end matchcontinue;
end getCompitemNamed;

public function existClass
" This function takes a component reference and a program.
   It returns true if the refrenced class exists in the
   symbol table, otherwise it returns false."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;

    case (cr,p)
      equation
        path = Absyn.crefToPath(cr);
        getPathedClassInProgram(path, p);
      then
        true;

    else false;
  end matchcontinue;
end existClass;

public function isPrimitiveClass
"Return true of a class is a primitive class, i.e. one of the builtin
  classes or the \'type\' restricted class. It also checks derived classes
  using short class definition."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inClass,inProgram)
    local
      Absyn.Path inmodel,path;
      Absyn.Class cdef;
      Boolean res;
      String cname;
      Absyn.Program p;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_INTEGER()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_REAL()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_STRING()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_BOOLEAN()),_) then true;
    // BTH
    case (Absyn.CLASS(restriction = Absyn.R_PREDEFINED_CLOCK()),_) then true;
    case (Absyn.CLASS(restriction = Absyn.R_TYPE()),_) then true;
    case (Absyn.CLASS(name = cname,restriction = Absyn.R_CLASS(),body = Absyn.DERIVED(typeSpec = Absyn.TPATH(path,_))),p)
      equation
        inmodel = Absyn.crefToPath(Absyn.CREF_IDENT(cname,{}));
        (cdef,_) = lookupClassdef(path, inmodel, p);
        res = isPrimitiveClass(cdef, p);
      then
        res;
  end match;
end isPrimitiveClass;

public function mergeProgram
  "Merges two programs into one."
  input Absyn.Program newProgram;
  input Absyn.Program oldProgram;
  output Absyn.Program program;
protected
  list<Absyn.Class> cl1, cl2;
  Absyn.Within w;
algorithm
  Absyn.PROGRAM(classes = cl1, within_ = w) := newProgram;
  Absyn.PROGRAM(classes = cl2) := oldProgram;
  program := Absyn.PROGRAM(listAppend(cl1, cl2), w);
end mergeProgram;

public function updateProgram
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input Absyn.Program inNewProgram;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  list<Absyn.Class> cs;
  Absyn.Within w;
algorithm
  Absyn.PROGRAM(classes=cs,within_=w) := inNewProgram;
  outProgram := updateProgram2(listReverse(cs),w,inOldProgram, mergeAST);
end updateProgram;

protected function updateProgram2
" This function takes an old program (second argument), i.e. the old
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
   It also takes in the current symboltable and returns a new one with any
   replaced functions cache cleared."
  input list<Absyn.Class> inNewClasses;
  input Absyn.Within w;
  input Absyn.Program inOldProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := match (inNewClasses,w,inOldProgram)
    local
      Absyn.Program prg,newp,p2,newp_1;
      Absyn.Class c1;
      String name;
      list<Absyn.Class> c2,c3;
      Absyn.Within w2;

    case ({},_,prg) then prg;

    case ((c1 as Absyn.CLASS(name = name)) :: c2,Absyn.TOP(), (p2 as Absyn.PROGRAM(classes = c3,within_ = w2)))
      equation
        if classInProgram(name, p2) then
          newp = replaceClassInProgram(c1, p2, mergeAST);
        else
          newp = Absyn.PROGRAM((c1 :: c3),w2);
        end if;
      then updateProgram2(c2,w,newp, mergeAST);

    case ((c1 :: c2),Absyn.WITHIN(),p2)
      equation
        newp = insertClassInProgram(c1, w, p2, mergeAST);
        newp_1 = updateProgram2(c2,w,newp, mergeAST);
      then newp_1;

  end match;
end updateProgram2;

public function addScope
" This function adds the scope of the scope variable to
   the program, so it can be inserted at the correct place.
   It also adds the scope to BEGIN_DEFINITION, COMP_DEFINITION
   and IMPORT_DEFINITION so an empty class definition can be
   inserted at the correct place."
  input Absyn.Program inProgram;
  input list<GlobalScript.Variable> inVariableLst;
  output Absyn.Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inProgram,inVariableLst)
    local
      Absyn.Path path,newpath,path2;
      list<Absyn.Class> cls;
      list<GlobalScript.Variable> vars;
      Absyn.Within w;
      Absyn.Program p;

    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.TOP()),vars)
      equation
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(path));

    case (Absyn.PROGRAM(classes = cls,within_ = w),vars)
      equation
        failure(_ = getVariableValue("scope", vars));
      then
        Absyn.PROGRAM(cls,w);
    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.WITHIN(path = path2)),vars)
      equation
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars) "This should probably be forbidden." ;
        newpath = Absyn.joinPaths(path, path2);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(newpath));
    else inProgram;
  end matchcontinue;
end addScope;

protected function getVariableValue
"Return the value of an interactive variable
  from a list of GlobalScript.Variable."
  input Absyn.Ident inIdent;
  input list<GlobalScript.Variable> inVariableLst;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inIdent,inVariableLst)
    local
      String id1,id2;
      Values.Value v;
      list<GlobalScript.Variable> rest;

    case (id1,(GlobalScript.IVAR(varIdent = id2,value = v) :: _))
      equation
        true = stringEq(id1, id2);
      then
        v;

    case (id1,(GlobalScript.IVAR(varIdent = id2) :: rest))
      equation
        false = stringEq(id1, id2);
        v = getVariableValue(id1, rest);
      then
        v;
  end matchcontinue;
end getVariableValue;

protected function getVariableValueLst
"Return the value of an interactive variable
  from a list of GlobalScript.Variable."
  input list<String> ids;
  input list<GlobalScript.Variable> vars;
  output Values.Value val;
algorithm
  val := matchcontinue (ids,vars)
    local
      Integer ix;
      String id1,id2,id3;
      Values.Value v;
      list<GlobalScript.Variable> rest;
      list<String> comp,srest;
      list<Values.Value> vals;
      DAE.Type t;

    case (id1::_, (GlobalScript.IVAR(varIdent = id2) :: rest))
      equation
        false = stringEq(id1, id2);
        v = getVariableValueLst(ids, rest);
      then
        v;

    case (id1::id2::srest, (GlobalScript.IVAR(varIdent = id3,value = Values.RECORD(orderd = vals, comp = comp)) :: _))
      equation
        true = stringEq(id1, id3);
        ix = List.position1OnTrue(comp, stringEq, id2);
        v = listGet(vals, ix);
        v = getVariableValueLst(id2::srest, {GlobalScript.IVAR(id2,v,DAE.T_UNKNOWN_DEFAULT)});
      then
        v;

    case ({id1}, (GlobalScript.IVAR(varIdent = id2,value = v) :: _))
      equation
        true = stringEq(id1, id2);
      then
        v;

  end matchcontinue;
end getVariableValueLst;

protected function lookupClassdef
" This function takes a Path of a class to lookup and a Path
   as a starting point for the lookup rules and a Program.
   It returns the Class definition and the complete Path to the class."
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input Absyn.Program inProgram3;
  output Absyn.Class outClass;
  output Absyn.Path outPath;
algorithm
  (outClass,outPath) := matchcontinue (inPath1,inPath2,inProgram3)
    local
      Absyn.Class inmodeldef,cdef;
      Absyn.Path newpath,path,inmodel,innewpath,respath;
      Absyn.Program p;
      String s1,s2;

    case (path,inmodel,p as Absyn.PROGRAM())
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 1 Looking for: " + Absyn.pathString(path) + " in: " + Absyn.pathString(inmodel));
        // remove self reference, otherwise we go into an infinite loop!
        path = InstUtil.removeSelfReference(Absyn.pathLastIdent(inmodel),path);
        inmodeldef = getPathedClassInProgram(inmodel, p) "Look first inside \'inmodel\'" ;
        cdef = getPathedClassInProgram(path, Absyn.PROGRAM({inmodeldef},Absyn.TOP()));
        newpath = Absyn.joinPaths(inmodel, path);
      then
        (cdef,newpath);

    case (path,inmodel,p) /* Then look inside next level */
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 2 Looking for: " + Absyn.pathString(path) + " in: " + Absyn.pathString(inmodel));
        innewpath = Absyn.stripLast(inmodel);
        (cdef,respath) = lookupClassdef(path, innewpath, p);
      then
        (cdef,respath);

    case (path,_,p)
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 3 Looking for: " + Absyn.pathString(path) + " in: " + Absyn.pathString(inmodel));
        cdef = getPathedClassInProgram(path, p) "Finally look in top level" ;
      then
        (cdef,path);

    case (Absyn.IDENT(name = "Real"),_,_) then (Absyn.CLASS("Real",false,false,false,Absyn.R_PREDEFINED_REAL(),
          Absyn.dummyParts,Absyn.dummyInfo),Absyn.IDENT("Real"));

    case (Absyn.IDENT(name = "Integer"),_,_) then (Absyn.CLASS("Integer",false,false,false,Absyn.R_PREDEFINED_INTEGER(),
          Absyn.dummyParts,Absyn.dummyInfo),Absyn.IDENT("Integer"));

    case (Absyn.IDENT(name = "String"),_,_) then (Absyn.CLASS("String",false,false,false,Absyn.R_PREDEFINED_STRING(),
          Absyn.dummyParts,Absyn.dummyInfo),Absyn.IDENT("String"));

    case (Absyn.IDENT(name = "Boolean"),_,_) then (Absyn.CLASS("Boolean",false,false,false,Absyn.R_PREDEFINED_BOOLEAN(),
          Absyn.dummyParts,Absyn.dummyInfo),Absyn.IDENT("Boolean"));
    // BTH
    case (Absyn.IDENT(name = "Clock"),_,_)
      equation
        true = Config.synchronousFeaturesAllowed();
      then (Absyn.CLASS("Clock",false,false,false,Absyn.R_PREDEFINED_CLOCK(),
          Absyn.dummyParts,Absyn.dummyInfo),Absyn.IDENT("Clock"));

    case (path,inmodel,_)
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 8 Looking for: " + Absyn.pathString(path) + " in: " + Absyn.pathString(inmodel));
        s1 = Absyn.pathString(path);
        s2 = Absyn.pathString(inmodel);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,s2});
      then
        fail();
  end matchcontinue;
end lookupClassdef;

protected function deleteOrUpdateComponent
" This function deletes a component from a class given the name of the
   component instance, the model in which the component is instantiated in,
   and the Program. Both public and protected lists are searched."
  input String inString;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Option<tuple<Absyn.Path,Absyn.ComponentItem>> item;
  output Absyn.Program outProgram;
algorithm
  outProgram := match (inString,inComponentRef,inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      String name;
      Absyn.ComponentRef model_;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Absyn.Within w;

    case (name,(model_ as Absyn.CREF_QUAL()),(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteOrUpdateComponentFromClass(name, cdef, item);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then newp;

    case (name,(model_ as Absyn.CREF_IDENT()),(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteOrUpdateComponentFromClass(name, cdef, item);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then newp;

  end match;
end deleteOrUpdateComponent;

protected function deleteOrUpdateComponentFromClass
" This function deletes a component from a class given
   the name of the component instance, and a \'Class\'.
   Both public and protected lists are searched."
  input String inString;
  input Absyn.Class inClass;
  input Option<tuple<Absyn.Path,Absyn.ComponentItem>> item;
  output Absyn.Class outClass;
algorithm
  outClass := match (inString,inClass)
    local
      list<Absyn.ElementItem> publst,publst2,protlst,protlst2;
      Integer l2,l1,l1_1;
      list<Absyn.ClassPart> parts2,parts;
      String name,i;
      Boolean p,f,e, success;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.Ident bcpath;
      list<Absyn.ElementArg> mod;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

     // Search in public list
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),
                           info = file_info))
      equation
        publst = getPublicList(parts);
        (publst2, success) = deleteOrUpdateComponentFromElementitems(name, publst, item);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        if (/*delete case*/(intEq(l1_1, l2) and boolNot(isSome(item)) and success) or
            /*update case*/(boolNot(intEq(l1_1, l2)) and isSome(item)) and success) then
          parts2 = replacePublicList(parts, publst2);
        else
          protlst = getProtectedList(parts);
          protlst2 = deleteOrUpdateComponentFromElementitems(name, protlst, item);
          parts2 = replaceProtectedList(parts, protlst2);
        end if;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

     // adrpo search also in model extends X end X
    case (name,Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.CLASS_EXTENDS(baseClassName=bcpath, modifications=mod, parts = parts,ann = ann,comment = cmt),
                           info = file_info))
      equation
        publst = getPublicList(parts);
        (publst2, success) = deleteOrUpdateComponentFromElementitems(name, publst, item);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        if (/*delete case*/(intEq(l1_1, l2) and boolNot(isSome(item)) and success) or
            /*update case*/(boolNot(intEq(l1_1, l2)) and isSome(item)) and success) then
          parts2 = replacePublicList(parts, publst2);
        else
          protlst = getProtectedList(parts);
          protlst2 = deleteOrUpdateComponentFromElementitems(name, protlst, item);
          parts2 = replaceProtectedList(parts, protlst2);
        end if;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcpath,mod,cmt,parts2,ann),file_info);
  end match;
end deleteOrUpdateComponentFromClass;

protected function deleteOrUpdateComponentFromElementitems
"Helper function to deleteOrUpdateComponentFromClass."
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Option<tuple<Absyn.Path,Absyn.ComponentItem>> item;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean success;
algorithm
  (outAbsynElementItemLst, success) := match (inString,inAbsynElementItemLst)
    local
      String name,name2;
      list<Absyn.ElementItem> xs,res;
      Absyn.ElementItem x;
      Absyn.Element elt, eltold;
      list<Absyn.ComponentItem> comps;
      Absyn.ComponentItem compitem;
      Absyn.ElementSpec spec;
      Absyn.Path tppath;
      Absyn.TypeSpec typeSpec;
      Boolean hasOtherComponents;
      Boolean successResult;
    case (_,{}) then ({}, false);
    case (name,(x as Absyn.ELEMENTITEM(element = elt as Absyn.ELEMENT(specification = spec as Absyn.COMPONENTS(typeSpec = typeSpec as Absyn.TPATH(), components = comps)))) :: xs)
      algorithm
        if max(match c
            case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2)) guard stringEq(name, name2) then true;
            else false;
            end match for c in comps) then
          // These components do contain the name we are looking for
          (res, successResult) := match item
            case SOME((tppath, compitem))
              algorithm
                // It is an update operation
                if Absyn.pathEqual(tppath, Absyn.typeSpecPath(spec.typeSpec)) then
                  spec.components := list(match c
                    case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2)) guard stringEq(name, name2) then compitem;
                    else c;
                  end match for c in comps);
                  elt.specification := spec;
                  res := Absyn.ELEMENTITEM(elt)::xs;
                  successResult := true;
                else
                  /* We need to split the old component into two parts: one with the renamed typename */
                  spec.components := list(c for c
                    guard match c
                      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2)) then not stringEq(name, name2);
                      else true;
                    end match in comps);
                  hasOtherComponents := not listEmpty(spec.components);
                  if hasOtherComponents then
                    elt.specification := spec;
                    eltold := elt;
                  end if;
                  spec.components := {compitem};
                  typeSpec.path := tppath;
                  spec.typeSpec := typeSpec;
                  elt.specification := spec;
                  res := Absyn.ELEMENTITEM(elt)::xs;
                  if hasOtherComponents then
                    res := Absyn.ELEMENTITEM(eltold)::res;
                  end if;
                  successResult := true;
                end if;
              then (res, successResult);
            else
              algorithm
                // It is a deletion
                if listLength(comps)==1 then
                  res := xs;
                  successResult := true;
                else
                  spec.components := list(c for c
                    guard match c
                      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2)) then not stringEq(name, name2);
                      else true;
                    end match in comps);
                  elt.specification := spec;
                  res := Absyn.ELEMENTITEM(elt)::xs;
                  successResult := true;
                end if;
              then (res, successResult);
          end match;
        else
          (res, successResult) := deleteOrUpdateComponentFromElementitems(name, xs, item);
          res := x :: res;
        end if;
      then (res, successResult);
    case (name,(x :: xs))
      equation
        // Did not find the name we are looking for in element x
        (res, successResult) = deleteOrUpdateComponentFromElementitems(name, xs, item);
      then ((x :: res), successResult);
  end match;
end deleteOrUpdateComponentFromElementitems;

public function addComponent " This function takes:
   arg1 - string giving the instancename,
   arg2 - `ComponentRef\' giving the component type
   arg3 - ComponentRef giving the model to instantiate the component within,
   arg4 - `NamedArg\' list of annotations
   arg5 - a Program.
   The result is an updated program with the component and its annotations
   inserted, and a string \"OK\" for success. If the insertion fails, a
   suitable error string is given along with the input Program.
"
  input String inString1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inString1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,modelwithin,tppath;
      String name, filename;
      Absyn.ComponentRef tp,model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Option<Absyn.Comment> annotation_;
      Option<Absyn.Modification> modification;
      Absyn.Within w;
      Absyn.InnerOuter io;
      Option<Absyn.RedeclareKeywords> redecl;
      Absyn.ElementAttributes attr;

    // class cannot be found
    case (_,_,model_,_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        failure(_ = getPathedClassInProgram(modelpath, p));
      then
        (p,"false\n");

    // adding component to model that resides inside package
    case (name,tp,model_,nargs,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        w = match modelpath case Absyn.IDENT() then Absyn.TOP(); else Absyn.WITHIN(Absyn.stripLast(modelpath)); end match;
        (cdef as Absyn.CLASS(info=SOURCEINFO(fileName=filename))) = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        annotation_ = annotationListToAbsynComment(nargs,NONE());
        modification = modificationToAbsyn(nargs,NONE());
        (io,redecl,attr) = getDefaultPrefixes(p,tppath);
        newcdef = addToPublic(cdef,
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,redecl,io,
          Absyn.COMPONENTS(attr,Absyn.TPATH(Absyn.pathStripSamePrefix(tppath,modelpath),NONE()),{
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),NONE(),annotation_)}),
          SOURCEINFO(filename,false,0,0,0,0,0.0),NONE())));
        newp = updateProgram(Absyn.PROGRAM({newcdef},w), p);
      then
        (newp,"Ok\n");

    else (inProgram5,"Error");

  end matchcontinue;
end addComponent;

protected function getDefaultPrefixes "Retrieves default prefixes by looking at the defaultComponentPrefixes annotation"
  input Absyn.Program p;
  input Absyn.Path className;
  output Absyn.InnerOuter io;
  output Option<Absyn.RedeclareKeywords> redecl;
  output Absyn.ElementAttributes attr;
algorithm
  (io,redecl,attr) := match(p,className)
  local String str;
    case(_,_) equation
      str = getNamedAnnotation(className,p,Absyn.IDENT("defaultComponentPrefixes"),SOME("{}"),getDefaultComponentPrefixesModStr);
      io = getDefaultInnerOuter(str);
      redecl = getDefaultReplaceable(str);
      redecl = makeReplaceableIfPartial(p, className, redecl);
      attr = getDefaultAttr(str);
    then(io,redecl,attr);
  end match;
end getDefaultPrefixes;

protected function makeReplaceableIfPartial
"This function takes:
  arg1 - a Program,
  arg2 - the path of class,
  arg3 - redeclare option.
  The result is an updated redeclare option.
  This function checks if the class is partial or not, if yes then it adds the replaceable keyword to the component."
  input Absyn.Program p;
  input Absyn.Path className;
  input Option<Absyn.RedeclareKeywords> redecl;
  output Option<Absyn.RedeclareKeywords> new_redecl;
algorithm
  new_redecl := match(p, className, redecl)
    case (_, _, NONE()) guard isPartial(className, p)
      then SOME(Absyn.REPLACEABLE());
    /* if the above case fails i.e class is not partial */
    case (_, _, NONE())
    then redecl;
    case (_, _, SOME(Absyn.REPLACEABLE()))
    then redecl;
  end match;
end makeReplaceableIfPartial;

protected function getDefaultInnerOuter "helper function to getDefaultPrefixes"
  input String str;
  output Absyn.InnerOuter io;
algorithm
    io := matchcontinue(str)
      case _ equation
        -1 = System.stringFind(str,"inner");
       -1 = System.stringFind(str,"outer");
      then Absyn.NOT_INNER_OUTER();

      case _ equation
       -1 = System.stringFind(str,"outer");
      then Absyn.INNER();

      case _ equation
       -1 = System.stringFind(str,"inner");
      then Absyn.OUTER();
      end matchcontinue;
end getDefaultInnerOuter;

protected function getDefaultReplaceable "helper function to getDefaultPrefixes"
  input String str;
  output Option<Absyn.RedeclareKeywords> repl;
algorithm
    repl := matchcontinue(str)
      case _ equation
        -1 = System.stringFind(str,"replaceable");
      then NONE();
      case _ equation
       failure(-1 = System.stringFind(str,"replaceable"));
      then SOME(Absyn.REPLACEABLE());
      end matchcontinue;
end getDefaultReplaceable;

protected function getDefaultAttr "helper function to getDefaultPrefixes"
  input String str;
  output Absyn.ElementAttributes attr;
algorithm
    attr := matchcontinue(str)
      case _ equation
        failure(-1 = System.stringFind(str,"parameter"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.PARAM(),Absyn.BIDIR(),Absyn.NONFIELD(),{});

      case _ equation
        failure(-1 = System.stringFind(str,"constant"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.CONST(),Absyn.BIDIR(),Absyn.NONFIELD(),{});

      case _ equation
        failure(-1 = System.stringFind(str,"discrete"));
      then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.DISCRETE(),Absyn.BIDIR(),Absyn.NONFIELD(),{});
      case _ then Absyn.ATTR(false,false,Absyn.NON_PARALLEL(),Absyn.VAR(),Absyn.BIDIR(),Absyn.NONFIELD(),{});
  end matchcontinue;
end getDefaultAttr;

protected function getDefaultComponentPrefixesModStr "Extractor function for defaultComponentPrefixes modifier"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue(mod)
    local Absyn.Exp e;
    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e)))) equation
      docStr = Dump.printExpStr(e);
    then docStr;
    else "";
  end matchcontinue;
end getDefaultComponentPrefixesModStr;

protected function updateComponent
" This function updates a component in a class. The reason for having
   thisfunction is that a deletion followed by an addition would mean that
   all optional arguments must be present to the add_componentfunction
   in order to get the same component attributes,etc. as previous."
  input String inString1;
  input Absyn.ComponentRef inTypeCref;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString) := matchcontinue (inString1,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.ComponentRef tp;
      Absyn.Path modelpath,modelwithin,tppath,tppath2;
      Option<Absyn.ArrayDim> x;
      Absyn.Program p_1,newp,p;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef,newcdef;
      list<Absyn.ElementItem> publst,protlst;
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      String name;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> items;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ArrayDim arrayDimensions;
      Option<Absyn.Modification> mod,modification;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> ann,annotation_;
      Absyn.ComponentRef model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Within w;

    // Updating a component to a model
    case (name,model_,nargs,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        tppath2 = Absyn.crefToPath(inTypeCref);
        Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) = getPathedClassInProgram(modelpath, p);
        publst = getPublicList(parts);
        protlst = getProtectedList(parts);
        Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(_,Absyn.TPATH(_,_),items),_,_) = getElementContainsName(Absyn.CREF_IDENT(name,{}), listAppend(publst, protlst));
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,arrayDimensions,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newp = deleteOrUpdateComponent(name, model_, p, SOME((tppath2, Absyn.COMPONENTITEM(Absyn.COMPONENT(name,arrayDimensions,modification),cond,annotation_))));
      then
        (newp,"true");

    // failure
    else (inProgram5,"false");
    /* adrpo: TODO!: handle also model extends M end M; i.e. CLASS_EXTENDS */
  end matchcontinue;
end updateComponent;

public function addClassAnnotation
  "Adds an annotation to the referenced class."
  input Absyn.ComponentRef inClass;
  input list<Absyn.NamedArg> inAnnotation;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
protected
  Absyn.Path class_path;
  Absyn.Class cls;
  Absyn.Within class_within;
algorithm
  class_path := Absyn.crefToPath(inClass);
  cls := getPathedClassInProgram(class_path, inProgram);
  cls := addClassAnnotationToClass(cls, annotationListToAbsyn(inAnnotation));
  class_within := if Absyn.pathIsIdent(class_path) then
    Absyn.TOP() else Absyn.WITHIN(Absyn.stripLast(class_path));
  outProgram := updateProgram(Absyn.PROGRAM({cls}, class_within), inProgram);
end addClassAnnotation;

public function addClassAnnotationToClass
  "Adds an annotation to a given class."
  input Absyn.Class inClass;
  input Absyn.Annotation inAnnotation;
  output Absyn.Class outClass;
protected
  Absyn.ClassDef body;
algorithm
  Absyn.CLASS(body = body) := inClass;

  body := match body
    case Absyn.PARTS()
      algorithm
        body.ann := {List.fold(body.ann, Absyn.mergeAnnotations, inAnnotation)};
      then
        body;

    case Absyn.DERIVED()
      algorithm
        body.comment := Absyn.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.ENUMERATION()
      algorithm
        body.comment := Absyn.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.OVERLOAD()
      algorithm
        body.comment := Absyn.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.CLASS_EXTENDS()
      algorithm
        body.ann := {List.fold(body.ann, Absyn.mergeAnnotations, inAnnotation)};
      then
        body;

    case Absyn.PDER()
      algorithm
        body.comment := Absyn.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;
  end match;

  outClass := Absyn.setClassBody(inClass, body);
end addClassAnnotationToClass;

protected function getInheritedClassesHelper
"Helper function to getInheritedClasses."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input FCore.Graph inEnv4;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inClass1,inClass2,inEnv4)
    local
      list<Absyn.ComponentRef> lst;
      Integer n_1,n;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      String str,id;
      SCode.Element c;
      Absyn.Class cdef;
      FCore.Graph env,env2,env_2;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;

    case ((c as SCode.CLASS(name = id,encapsulatedPrefix = encflag,restriction = restr)),cdef,env)
      algorithm
        ErrorExt.setCheckpoint("getInheritedClassesHelper");
        if SCode.isDerivedClass(c) then
          // for derived classes search in the parent
          env_2 := env;
        else
          // for non-derived classes search from self
          env2 := FGraph.openScope(env, encflag, id, FGraph.restrictionToScopeType(restr));
          ci_state := ClassInf.start(restr, FGraph.getGraphName(env2));
          (_,env_2,_,_,_) :=
            Inst.partialInstClassIn(FCore.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
          end if;
        lst := getBaseClasses(cdef, env_2);
        ErrorExt.rollBack("getInheritedClassesHelper");
      then
        lst;

    // clear any messages that may have been added
    case ((SCode.CLASS()),_,_)
      equation
        ErrorExt.rollBack("getInheritedClassesHelper");
      then
        fail();

  end matchcontinue;
end getInheritedClassesHelper;

public function getInheritedClasses
  input Absyn.Path inPath;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue inPath
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      FCore.Graph env,env_1;
      SCode.Element c;
      list<Absyn.ComponentRef> lst;
      Absyn.Program p;
      list<Absyn.ElementSpec> extendsLst;
      FCore.Cache cache;
      list<Absyn.Path> paths;

    case (modelpath)
      equation
        cdef = getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        p_1 = SymbolTable.getSCode();
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,(c as SCode.CLASS()),env_1) = Lookup.lookupClass(cache,env, modelpath);
        lst = getInheritedClassesHelper(c, cdef, env_1);
        failure({} = lst);
        paths = List.map(lst, Absyn.crefToPath);
      then
        paths;
    case (modelpath) /* if above fails, baseclass not defined. return its name */
      equation
        cdef = getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        extendsLst = getExtendsInClass(cdef);
        paths = List.map(extendsLst, Absyn.elementSpecToPath);
      then
        paths;
    else {};
  end matchcontinue;
end getInheritedClasses;

protected function getInheritanceCount
"This function takes a ComponentRef and a Program and
  returns the number of inherited classes in the class
  referenced by the ComponentRef."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        count = countBaseClasses(cdef);
      then
        count;
    else 0;
  end matchcontinue;
end getInheritanceCount;

protected function getNthInheritedClass
"This function takes a ComponentRef, an integer and a Program and returns
  the nth inherited class in the class referenced by the ComponentRef."
  input Absyn.ComponentRef inComponentRef;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inInteger)
    local
      Absyn.Path modelpath,path;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      FCore.Graph env,env_1;
      SCode.Element c;
      String id,str,s;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.ComponentRef model_;
      Integer n,n_1;
      Absyn.Program p;
      list<Absyn.ElementSpec> extends_;
      FCore.Cache cache;

    case (model_,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        p_1 = SymbolTable.getSCode();
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,(c as SCode.CLASS()),env_1) = Lookup.lookupClass(cache,env, modelpath);
        str = getNthInheritedClass2(c, cdef, n, env_1);
      then
        str;
    case (model_,n) /* if above fails, baseclass not defined. return its name */
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        extends_ = getExtendsInClass(cdef);
        Absyn.EXTENDS(path,_,_) = listGet(extends_, n);
        s = Absyn.pathString(path);
      then
        s;
    else "Error";
  end matchcontinue;
end getNthInheritedClass;

protected function getNthInheritedClassAnnotationOpt
"This function takes a ComponentRef, an integer and a Program and returns
  the ANNOTATION on the extends of the nth inherited class in the class referenced by the modelpath."
  input Absyn.Path inModelPath;
  input Integer inInteger;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output String outString;
  output Option<Absyn.Annotation> annotationOpt;
algorithm
  (outString, annotationOpt) := matchcontinue (inModelPath,inInteger,inClass,inProgram)
    local
      Absyn.Path modelpath,path;
      Absyn.Class cdef;
      String s;
      Integer n,n_1;
      Absyn.Program p;
      list<Absyn.ElementSpec> extends_;
      Option<Absyn.Annotation> annOpt;

    /* adrpo: fixme, handle this case too!
    case (modelpath,n,inClass,p)
      equation
        cdef = inClass;
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(cache, env, modelpath);
        str = getNthInheritedClass2(c, cdef, n, env_1);
      then
        (str, annOpt);
    */

    case (_,n,_,_) /* if above fails, baseclass not defined. return its name */
      equation
        cdef = inClass;
        extends_ = getExtendsInClass(cdef);
        Absyn.EXTENDS(path,_,annOpt) = listGet(extends_, n);
        s = Absyn.pathString(path);
      then
        (s, annOpt);

    else ("Error", NONE());
  end matchcontinue;
end getNthInheritedClassAnnotationOpt;

protected function getMapAnnotationStr
"function: getMapAnnotationStr"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input String inMapType "IconMap or DiagramMap";
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementArgLst, inMapType, inClass, inFullProgram, inModelPath)
    local
      String str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      String mapType;

    case ({}, _,_,_,_) then "{}";

    case ((ann as Absyn.MODIFICATION(path = Absyn.IDENT(name = mapType))) :: _,_,
          _, _, _)
      equation
        // make sure is the given type: IconMap or DiagramMap
        true = stringEqual(mapType, inMapType);
        str = getAnnotationString(Absyn.ANNOTATION({ann}), inClass, inFullProgram, inModelPath);
      then
        str;

    case (_ :: xs, _, _, _, _)
      equation
        str = getMapAnnotationStr(xs, inMapType, inClass, inFullProgram, inModelPath);
      then
        str;
  end matchcontinue;
end getMapAnnotationStr;

protected function getNthInheritedClassMapAnnotation
"This function takes a ComponentRef, an integer and a Program and returns
  the ANNOTATION on the extends of the nth inherited class in the class referenced by the ComponentRef."
  input Absyn.Path inModelPath;
  input Integer inInteger;
  input Absyn.Program inProgram;
  input String inMapType "IconMap or DiagramMap";
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inInteger,inProgram,inMapType)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      String s,annStr;
      Integer n;
      Absyn.Program p;
      list<Absyn.ElementArg> elArgs;

    case (modelpath,n,p,_)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (s, SOME(Absyn.ANNOTATION(elArgs))) = getNthInheritedClassAnnotationOpt(modelpath, n, cdef, p);
        annStr = getMapAnnotationStr(elArgs,inMapType, cdef, p, modelpath);
        s = "{" + s + ", " + annStr + "}";
      then
        s;
    case (modelpath,n,p,_)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (s, NONE()) = getNthInheritedClassAnnotationOpt(modelpath, n, cdef, p);
        s = "{" + s + ",{}}";
      then
        s;
    else "Error";
  end matchcontinue;
end getNthInheritedClassMapAnnotation;

protected function getExtendsInClass
"Returns all ElementSpec of EXTENDS in a class."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst := match (inClass)
    local
      list<Absyn.ElementSpec> res;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
    /* a class with parts */
    case (Absyn.CLASS(
                      body = Absyn.PARTS(classParts = parts)))
      equation
        res = getExtendsInParts(parts);
      then
        res;
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(
                      body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        res = getExtendsInParts(parts);
      then
        res;
    /* adrpo: TODO! how about model extends M(modifications) end M??
                    should we report EXTENDS(IDENT(M), modifications)? */
  end match;
end getExtendsInClass;

protected function getExtendsInParts
"author: PA
  Helper function to getExtendsInElass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> parts;

    case {} then {};

    case ((Absyn.PUBLIC(contents = elts) :: parts))
      equation
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: parts))
      equation
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: parts))
      equation
        res = getExtendsInParts(parts);
      then
        res;

  end matchcontinue;
end getExtendsInParts;

protected function getExtendsInElementitems
"author: PA
  Helper function to getExtendsInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.ElementSpec> res;
      Absyn.ElementSpec e;
      list<Absyn.ElementItem> es;
    case ({}) then {};
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (e as Absyn.EXTENDS()))) :: es))
      equation
        res = getExtendsInElementitems(es);
      then
        (e :: res);
    case ((_ :: es))
      equation
        res = getExtendsInElementitems(es);
      then
        res;
  end matchcontinue;
end getExtendsInElementitems;

protected function getNthInheritedClass2
"Helper function to getNthInheritedClass."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input FCore.Graph inEnv4;
  output String outString;
algorithm
  outString := match (inClass1,inClass2,inInteger3,inEnv4)
    local
      list<Absyn.ComponentRef> lst;
      Integer n_1,n;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      String str,id;
      SCode.Element c;
      Absyn.Class cdef;
      FCore.Graph env,env2,env_2;
      ClassInf.State ci_state;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;

    case ((c as SCode.CLASS(name = id,encapsulatedPrefix = encflag,restriction = restr)),cdef,n,env)
      algorithm
        // for derived classes, search in parents
        if SCode.isDerivedClass(c) then
          lst := getBaseClasses(cdef, env);
        else // for non-derived classes, search from inside the class
          env2 := FGraph.openScope(env, encflag, id, FGraph.restrictionToScopeType(restr));
          ci_state := ClassInf.start(restr, FGraph.getGraphName(env2));
          (_,env_2,_,_,_) :=
            Inst.partialInstClassIn(FCore.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
              DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
          lst := getBaseClasses(cdef, env_2);
        end if;
        cref := listGet(lst, n);
        path := Absyn.crefToPath(cref);
        str := Absyn.pathString(path);
      then
        str;
  end match;
end getNthInheritedClass2;

public function getComponentCount
" This function takes a ComponentRef and a Program and returns the
   number of public components in the class referenced by the ComponentRef."
  input Absyn.ComponentRef model_;
  input Absyn.Program p;
  output Integer count;
protected
  Absyn.Path modelpath;
  Absyn.Class cdef;
algorithm
  modelpath := Absyn.crefToPath(model_);
  cdef := getPathedClassInProgram(modelpath, p);
  count := countComponents(cdef);
end getComponentCount;

protected function countComponents
" This function takes a Class and returns the
   number of components in that class"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer c1,c2,res;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.Annotation> ann;

    // a class with parts
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (_ :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        res = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
      then
        res;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = {})) then 0;

    // adrpo: handle also an extended class with parts: model extends M end M;
    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: lst),ann=ann,comment = cmt),info = file_info)
      equation
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        res = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
      then
        res;

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {})) then 0;

    // a derived class
    case Absyn.CLASS(body = Absyn.DERIVED()) then -1;

  end matchcontinue;
end countComponents;

protected function countComponentsInElts
"Helper function to countComponents"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  match (inAbsynElementItemLst)
    local
      list<Absyn.ComponentItem> complst;
      list<Absyn.ElementItem> lst;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = complst))) :: lst))
      then
        countComponentsInElts(lst, inInteger + listLength(complst));
    case ((_ :: lst))
      then
        countComponentsInElts(lst, inInteger);
    case ({}) then inInteger;
  end match;
end countComponentsInElts;

protected function getNthComponent "
   This function takes a `ComponentRef\', a `Program\' and an int and
   returns a comma separated string of names containing the name, type
   and comment of that component.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      list<SCode.Element> p_1;
      FCore.Graph env,env_1;
      SCode.Element c;
      String id,str;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
      FCore.Cache cache;

    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,(c as SCode.CLASS()),env_1) = Lookup.lookupClass(cache,env, modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        str = getNthComponent2(c, cdef, n, env_1);
      then
        str;
    else "Error";
  end matchcontinue;
end getNthComponent;

protected function getNthComponent2
"Helper function to get_nth_component."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input FCore.Graph inEnv4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClass1,inClass2,inInteger3,inEnv4)
    local
      FCore.Graph env2,env_2,env;
      ClassInf.State ci_state;
      Absyn.Element comp;
      String s1,str,id;
      SCode.Element c;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Integer n;

    case ((c as SCode.CLASS(name = id,encapsulatedPrefix = encflag,restriction = restr)),cdef,n,env)
      equation
        env2 = FGraph.openScope(env, encflag, id, FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
        (_,env_2,_,_,_) =
          Inst.partialInstClassIn(FCore.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
        comp = getNthComponentInClass(cdef, n);
        {s1} = getComponentInfoOld(comp, env_2);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    else
      equation
        print("Interactive.getNthComponent2 failed\n");
      then
        fail();
  end matchcontinue;
end getNthComponent2;

protected function useQuotes
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inAbsynNamedArgLst)
    local
      Absyn.NamedArg a;
      list<Absyn.NamedArg> al;
      Boolean b,res;
    case ({}) then false;
    case ((Absyn.NAMEDARG(argName = "useQuotes",argValue = Absyn.BOOL(value = b)) :: _)) then b;
    case ((_ :: al))
      equation
        res = useQuotes(al);
      then
        res;
  end match;
end useQuotes;

protected function insertQuotesToList
  input list<String> inStringList;
  output list<String> outStringList;
algorithm
  outStringList := match (inStringList)
    local
      list<String> res,rest;
      String str_1,str;
    case ({}) then {};
    case ((str :: rest))
      equation
        str_1 = stringAppendList({"\"",str,"\""});
        res = insertQuotesToList(rest);
      then
        (str_1 :: res);
  end match;
end insertQuotesToList;

public function getComponents
" This function takes a `ComponentRef\', a `Program\' and an int and  returns
   a list of all components, as returned by get_nth_component."
  input Absyn.ComponentRef cr;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := getComponents2(cr,inBoolean);
end getComponents;

protected function getComponents2
" This function takes a `ComponentRef\', a `Program\' and an int and  returns
   a list of all components, as returned by get_nth_component."
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inBoolean)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      FCore.Graph env,env_1,env2,env_2;
      SCode.Element c;
      String id,s1,s2,str,res;
      SCode.Encapsulated encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      list<Absyn.Element> comps1,comps2;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      FCore.Cache cache;
      Boolean b, permissive;

    case (model_,b)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        p_1 = SymbolTable.getSCode();
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (cache,(c as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(cache,env, modelpath);
        env2 = FGraph.openScope(env_1, encflag, id, FGraph.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, FGraph.getGraphName(env2));
        permissive = Flags.getConfigBool(Flags.PERMISSIVE);
        Flags.setConfigBool(Flags.PERMISSIVE, true);
        (_,env_2,_,_,_) =
          Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(),
            Prefix.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
        Flags.setConfigBool(Flags.PERMISSIVE, permissive);
        comps1 = getPublicComponentsInClass(cdef);
        s1 = getComponentsInfo(comps1, b, "\"public\"", env_2);
        comps2 = getProtectedComponentsInClass(cdef);
        s2 = getComponentsInfo(comps2, b, "\"protected\"", env_2);
        str = Util.stringDelimitListNonEmptyElts({s1,s2}, ",");
        res = stringAppendList({"{",str,"}"});
      then res;
    else "Error";
  end matchcontinue;
end getComponents2;

protected function getComponentAnnotations " This function takes a `ComponentRef\', a `Program\' and
   returns a list of all component annotations, as returned by
   get_nth_component_annotation.
   Both public and protected components are returned, but they need to
   be in the same order as get_componentsfunctions, i.e. first public
   components then protected ones."
  input Absyn.ComponentRef inClassPath;
  input Absyn.Program inProgram;
  output String outString;
protected
  Absyn.Path model_path;
  Absyn.Class cdef;
  list<Absyn.Element> comps1, comps2, comps;
algorithm
  try
    model_path := Absyn.crefToPath(inClassPath);
    cdef := getPathedClassInProgram(model_path, inProgram);
    comps1 := getPublicComponentsInClass(cdef);
    comps2 := getProtectedComponentsInClass(cdef);
    comps := listAppend(comps1, comps2);
    outString := getComponentAnnotationsFromElts(comps, cdef, inProgram, model_path);
    outString := stringAppendList({"{", outString, "}"});
  else
    outString := "Error";
  end try;
end getComponentAnnotations;

protected function getNthComponentAnnotation "
   This function takes a `ComponentRef\', a `Program\' and an int and
   returns a comma separated string of values corresponding to the flat
   record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String s1,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        s1 = getComponentAnnotation(comp, cdef, p, modelpath);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    else "Error";
  end matchcontinue;
end getNthComponentAnnotation;

protected function getNthComponentModification "
  This function takes a `ComponentRef\', a `Program\' and an int and
  returns a comma separated string of values corresponding to the
  flat record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String str,str_1;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        str = getComponentModification(comp);
        str_1 = stringAppendList({"{",str,"}"});
      then
        str_1;
    else "Error";
  end matchcontinue;
end getNthComponentModification;

protected function getNthComponentCondition
"This function takes a `ComponentRef\', a `Program\' and an int and
  returns a component condition."
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String str,str_1;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        str = getComponentCondition(comp);
        str = System.trim(str, " ");
        str_1 = stringAppendList({"\"",str,"\""});
      then
        str_1;
    else "Error";
  end matchcontinue;
end getNthComponentCondition;

protected function getComponentCondition
" Helper function to getNthComponentCondition."
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst)))
      equation
        str = getComponentitemsCondition(lst);
      then
        str;
    else "";
  end matchcontinue;
end getComponentCondition;

protected function getComponentitemsCondition
"Helper function to getNthComponentCondition."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm
  outString:=
  match (inAbsynComponentItemLst)
    local
      String res;
      Option<Absyn.ComponentCondition> cond;
    case ({(Absyn.COMPONENTITEM(condition = cond))})
      equation
        res = Dump.unparseComponentCondition(cond);
      then
        res;
  end match;
end getComponentitemsCondition;

public function getNthConnection "
  This function takes a `ComponentRef\' and a `Program\' and an int and
  returns a comma separated string for the nth connection, e.g. \"R1.n,C.p\".
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output list<Values.Value> outValue;
algorithm
  outValue:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Equation eq;
      Option<Absyn.Comment> cmt;
      list<Values.Value> vals;
      String str,s1,s2;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        Absyn.EQUATIONITEM(equation_ = eq, comment = cmt) = listGet(getConnections(cdef), n);
        str = getStringComment(cmt);
        (s1, s2) = getConnectionStr(eq);
        vals = {Values.STRING(s1), Values.STRING(s2), Values.STRING(str)};
      then
        vals;
    else {};
  end matchcontinue;
end getNthConnection;

public function getStringComment
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString:=
  match (inAbsynCommentOption)
    local String str;
    case (SOME(Absyn.COMMENT(_,SOME(str)))) then str;
    else "";
  end match;
end getStringComment;

protected function addConnection "
  Adds a connect equation to the model, i..e connect(c1,c2)

  inputs: (Absyn.ComponentRef, /* model name */
             Absyn.ComponentRef, /* c1 */
             Absyn.ComponentRef, /* c2 */
             Absyn.NamedArg list, /* annotations */
             Absyn.Program) =>
  outputs: (string, Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,package_;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;
      Option<Absyn.Comment> cmt;
      list<Absyn.NamedArg> nargs;

    case ((model_ as Absyn.CREF_IDENT()),c1,c2,{},(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE(),Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
      then
        ("Ok",newp);

    case ((model_ as Absyn.CREF_QUAL()),c1,c2,{},(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE(),Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_IDENT()),c1,c2,nargs,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        cmt = annotationListToAbsynComment(nargs,NONE());
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt,Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_QUAL()),c1,c2,nargs,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        cmt = annotationListToAbsynComment(nargs,NONE());
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt,Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
      then
        ("Ok",newp);
  end matchcontinue;
end addConnection;

public function updateConnectionAnnotation
  "Updates a connection annotation in a model."
  input Absyn.Path inPath;
  input String inFrom;
  input String inTo;
  input Absyn.Annotation inAnnotation;
  input Absyn.Program inProgram;
  output Boolean outResult;
  output Absyn.Program outProgram;
algorithm
  (outResult, outProgram) := matchcontinue (inPath, inFrom , inTo, inAnnotation, inProgram)
    local
      Absyn.Path path, modelwithin;
      String from, to;
      Absyn.Annotation ann;
      Absyn.Class cdef, newcdef;
      Absyn.Program newp, p;

    case (path, from, to, ann, (p as Absyn.PROGRAM()))
      equation
        modelwithin = Absyn.stripLast(path);
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionAnnotationInClass(cdef, from, to, ann);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (true, newp);

    case (path, from, to, ann, (p as Absyn.PROGRAM()))
      equation
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionAnnotationInClass(cdef, from, to, ann);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (true, newp);

    case (_, _, _, _, (p as Absyn.PROGRAM())) then (false, p);
  end matchcontinue;
end updateConnectionAnnotation;

protected function updateConnectionAnnotationInClass
  "Helper function to updateConnectionAnnotation."
  input Absyn.Class inClass1;
  input String inFrom;
  input String inTo;
  input Absyn.Annotation inAnnotation;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1, inFrom, inTo, inAnnotation)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
      String from, to;
      Absyn.Annotation annotation_;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),info = file_info),from,to,annotation_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionAnnotationInEqList(eqlst, from, to, annotation_);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt),info = file_info),from,to,annotation_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionAnnotationInEqList(eqlst, from, to, annotation_);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);
  end match;
end updateConnectionAnnotationInClass;

protected function updateConnectionAnnotationInEqList
  "Helper function to updateConnectionAnnotation."
  input list<Absyn.EquationItem> equations;
  input String from;
  input String to;
  input Absyn.Annotation ann;
  output list<Absyn.EquationItem> outEquations = {};
protected
  Absyn.ComponentRef c1, c2;
  String c1_str, c2_str;
algorithm
  for eq in equations loop
    eq := match eq
      case Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2))
        algorithm
          c1_str := Absyn.crefString(c1);
          c2_str := Absyn.crefString(c2);

          if (c1_str == from and c2_str == to) or (c1_str == to and c2_str == from) then
            eq.comment := SOME(Absyn.COMMENT(SOME(ann), NONE()));
          end if;
        then
          eq;

      else eq;
    end match;

    outEquations := eq :: outEquations;
  end for;

  outEquations := Dangerous.listReverseInPlace(outEquations);
end updateConnectionAnnotationInEqList;

public function updateConnectionNames
  "Updates a connection connector names in a model."
  input Absyn.Path inPath;
  input String inFrom;
  input String inTo;
  input String inFromNew;
  input String inToNew;
  input Absyn.Program inProgram;
  output Boolean outResult;
  output Absyn.Program outProgram;
algorithm
  (outResult, outProgram) := matchcontinue (inPath, inFrom, inTo, inFromNew, inToNew, inProgram)
    local
      Absyn.Path path, modelwithin;
      String from, to, fromNew, toNew;
      Absyn.Class cdef, newcdef;
      Absyn.Program newp, p;

    case (path, from, to, fromNew, toNew, (p as Absyn.PROGRAM()))
      equation
        modelwithin = Absyn.stripLast(path);
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionNamesInClass(cdef, from, to, fromNew, toNew);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (true, newp);

    case (path, from, to, fromNew, toNew, (p as Absyn.PROGRAM()))
      equation
        cdef = getPathedClassInProgram(path, p);
        newcdef = updateConnectionNamesInClass(cdef, from, to, fromNew, toNew);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (true, newp);

    case (_, _, _, _, _, (p as Absyn.PROGRAM())) then (false, p);
  end matchcontinue;
end updateConnectionNames;

protected function updateConnectionNamesInClass
  "Helper function to updateConnectionNames."
  input Absyn.Class inClass1;
  input String inFrom;
  input String inTo;
  input String inFromNew;
  input String inToNew;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1, inFrom, inTo, inFromNew, inToNew)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
      String from, to, fromNew, toNew;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),info = file_info),from,to,fromNew,toNew)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionNamesInEqList(eqlst, from, to, fromNew, toNew);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt),info = file_info),from,to,fromNew,toNew)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = updateConnectionNamesInEqList(eqlst, from, to, fromNew, toNew);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);
  end match;
end updateConnectionNamesInClass;

protected function updateConnectionNamesInEqList
  "Helper function to updateConnectionNames."
  input list<Absyn.EquationItem> equations;
  input String from;
  input String to;
  input String fromNew;
  input String toNew;
  output list<Absyn.EquationItem> outEquations = {};
protected
  Absyn.ComponentRef c1, c2;
  String c1_str, c2_str;
algorithm
  for eq in equations loop
    eq := match eq
      case Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2))
        algorithm
          c1_str := Absyn.crefString(c1);
          c2_str := Absyn.crefString(c2);

          if (c1_str == from and c2_str == to) or (c1_str == to and c2_str == from) then
            eq.equation_ := Absyn.EQ_CONNECT(Parser.stringCref(fromNew), Parser.stringCref(toNew));
          end if;
        then
          eq;

      else eq;
    end match;

    outEquations := eq :: outEquations;
  end for;

  outEquations := Dangerous.listReverseInPlace(outEquations);
end updateConnectionNamesInEqList;

protected function deleteConnection "
  Delete the connection connect(c1,c2) from a model.

  inputs:  (Absyn.ComponentRef, /* model name */
              Absyn.ComponentRef, /* c1 */
              Absyn.ComponentRef, /* c2 */
              Absyn.Program)
  outputs:  (string,Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;

    case (model_,c1,c2,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        ("Ok",newp);
    case (model_,c1,c2,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        ("Ok",newp);
    case (_,_,_,(p as Absyn.PROGRAM())) then ("Error",p);
  end matchcontinue;
end deleteConnection;

protected function deleteEquationInClass
"Helper function to deleteConnection."
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.ComponentRef c1,c2;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),info = file_info),c1,c2)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteEquationInEqlist(eqlst, c1, c2);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt),info = file_info),c1,c2)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteEquationInEqlist(eqlst, c1, c2);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);
  end match;
end deleteEquationInClass;

protected function deleteEquationInEqlist
"Helper function to deleteConnection."
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := match (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> res,xs;
      Absyn.ComponentRef cn1,cn2,c1,c2;
      Absyn.EquationItem x;

    case ({},_,_) then {};
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = cn1,connector2 = cn2)) :: xs),c1,c2)
      guard
        Absyn.crefEqual(c1,cn1) and Absyn.crefEqual(c2,cn2)
      then
        deleteEquationInEqlist(xs, c1, c2);
    case ((x :: xs),c1,c2)
      equation
        res = deleteEquationInEqlist(xs, c1, c2);
      then
        (x :: res);
  end match;
end deleteEquationInEqlist;

public function addTransition
"Adds a transition to the model, i.e., transition(state1, state2, i > 10)"
  input Absyn.ComponentRef inComponentRef;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b,outProgram) := addTransitionWithAnnotation(inComponentRef, from, to, condition, immediate, reset, synchronize, priority, annotationListToAbsyn(inAbsynNamedArgLst), inProgram);
end addTransition;

public function addTransitionWithAnnotation
"Adds a transition to the model, i.e., transition(state1, state2, i > 10)"
  input Absyn.ComponentRef inComponentRef;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  input Absyn.Annotation inAnnotation;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b,outProgram) := match (inComponentRef, from, to, condition, immediate, reset, synchronize, priority, inAnnotation, inProgram)
    local
      Absyn.Path modelpath,package_;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_;
      String from_, to_, condition_;
      Boolean immediate_, reset_, synchronize_;
      Integer priority_;
      Absyn.Within w;
      Absyn.Annotation ann;
      Option<Absyn.Comment> cmt;
      Absyn.Exp conditionExp;

    case ((model_ as Absyn.CREF_IDENT()), from_, to_, condition_, immediate_, reset_, synchronize_, priority_, ann,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        GlobalScript.ISTMTS({GlobalScript.IEXP(conditionExp, _)}, _) = Parser.parsestringexp(condition_);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("transition", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(from_, {})), Absyn.CREF(Absyn.CREF_IDENT(to_, {})),
                                conditionExp}, {Absyn.NAMEDARG("immediate", Absyn.BOOL(immediate_)),
                                Absyn.NAMEDARG("reset", Absyn.BOOL(reset_)), Absyn.NAMEDARG("synchronize", Absyn.BOOL(synchronize_)),
                                Absyn.NAMEDARG("priority", Absyn.INTEGER(priority_))})), cmt, Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
      then
        (true, newp);

    case ((model_ as Absyn.CREF_QUAL()), from_, to_, condition_, immediate_, reset_, synchronize_, priority_, ann,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        GlobalScript.ISTMTS({GlobalScript.IEXP(conditionExp, _)}, _) = Parser.parsestringexp(condition_);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("transition", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(from_, {})), Absyn.CREF(Absyn.CREF_IDENT(to_, {})),
                                conditionExp}, {Absyn.NAMEDARG("immediate", Absyn.BOOL(immediate_)),
                                Absyn.NAMEDARG("reset", Absyn.BOOL(reset_)), Absyn.NAMEDARG("synchronize", Absyn.BOOL(synchronize_)),
                                Absyn.NAMEDARG("priority", Absyn.INTEGER(priority_))})), cmt, Absyn.dummyInfo));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
      then
        (true, newp);
  end match;
end addTransitionWithAnnotation;

public function deleteTransition
"Delete the transition transition(c1,c2) from a model."
  input Absyn.ComponentRef inComponentRef1;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  input Absyn.Program inProgram;
  output Boolean b;
  output Absyn.Program outProgram;
algorithm
  (b,outProgram) := matchcontinue (inComponentRef1, from, to, condition, immediate, reset, synchronize, priority, inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      String from_, to_, condition_;
      Boolean immediate_, reset_, synchronize_;
      Integer priority_;
      Absyn.Within w;

    case (model_, from_, to_, condition_, immediate_, reset_, synchronize_, priority_ ,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteTransitionInClass(cdef, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (true, newp);
    case (model_, from_, to_, condition_, immediate_, reset_, synchronize_, priority_ ,(p as Absyn.PROGRAM()))
      equation
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteTransitionInClass(cdef, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (true, newp);
    case (_,_,_,_,_,_,_,_,(p as Absyn.PROGRAM())) then (false, p);
  end matchcontinue;
end deleteTransition;

protected function deleteTransitionInClass
"Helper function to deleteTransition."
  input Absyn.Class inClass;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass, from, to, condition, immediate, reset, synchronize, priority)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i, bcname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      String from_, to_, condition_;
      Boolean immediate_, reset_, synchronize_;
      Integer priority_;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),
                      info = file_info), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteTransitionInEqlist(eqlst, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);
    /* an extended class with parts: model extends M end M;  */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)
                      ,info = file_info), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      equation
        eqlst = getEquationList(parts);
        eqlst_1 = deleteTransitionInEqlist(eqlst, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);
  end match;
end deleteTransitionInClass;

protected function deleteTransitionInEqlist
"Helper function to deleteTransition."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := matchcontinue (inAbsynEquationItemLst, from, to, condition, immediate, reset, synchronize, priority)
    local
      list<Absyn.EquationItem> res,xs;
      String from_, to_, condition_;
      Boolean immediate_, reset_, synchronize_;
      Integer priority_;
      Absyn.ComponentRef name;
      list<Absyn.Exp> expArgs;
      list<Absyn.NamedArg> namedArgs;
      list<String> args;
      Absyn.Exp conditionExp;
      Absyn.EquationItem x;

    case ({},_,_,_,_,_,_,_) then {};
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_NORETCALL(name, Absyn.FUNCTIONARGS(expArgs, namedArgs))) :: xs), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      guard Absyn.crefEqual(name, Absyn.CREF_IDENT("transition", {}))
      equation
        args = List.map(expArgs, Dump.printExpStr);
        args = addOrUpdateNamedArg(namedArgs, "immediate", "true", args, 4);
        args = addOrUpdateNamedArg(namedArgs, "reset", "true", args, 5);
        args = addOrUpdateNamedArg(namedArgs, "synchronize", "false", args, 6);
        args = addOrUpdateNamedArg(namedArgs, "priority", "1", args, 7);
        // parse the condition string to make it EXP.
        GlobalScript.ISTMTS({GlobalScript.IEXP(conditionExp, _)}, _) = Parser.parsestringexp(condition_);
        condition_ = Dump.printExpStr(conditionExp);
        true = compareTransitionFuncArgs(args, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
      then
        deleteTransitionInEqlist(xs, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
    case ((x :: xs), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      equation
        res = deleteTransitionInEqlist(xs, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
      then
        (x :: res);
  end matchcontinue;
end deleteTransitionInEqlist;

public function addOrUpdateNamedArg
  "Applies the named argument value if it exists.
  The named argument override the value of argument if its on same position."
  input list<Absyn.NamedArg> inNamedArgLst;
  input String namedArg;
  input String defaultValue;
  input list<String> inTransition;
  input Integer position;
  output list<String> outTransition;
protected
  String namedArgValue;
  Boolean isDefault;
algorithm
  (namedArgValue, isDefault) := namedArgValueAsString(inNamedArgLst, namedArg, defaultValue);
  if listLength(inTransition) < position then
    outTransition := List.insert(inTransition, position, namedArgValue);
  elseif boolAnd((listLength(inTransition) >= position), boolNot(isDefault)) then
    outTransition := List.replaceAt(namedArgValue, position, inTransition);
  else
    outTransition := inTransition;
  end if;
end addOrUpdateNamedArg;

protected function namedArgValueAsString
  "Returns the named argument value as string."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input String inNamedArg;
  input String inDefaultValue;
  output String outNamedArg;
  output Boolean outDefault;
algorithm
  (outNamedArg, outDefault) := match (inAbsynNamedArgLst)
    local
      Absyn.NamedArg namedArg;
      list<Absyn.NamedArg> al;
      Absyn.Ident namedArgName;
      Absyn.Exp namedArgValue;

    case ({}) then (inDefaultValue,true);

    case (((namedArg as Absyn.NAMEDARG(argName = namedArgName)) :: _))
      guard stringEq(namedArgName, inNamedArg)
      then
        (Dump.printNamedArgValueStr(namedArg), false);

    case ((_ :: al))
      then
        namedArgValueAsString(al, inNamedArg, inDefaultValue);

  end match;
end namedArgValueAsString;

protected function compareTransitionFuncArgs
"Helper function to deleteTransition."
  input list<String> args;
  input String from;
  input String to;
  input String condition;
  input Boolean immediate;
  input Boolean reset;
  input Boolean synchronize;
  input Integer priority;
  output Boolean b;
algorithm
  b := matchcontinue (args, from, to, condition, immediate, reset, synchronize, priority)
    local
      String from1, to1, condition1, immediate1, reset1, synchronize1, priority1, from2, to2, condition2;
      Boolean immediate2, reset2, synchronize2;
      Integer priority2;

    case ({from1, to1, condition1}, from2, to2, condition2, _, _, _, _)
      guard
        stringEq(from1, from2) and stringEq(to1, to2) and stringEq(condition1, condition2)
      then
        true;

    case ({from1, to1, condition1, immediate1}, from2, to2, condition2, immediate2, _, _, _)
      guard
        stringEq(from1, from2) and stringEq(to1, to2) and stringEq(condition1, condition2) and stringEq(immediate1, boolString(immediate2))
      then
        true;

    case ({from1, to1, condition1, immediate1, reset1}, from2, to2, condition2, immediate2, reset2, _, _)
      guard
        stringEq(from1, from2) and stringEq(to1, to2) and stringEq(condition1, condition2) and stringEq(immediate1, boolString(immediate2))
        and stringEq(reset1, boolString(reset2))
      then
        true;

    case ({from1, to1, condition1, immediate1, reset1, synchronize1}, from2, to2, condition2, immediate2, reset2, synchronize2, _)
      guard
        stringEq(from1, from2) and stringEq(to1, to2) and stringEq(condition1, condition2) and stringEq(immediate1, boolString(immediate2))
        and stringEq(reset1, boolString(reset2)) and stringEq(synchronize1, boolString(synchronize2))
      then
        true;

    case ({from1, to1, condition1, immediate1, reset1, synchronize1, priority1}, from2, to2, condition2, immediate2, reset2, synchronize2, priority2)
      guard
        stringEq(from1, from2) and stringEq(to1, to2) and stringEq(condition1, condition2) and stringEq(immediate1, boolString(immediate2))
        and stringEq(reset1, boolString(reset2)) and stringEq(synchronize1, boolString(synchronize2)) and stringEq(priority1, intString(priority2))
      then
        true;

    else false;
  end matchcontinue;
end compareTransitionFuncArgs;

protected function getComponentComment
"Get the component commment."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram4;
  output String outString;
algorithm
  (outString) :=  match (inComponentRef1,inComponentRef2,inProgram4)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      Absyn.Program p;
      Absyn.ComponentRef class_,cr1;
      String cmt;
    case (class_,cr1,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        cmt = getComponentCommentInClass(cdef, cr1);
      then
        cmt;
  end match;
end getComponentComment;

protected function getComponentCommentInClass
"Helper function to getComponentComment."
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inClass,inComponentRef)
    local
      list<Absyn.ClassPart> parts;
      String cmt;
      Absyn.ComponentRef cr1;
    /* a class with parts */
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),cr1)
      equation
        cmt = getComponentCommentInParts(parts, cr1);
      then
        cmt;
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),cr1)
      equation
        cmt = getComponentCommentInParts(parts, cr1);
      then
        cmt;
  end match;
end getComponentCommentInClass;

protected function getComponentCommentInParts
"Helper function to getComponentComment."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynClassPartLst,inComponentRef)
    local
      list<Absyn.ElementItem> elts,e;
      list<Absyn.ClassPart> xs;
      Absyn.ComponentRef cr1;
      String cmt;
      Absyn.ClassPart p;

    case ((Absyn.PUBLIC(contents = elts) :: _),cr1)
      equation
        cmt = getComponentCommentInElementitems(elts, cr1);
      then
        cmt;

    // rule above failed
    case ((Absyn.PUBLIC() :: xs),cr1)
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;

    case ((Absyn.PROTECTED(contents = elts) :: _),cr1)
      equation
        cmt = getComponentCommentInElementitems(elts, cr1);
      then
        cmt;

    // rule above failed
    case ((Absyn.PROTECTED() :: xs),cr1)
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;

    case ((_ :: xs),cr1)
      equation
        cmt = getComponentCommentInParts(xs, cr1);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInParts;

protected function getComponentCommentInElementitems
"Helper function to getComponentComment."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementItemLst,inComponentRef)
    local
      Absyn.ElementSpec spec;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      String cmt;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.ElementItem> es;
      Absyn.ComponentRef cr1;
      Absyn.ElementItem e;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = spec)) :: _),cr1)
      equation
        cmt = getComponentCommentInElementspec(spec, cr1);
      then
        cmt;
    case ((_ :: es),cr1)
      equation
        cmt = getComponentCommentInElementitems(es, cr1);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInElementitems;

protected function getComponentCommentInElementspec
"Helper function to getComponentComment."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inElementSpec,inComponentRef)
    local
      list<Absyn.ComponentItem> citems;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.ComponentRef cr;
      String cmt;
    case (Absyn.COMPONENTS(components = citems),cr)
      equation
        cmt = getComponentCommentInCompitems(citems, cr);
      then
        cmt;
  end match;
end getComponentCommentInElementspec;

protected function getComponentCommentInCompitems
"Helper function to getComponentComment."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynComponentItemLst,inComponentRef)
    local
      Option<Absyn.Comment> compcmt;
      String id,cmt;
      list<Absyn.Subscript> ad;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      list<Absyn.ComponentItem> cs;
      Absyn.ComponentRef cr;
      Absyn.ComponentItem c;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad),comment = compcmt) :: _),cr)
      equation
        true = Absyn.crefEqual(Absyn.CREF_IDENT(id,ad), cr);
        cmt = getClassCommentInCommentOpt(compcmt);
      then
        cmt;
    case ((_ :: cs),cr)
      equation
        cmt = getComponentCommentInCompitems(cs, cr);
      then
        cmt;
  end matchcontinue;
end getComponentCommentInCompitems;

protected function getClassCommentInCommentOpt
"Helper function to getComponentComment."
  input Option<Absyn.Comment> inComment;
  output String outString;
algorithm
  outString := match inComment
    case SOME(Absyn.COMMENT(comment = SOME(outString))) then outString;
    else "";
  end match;
end getClassCommentInCommentOpt;

protected function setComponentComment
"author :PA
  Sets the component commment given by class name and ComponentRef."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input String inString3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inString3,inProgram4)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1;
      String cmt;

    case (class_,cr1,cmt,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentCommentInClass(cdef, cr1, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        ("Ok",newp);

    else ("Error",inProgram4);
  end matchcontinue;
end setComponentComment;

protected function setComponentCommentInClass
"author: PA
  Helper function to setComponentComment."
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass,inComponentRef,inString)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt,bcname;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      SourceInfo info;
      Absyn.ComponentRef cr1;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = pcmt),info = info),cr1,cmt)
      equation
        parts_1 = setComponentCommentInParts(parts, cr1, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,pcmt),info);
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,ann=ann,comment = pcmt),info = info),cr1,cmt)
      equation
        parts_1 = setComponentCommentInParts(parts, cr1, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.CLASS_EXTENDS(bcname,modif,pcmt,parts_1,ann),info);
  end match;
end setComponentCommentInClass;

protected function setComponentCommentInParts
"author: PA
  Helper function to setComponentCommentInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inComponentRef,inString)
    local
      list<Absyn.ElementItem> elts_1,elts,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1;
      String cmt;
      Absyn.ClassPart p;

    case ((Absyn.PUBLIC(contents = elts) :: xs),cr1,cmt)
      equation
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PUBLIC(elts_1) :: xs);

    // rule above failed
    case ((Absyn.PUBLIC(contents = e) :: xs),cr1,cmt)
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PUBLIC(e) :: xs_1);

    case ((Absyn.PROTECTED(contents = elts) :: xs),cr1,cmt)
      equation
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PROTECTED(elts_1) :: xs);

    // rule above failed
    case ((Absyn.PROTECTED(contents = e) :: xs),cr1,cmt)
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PROTECTED(e) :: xs_1);

    case ((p :: xs),cr1,cmt)
      equation
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setComponentCommentInParts;

protected function setComponentCommentInElementitems
"author: PA
  Helper function to setComponentParts. "
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inComponentRef,inString)
    local
      Absyn.ElementSpec spec_1,spec;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      String cmt;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.ElementItem> es,es_1;
      Absyn.ComponentRef cr1;
      Absyn.ElementItem e;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = spec,info = info,constrainClass = constr)) :: es),cr1,cmt)
      equation
        spec_1 = setComponentCommentInElementspec(spec, cr1, cmt);
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,inout,spec_1,info,constr)) :: es);
    case ((e :: es),cr1,cmt)
      equation
        es_1 = setComponentCommentInElementitems(es, cr1, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setComponentCommentInElementitems;

protected function setComponentCommentInElementspec
"author: PA
  Helper function to setComponentElementitems."
  input Absyn.ElementSpec inElementSpec;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElementSpec,inComponentRef,inString)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.ComponentRef cr;
      String cmt;
    case (Absyn.COMPONENTS(attributes = attr,typeSpec=tp,components = citems),cr,cmt)
      equation
        citems_1 = setComponentCommentInCompitems(citems, cr, cmt);
      then
        Absyn.COMPONENTS(attr,tp,citems_1);
  end match;
end setComponentCommentInElementspec;

protected function setComponentCommentInCompitems
"author: PA
  Helper function to set_component_elementspec."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst,inComponentRef,inString)
    local
      Option<Absyn.Comment> compcmt_1,compcmt;
      String id,cmt;
      list<Absyn.Subscript> ad;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      list<Absyn.ComponentItem> cs,cs_1;
      Absyn.ComponentRef cr;
      Absyn.ComponentItem c;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = mod),condition = cond,comment = compcmt) :: cs),cr,cmt)
      equation
        true = Absyn.crefEqual(Absyn.CREF_IDENT(id,{}), cr);
        compcmt_1 = setClassCommentInCommentOpt(compcmt, cmt);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad,mod),cond,compcmt_1) :: cs);
    case ((c :: cs),cr,cmt)
      equation
        cs_1 = setComponentCommentInCompitems(cs, cr, cmt);
      then
        (c :: cs_1);
  end matchcontinue;
end setComponentCommentInCompitems;

protected function setConnectionComment
"author: PA
  Sets the nth connection comment."
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inString4,inProgram5)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1,cr2;
      String cmt;
    case (class_,cr1,cr2,cmt,p as Absyn.PROGRAM())
      equation
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setConnectionCommentInClass(cdef, cr1, cr2, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    else (inProgram5,"Error");
  end matchcontinue;
end setConnectionComment;

protected function setConnectionCommentInClass
"author: PA
  Sets a connection comment in a Absyn.Class given two Absyn,ComponentRef"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt,bcname;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      SourceInfo info;
      Absyn.ComponentRef cr1,cr2;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = pcmt),info = info),cr1,cr2,cmt)
      equation
        parts_1 = setConnectionCommentInParts(parts, cr1, cr2, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,pcmt),info);
    /* an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = restr,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,ann=ann,comment = pcmt),info = info),cr1,cr2,cmt)
      equation
        parts_1 = setConnectionCommentInParts(parts, cr1, cr2, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.CLASS_EXTENDS(bcname,modif,pcmt,parts_1,ann),info);
  end match;
end setConnectionCommentInClass;

protected function setConnectionCommentInParts
"author: PA
  Helper function to setConnectionCommentInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.EquationItem> e_1,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1,cr2;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt)
      equation
        e_1 = setConnectionCommentInEquations(e, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e_1) :: xs);
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt) /* rule above failed */
      equation
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e) :: xs_1);
    case ((p :: xs),cr1,cr2,cmt)
      equation
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setConnectionCommentInParts;

protected function setConnectionCommentInEquations
"author: PA
  Helper function to setConnectionCommentInParts"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3,inString4)
    local
      Option<Absyn.Comment> eqcmt_1,eqcmt;
      Absyn.ComponentRef c1,c2,cr1,cr2;
      list<Absyn.EquationItem> es,es_1;
      String cmt;
      Absyn.EquationItem e;
      SourceInfo info;
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2),comment = eqcmt, info = info) :: es),cr1,cr2,cmt)
      equation
        true = Absyn.crefEqual(cr1, c1);
        true = Absyn.crefEqual(cr2, c2);
        eqcmt_1 = setClassCommentInCommentOpt(eqcmt, cmt);
      then
        (Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),eqcmt_1,info) :: es);
    case ((e :: es),cr1,cr2,cmt)
      equation
        es_1 = setConnectionCommentInEquations(es, cr1, cr2, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setConnectionCommentInEquations;

protected function getNthConnectionAnnotation
"This function takes a ComponentRef and a Program and an int and
  returns a comma separated string  of values for the annotation of
  the nth connection."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.EquationItem citem;
      String s1,str;
      Absyn.Program p;
      Integer n;
    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        citem = listGet(getConnections(cdef), n);
        s1 = getConnectionAnnotationStr(citem, cdef, p, modelpath);
        str = stringAppendList({"{", s1, "}"});
      then
        str;
    else "{}";
  end matchcontinue;
end getNthConnectionAnnotation;

protected function getConnectorCount
"This function takes a ComponentRef and a Program and returns the number
  of connector components in the class given by the classname in the
  ComponentRef. A partial instantiation of the inheritance structure is
  performed in order to find all connectors of the class.
  inputs:  (Absyn.ComponentRef, Absyn.Program)
  outputs: string"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      String countstr;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation
        modelpath = Absyn.crefToPath(model_) "A complete instantiation is far too expensive. Instead we only
    look through the components of the class for types declared using
    the \"connector\" restricted class keyword. We also look in
    base classes  (recursively)
  " ;
        cdef = getPathedClassInProgram(modelpath, p);
        count = countPublicConnectors(modelpath, p, cdef);
        countstr = intString(count);
      then
        countstr;
    else "Error";
  end matchcontinue;
end getConnectorCount;

protected function getNthConnector
"This function takes a ComponentRef and a Program and an int and returns
  a string with the name of the nth
  connector component in the class given by ComponentRef in the Program."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String str,tpstr,resstr;
      Absyn.Program p;
      Integer n;

    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (str,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        tpstr = Absyn.pathString(tp);
        resstr = stringAppendList({str, ",", tpstr});
      then
        resstr;
    else "Error";
  end matchcontinue;
end getNthConnector;

protected function getNthConnectorIconAnnotation
" This function takes a ComponentRef and a Program and an int and returns
   a string with the name of the nth connectors icon annotation in the
   class given by ComponentRef in the Program."
  input Absyn.Path inModelPath;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inModelPath,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String resstr;
      Absyn.Program p;
      Integer n;
    case (modelpath,p,n)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        (_,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        resstr = getIconAnnotation(tp, p);
      then
        resstr;
    else "Error";
  end matchcontinue;
end getNthConnectorIconAnnotation;

protected function getDiagramAnnotation
"This function takes a Path and a Program and returns a comma separated
  string of values for the diagram annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        str = getAnnotationInClass(cdef, DIAGRAM_ANNOTATION(), p, modelpath);
      then
        str;
    else "{}";
  end matchcontinue;
end getDiagramAnnotation;

public function getNamedAnnotation
"This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Path id;
  input Option<T> default;
  input ModFunc f;
  partial function ModFunc
    input Option<Absyn.Modification> mod;
    output T docStr;
  end ModFunc;
  output T outString;
  replaceable type T subtypeof Any;
algorithm
  outString := matchcontinue (inPath,inProgram,id,default,f)
    local
      Absyn.Class cdef;
      T str;
      Absyn.Path modelpath;
      Absyn.Program p;

    case (modelpath,p,_,_,_)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        SOME(str) = Absyn.getNamedAnnotationInClass(cdef,id,f);
      then
        str;

    case (_,_,_,SOME(str),_) then str;
  end matchcontinue;
end getNamedAnnotation;

constant Absyn.Path USES_PATH = Absyn.Path.IDENT("uses");

public function getUsesAnnotation
  "Returns the uses-annotations of the top-level classes in the given program."
  input Absyn.Program program;
  output list<Annotation> outUses = {};

  type Annotation = tuple<Absyn.Path, list<String>, Boolean>;
protected
  Option<list<Annotation>> opt_uses;
  list<Annotation> uses;
  list<Absyn.Class> classes;
algorithm
  Absyn.PROGRAM(classes = classes) := program;

  for cls in classes loop
    opt_uses := Absyn.getNamedAnnotationInClass(cls, USES_PATH, getUsesAnnotationString);

    if isSome(opt_uses) then
      SOME(uses) := opt_uses;
      outUses := listAppend(uses, outUses);
    end if;
  end for;
end getUsesAnnotation;

public function getUsesAnnotationOrDefault
"This function takes a Path and a Program and returns a comma separated
  string of values for the Documentation annotation for the class named by the
  first argument."
  input Absyn.Program p;
  input Boolean requireExactVersion;
  output list<tuple<Absyn.Path,list<String>,Boolean>> usesStr;
protected
  list<Absyn.Path> paths;
  list<list<String>> strs;
algorithm
  usesStr := getUsesAnnotation(p);
  paths := List.map(usesStr,Util.tuple31);
  strs := List.map(usesStr,Util.tuple32);
  if not requireExactVersion then
    strs := List.map1(strs,listAppend,{"default"});
  end if;
  usesStr := list((p,s,false) threaded for p in paths, s in strs);
end getUsesAnnotationOrDefault;

protected function getUsesAnnotationString
  input Option<Absyn.Modification> mod;
  output list<tuple<Absyn.Path,list<String>,Boolean>> usesStr;
algorithm
  usesStr := match (mod)
    local
      list<Absyn.ElementArg> arglst;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then getUsesAnnotationString2(arglst);

  end match;
end getUsesAnnotationString;

protected function getUsesAnnotationString2
  input list<Absyn.ElementArg> eltArgs;
  output list<tuple<Absyn.Path,list<String>,Boolean>> strs;
algorithm
  strs := match eltArgs
    local
      list<Absyn.ElementArg> xs;
      String name,  version;
      list<tuple<Absyn.Path,list<String>,Boolean>> ss;
      Absyn.Info info;

    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = name),
      modification=SOME(Absyn.CLASSMOD(elementArgLst={
        Absyn.MODIFICATION(path = Absyn.IDENT(name="version"),modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.STRING(version)))))
      })))::xs)
      equation
        ss = getUsesAnnotationString2(xs);
      then (Absyn.IDENT(name),{version},false)::ss;

    case (Absyn.MODIFICATION(info = info, path = Absyn.IDENT(name = name))::xs)
      equation
        Error.addSourceMessage(Error.USES_MISSING_VERSION, {name}, info);
        ss = getUsesAnnotationString2(xs);
      then (Absyn.IDENT(name),{"default"},false)::ss;

    case (_::xs)
      equation
        ss = getUsesAnnotationString2(xs);
      then ss;

    end match;
end getUsesAnnotationString2;

protected function getIconAnnotation
"This function takes a Path and a Program and returns a comma separated
  string of values for the icon annotation for the class named by the
  first argument."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
        str = getAnnotationInClass(cdef, ICON_ANNOTATION(), p, modelpath);
      then
        str;
    else "{}";
  end matchcontinue;
end getIconAnnotation;

public function getPackagesInPath
" This function takes a Path and a Program and returns a list of the
   names of the packages found in the Path."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output list<Absyn.Path> paths;
algorithm
  paths := matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
      then getPackagesInClass(modelpath, p, cdef);
    else {};
  end matchcontinue;
end getPackagesInPath;

public function getTopPackages
" This function takes a Path and a Program and returns a list of the
   names of the packages found in the Path."
  input Absyn.Program p;
  output list<Absyn.Path> paths;
algorithm
  paths := List.map(getTopPackagesInProgram(p),Absyn.makeIdentPathFromString);
end getTopPackages;

protected function getTopPackagesInProgram
"Helper function to getTopPackages."
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id,restriction = Absyn.R_PACKAGE()) :: rest),within_ = w))
      equation
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopPackagesInProgram;

protected function getPackagesInClass
" This function takes a Class definition and a Path identifying
   the class. It returns a string containing comma separated package
   names found in the class definition."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<Absyn.Path> outString;
algorithm
  outString:=
  match (inPath,inProgram,inClass)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Option<String> cmt;
      Absyn.Path inmodel,path;
      Absyn.Program p;
    /* a class with parts */
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        strlist = getPackagesInParts(parts);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        strlist = getPackagesInParts(parts);
      then List.map(strlist,Absyn.makeIdentPathFromString);
     /* a derived class */
    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(_,_))))
      equation
        /* adrpo: 2009-10-27 we shouldn't look into derived!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getPackagesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getPackagesInClass;

protected function getPackagesInParts
"Helper function to getPackagesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;

    case {} then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        l1 = getPackagesInElts(elts);
        l2 = getPackagesInParts(rest);
        res = listAppend(l1, l2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        l1 = getPackagesInElts(elts);
        l2 = getPackagesInParts(rest);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest))
      equation
        res = getPackagesInParts(rest);
      then
        res;

  end matchcontinue;
end getPackagesInParts;

protected function getPackagesInElts
"Helper function to getPackagesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
    case {} then {};
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,restriction = Absyn.R_PACKAGE())))) :: rest))
      equation
        res = getPackagesInElts(rest);
      then
        (id :: res);
    case ((_ :: rest))
      equation
        res = getPackagesInElts(rest);
      then
        res;
  end matchcontinue;
end getPackagesInElts;

public function getClassnamesInPath
"Return a comma separated list of classes in a given Path."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<Absyn.Path> paths;
algorithm
  paths :=
  matchcontinue (inPath,inProgram,inShowProtected,includeConstants)
    local
      Absyn.Class cdef;
      Absyn.Path modelpath;
      Absyn.Program p;
      Boolean b,c;
    case (modelpath,p,b,c)
      equation
        cdef = getPathedClassInProgram(modelpath, p);
      then getClassnamesInClass(modelpath, p, cdef, b, c);
    else {};
  end matchcontinue;
end getClassnamesInPath;

public function getTopClassnames
" This function takes a Path and a Program and returns a list of
   the names of the packages found at the top scope."
  input Absyn.Program p;
  output list<Absyn.Path> paths;
algorithm
  paths := List.map(getTopClassnamesInProgram(p),Absyn.makeIdentPathFromString);
end getTopClassnames;

public function getTopClassnamesInProgram
"Helper function to getTopClassnames."
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w))
      equation
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopClassnamesInProgram;

protected function getTopQualifiedClassnames
 "Takes a Program and returns a list of the fully top_qualified
 names of the packages found at the top scope.
 Example:
  within X.Y class Z -> X.Y.Z;"
  input Absyn.Program inProgram;
  output list<Absyn.Path> outStringLst;
algorithm
  outStringLst := matchcontinue (inProgram)
    local
      String id;
      list<Absyn.Path> res;
      list<Absyn.Class> rest;
      Absyn.Within w;
      Absyn.Path p;

    case Absyn.PROGRAM(classes = {}) then {};
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w))
      equation
        p = Absyn.joinWithinPath(w, Absyn.IDENT(id));
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w));
      then p::res;
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopQualifiedClassnames;

protected function getClassnamesInClass
" This function takes a `Class\' definition and a Path identifying the
   class.
   It returns a string containing comma separated package names found
   in the class definition.
   The list also contains proctected classes if inShowProtected is true."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<Absyn.Path> paths;
algorithm
  paths := match (inPath,inProgram,inClass,inShowProtected,includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b,c;
    /* a class with parts */
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then List.map(strlist,Absyn.makeIdentPathFromString);
    /* a derived class */
    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(_, _))),_,_)
      equation
        /* adrpo 2009-10-27: we sholdn't dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getClassnamesInClass(newpath, p, cdef);
        */
      then {};
  end match;
end getClassnamesInClass;

public function getClassnamesInParts
"Helper function to getClassnamesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynClassPartLst,inShowProtected,includeConstants)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Boolean b,c;

    case ({},_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest),b,c)
      equation
        l1 = getClassnamesInElts(elts,c);
        l2 = getClassnamesInParts(rest,b,c);
        res = listAppend(l1, l2);
      then
        res;

    // adeas31 2012-01-25: Also check the protected sections.
    case ((Absyn.PROTECTED(contents = elts) :: rest), true, c)
      equation
        l1 = getClassnamesInElts(elts,c);
        l2 = getClassnamesInParts(rest,true,c);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest),b,c)
      equation
        res = getClassnamesInParts(rest,b,c);
      then
        res;

  end matchcontinue;
end getClassnamesInParts;

public function getClassnamesInElts
"Helper function to getClassnamesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean includeConstants;
  output list<String> outStringLst;
protected
  DoubleEndedList<String> delst;
algorithm
  delst := DoubleEndedList.fromList({});
  for elt in inAbsynElementItemLst loop
  _ := match elt
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
      Boolean c;
      list<Absyn.ComponentItem> lst;
      list<String> names;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = id)))))
      algorithm
        DoubleEndedList.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ =
                 Absyn.CLASS(name = id))))
      algorithm
        DoubleEndedList.push_back(delst, id);
      then ();

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.CONST()),
                 components = lst))) guard includeConstants
      algorithm
        DoubleEndedList.push_list_back(delst, getComponentItemsName(lst,false));
      then ();

    else ();
  end match;
  end for;
  outStringLst := DoubleEndedList.toListAndClear(delst);
end getClassnamesInElts;

protected function getBaseClasses
" This function gets all base classes of a class, NOT Recursive.
   It uses the environment to get the fully qualified names of the classes."
  input Absyn.Class inClass;
  input FCore.Graph inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inClass,inEnv)
    local
      list<Absyn.ComponentRef> res;
      list<Absyn.ClassPart> parts;
      FCore.Graph env;
      Absyn.Path tp;
      String baseClassName;
      Option<String> comment;
      list<Absyn.ElementArg> modifications;
      FCore.Graph cenv;
      Absyn.Path envpath,p1;
      String tpname,str;
      Absyn.ComponentRef cref;
      SCode.Element c;
      FCore.Cache cache;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),env)
      equation
        res = getBaseClassesFromParts(parts, env);
      then
        res;

    // adrpo: handle the case for model extends baseClassName end baseClassName;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName, _, _, parts = parts)),env)
      equation
        (_,_,cenv) = Lookup.lookupClassIdent(FCore.emptyCache(), env, baseClassName, SOME(inClass.info));
        SOME(envpath) = FGraph.getScopePath(cenv);
        p1 = Absyn.joinPaths(envpath, Absyn.IDENT(baseClassName));
        cref = Absyn.pathToCref(p1);
        res = getBaseClassesFromParts(parts, env);
      then cref::res;

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(tp,_))),env)
      equation
        (_,_,cenv) = Lookup.lookupClass(FCore.emptyCache(), env, tp, SOME(inClass.info));
        SOME(envpath) = FGraph.getScopePath(cenv);
        tpname = Absyn.pathLastIdent(tp);
        p1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p1);
        // str = Absyn.pathString(p1);
      then {cref};

    case (Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(tp,_))),env)
      equation
        (_,_,cenv) = Lookup.lookupClass(FCore.emptyCache(), env, tp, SOME(inClass.info));
        NONE() = FGraph.getScopePath(cenv);
        cref = Absyn.pathToCref(tp);
        then {cref};

    else {};

  end matchcontinue;
end getBaseClasses;

protected function getBaseClassesFromParts
"Helper function to getBaseClasses."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input FCore.Graph inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynClassPartLst,inEnv)
    local
      list<Absyn.ComponentRef> c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      FCore.Graph env;

    case ((Absyn.PUBLIC(contents = elts) :: rest),env)
      equation
        c1 = getBaseClassesFromElts(elts, env);
        c2 = getBaseClassesFromParts(rest, env);
        res = listAppend(c1, c2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest),env)
      equation
        c1 = getBaseClassesFromElts(elts, env);
        c2 = getBaseClassesFromParts(rest, env);
        res = listAppend(c1, c2);
      then
        res;

    case ((_ :: rest),env)
      equation
        res = getBaseClassesFromParts(rest, env);
      then
        res;

    case ({},_) then {};

  end matchcontinue;
end getBaseClassesFromParts;

protected function getBaseClassesFromElts
"Helper function to getBaseClassesFromParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input FCore.Graph inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynElementItemLst,inEnv)
    local
      FCore.Graph env,env_1;
      list<Absyn.ComponentRef> cl;
      SCode.Element c;
      Absyn.Path envpath,p_1,path;
      String tpname;
      Absyn.ComponentRef cref;
      list<Absyn.ElementItem> rest;
      Absyn.Element e;

    case ({},_) then {};

    case ((Absyn.ELEMENTITEM(element = e as Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env) "Inherited class is defined inside package" ;
        (_,_,env_1) = Lookup.lookupClass(FCore.emptyCache(),env, path, SOME(e.info));
        SOME(envpath) = FGraph.getScopePath(env_1);
        tpname = Absyn.pathLastIdent(path);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p_1);
      then
        (cref :: cl);

    case ((Absyn.ELEMENTITEM(element = e as Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env) "Inherited class defined on top level scope" ;
        (_,_,env_1) = Lookup.lookupClass(FCore.emptyCache(),env, path, SOME(e.info));
        NONE() = FGraph.getScopePath(env_1);
        cref = Absyn.pathToCref(path);
      then
        (cref :: cl);

    case ((_ :: rest),env)
      equation
        cl = getBaseClassesFromElts(rest, env);
      then
        cl;

  end matchcontinue;
end getBaseClassesFromElts;

protected function countBaseClasses
" This function counts the number of base classes of a class"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer res;
      list<Absyn.ClassPart> parts;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        res = countBaseClassesFromParts(parts);
      then
        res;

    // adrpo: add the case for model extends baseClassName extends SomeElseClass; end baseClassName;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        res = countBaseClassesFromParts(parts);
      then
        res + 1;

    case (Absyn.CLASS(body = Absyn.DERIVED())) then 1;

    else 0;

  end matchcontinue;
end countBaseClasses;

protected function countBaseClassesFromParts
"Helper function to countBaseClasses."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynClassPartLst)
    local
      Integer c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        c1 = countBaseClassesFromElts(elts);
        c2 = countBaseClassesFromParts(rest);
      then
        c1 + c2;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        c1 = countBaseClassesFromElts(elts);
        c2 = countBaseClassesFromParts(rest);
      then
        c1 + c2;

    case ((_ :: rest))
      equation
        res = countBaseClassesFromParts(rest);
      then
        res;

    case ({}) then 0;

  end matchcontinue;
end countBaseClassesFromParts;

protected function countBaseClassesFromElts
"Helper function to countBaseClassesFromParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inAbsynElementItemLst)
    local
      Integer cl;
      Absyn.Path path;
      list<Absyn.ElementItem> rest;

    case ({}) then 0;

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS())) :: rest))
      equation
        cl = countBaseClassesFromElts(rest) "Inherited class" ;
      then
        cl + 1;

    case ((_ :: rest))
      equation
        cl = countBaseClassesFromElts(rest);
      then
        cl;

  end matchcontinue;
end countBaseClassesFromElts;

protected function getAnnotationInClass
  "Helper function to getIconAnnotation."
  input Absyn.Class inClass;
  input AnnotationType annotationType;
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output String annotationStr;
protected
  Absyn.ClassDef body;
  list<Absyn.ElementArg> ann;
algorithm
  Absyn.CLASS(body = body) := inClass;

  ann := match body
    case Absyn.PARTS()
      then List.flatten(list(Absyn.annotationToElementArgs(a) for a in body.ann));

    case Absyn.CLASS_EXTENDS()
      then List.flatten(list(Absyn.annotationToElementArgs(a) for a in body.ann));

    case Absyn.DERIVED(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(ann)))))
      then ann;

    case Absyn.ENUMERATION(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(ann)))))
      then ann;

    case Absyn.OVERLOAD(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(ann)))))
      then ann;

    case Absyn.PDER(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(ann)))))
      then ann;
  end match;

  annotationStr := getAnnotationStr(ann, annotationType, inClass, inProgram, inModelPath);
  annotationStr := "{" + annotationStr + "}";
end getAnnotationInClass;

protected function isAnnotationType
  "Checks if the name of an annotation matches the annotation type given."
  input String annotationStr;
  input AnnotationType annotationType;
algorithm
  _ := match(annotationStr, annotationType)
    case ("Icon", ICON_ANNOTATION()) then ();
    case ("Diagram", DIAGRAM_ANNOTATION()) then ();
  end match;
end isAnnotationType;

protected function containAnnotation
"Helper function to getAnnotationFromElts."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input AnnotationType annotationType;
algorithm
  _ := matchcontinue (inAbsynElementArgLst, annotationType)
    local
      list<Absyn.ElementArg> lst;
      String ann_name;

    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = ann_name)) :: _), _)
      equation
        isAnnotationType(ann_name, annotationType);
      then
        ();

    case ((_ :: lst), _)
      equation
        containAnnotation(lst, annotationType);
      then
        ();
  end matchcontinue;
end containAnnotation;

protected function getAnnotationStr
"Helper function to getIconAnnotationInClass."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input AnnotationType annotationType;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynElementArgLst, annotationType, inClass, inProgram, inModelPath)
    local
      String str, ann_name;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
      Absyn.Program fullProgram;
      Absyn.Class c;
      Absyn.Path p;

    case (((ann as Absyn.MODIFICATION(path = Absyn.IDENT(name = ann_name))) :: _), _, c, fullProgram, p)
      equation
        isAnnotationType(ann_name, annotationType);
        str = getAnnotationString(Absyn.ANNOTATION({ann}), c, fullProgram, p);
      then
        str;

    case ((_ :: xs), _, c, fullProgram, p)
      equation
        str = getAnnotationStr(xs, annotationType, c, fullProgram, p);
      then
        str;

  end matchcontinue;
end getAnnotationStr;

public function getDocumentationClassAnnotation
"Returns the documentation class annotation of a class.
  This is annotated with the annotation:
  annotation (DocumentationClass=true); in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output Boolean isDocClass;
algorithm
  isDocClass := match(className,p)
    local
      String docStr;
    case(_,_)
      equation
        docStr = getNamedAnnotation(className,p,Absyn.IDENT("DocumentationClass"),SOME("false"),getDocumentationClassAnnotationModStr);
      then
        stringEq(docStr, "true");
  end match;
end getDocumentationClassAnnotation;

protected function getDocumentationClassAnnotationModStr
"Extractor function for DocumentationClass"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue(mod)
    local Absyn.Exp e;

    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e))))
      equation
        docStr = Dump.printExpStr(e);
      then
        docStr;

    else "false";

  end matchcontinue;
end getDocumentationClassAnnotationModStr;

protected function getDefaultComponentName
"Returns the default component name of a class.
  This is annotated with the annotation:
  annotation(defaultComponentName=\"name\"); in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output String compName;
algorithm
  compName := match(className,p)
    case(_,_)
      equation
        compName = getNamedAnnotation(className,p,Absyn.IDENT("defaultComponentName"),SOME("{}"),getDefaultComponentNameModStr);
      then
        compName;
  end match;
end getDefaultComponentName;

protected function getDefaultComponentNameModStr
"Extractor function for defaultComponentName modifier"
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue(mod)
    local Absyn.Exp e;

    case(SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e))))
      equation
        docStr = Dump.printExpStr(e);
      then
        docStr;

    else "";

  end matchcontinue;
end getDefaultComponentNameModStr;

protected function getDefaultComponentPrefixes
"Returns the default component prefixes of a class.
  This is annotated with the annotation
    annotation(defaultComponentPrefixes=\"<prefixes>\");
  in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output String compName;
algorithm
  compName := match(className,p)
    case(_,_)
      equation
        compName = getNamedAnnotation(className,p,Absyn.IDENT("defaultComponentPrefixes"),SOME("{}"),getDefaultComponentPrefixesModStr);
      then
        compName;
  end match;
end getDefaultComponentPrefixes;

public function getAnnotationValue
  input Option<Absyn.Modification> mod;
  output String str;
algorithm
  str := matchcontinue (mod)
    local
      String s;
      Absyn.Exp exp;

    case (SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp))))
      equation
        s = Dump.printExpStr(exp);
        s = stringAppendList({"{", s, "}"});
      then
        s;

    // adrpo: empty if no value
    else "{}";
  end matchcontinue;
end getAnnotationValue;

public function getAnnotationExp
  input Option<Absyn.Modification> mod;
  output Absyn.Exp exp;
algorithm
  SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp))) := mod;
end getAnnotationExp;

public function getAnnotationStringValueOrFail
  input Option<Absyn.Modification> mod;
  output String str;
algorithm
  str := match (mod)
    local
      String s;

    case (SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=Absyn.STRING(s))))) then s;
  end match;
end getAnnotationStringValueOrFail;

public function getExperimentAnnotationString
"@author: adrpo
 gets the experiment annotation values"
  input Option<Absyn.Modification> mod;
  output String experimentStr;
algorithm
  experimentStr := match (mod)
    local
      list<Absyn.ElementArg> arglst;
      list<String> strs;
      String s;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        strs = getExperimentAnnotationString2(arglst);
        s = stringDelimitList(strs,",");
        s = stringAppendList({"{", s, "}"});
      then
        s;

  end match;
end getExperimentAnnotationString;

protected function getExperimentAnnotationString2
"Helper function to getExperimentAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output list<String> strs;
algorithm
  strs := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String name, s;
      list<String> ss;

    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = name),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::xs)
      equation
          s =  name + "=" + Dump.printExpStr(exp);
          ss = getExperimentAnnotationString2(xs);
      then s::ss;

    case (_::xs)
      equation
          ss = getExperimentAnnotationString2(xs);
      then ss;

    end matchcontinue;
end getExperimentAnnotationString2;

public function getDocumentationAnnotationString
  input Option<Absyn.Modification> mod;
  output tuple<String,String,String> docStr;
algorithm
  docStr := match (mod)
    local
      list<Absyn.ElementArg> arglst;
      String info, revisions, infoHeader;
      Boolean partialInst;
    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      equation
        partialInst = System.getPartialInstantiation();
        System.setPartialInstantiation(true);
        info = getDocumentationAnnotationInfo(arglst);
        revisions = getDocumentationAnnotationRevision(arglst);
        infoHeader = getDocumentationAnnotationInfoHeader(arglst);
        System.setPartialInstantiation(partialInst);
      then ((info,revisions,infoHeader));
  end match;
end getDocumentationAnnotationString;

protected function getDocumentationAnnotationInfo
"Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output String str;
algorithm
  str := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      DAE.Exp dexp;
      list<Absyn.ElementArg> xs;
      String s;
      String ss;
    case ({}) then "";
    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = "info"),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::_)
      equation
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, Prefix.NOPRE(), Absyn.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
        // ss = getDocumentationAnnotationInfo(xs);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationInfo(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationInfo;

protected function getDocumentationAnnotationRevision
"Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output String str;
algorithm
  str := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String s;
      String ss;
      DAE.Exp dexp;
    case ({}) then "";
    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = "revisions"),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::_)
      equation
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, Prefix.NOPRE(), Absyn.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationRevision(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationRevision;

protected function getDocumentationAnnotationInfoHeader
"Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output String str;
algorithm
  str := matchcontinue (eltArgs)
    local
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
      String s;
      String ss;
      DAE.Exp dexp;
    case ({}) then "";
    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = "__OpenModelica_infoHeader"),
          modification=SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp))))::_)
      equation
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, Prefix.NOPRE(), Absyn.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationInfoHeader(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationInfoHeader;

protected function getNthPublicConnectorStr
"Helper function to getNthConnector."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm
  (outString,outPath) := matchcontinue (inPath,inClass,inProgram,inInteger)
    local
      String str,a;
      Absyn.Path tp,modelpath;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Absyn.Program p;
      Integer n,c1,c2;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.Annotation> ann;

    case (modelpath,Absyn.CLASS(body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: _))),p,n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, elt, n);
      then
        (str,tp);

    /*
     * The rule above failed, count the number of connectors in the first
     * public list, subtract the number and try the rest of the list
     */
    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),ann=ann,comment = cmt),info = file_info),p,n)
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},{Absyn.PUBLIC(elt)},ann,cmt),file_info));
        c2 = n - c1;
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), p, c2);
      then
        (str,tp);

    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (_ :: lst),ann=ann,comment = cmt),info = file_info),p,n)
      equation
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), p, n);
      then
        (str,tp);

    /***********   adrpo: handle also the case of model extends name end name; **********/
    case (modelpath,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: _))),p,n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, elt, n);
      then
        (str,tp);

    /*
     * The rule above failed, count the number of connectors in the first
     * public list, subtract the number and try the rest of the list
     */
    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),ann=ann,comment = cmt),info = file_info),p,n)
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},{Absyn.PUBLIC(elt)},ann,cmt),file_info));
        c2 = n - c1;
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), p, c2);
      then
        (str,tp);

    case (modelpath,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),ann=ann,comment = cmt),info = file_info),p,n)
      equation
        (str,tp) = getNthPublicConnectorStr(modelpath, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), p, n);
      then
        (str,tp);

  end matchcontinue;
end getNthPublicConnectorStr;

protected function getNthConnectorStr
" This function takes an ElementItem list and an int and
   returns the name of the nth connector component in that list."
  input Absyn.Program inProgram;
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm
  (outString,outPath) := matchcontinue (inProgram,inPath,inAbsynElementItemLst,inInteger)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,tp,modelpath;
      String str;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      Integer n,c1,c2,newn;
      list<Absyn.ComponentItem> complst;

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp))) :: _),n)
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        (str,tp) = getNthPublicConnectorStr(newmodelpath, cdef, p, n);
      then
        (str,tp);

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp))) :: lst),n)
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, c2);
      then
        (str,tp);

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst))) :: _),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p);
        str = getNthCompname(complst, n);
      then
        (str,tp);

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst))) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p)
        "Not so fast, since we lookup and instantiate two times just because this was not the connector we were looking for." ;
        c1 = listLength(complst);
        newn = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, newn);
      then
        (str,tp);

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst))) :: _),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p);
        str = getNthCompname(complst, n);
      then
        (str,tp);

    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp,_),components = complst))) :: lst),n)
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p)
        "Not so fast, since we lookup and instantiate two times just because this was not the connector we were looking for." ;
        c1 = listLength(complst);
        newn = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, newn);
      then
        (str,tp);

    case (p,modelpath,(_ :: lst),n)
      equation
        (str,tp) = getNthConnectorStr(p, modelpath, lst, n);
      then
        (str,tp);

    case (_,_,{},_) then fail();

  end matchcontinue;
end getNthConnectorStr;

protected function getNthCompname
"Returns the nth component name from a list of ComponentItems.
  Index is from 1..n."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inAbsynComponentItemLst,inInteger)
    local
      String id,res;
      list<Absyn.ComponentItem> lst,xs;
      Integer n1,n;

    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)) :: _),1) then id;

    case ((_ :: xs),n)
      equation
        n1 = n - 1;
        res = getNthCompname(xs, n1);
      then
        res;

    case ({},_) then fail();

  end match;
end getNthCompname;

protected function countPublicConnectors
"This function takes a Class and counts the number of connector
  components in the class. This also includes counting in inherited classes."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inPath,inProgram,inClass)
    local
      Integer c1,c2,res;
      Absyn.Path modelpath,newmodelpath,cname;
      Absyn.Program p;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.Class cdef;
      list<Absyn.Annotation> ann;

    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),ann=ann,comment = cmt),
                  info = file_info))
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countConnectors(modelpath, p, elt);
      then
        c1 + c2;

    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.PARTS(classParts = (_ :: lst),ann = ann,comment = cmt),
                  info = file_info))
      equation
        res = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
      then
        res;

    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = {})))
      then 0;

    // adrpo: handle also the case of model extends name end name;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),ann = ann,comment = cmt),
                  info = file_info))
      equation
        c1 = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
        c2 = countConnectors(modelpath, p, elt);
      then
        c1 + c2;

    // adrpo: handle also the case of model extends name end name;
    case (modelpath,p,
      Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                  body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),ann=ann,comment = cmt),
                  info = file_info))
      equation
        res = countPublicConnectors(modelpath, p, Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info));
      then
        res;

    // adrpo: handle also the case of model extends name end name;
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {})))
      then 0;

    // the case model name = OtherName;
    case (modelpath,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(cname, _))))
      equation
        (cdef,newmodelpath) = lookupClassdef(cname, modelpath, p);
        res = countPublicConnectors(newmodelpath, p, cdef);
      then
        res;

  end matchcontinue;
end countPublicConnectors;

protected function countConnectors
"This function takes a Path to the current model and a ElementItem
  list and returns the number of connector components in that list."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inPath,inProgram,inAbsynElementItemLst)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,modelpath,tp;
      Integer c1,c2,res;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      list<Absyn.ComponentItem> complst;

    case (modelpath,p,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp))) :: lst))
      equation
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp, _),components = complst))) :: lst))
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p);
        c1 = listLength(complst);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(Absyn.ELEMENTITEM(element =
      Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp, _),components = complst))) :: lst))
      equation
        (Absyn.CLASS(_,_,_,_,Absyn.R_EXP_CONNECTOR(),_,_),_) = lookupClassdef(tp, modelpath, p);
        c1 = listLength(complst);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;

    case (modelpath,p,(_ :: lst)) /* Rule above didn\'t match => element not connector components, try rest of list */
      equation
        res = countConnectors(modelpath, p, lst);
      then
        res;

    case (_,_,{}) then 0;

  end matchcontinue;
end countConnectors;

protected function getConnectionAnnotationStrElArgs
  input list<Absyn.ElementArg> inElArgLst;
  input SourceInfo info;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inElArgLst,info,inClass,inFullProgram,inModelPath)
    local
      Absyn.FunctionArgs fargs;
      list<SCode.Element> p_1;
      FCore.Graph env;
      DAE.Exp newexp;
      String gexpstr, gexpstr_1, annName;
      list<String> res;
      list<Absyn.ElementArg>  mod, rest;
      FCore.Cache cache;
      DAE.Properties prop;
      Absyn.Program lineProgram;

    // handle empty
    case ({},_,_,_,_) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = SOME(Absyn.CLASSMOD(mod,_))) :: rest,_,_, _, _)
      equation
        lineProgram = modelicaAnnotationProgram(Config.getAnnotationVersion());
        fargs = createFuncargsFromElementargs(mod);
        p_1 = SCodeUtil.translateAbsyn2SCode(lineProgram);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,newexp,prop) = StaticScript.elabGraphicsExp(cache,env, Absyn.CALL(Absyn.CREF_IDENT(annName,{}),fargs), false,Prefix.NOPRE(), info) "impl" ;
        (cache, newexp, prop) = Ceval.cevalIfConstant(cache, env, newexp, prop, false, info);
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = ExpressionDump.printExpStr(newexp);
        res = getConnectionAnnotationStrElArgs(rest, info, inClass, inFullProgram, inModelPath);
      then
        (gexpstr :: res);
    case (Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = SOME(Absyn.CLASSMOD(_,Absyn.NOMOD()))) :: rest,_,_,_,_)
      equation
        gexpstr_1 = stringAppendList({annName,"(error)"});
        res = getConnectionAnnotationStrElArgs(rest, info, inClass, inFullProgram, inModelPath);
      then
        (gexpstr_1 :: res);
  end matchcontinue;
end getConnectionAnnotationStrElArgs;

protected function getConnectionAnnotationStr
" This function takes an `EquationItem\' and returns a comma separated
   string of values  from the flat record of a connection annotation that
   is found in the `EquationItem\'."
  input Absyn.EquationItem inEquationItem;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := match (inEquationItem, inClass, inFullProgram, inModelPath)
    local
      String gexpstr;
      list<String> res;
      list<Absyn.ElementArg>  annotations;
      SourceInfo info;

    case (Absyn.EQUATIONITEM(info=info, equation_ = Absyn.EQ_CONNECT(),
      comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annotations)),_))),
      _, _, _)
    equation
        res = getConnectionAnnotationStrElArgs(annotations, info, inClass, inFullProgram, inModelPath);
        gexpstr = stringDelimitList(res, ", ");
    then
      gexpstr;
    case (Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(),comment = NONE()),
          _, _, _)
      then
        fail();
  end match;
end getConnectionAnnotationStr;

public function createFuncargsFromElementargs
"Trasform an ElementArg list to function argments. This is used when
  translating a graphical annotation to a record constructor."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs := matchcontinue (inAbsynElementArgLst)
    local
      list<Absyn.Exp> expl;
      list<Absyn.NamedArg> narg;
      String id;
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;

    case ({}) then Absyn.FUNCTIONARGS({},{});

    case ((Absyn.MODIFICATION(path = Absyn.IDENT(name = id),modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp)))) :: xs))
      equation
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,(Absyn.NAMEDARG(id,exp) :: narg));

    case ((_ :: xs))
      equation
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,narg);
  end matchcontinue;
end createFuncargsFromElementargs;

protected function getConnectionStr
" This function takes an Equation assumed to contain a connection and
   returns a comma separated string of componentreferences, e.g \"R1.n,C.p\"
   for  connect(R1.n,C.p)."
  input Absyn.Equation inEquation;
  output String outFromString;
  output String outToString;
algorithm
  (outFromString, outToString) := match (inEquation)
    local
      String s1,s2,str;
      Absyn.ComponentRef cr1,cr2;

    case Absyn.EQ_CONNECT(connector1 = cr1,connector2 = cr2)
      equation
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
      then
        (s1, s2);
  end match;
end getConnectionStr;

public function getConnections
"This function takes a Class and returns a list of connections in the Class."
  input Absyn.Class inClass;
  output list<Absyn.EquationItem> outList;
algorithm
  outList := match (inClass)
    local
      list<Absyn.EquationItem> connectionsList;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        connectionsList = getConnectionsInClassparts(parts);
      then
        connectionsList;

    // adrpo: handle also the case model extends X end X;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        connectionsList = getConnectionsInClassparts(parts);
      then
        connectionsList;

    case Absyn.CLASS(body = Absyn.DERIVED()) then {};

  end match;
end getConnections;

protected function getConnectionsInClassparts
" This function takes a ClassPart list and returns
   a list of connections in that list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> eqlist1, eqlist2;
      list<Absyn.ClassPart> xs;

    case ((Absyn.EQUATIONS(contents = eqlist1) :: xs))
      equation
        eqlist1 = getConnectionsInEquations(eqlist1);
        eqlist2 = getConnectionsInClassparts(xs);
      then
        listAppend(eqlist1, eqlist2);

    case ((_ :: xs))
      equation
        eqlist1 = getConnectionsInClassparts(xs);
      then
        eqlist1;

    case ({}) then {};

  end matchcontinue;
end getConnectionsInClassparts;

protected function getConnectionsInEquations
" This function takes an Equation list and returns a list
   of connect statements in that list."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.EquationItem> outList;
algorithm
  outList := match (inAbsynEquationItemLst)
    local
      Absyn.EquationItem eq;
      list<Absyn.EquationItem> eqlist1, eqlist2;
      list<Absyn.EquationItem> xs;
      list<Absyn.EquationItem> forEqList;

    case (((eq as Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT())) :: xs))
      equation
        eqlist1 = getConnectionsInEquations(xs);
      then
        eq::eqlist1;


    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR(forEquations = forEqList)) :: xs))
      equation
        eqlist1 = getConnectionsInEquations(forEqList);
        eqlist2 = getConnectionsInEquations(xs);
      then
        listAppend(eqlist1, eqlist2);

    case ((_ :: xs))
      equation
        eqlist1 = getConnectionsInEquations(xs);
      then
        eqlist1;

    case ({}) then {};

  end match;
end getConnectionsInEquations;

protected function getComponentAnnotationsFromElts
"Helper function to getComponentAnnotations."
  input list<Absyn.Element> comps;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String resStr;
protected
  list<SCode.Element> graphicProgramSCode;
  FCore.Graph env;
  list<String> res;
  Absyn.Program placementProgram;
  GraphicEnvCache cache;
algorithm
  placementProgram := modelicaAnnotationProgram(Config.getAnnotationVersion());
  graphicProgramSCode := SCodeUtil.translateAbsyn2SCode(placementProgram);
  (_,env) := Inst.makeEnvFromProgram(graphicProgramSCode);
  cache := GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath);
  res := getComponentitemsAnnotations(comps, env, inClass, cache);
  resStr := stringDelimitList(res, ",");
end getComponentAnnotationsFromElts;

protected function getComponentitemsAnnotations
"Helper function to getComponentAnnotationsFromElts"
  input list<Absyn.Element> inElements;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output list<String> outStringLst = {};
protected
  list<String> res;
  GraphicEnvCache cache = inCache;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
algorithm
  for e in listReverse(inElements) loop
    outStringLst := matchcontinue e
      case Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items), constrainClass = cc)
        algorithm
          (res, cache) := getComponentitemsAnnotationsFromItems(items,
            getAnnotationsFromConstraintClass(cc), inEnv, inClass, cache);
        then
          listAppend(res, outStringLst);

      case Absyn.ELEMENT(specification = Absyn.COMPONENTS())
        then "{}" :: outStringLst;

      else outStringLst;
    end matchcontinue;
  end for;
end getComponentitemsAnnotations;

protected function getAnnotationsFromConstraintClass
  input Option<Absyn.ConstrainClass> inCC;
  output list<Absyn.ElementArg> outElArgLst;
algorithm
  outElArgLst := match(inCC)
    local list<Absyn.ElementArg> elementArgs;
    case SOME(Absyn.CONSTRAINCLASS(comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs))))))
      then elementArgs;
    else {};
  end match;
end getAnnotationsFromConstraintClass;

protected function getComponentitemsAnnotationsElArgs
"Helper function to getComponentitemsAnnotationsFromItems."
  input list<Absyn.ElementArg> inElementArgs;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output list<String> outStringLst = {};
  output GraphicEnvCache outCache = inCache;
protected
  String str, ann_name;
  Absyn.Exp eq_aexp;
  DAE.Exp eq_dexp;
  DAE.Properties prop;
  SourceInfo info;
  FCore.Cache cache;
  FCore.Graph env, env2;
  list<Absyn.ElementArg> mod;
  SCode.Element c;
  SCode.Mod smod;
  DAE.Mod dmod;
  DAE.DAElist dae;
algorithm
  for e in listReverse(inElementArgs) loop
    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          modification = SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(eq_aexp))),
          info = info)
        algorithm
          (cache, env, _, outCache) := buildEnvForGraphicProgram(outCache, {});

          (_, eq_dexp, prop) :=
            StaticScript.elabGraphicsExp(cache, env, eq_aexp, false, Prefix.NOPRE(), info);

          (cache, eq_dexp, prop) := Ceval.cevalIfConstant(cache, env, eq_dexp, prop, false, info);
          eq_dexp := ExpressionSimplify.simplify1(eq_dexp);
          Print.clearErrorBuf() "Clear any error messages generated by the annotations.";

          str := ExpressionDump.printExpStr(eq_dexp);
        then
          stringAppendList({ann_name, "=", str});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          modification = SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())),
          info = info)
        algorithm
          (cache, env, _, outCache) := buildEnvForGraphicProgram(outCache, mod);

          (cache, c, env2) := Lookup.lookupClassIdent(cache, inEnv, ann_name);
          smod := SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(mod,
            Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          (cache, dmod) := Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy, Prefix.NOPRE(),
            smod, false, Mod.COMPONENT(ann_name), Absyn.dummyInfo);

          c := SCode.classSetPartial(c, SCode.NOT_PARTIAL());
          (_, _, _, _, dae) := Inst.instClass(cache, env2, InnerOuter.emptyInstHierarchy,
            UnitAbsyn.noStore, dmod, Prefix.NOPRE(), c, {}, false,
            InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);

          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({ann_name, "(", str, ")"});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(ann_name),
          modification = SOME(Absyn.CLASSMOD(_, Absyn.NOMOD())))
        then stringAppendList({ann_name, "(error)"});

      case Absyn.MODIFICATION(path = Absyn.IDENT(ann_name), modification = NONE())
        algorithm
          (cache, _, _, outCache) := buildEnvForGraphicProgram(outCache, {});

          (cache, c, env) := Lookup.lookupClassIdent(cache, inEnv, ann_name);
          c := SCode.classSetPartial(c, SCode.NOT_PARTIAL());
          (_, _, _, _, dae) := Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy,
            UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(), c, {}, false,
            InstTypes.TOP_CALL(), ConnectionGraph.EMPTY, Connect.emptySet);

          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({ann_name, "(", str, ")"});

    end matchcontinue;

    outStringLst := str :: outStringLst;
  end for;
end getComponentitemsAnnotationsElArgs;

protected function getComponentitemsAnnotationsFromItems
"Helper function to getComponentitemsAnnotations."
  input list<Absyn.ComponentItem> inComponentItems;
  input list<Absyn.ElementArg> ccAnnotations;
  input FCore.Graph inEnv;
  input Absyn.Class inClass;
  input GraphicEnvCache inCache;
  output list<String> outStringLst = {};
  output GraphicEnvCache outCache = inCache;
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

    (res, outCache) := getComponentitemsAnnotationsElArgs(annotations, inEnv, inClass, outCache);
    str := stringDelimitList(res, ", ");
    outStringLst := stringAppendList({"{", str, "}"}) :: outStringLst;
  end for;
end getComponentitemsAnnotationsFromItems;

protected function getComponentAnnotation
"This function takes an Element and returns a comma separated string
  of values corresponding to the flat record for a component annotation.
  If several components are declared within the eleement, a list of values
  is given for each of them."
  input Absyn.Element inElement;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := matchcontinue (inElement,inClass,inFullProgram,inModelPath)
    local
      String str;
      list<Absyn.ComponentItem> lst;

    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst)),
          _,_,_)
      equation
        str = getComponentitemsAnnotation(lst, inClass,inFullProgram,inModelPath);
      then
        str;

    else "";
  end matchcontinue;
end getComponentAnnotation;

public function modelicaAnnotationProgram
   input String annotationVersion "1.x or 2.x or 3.x";
   output Absyn.Program annotationProgram;
algorithm
  annotationProgram := match(annotationVersion)
    local
      Absyn.Program annProg;

    case ("1.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_1_x, "<1.x annotations>");
      then annProg;

    case ("2.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_2_x, "<2.x annotations>");
      then annProg;

    case ("3.x")
      equation
        annProg = Parser.parsestring(Constants.annotationsModelica_3_x, "<3.x annotations>");
      then annProg;
  end match;
end modelicaAnnotationProgram;

protected function getComponentitemsAnnotation
"Helper function to get_component_annotation."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
algorithm
  outString := match (inAbsynComponentItemLst,inClass,inFullProgram,inModelPath)
    local
      String s1,str,res;
      list<Absyn.ElementArg> mod;
      list<Absyn.ComponentItem> rest;

    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(path = Absyn.IDENT("Placement")) :: _)))),_))) ::
      (rest as (_ :: _))),
      _,_,_)
      equation
        s1 = getAnnotationString(Absyn.ANNOTATION(mod), inClass, inFullProgram, inModelPath);
        str = getComponentitemsAnnotation(rest, inClass, inFullProgram, inModelPath);
        res = stringAppendList({"{", s1, "},", str});
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(path = Absyn.IDENT("Placement")) :: _)))),_)))},
      _,_,_)
      equation
        s1 = getAnnotationString(Absyn.ANNOTATION(mod),inClass,inFullProgram,inModelPath);
        res = stringAppendList({"{", s1, "}"});
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(NONE(),_))) :: (rest as (_ :: _))),
      _,_,_)
      equation
        str = getComponentitemsAnnotation(rest,inClass,inFullProgram,inModelPath);
        res = stringAppend("{nada},", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = NONE()) :: (rest as (_ :: _))),
      _,_,_)
      equation
        str = getComponentitemsAnnotation(rest,inClass,inFullProgram,inModelPath);
        res = stringAppend("{},", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE())},_,_,_)
      equation
        res = "{}";
      then
        res;
  end match;
end getComponentitemsAnnotation;

public function getComponentModification
" This function takes an Element and returns a comma separated
   list of Code expression for the modification of the component."
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst)))
      equation
        str = getComponentitemsModification(lst);
      then
        str;
    else "";
  end matchcontinue;
end getComponentModification;

protected function getComponentitemsModification
"Helper function to get_component_modification."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,s2,res,str;
      Absyn.Modification mod;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod))) :: (rest as (_ :: _))))
      equation
        s1 = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
        s2 = getComponentitemsModification(rest);
        res = stringAppendList({s1,",",s2});
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod)))})
      equation
        res = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE())) :: (rest as (_ :: _))))
      equation
        str = getComponentitemsModification(rest);
        res = stringAppend("$Code(),", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE())) :: (rest as (_ :: _))))
      equation
        str = getComponentitemsModification(rest);
        res = stringAppend("$Code(),", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE())})
      equation
        res = "$Code()";
      then
        res;
  end matchcontinue;
end getComponentitemsModification;

protected function buildEnvForGraphicProgram
  "Builds an environment for instantiating graphical annotations. If the
   annotation modification only contains literals we only need to make an
   environment from the program, otherwise we need to fully instantiate the
   class used. To avoid doing this work over and over this function takes and
   returns a GraphicEnvCache, which is used to save the state between multiple
   calls to this function.

   This function is called by getAnnotationString, which expects to get back an
   Absyn.Program where the graphical annotation classes have been added. Since
   this is only used by getAnnotationString so far, and it always calls this
   function with an empty cache, this function returns a dummy program when
   called with a non-empty cache. The generated absyn program could easily be
   added to the cache if necessary though."
  input GraphicEnvCache inCache;
  input list<Absyn.ElementArg> inAnnotationMod;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output Absyn.Program outGraphicProgram;
  output GraphicEnvCache outGraphicEnvCache;
algorithm
  (outCache, outEnv, outGraphicProgram, outGraphicEnvCache) := match inCache
    local
      Absyn.Program absyn_program;
      SCode.Program scode_program;

    // Class already fully instantiated, return cached data.
    case GRAPHIC_ENV_FULL_CACHE()
      then (inCache.cache, inCache.env, Absyn.dummyProgram, inCache);

    // Partial cache, instantiate class to make full cache if needed.
    case GRAPHIC_ENV_PARTIAL_CACHE()
      algorithm
        if Absyn.onlyLiteralsInAnnotationMod(inAnnotationMod) then
          outCache := inCache.cache;
          outEnv := inCache.env;
          outGraphicEnvCache := inCache;
          outGraphicProgram := inCache.program;
        else
          (outCache, outEnv, outGraphicProgram) :=
            buildEnvForGraphicProgramFull(inCache.program, inCache.modelPath);
          outGraphicEnvCache := GRAPHIC_ENV_FULL_CACHE(outCache, outEnv);
        end if;
      then
        (outCache, outEnv, outGraphicProgram, outGraphicEnvCache);

    // No cache, make partial or full cache as needed.
    case GRAPHIC_ENV_NO_CACHE()
      algorithm
        if Absyn.onlyLiteralsInAnnotationMod(inAnnotationMod) then
          outGraphicProgram := modelicaAnnotationProgram(Config.getAnnotationVersion());
          scode_program := SCodeUtil.translateAbsyn2SCode(outGraphicProgram);
          (outCache, outEnv) := Inst.makeEnvFromProgram(scode_program);
          outGraphicEnvCache :=
            GRAPHIC_ENV_PARTIAL_CACHE(inCache.program, inCache.modelPath, outCache, outEnv);
        else
          (outCache, outEnv, outGraphicProgram) :=
            buildEnvForGraphicProgramFull(inCache.program, inCache.modelPath);
          outGraphicEnvCache := GRAPHIC_ENV_FULL_CACHE(outCache, outEnv);
        end if;
      then
        (outCache, outEnv, outGraphicProgram, outGraphicEnvCache);

  end match;
end buildEnvForGraphicProgram;

protected function buildEnvForGraphicProgramFull
  "Helper function to buildEnvForGraphicProgram. Builds an environment by fully
   instantiating the currently used class."
  input Absyn.Program inProgram;
  input Absyn.Path inModelPath;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output Absyn.Program outProgram;
protected
  Boolean check_model, eval_param, failed = false, graphics_mode;
  Absyn.Program graphic_program;
  SCode.Program scode_program;
algorithm
  graphic_program := modelicaAnnotationProgram(Config.getAnnotationVersion());
  outProgram := updateProgram(graphic_program, inProgram);
  scode_program := SCodeUtil.translateAbsyn2SCode(outProgram);

  check_model := Flags.getConfigBool(Flags.CHECK_MODEL);
  eval_param := Config.getEvaluateParametersInAnnotations();
  graphics_mode := Config.getGraphicsExpMode();
  Flags.setConfigBool(Flags.CHECK_MODEL, true);
  Config.setEvaluateParametersInAnnotations(true);
  Config.setGraphicsExpMode(true);

  try
    (outCache, outEnv) := Inst.instantiateClass(FCore.emptyCache(), InnerOuter.emptyInstHierarchy, scode_program, inModelPath);
  else
    failed := true;
  end try;

  Config.setEvaluateParametersInAnnotations(eval_param);
  Flags.setConfigBool(Flags.CHECK_MODEL, check_model);
  Config.setGraphicsExpMode(graphics_mode);
  if failed then
    fail();
  end if;
end buildEnvForGraphicProgramFull;

protected function getAnnotationString
  "Renders an annotation as a string."
  input Absyn.Annotation inAnnotation;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
protected
algorithm
  outString := matchcontinue inAnnotation
    local
      String ann_name;
      list<Absyn.ElementArg> mod, stripped_mod, graphic_mod;
      SourceInfo info;
      Boolean is_icon, is_diagram;
      FCore.Cache cache;
      FCore.Graph env;
      Absyn.Program graphic_prog;
      SCode.Element placement_cls;
      SCode.Mod smod;
      DAE.Mod dmod;
      Absyn.Exp graphic_exp;
      DAE.Exp graphic_dexp;
      DAE.Properties prop;
      DAE.DAElist dae;

    case Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(
        path = Absyn.IDENT(name = ann_name),
        modification = SOME(Absyn.CLASSMOD(elementArgLst = mod)),
        info = info)})
      algorithm
        is_icon := ann_name == "Icon";
        is_diagram := ann_name == "Diagram";

        (stripped_mod, graphic_mod) := stripGraphicsAndInteractionModification(mod);
        ErrorExt.setCheckpoint("buildEnvForGraphicProgram");
        try
        (cache, env, graphic_prog) :=
          buildEnvForGraphicProgram(GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath), mod);
          ErrorExt.rollBack("buildEnvForGraphicProgram");
        else
          ErrorExt.delCheckpoint("buildEnvForGraphicProgram");
          // Fallback to only the graphical primitives left in the program
          (cache, env, graphic_prog) := buildEnvForGraphicProgram(GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath), {});
        end try;

        smod := SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())),
          SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
        (cache, dmod) := Mod.elabMod(cache, env, InnerOuter.emptyInstHierarchy,
          Prefix.NOPRE(), smod, false, Mod.COMPONENT(ann_name), info);

        placement_cls := SCodeUtil.translateClass(getClassInProgram(ann_name, graphic_prog));
        (cache, _, _, _, dae) :=
          Inst.instClass(cache, env, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
            dmod, Prefix.NOPRE(), placement_cls, {}, false, InstTypes.TOP_CALL(),
            ConnectionGraph.EMPTY, Connect.emptySet);
        outString := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

        // Icon and Diagram contain graphic primitives which must be handled
        // specially.
        if is_icon or is_diagram then
          try
            {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod =
              Absyn.EQMOD(exp = graphic_exp))))} := graphic_mod;
            (_, graphic_dexp, prop) := StaticScript.elabGraphicsExp(cache, env,
              graphic_exp, false, Prefix.NOPRE(), info);

            if is_icon then
              ErrorExt.setCheckpoint("getAnnotationString: Icon");
              (cache, graphic_dexp) :=
                Ceval.cevalIfConstant(cache, env, graphic_dexp, prop, false, info);
              graphic_dexp := ExpressionSimplify.simplify1(graphic_dexp);
              ErrorExt.rollBack("getAnnotationString: Icon");
            end if;

            outString := outString + "," + ExpressionDump.printExpStr(graphic_dexp);
          else
          end try;
        end if;

        Print.clearErrorBuf() "This is to clear the error-msg generated by the annotations.";
      then
        outString;

    // If we fail, just return the annotation as it is.
    else Dump.unparseAnnotation(inAnnotation) + " ";
  end matchcontinue;
end getAnnotationString;

protected function stripGraphicsAndInteractionModification
" This function strips out the `graphics\' modification from an ElementArg
   list and return two lists, one with the other modifications and the
   second with the `graphics\' modification"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst1;
  output list<Absyn.ElementArg> outAbsynElementArgLst2;
algorithm
  (outAbsynElementArgLst1,outAbsynElementArgLst2) := matchcontinue (inAbsynElementArgLst)
    local
      Absyn.ElementArg mod;
      list<Absyn.ElementArg> rest,l1,l2;

    // handle empty
    case ({}) then ({},{});

    // adrpo: remove interaction annotations as we don't handle them currently
    case (((Absyn.MODIFICATION(path = Absyn.IDENT(name = "interaction"))) :: rest))
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,l2);

    // adrpo: remove empty annotations, to handle bad Dymola annotations, for example: Diagram(graphics)
    case (((Absyn.MODIFICATION(modification = NONE(), path = Absyn.IDENT(name = "graphics"))) :: rest))
      equation
         (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,l2);

    // add graphics to the second tuple
    case (((mod as Absyn.MODIFICATION(modification = SOME(_), path = Absyn.IDENT(name = "graphics"))) :: rest))
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        (l1,mod::l2);

    // collect in the first tuple
    case (((mod as Absyn.MODIFICATION()) :: rest))
      equation
        (l1,l2) = stripGraphicsAndInteractionModification(rest);
      then
        ((mod :: l1),l2);

  end matchcontinue;
end stripGraphicsAndInteractionModification;

public function getComponentsInClass
" Both public and protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
                case Absyn.PROTECTED(contents = elts)
                  algorithm
                    lst1 := getComponentsInElementitems(elts);
                    res := List.append_reverse(lst1, res);
                  then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
                case Absyn.PROTECTED(contents = elts)
                  algorithm
                    lst1 := getComponentsInElementitems(elts);
                    res := List.append_reverse(lst1, res);
                  then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};

  end match;
end getComponentsInClass;

public function getPublicComponentsInClass
" Public lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PUBLIC(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};
  end match;
end getPublicComponentsInClass;

public function getProtectedComponentsInClass
" Protected lists are searched."
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm
  outAbsynElementLst:=
  match (inClass)
    local
      list<Absyn.Element> lst1,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PROTECTED(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then {};
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = lst)))
      algorithm
        res := {};
        for elt in lst loop
          _ := match elt
              case Absyn.PROTECTED(contents = elts)
                algorithm
                  lst1 := getComponentsInElementitems(elts);
                  res := List.append_reverse(lst1, res);
                then ();
              else ();
            end match;
        end for;
        res := Dangerous.listReverseInPlace(res);
      then
        res;

    else {};
  end match;
end getProtectedComponentsInClass;

protected function getComponentsInElementitems
"Helper function to getComponentsInClass."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Element> outAbsynElementLst = {};
algorithm
  for el in inAbsynElementItemLst loop
    _ := match (el)
        local
          Absyn.Element elt;
        case Absyn.ELEMENTITEM(element = elt)
          algorithm
            outAbsynElementLst := elt :: outAbsynElementLst;
          then ();

        else ();
      end match;
  end for;
  outAbsynElementLst := Dangerous.listReverseInPlace(outAbsynElementLst);
end getComponentsInElementitems;

protected function getNthComponentInClass
"Returns the nth GlobalScript.Component of a class. Indexed from 1..n."
  input Absyn.Class inClass;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm
  outElement:=
  matchcontinue (inClass,inInteger)
    local
      Integer count,n,c1,newn;
      Absyn.Element res;
      String a,newnstr;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst,rest;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: _))),n)
      equation
        count = countComponentsInElts(elt, 0);
        true = n <= count;
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    // The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: rest),ann = ann,comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt, 0);
        newn = n - c1;
        true = newn > 0;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},rest,ann,cmt),file_info),
          newn);
      then
        res;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: _))),n)
      equation
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    // The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: rest),comment = cmt,ann = ann),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt, 0);
        newn = n - c1;
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},rest,ann,cmt),file_info), newn);
      then
        res;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (_ :: lst),ann = ann,comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), n);
      then
        res;

    case (Absyn.CLASS(body = Absyn.PARTS(classParts = {})),_)
      then fail();

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: _))),n)
      equation
        count = countComponentsInElts(elt, 0);
        (n <= count) = true;
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    // The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: rest),ann = ann,comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt, 0);
        newn = n - c1;
        true = newn > 0;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},rest,ann,cmt),file_info),
          newn);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: _))),n)
      equation
        res = getNthComponentInElementitems(elt, n);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    // The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: rest),ann = ann,comment = cmt),
                      info = file_info),n)
      equation
        c1 = countComponentsInElts(elt, 0);
        newn = n - c1;
        true = newn > 0;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},rest,ann,cmt),file_info), newn);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),ann = ann,comment = cmt),
                      info = file_info),n)
      equation
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},{},lst,ann,cmt),file_info), n);
      then
        res;

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {})),_)
      then fail();


    case (Absyn.CLASS(body = Absyn.DERIVED()),_)
      then fail();

  end matchcontinue;
end getNthComponentInClass;

protected function getNthComponentInElementitems
" This function takes an ElementItem list and an integer
   and returns the nth component in the list, indexed from 1..n."
  input list<Absyn.ElementItem> inElements;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm
  outElement:= match (inElements, inInteger)
    local
      Boolean a;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.InnerOuter c;
      Absyn.ElementAttributes e;
      Absyn.TypeSpec f;
      Absyn.ComponentItem item;
      SourceInfo info;
      Option<Absyn.ConstrainClass> i;
      Integer numcomps,newn,n,n_1;
      Absyn.Element res;
      list<Absyn.ComponentItem> lst;
      list<Absyn.ElementItem> rest;

    case ((Absyn.ELEMENTITEM(element =
        Absyn.ELEMENT(a, b, c, Absyn.COMPONENTS(e, f, (item::_)), info, i)) :: _),1)
      then
        Absyn.ELEMENT(a,b,c,Absyn.COMPONENTS(e,f,{item}),info,i);

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(a, b, c,
        Absyn.COMPONENTS(e, f, lst), info, i)) :: rest),n)
      algorithm
        numcomps := listLength(lst);

        if n > numcomps then
          newn := n - numcomps;
          res := getNthComponentInElementitems(rest, newn);
        else
          item := listGet(lst, n);
          res := Absyn.ELEMENT(a, b, c, Absyn.COMPONENTS(e, f, {item}), info, i);
        end if;
      then
        res;

    case ((_ :: rest),n)
      equation
        res = getNthComponentInElementitems(rest, n);
      then
        res;

    case ({},_) then fail();

  end match;
end getNthComponentInElementitems;

protected function getComponentInfo
" This function takes an Element and returns a list of strings
   of comma separated values of the type and name and comment,
   and attributes of  of the component, If Element is not a
   component, the empty string is returned.
   inputs: (Absyn.Element, string, /* public or protected */, FCore.Graph)
   outputs: string list"
  input Absyn.Element inElement;
  input Boolean inQuoteNames;
  input String inVisibility;
  input FCore.Graph inEnv;
  output list<String> outStringLst;
algorithm
  outStringLst := match inElement
    local
      Absyn.ElementAttributes attr;
      Absyn.Path p, env_path, pkg_path, tp_path;
      list<Absyn.ComponentItem> comps;
      FCore.Graph env;
      list<String> names, dims;
      Option<Absyn.Path> oenv_path;
      String tp_name, typename, final_str, repl_str, io_str;
      String flow_str, stream_str, var_str, dir_str, dim_str, str;

    case Absyn.ELEMENT(specification = Absyn.COMPONENTS(
        attributes = attr, typeSpec = Absyn.TPATH(path = p), components = comps))
      algorithm
        typename := matchcontinue ()
          // Look up the full type path.
          case ()
            algorithm
              (_, _, env) := Lookup.lookupClass(FCore.emptyCache(), inEnv, p);
              oenv_path := FGraph.getScopePath(env);

              // If the type was found in a non-top scope, construct the fully
              // qualified path of the type. Otherwise the type is already fully
              // qualified, and we can use it as it is.
              if isSome(oenv_path) then
                SOME(env_path) := oenv_path;
                tp_name := Absyn.pathLastIdent(p);
                tp_path := Absyn.suffixPath(env_path, tp_name);
              else
                tp_path := p;
              end if;
            then
              Absyn.pathString(tp_path);

          // If the first case fails, i.e. if the type name doesn't reference an
          // existing type, try to construct a fully qualified path to where the
          // type should be, but isn't.
          case ()
            algorithm
              // Look up the first identifier in the type name.
              pkg_path := Absyn.pathFirstPath(p);
              (_, _, env) := Lookup.lookupClass(FCore.emptyCache(), inEnv, pkg_path);
              oenv_path := FGraph.getScopePath(env);

              // Replace the first identifier in the type name with the path to
              // the found class. If the class was found at top-scope, i.e. if
              // oenv_path is NONE, then the type name is already fully qualified.
              if isSome(oenv_path) then
                SOME(env_path) := oenv_path;
                tp_path := Absyn.joinPaths(env_path, p);
              else
                tp_path := p;
              end if;
            then
              Absyn.pathString(tp_path);

          else Absyn.pathString(p);
        end matchcontinue;

        names := getComponentItemsNameAndComment(comps, inQuoteNames);
        dims := getComponentitemsDimension(comps);
        final_str := boolString(inElement.finalPrefix);
        repl_str := boolString(keywordReplaceable(inElement.redeclareKeywords));
        io_str := innerOuterStr(inElement.innerOuter);
        flow_str := attrFlowStr(attr);
        stream_str := attrStreamStr(attr);
        var_str := attrVariabilityStr(attr);
        dir_str := attrDirectionStr(attr);
        dim_str := attrDimensionStr(attr);

        if inQuoteNames then
          typename := StringUtil.quote(typename);
          final_str := StringUtil.quote(final_str);
          repl_str := StringUtil.quote(repl_str);
          flow_str := StringUtil.quote(flow_str);
          stream_str := StringUtil.quote(stream_str);
        end if;

        names := prefixTypename(typename, names);
        str := stringDelimitList({inVisibility, final_str, flow_str,
          stream_str, repl_str, var_str, io_str, dir_str}, ", ");
      then
        suffixInfos(names, dims, dim_str, str, inQuoteNames);

    else {};

  end match;
end getComponentInfo;

protected function arrayDimensionStr
"prints array dimensions to a string"
  input Option<Absyn.ArrayDim> ad;
  output String str;
algorithm
  str:=match(ad)
  local Absyn.ArrayDim adim;
    case(SOME(adim)) equation
      str = stringDelimitList(List.map(adim,Dump.printSubscriptStr),",");
    then str;
    else "";
  end match;
end arrayDimensionStr;


protected function getComponentsInfo
"Helper function to get_components.
  Return all the info as a comma separated list of values.
  get_component_info => {{name, type, comment, access, final, flow, stream, replaceable, variability,innerouter,vardirection},..}
  where access is one of: \"public\", \"protected\"
  where final is one of: true, false
  where flow is one of: true, false
  where flow is one of: true, false
  where stream is one of: true, false
  where replaceable is one of: true, false
  where parallelism is one of: \"parglobal\", \"parlocal\", \"unspecified\"
  where variability is one of: \"constant\", \"parameter\", \"discrete\" or \"unspecified\"
  where innerouter is one of: \"inner\", \"outer\", (\"innerouter\") or \"none\"
  where vardirection is one of: \"input\", \"output\" or \"unspecified\".
  inputs:  (Absyn.Element list, string /* \"public\" or \"protected\" */, FCore.Graph)
  outputs:  string"
  input list<Absyn.Element> inAbsynElementLst;
  input Boolean inBoolean;
  input String inString;
  input FCore.Graph inEnv;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynElementLst,inBoolean,inString,inEnv)
    local
      list<String> lst;
      String lst_1,res,access;
      list<Absyn.Element> elts;
      FCore.Graph env;
      Boolean b;
    case (elts,_,access,env)
      equation
        ((lst as (_ :: _))) = getComponentsInfo2(elts, inBoolean, access, env, {});
        lst_1 = stringDelimitList(lst, "},{");
        res = stringAppendList({"{",lst_1,"}"});
      then
        res;
    else "";
  end matchcontinue;
end getComponentsInfo;

protected function getComponentsInfo2
"Helper function to getComponentsInfo
  inputs: (Absyn.Element list, string /* \"public\" or \"protected\" */, FCore.Graph)
  outputs: string list"
  input list<Absyn.Element> inAbsynElementLst;
  input Boolean inBoolean;
  input String inString;
  input FCore.Graph inEnv;
  input list<String> acc;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inAbsynElementLst,inBoolean,inString,inEnv,acc)
    local
      list<String> res;
      Absyn.Element elt;
      list<Absyn.Element> rest;
      String access;
      FCore.Graph env;
      Boolean b;
    case ({},_,_,_,_) then listReverse(acc);
    case ((elt :: rest),b,access,env,_)
      equation
        res = getComponentInfo(elt, b, access, env);
      then getComponentsInfo2(rest, b, access, env, List.append_reverse(res,acc));
  end match;
end getComponentsInfo2;

public function keywordReplaceable
"Returns true if RedeclareKeywords contains replaceable."
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true;
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true;
    else false;
  end match;
end keywordReplaceable;

protected function getComponentInfoOld
" This function takes an `Element\' and returns a list of strings
   of comma separated values of the type and name and comment of
   the component, e.g. \'Resistor,R1, \"comment\"\'
   or \'Resistor,R1,\"comment1\",R2,\"comment2\"\'
   If Element is not a component, the empty string is returned"
  input Absyn.Element inElement;
  input FCore.Graph inEnv;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inElement,inEnv)
    local
      SCode.Element c;
      FCore.Graph env_1,env;
      Absyn.Path envpath,p_1,p;
      String tpname,typename;
      list<Absyn.ComponentItem> lst;
      list<String> names,strList;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.ElementAttributes attr;

    case (Absyn.ELEMENT(
                        specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(p, _),components = lst)),
          env)
      equation
        (_,_,env_1) = Lookup.lookupClass(FCore.emptyCache(),env, p, SOME(inElement.info));
        SOME(envpath) = FGraph.getScopePath(env_1);
        tpname = Absyn.pathLastIdent(p);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        typename = Absyn.pathString(p_1);
        names = getComponentItemsNameAndComment(lst,false);
        strList = prefixTypename(typename, names);
      then
        strList;

    case (Absyn.ELEMENT(
                        specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(p, _),components = lst)),
          _)
      equation
        typename = Absyn.pathString(p);
        names = getComponentItemsNameAndComment(lst,false);
        strList = prefixTypename(typename, names);
      then
        strList;

    case (_,_) then {};

    else
      equation
        print("Interactive.getComponentInfoOld failed\n");
      then
        fail();
  end matchcontinue;
end getComponentInfoOld;

protected function innerOuterStr
"Helper function to getComponentInfo, retrieve the inner outer string."
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  match (inInnerOuter)
    case (Absyn.INNER()) then "\"inner\"";
    case (Absyn.OUTER()) then "\"outer\"";
    case (Absyn.NOT_INNER_OUTER()) then "\"none\"";
    case (Absyn.INNER_OUTER()) then "\"innerouter\"";
  end match;
end innerOuterStr;

protected function attrFlowStr
"Helper function to get_component_info,
  retrieve flow attribite as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean f;
    case (Absyn.ATTR(flowPrefix = f))
      equation
        res = boolString(f);
      then
        res;
  end match;
end attrFlowStr;

protected function attrStreamStr
"Helper function to get_component_info,
  retrieve stream attribute as bool string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    local
      String res;
      Boolean s;
    case (Absyn.ATTR(streamPrefix = s))
      equation
        res = boolString(s);
      then
        res;
  end match;
end attrStreamStr;

protected function attrParallelismStr
"Helper function to get_component_info,
  retrieve parallelism as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(parallelism = Absyn.PARGLOBAL())) then "\"parglobal\"";
    case (Absyn.ATTR(parallelism = Absyn.PARLOCAL())) then "\"parlocal\"";
    case (Absyn.ATTR(parallelism = Absyn.NON_PARALLEL())) then "";
  end match;
end attrParallelismStr;

protected function attrVariabilityStr
"Helper function to get_component_info,
  retrieve variability as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(variability = Absyn.VAR())) then "\"unspecified\"";
    case (Absyn.ATTR(variability = Absyn.DISCRETE())) then "\"discrete\"";
    case (Absyn.ATTR(variability = Absyn.PARAM())) then "\"parameter\"";
    case (Absyn.ATTR(variability = Absyn.CONST())) then "\"constant\"";
  end match;
end attrVariabilityStr;

protected function attrDimensionStr
"Helper function to getComponentInfo,
  retrieve dimension as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
      local Absyn.ArrayDim ad;
    case (Absyn.ATTR(arrayDim = ad)) then arrayDimensionStr(SOME(ad));
  end match;
end attrDimensionStr;

protected function attrDirectionStr
"Helper function to get_component_info,
  retrieve direction as a string."
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  match (inElementAttributes)
    case (Absyn.ATTR(direction = Absyn.INPUT())) then "\"input\"";
    case (Absyn.ATTR(direction = Absyn.OUTPUT())) then "\"output\"";
    case (Absyn.ATTR(direction = Absyn.BIDIR())) then "\"unspecified\"";
  end match;
end attrDirectionStr;

protected function getComponentitemsDimension
"Retrieves the dimensions of a list of components as a list of strings."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String str;
      list<String> lst,res;
      Absyn.ComponentItem c2;
      list<Absyn.ComponentItem> rest;
      Absyn.ArrayDim ad;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(arrayDim=ad))) :: (c2 :: rest))
      equation
        lst = getComponentitemsDimension((c2 :: rest));
        str = stringDelimitList(List.map(ad,Dump.printSubscriptStr),",");
      then (str :: lst);
    case ((_ :: rest))
      equation
        res = getComponentitemsDimension(rest);
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(arrayDim = ad))})
      equation
        str = stringDelimitList(List.map(ad,Dump.printSubscriptStr),",");
      then
        {str};
    case ({_}) then {};
  end matchcontinue;
end getComponentitemsDimension;

protected function suffixInfos
"Helper function to getComponentInfo.
  Add suffix info (from each component) to element names, dimensions, etc."
  input list<String> eltInfo;
  input list<String> idims;
  input String typeAd;
  input String suffix;
  input Boolean inBoolean;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (eltInfo,idims,typeAd,suffix,inBoolean)
    local
      list<String> res,rest,dims;
      String str_1,str;
      String dim,s1;
      Boolean b;
    case ({},{},_,_,_) then {};
    case ((str :: rest),dim::dims,_,_,b)
      equation
        res = suffixInfos(rest, dims,typeAd,suffix,b);
        s1 = Util.stringDelimitListNonEmptyElts({dim,typeAd},",");
        str_1 = if b then stringAppendList({str,", ",suffix,",\"{",s1,"}\""}) else stringAppendList({str,", ",suffix,",{",s1,"}"});
      then
        (str_1 :: res);
  end match;
end suffixInfos;

protected function prefixTypename
"Helper function to getComponentInfo. Add a prefix typename to each string in the list."
  input String inType;
  input list<String> inComponents;
  output list<String> outComponents =
    list(stringAppendList({inType, ",", c}) for c in inComponents);
end prefixTypename;

protected function getComponentItemsNameAndComment
" separated list of all component names and comments (if any)."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inQuoteNames "Adds quotes around the component names if true.";
  output list<String> outStrings = {};
protected
  String name, cmt_str, str;
algorithm
  for comp in listReverse(inComponents) loop
    _ := match comp
      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))
        algorithm
          cmt_str := getClassCommentInCommentOpt(comp.comment);
          outStrings := (if inQuoteNames then
            stringAppendList({"\"", name, "\",\"", cmt_str, "\""}) else
            stringAppendList({name, ",\"", cmt_str, "\""})) :: outStrings;
        then
          ();

      else ();
    end match;
  end for;
end getComponentItemsNameAndComment;

protected function getComponentItemsName
" separated list of all component names."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inQuoteNames "Adds quotes around the component names if true.";
  output list<String> outStrings = {};
protected
  String name;
algorithm
  for comp in listReverse(inComponents) loop
    _ := match comp
      case Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name))
        algorithm
          outStrings := (if inQuoteNames then
            stringAppendList({"\"", name, "\""}) else
            stringAppendList({name})) :: outStrings;
        then
          ();

      else ();
    end match;
  end for;
end getComponentItemsName;

public function addToPublic
" This function takes a Class definition and adds an
   ElementItem to the first public list in the class.
   If no public list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.ElementItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs=classAttrs,classParts = parts,comment = cmt,ann = ann),
                      info = file_info),eitem)
      equation
        publst = getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,comment = cmt,ann=ann),
                      info = file_info),eitem)
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,(Absyn.PUBLIC({eitem}) :: parts),ann,cmt),file_info);

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        publst = getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann),file_info);

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PUBLIC({eitem}) :: parts),ann),file_info);
    case (Absyn.CLASS(
                      body = Absyn.DERIVED()),_)
      then fail();

  end matchcontinue;
end addToPublic;

protected function addToProtected
" This function takes a Class definition and adds an
   ElementItem to the first protected list in the class.
   If no protected list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> protlst,protlst2;
      list<Absyn.ClassPart> parts2,parts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.ElementItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,comment = cmt, ann = ann),
                      info = file_info),eitem)
      equation
        protlst = getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,comment = cmt, ann = ann),
                      info = file_info),eitem)
      then Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,(Absyn.PROTECTED({eitem}) :: parts),ann,cmt),file_info);

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt, ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        protlst = getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2, ann),file_info);

    // adrpo: handle also the case model extends X end X;
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt, ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      then Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PROTECTED({eitem}) :: parts),ann),file_info);

    // handle the model X = Y case
    /*
    case (Absyn.CLASS(body = Absyn.DERIVED()),_)
      then fail();
    */
  end matchcontinue;
end addToProtected;

public function addToEquation
" This function takes a Class definition and adds an
   EquationItem to the first equation list in the class.
   If no public list is available in the class one is created."
  input Absyn.Class inClass;
  input Absyn.EquationItem inEquationItem;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inEquationItem)
    local
      list<Absyn.EquationItem> eqlst,eqlst2;
      list<Absyn.ClassPart> parts2,parts,newparts;
      String i, baseClassName;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      SourceInfo file_info;
      Absyn.EquationItem eitem;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = file_info),eitem)
      equation
        eqlst = getEquationList(parts);
        eqlst2 = listAppend(eqlst, {eitem});
        parts2 = replaceEquationList(parts, eqlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,newparts,ann,cmt),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        eqlst = getEquationList(parts);
        eqlst2 = listAppend(eqlst, {eitem});
        parts2 = replaceEquationList(parts, eqlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 ann = ann,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,newparts,ann),file_info);

    case (Absyn.CLASS(body = Absyn.DERIVED()),_)
      then fail();

  end matchcontinue;
end addToEquation;

protected function buildPath
"Helper function to replaceClassInProgram.
  Takes a programs 'within' and a ident, and creates a path out of it."
  input Absyn.Within inWithin;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath :=
  match (inWithin,inPath)
    local Absyn.Path p, p1, p2;
    case (Absyn.TOP(), p) then p;
    case (Absyn.WITHIN(path = p),p1) equation p2 = Absyn.joinPaths(p, p1); then p2;
  end match;
end buildPath;

protected function replaceClassInProgram2
  input Absyn.Class inClass;
  input String inClassName;
  output Boolean outReplace;
protected
  String cls_name;
algorithm
  Absyn.CLASS(name = cls_name) := inClass;
  outReplace := cls_name == inClassName;
end replaceClassInProgram2;

protected function replaceClassInProgram
" This function takes a Class and a Program and replaces the class
   definition at the top level in the program by the class definition of
   the Class. It also updates the functionlist for the symboltable if needed."
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
protected
  String cls_name1, cls_name2;
  list<Absyn.Class> clst, clsFilter;
  Absyn.Within w;
  Boolean replaced;
  Absyn.Class cls;
algorithm
  Absyn.CLASS(name = cls_name1) := inClass;
  Absyn.PROGRAM(classes = clst, within_ = w) := inProgram;
  if mergeAST then
    clsFilter := List.filterOnTrue(clst, function replaceClassInProgram2(inClassName = cls_name1));
    if listEmpty(clsFilter)
    then
      cls := inClass;
    else
      cls::_ := clsFilter;
      cls := mergeClasses(inClass, cls);
    end if;
  else
   cls := inClass;
  end if;
  (clst, replaced) := List.replaceOnTrue(cls, clst,
    function replaceClassInProgram2(inClassName = cls_name1));

  if not replaced then
    clst := List.appendElt(inClass, clst);
  end if;

  outProgram := Absyn.PROGRAM(clst, w);
end replaceClassInProgram;

protected function insertClassInProgram
" This function inserts the class into the Program at the scope given by
   the within argument. If the class referenced by the within argument is
   not defined, the function prints an error message and fails."
  input Absyn.Class inClass;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inClass,inWithin,inProgram)
    local
      Absyn.Class c2,c3,c1;
      Absyn.Program pnew,p;
      Absyn.Within w;
      String n1,s1,s2,name;
      list<Absyn.Path> paths;

    case (c1,(w as Absyn.WITHIN(path = Absyn.QUALIFIED(name = n1))),p as Absyn.PROGRAM())
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2, mergeAST);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (c1,(w as Absyn.WITHIN(path = Absyn.IDENT(name = n1))),p as Absyn.PROGRAM())
      equation
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2, mergeAST);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p, mergeAST);
      then
        pnew;

    case (_,Absyn.WITHIN(path=Absyn.QUALIFIED(name="OpenModelica")),p) then p;

    case ((Absyn.CLASS(name = name)),w,p)
      equation
        s1 = Dump.unparseWithin(w);
        /* adeas31 2012-01-25: false indicates that the classnamesrecursive doesn't look into protected sections */
        /* adeas31 2016-11-29: false indicates that the classnamesrecursive doesn't look for constants */
        (_, paths) = getClassNamesRecursive(NONE(), p, false, false, {});
        s2 = stringAppendList(List.map1r(list(Absyn.pathString(p) for p in paths),stringAppend,"\n  "));
        Error.addMessage(Error.INSERT_CLASS, {name,s1,s2});
      then
        fail();

  end matchcontinue;
end insertClassInProgram;

protected function insertClassInClass "
   This function takes a class to update (the first argument)  and an inner
   class (which is either replacing
   an earlier class or is a new inner definition) and a within statement
   pointing inside the class (including the class itself in the reference),
   and updates the class with the inner class.
"
  input Absyn.Class inClass1;
  input Absyn.Within inWithin2;
  input Absyn.Class inClass3;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass := match (inClass1,inWithin2,inClass3)
    local
      Absyn.Class cnew,c1,c2,cinner,cnew_1;
      String name,name2;
      Absyn.Path path;

    case (c1,Absyn.WITHIN(path = Absyn.IDENT()),c2)
      then replaceInnerClass(c1, c2, mergeAST);

    case (c1,Absyn.WITHIN(path = Absyn.QUALIFIED(path = path)),c2)
      equation
        name2 = getFirstIdentFromPath(path);
        cinner = getInnerClass(c2, name2);
        cnew = insertClassInClass(c1, Absyn.WITHIN(path), cinner, mergeAST);
      then replaceInnerClass(cnew, c2, mergeAST);

  end match;
end insertClassInClass;

protected function getFirstIdentFromPath "
   This function takes a `Path` as argument and returns the first `Ident\'
   of the path.
"
  input Absyn.Path inPath;
  output Absyn.Ident outIdent;
algorithm
  outIdent:=
  match (inPath)
    local
      String name;
      Absyn.Path path;
    case (Absyn.IDENT(name = name)) then name;
    case (Absyn.QUALIFIED(name = name)) then name;
  end match;
end getFirstIdentFromPath;

protected function removeInnerClass "
   This function takes two class definitions. The first one is the local
   class that should be removed from the second one.
"
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2,prolst,prolst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname,n;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    // a class with parts - class found in public
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann, comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    // a class with parts - class found in protected
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann, comment = cmt),info = file_info))
      equation
        prolst = getProtectedList(parts);
        prolst2 = removeClassInElementitemlist(prolst, c1);
        parts2 = replaceProtectedList(parts, prolst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    // an extended class with parts: model extends M end M; - class found in public
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt,ann = ann),info = file_info))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);

    // an extended class with parts: model extends M end M; - class found in protected
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName=bcname,modifications=modif,parts = parts,comment = cmt,ann = ann),info = file_info))
      equation
        prolst = getProtectedList(parts);
        prolst2 = removeClassInElementitemlist(prolst, c1);
        parts2 = replaceProtectedList(parts, prolst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);

    // class not found anywhere!
    case (Absyn.CLASS(name = n),Absyn.CLASS(name = a, info = file_info))
      equation
        Error.addSourceMessage(Error.CLASS_NOT_FOUND, {n, a}, file_info);
      then
        fail();

  end matchcontinue;
end removeInnerClass;

protected function classElementItemIsNamed
  input String inClassName;
  input Absyn.ElementItem inElement;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inElement)
    local
      String name;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
        Absyn.CLASSDEF(class_ = (Absyn.CLASS(name = name)))))
      then inClassName == name;

    else false;
  end match;
end classElementItemIsNamed;

protected function removeClassInElementitemlist
" This function takes an Element list and a Class and returns a modified
   element list where the class definition of the class is removed."
  input list<Absyn.ElementItem> inElements;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outElements;
protected
  String name;
algorithm
  Absyn.CLASS(name = name) := inClass;
  outElements := List.deleteMemberOnTrue(name, inElements, classElementItemIsNamed);
end removeClassInElementitemlist;

protected function replaceInnerClass
"This function takes two class definitions. The first one is
  inserted/replaced as a local class inside the second one."
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2,prolst,prolst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a,bcname;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    // a class with parts - we can find the element in the public list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        (publst2, true) = replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    // a class with parts - we can find the element in the protected list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        prolst = getProtectedList(parts);
        (prolst2, true) = replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 = replaceProtectedList(parts, prolst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    // a class with parts - we cannot find the element in the public or protected list, add it to the public list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst = addClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    // an extended class with parts: model extends M end M; - we can find the element in the public list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        (publst2, true) = replaceClassInElementitemlist(publst, c1, mergeAST);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);

    // an extended class with parts: model extends M end M; - we can find the element in the protected list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        prolst = getProtectedList(parts);
        (prolst2, true) = replaceClassInElementitemlist(prolst, c1, mergeAST);
        parts2 = replaceProtectedList(parts, prolst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);

    // an extended class with parts: model extends M end M; - we cannot find the element in the public or protected list, add it to the public list
    case (c1,Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                         body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications = modif,parts = parts,ann=ann,comment = cmt),info = file_info))
      equation
        publst = getPublicList(parts);
        publst = addClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann),file_info);

    else
      equation
        Print.printBuf("Failed in replaceInnerClass\n");
      then
        fail();
  end matchcontinue;
end replaceInnerClass;

protected function replaceClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  input Boolean mergeAST = false "when true, the new program should be merged with the old program";
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean replaced "true signals a replacement, false nothing changed!";
algorithm
  (outAbsynElementItemLst, replaced) := match (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c, c1, c2;
      String name1,name;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      SourceInfo info;
      Option<Absyn.ConstrainClass> h;
      Absyn.InnerOuter io;

    case (((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = a,redeclareKeywords = b,innerOuter = io,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = c1 as Absyn.CLASS(name = name1)),constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      guard stringEq(name1, name)
      equation
        c = if mergeAST then mergeClasses(c2, c1) else c2;
        Absyn.CLASS(info = info) = c;
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(a,b,io,Absyn.CLASSDEF(e,c),info /* The new CLASS might have update info */,h)) :: xs, true);

    case ((e1 :: xs),c)
      equation
        (res, replaced) = replaceClassInElementitemlist(xs, c, mergeAST);
      then
        (e1 :: res, replaced);

    else ({}, false);

  end match;
end replaceClassInElementitemlist;

protected function addClassInElementitemlist
"This function takes an Element list and a Class and returns a modified
  element list where the class definition of the class is updated or added."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
protected
  Absyn.Info info;
algorithm
  Absyn.CLASS(info=info) := inClass;
  outAbsynElementItemLst := listAppend(inAbsynElementItemLst,
          {Absyn.ELEMENTITEM(
             Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),Absyn.CLASSDEF(false,inClass),
             info,NONE()))});
end addClassInElementitemlist;

protected function getInnerClass
"This function takes a class name and a class and
  returns the inner class definition having that name."
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inIdent)
    local
      list<Absyn.ElementItem> publst,prolst;
      Absyn.Class c1,c;
      list<Absyn.ClassPart> parts;
      String name,str,s1;
      Integer handle;

    // class found in public
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation
        prolst = getProtectedList(parts);
        c1 = getClassFromElementitemlist(prolst, name);
      then
        c1;

    // class found in public
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      equation
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;

    // class found in protected
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),name)
      equation
        prolst = getProtectedList(parts);
        c1 = getClassFromElementitemlist(prolst, name);
      then
        c1;

/* Does nothing
    case (c as Absyn.CLASS(),name)
      equation
        handle = Print.saveAndClearBuf();
        Print.printBuf("Interactive.getInnerClass failed, c:");
        Dump.dump(Absyn.PROGRAM({c},Absyn.TOP()));
        Print.printBuf("name :");
        Print.printBuf(name);
        Print.clear(); // Print.getString();
        Print.restoreBuf(handle);
      then
        fail();
*/
  end matchcontinue;
end getInnerClass;

protected function replacePublicList
" This function replaces the ElementItem list in
   the ClassPart list, and returns the updated list.
   If no public list is available, one is created."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newpublst,new,newpublist;

    case (((Absyn.PUBLIC()) :: rest),newpublst)
      equation
        rest_1 = deletePublicList(rest);
      then
        (Absyn.PUBLIC(newpublst) :: rest_1);

    case ((x :: xs),new)
      equation
        ys = replacePublicList(xs, new);
      then
        (x :: ys);

    case ({},newpublist) then {Absyn.PUBLIC(newpublist)};

  end match;
end replacePublicList;

protected function replaceProtectedList "
  This function replaces the `ElementItem\' list in the `ClassPart\' list,
  and returns the updated list.
  If no protected list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst := match (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newprotlist,new;

    case (((Absyn.PROTECTED()) :: rest),newprotlist)
      equation
        rest_1 = deleteProtectedList(rest);
      then
        (Absyn.PROTECTED(newprotlist) :: rest_1);

    case ((x :: xs),new)
      equation
        ys = replaceProtectedList(xs, new);
      then
        (x :: ys);

    case ({},newprotlist) then {Absyn.PROTECTED(newprotlist)};

  end match;
end replaceProtectedList;

public function replaceEquationList "
   This function replaces the `EquationItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst,inAbsynEquationItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.EquationItem> newequationlst,new;
    case (((Absyn.EQUATIONS()) :: rest),newequationlst) then (Absyn.EQUATIONS(newequationlst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceEquationList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end match;
end replaceEquationList;

protected function replaceInitialEquationList "
   This function replaces the `EquationItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst,inAbsynEquationItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.EquationItem> newequationlst,new;
    case (((Absyn.INITIALEQUATIONS()) :: rest),newequationlst) then (Absyn.INITIALEQUATIONS(newequationlst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceInitialEquationList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end match;
end replaceInitialEquationList;

protected function replaceAlgorithmList "
   This function replaces the `AlgorithmItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst,inAbsynAlgorithmItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.AlgorithmItem> newalgorithmlst,new;
    case (((Absyn.ALGORITHMS()) :: rest),newalgorithmlst) then (Absyn.ALGORITHMS(newalgorithmlst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceAlgorithmList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end match;
end replaceAlgorithmList;

protected function replaceInitialAlgorithmList "
   This function replaces the `AlgorithmItem\' list in the `ClassPart\' list,
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst,inAbsynAlgorithmItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.AlgorithmItem> newalgorithmlst,new;
    case (((Absyn.INITIALALGORITHMS()) :: rest),newalgorithmlst) then (Absyn.INITIALALGORITHMS(newalgorithmlst) :: rest);
    case ((x :: xs),new)
      equation
        ys = replaceInitialAlgorithmList(xs, new);
      then
        (x :: ys);
    case ({},_) then {};
  end match;
end replaceInitialAlgorithmList;

protected function deletePublicList "
  Deletes all PULIC classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PUBLIC() :: xs))
      equation
        res = deletePublicList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deletePublicList(xs);
      then
        (x :: res);
  end match;
end deletePublicList;

protected function deleteProtectedList "
  Deletes all PROTECTED classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case ((Absyn.PROTECTED() :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        res;
    case ((x :: xs))
      equation
        res = deleteProtectedList(xs);
      then
        (x :: res);
  end match;
end deleteProtectedList;

public function getPublicList "
  This function takes a ClassPart List and returns an appended list of
  all public lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PUBLIC(contents = res1) :: rest)
      equation
        res2 = getPublicList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        ys = getPublicList(xs);
      then
        ys;
  end match;
end getPublicList;

public function getProtectedList "
  This function takes a ClassPart List and returns an appended list of
  all protected lists."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  match (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {};
    case (Absyn.PROTECTED(contents = res1) :: rest)
      equation
        res2 = getProtectedList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        ys = getProtectedList(xs);
      then
        ys;
  end match;
end getProtectedList;

public function getEquationList "This function takes a ClassPart List and returns the first EquationItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := match (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.EQUATIONS(contents = lst) :: _) then lst;
    case ((_ :: xs))
      equation
        ys = getEquationList(xs);
      then
        ys;
    else fail();
  end match;
end getEquationList;

protected function getInitialEquationList "This function takes a ClassPart List and returns the first InitialEquationItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outAbsynInitialEquationItemLst;
algorithm
  outAbsynInitialEquationItemLst := match (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.INITIALEQUATIONS(contents = lst) :: _) then lst;
    case ((_ :: xs))
      equation
        ys = getInitialEquationList(xs);
      then
        ys;
    else fail();
  end match;
end getInitialEquationList;

protected function getAlgorithmList "This function takes a ClassPart List and returns the first AlgorithmItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.AlgorithmItem> outAbsynAlgorithmItemLst;
algorithm
  outAbsynAlgorithmItemLst := match (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.ALGORITHMS(contents = lst) :: _) then lst;
    case ((_ :: xs))
      equation
        ys = getAlgorithmList(xs);
      then
        ys;
    else fail();
  end match;
end getAlgorithmList;

protected function getInitialAlgorithmList "This function takes a ClassPart List and returns the first InitialAlgorithmItem
  list of the class."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.AlgorithmItem> outAbsynInitialAlgorithmItemLst;
algorithm
  outAbsynInitialAlgorithmItemLst := match (inAbsynClassPartLst)
    local
      list<Absyn.AlgorithmItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.INITIALALGORITHMS(contents = lst) :: _) then lst;
    case ((_ :: xs))
      equation
        ys = getInitialAlgorithmList(xs);
      then
        ys;
    else fail();
  end match;
end getInitialAlgorithmList;

protected function getClassFromElementitemlist "
  This function takes an ElementItem list and an Ident and returns the
  class definition among the element list having that identifier.
"
  input list<Absyn.ElementItem> inElements;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
protected
  Absyn.ElementItem elem;
algorithm
  elem := List.getMemberOnTrue(inIdent, inElements, classElementItemIsNamed);
  Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
    Absyn.CLASSDEF(class_ = outClass))) := elem;
end getClassFromElementitemlist;

protected function classInProgram
"This function takes a name and a Program and returns
  true if the name exists as a top class in the program."
  input String name;
  input Absyn.Program p;
  output Boolean b;
algorithm
  b := match p
    local
      String str;
    case Absyn.PROGRAM()
      algorithm
        for cl in p.classes loop
          Absyn.CLASS(name=str) := cl;
          if str == name then
            b := true;
            return;
          end if;
        end for;
      then false;
  end match;
end classInProgram;

public function getPathedClassInProgram
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program.
  If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr = false;
  output Absyn.Class outClass;
protected
  Absyn.Program p;
algorithm
  try
    outClass := getPathedClassInProgramWork(inPath, inProgram, enclOnErr);
  else
    (p, _) := FBuiltin.getInitialFunctions();
    outClass := getPathedClassInProgramWork(inPath, p, enclOnErr);
  end try;
end getPathedClassInProgram;

protected function getPathedClassInProgramWork
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program.
  If enclOnErr is true and such class doesn't exist return enclosing class."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Boolean enclOnErr;
  output Absyn.Class outClass;
algorithm
  outClass := match inPath
    local
      Absyn.Class c;
      String str;
      Absyn.Path path;

    case Absyn.IDENT(name = str)
      then
        getClassInProgram(str, inProgram);

    case Absyn.FULLYQUALIFIED(path)
      then
        getPathedClassInProgram(path, inProgram, enclOnErr);

    case Absyn.QUALIFIED(name = str, path = path)
      equation
        c = getClassInProgram(str, inProgram);
      then
        if enclOnErr then getPathedClassInProgramWorkNoThrow(path, c)
                     else getPathedClassInProgramWorkThrow(path, c);

  end match;
end getPathedClassInProgramWork;

protected function getPathedClassInProgramWorkThrow
"This function takes a Path and a Program and retrieves the
  class definition referenced by the Path from the Program."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := match inPath
    local
      Absyn.Class c;
      String str;
      Absyn.Path path;

    case Absyn.IDENT(name = str)
      then
        getClassInClass(str, inClass);


    case Absyn.FULLYQUALIFIED(path)
      then
        getPathedClassInProgramWorkThrow(path, inClass);

    case Absyn.QUALIFIED(name = str, path = path)
      equation
        c = getClassInClass(str, inClass);
      then
        getPathedClassInProgramWorkThrow(path, c);

  end match;
end getPathedClassInProgramWorkThrow;

protected function getPathedClassInProgramWorkNoThrow
"Retrieves the class definition referenced by the Path from the Class A.
 If such class doesn't exist return Class A."
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  try
    outClass := match inPath
      local
        Absyn.Class c;
        String str;
        Absyn.Path path;

      case Absyn.IDENT(name = str)
        then
          getClassInClass(str, inClass);

      case Absyn.FULLYQUALIFIED(path)
        then
          getPathedClassInProgramWorkNoThrow(path, inClass);

      case Absyn.QUALIFIED(name = str, path = path)
        equation
          c = getClassInClass(str, inClass);
        then
          getPathedClassInProgramWorkNoThrow(path, c);

    end match;
  else
    outClass := inClass;
  end try;
end getPathedClassInProgramWorkNoThrow;


protected function getClassInClass
" This function takes a Path and a Class
   and returns the class with the name Path.
   If that class does not exist, the function fails"
  input String inString;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass := List.find1(getClassesInClass(inClass), compareClassName, inString);
end getClassInClass;

protected function getClassesInClass
"This function takes a Class definition and returns
  a list of local Class definitions of that class."
  input Absyn.Class inClass;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst := match inClass
    local
      list<Absyn.Class> res;
      Absyn.Path modelpath,path;
      Absyn.Program p;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation
        res = getClassesInParts(parts);
      then
        res;

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      equation
        res = getClassesInParts(parts);
      then
        res;

    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(_,_)))
      equation
        /* adrpo 2009-10-27: do not dive into derived classes!
        (cdef,newpath) = lookupClassdef(path, modelpath, p);
        res = getClassesInClass(cdef);
        */
        res = {};
      then
        res;

  end match;
end getClassesInClass;

protected function getClassesInParts
"Helper function to getClassesInClass."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.Class> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;

    case {} then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;

    case ((_ :: rest))
      equation
        res = getClassesInParts(rest);
      then
        res;

  end matchcontinue;
end getClassesInParts;

protected function getClassesInElts
"Helper function to getClassesInParts."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm
  outAbsynClassLst:=
  match (inAbsynElementItemLst)
    local
      list<Absyn.Class> res;
      Absyn.Class class_;
      list<Absyn.ElementItem> rest;

    case {} then {};

    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = class_))) :: rest))
      equation
        res = getClassesInElts(rest);
      then
        (class_ :: res);

    case ((_ :: rest))
      equation
        res = getClassesInElts(rest);
      then
        res;

  end match;
end getClassesInElts;

protected function getClassInProgram
" This function takes a Path and a Program
   and returns the class with the name Path.
   If that class does not exist, the function fails"
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Class cl;
protected
  list<Absyn.Class> classes;
algorithm
  Absyn.PROGRAM(classes=classes) := inProgram;
  cl := List.find1(classes, compareClassName, inString);
end getClassInProgram;

protected function compareClassName
  input Absyn.Class cl;
  input String str;
  output Boolean b;
algorithm
  b := match (cl,str)
    local
      String c1name;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = c1name)),_)
      then stringEq(str, c1name);
    case (Absyn.CLASS(name = c1name),_)
      then stringEq(str, c1name);
  end match;
end compareClassName;

public function transformPathedClassInProgram
  "Transforms a referenced class in a program by applying the given function to it."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input FuncType inFunc;
  output Absyn.Program outProgram;

  partial function FuncType
    input Absyn.Class inClass;
    output Absyn.Class outClass;
  end FuncType;
algorithm
  outProgram := match inPath
    case Absyn.IDENT()
      then transformClassInProgram(inPath.name, inProgram, inFunc);

    case Absyn.FULLYQUALIFIED()
      then transformPathedClassInProgram(inPath.path, inProgram, inFunc);

    case Absyn.QUALIFIED()
      then transformClassInProgram(inPath.name, inProgram,
          function transformPathedClassInClass(inPath = inPath.path, inFunc = inFunc));

  end match;
end transformPathedClassInProgram;

public function transformClassInProgram
  "Transforms a referenced class in a program by applying the given function to
   it, replacing the old class with the new in the list of classes. Fails if the
   class can't be found."
  input String inName;
  input Absyn.Program inProgram;
  input FuncType inFunc;
  output Absyn.Program outProgram;

  partial function FuncType
    input Absyn.Class inClass;
    output Absyn.Class outClass;
  end FuncType;
protected
  list<Absyn.Class> classes, acc = {};
  Absyn.Within wi;
  Absyn.Class cls;
  String name;
algorithm
  Absyn.PROGRAM(classes, wi) := inProgram;

  while true loop
    cls :: classes := classes;
    Absyn.CLASS(name = name) := cls;

    if name == inName then
      cls := inFunc(cls);
      classes := List.append_reverse(acc, cls :: classes);
      outProgram := Absyn.PROGRAM(classes, wi);
      break;
    end if;

    acc := cls :: acc;
  end while;
end transformClassInProgram;

protected function transformPathedClassInClass
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input FuncType inFunc;
  output Absyn.Class outClass;

  partial function FuncType
    input Absyn.Class inClass;
    output Absyn.Class outClass;
  end FuncType;
algorithm
  outClass := match inPath
    case Absyn.Path.IDENT()
      then transformClassInClass(inPath.name, inFunc, inClass);

    case Absyn.Path.QUALIFIED()
      then transformClassInClass(inPath.name,
        function transformPathedClassInClass(inPath = inPath.path, inFunc = inFunc),
        inClass);

    case Absyn.Path.FULLYQUALIFIED()
      then transformPathedClassInClass(inPath.path, inClass, inFunc);

  end match;
end transformPathedClassInClass;

function transformClassInClass
  input String name;
  input FuncType func;
  input output Absyn.Class cls;

  partial function FuncType
    input output Absyn.Class cls;
  end FuncType;
protected
  Absyn.ClassDef body = cls.body;
algorithm
  () := match body
    case Absyn.ClassDef.PARTS()
      algorithm
        body.classParts := List.findMap(body.classParts,
          function transformClassInClassPart(name = name, func = func));
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        body.parts := List.findMap(body.parts,
          function transformClassInClassPart(name = name, func = func));
      then
        ();

    else ();
  end match;

  cls.body := body;
end transformClassInClass;

function transformClassInClassPart
  input String name;
  input FuncType func;
  input output Absyn.ClassPart part;
        output Boolean found;

  partial function FuncType
    input output Absyn.Class cls;
  end FuncType;
algorithm
  found := match part
    local
      list<Absyn.ElementItem> items;

    case Absyn.ClassPart.PUBLIC()
      algorithm
        (items, found) := List.findMap(part.contents,
          function transformClassInElementItem(name = name, func = func));
        part.contents := items;
      then
        found;

    case Absyn.ClassPart.PROTECTED()
      algorithm
        (items, found) := List.findMap(part.contents,
          function transformClassInElementItem(name = name, func = func));
        part.contents := items;
      then
        found;

    else false;
  end match;
end transformClassInClassPart;

function transformClassInElementItem
  input String name;
  input FuncType func;
  input output Absyn.ElementItem item;
        output Boolean found;

  partial function FuncType
    input output Absyn.Class cls;
  end FuncType;
algorithm
  found := match item
    local
      Absyn.Element e;

    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        (e, found) := transformClassInElement(name, func, item.element);
        item.element := e;
      then
        found;

    else false;
  end match;
end transformClassInElementItem;

function transformClassInElement
  input String name;
  input FuncType func;
  input output Absyn.Element element;
        output Boolean found;

  partial function FuncType
    input output Absyn.Class cls;
  end FuncType;
algorithm
  found := match element
    local
      Absyn.ElementSpec spec;

    case Absyn.Element.ELEMENT()
      algorithm
        (spec, found) := transformClassInElementSpec(name, func, element.specification);
        element.specification := spec;
      then
        found;

    else false;
  end match;
end transformClassInElement;

function transformClassInElementSpec
  input String name;
  input FuncType func;
  input output Absyn.ElementSpec spec;
        output Boolean found;

  partial function FuncType
    input output Absyn.Class cls;
  end FuncType;
algorithm
  found := match spec
    local
      Absyn.Class cls;

    case Absyn.ElementSpec.CLASSDEF(class_ = cls)
      guard cls.name == name
      algorithm
        spec.class_ := func(cls);
      then
        true;

    else false;
  end match;
end transformClassInElementSpec;

protected function modificationToAbsyn
" This function takes a list of NamedArg and returns an Absyn.Modification option.
   It collects binding equation from the named argument binding=<expr> and creates
   corresponding Modification option Absyn node.
   Future extension: add general modifiers. Problem: how to express this using named
   arguments. This is not possible. Instead we need a new data type for storing AST,
   and a constructor function for AST,
   e.g. AST x = ASTModification(redeclare R2 r, x=4.2); // new datatype AST
             // new constructor operator ASTModification"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Modification> inAbsynModificationOption;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  outAbsynModificationOption:=
  matchcontinue (inAbsynNamedArgLst,inAbsynModificationOption)
    local
      Absyn.Modification mod;
      list<Absyn.NamedArg> nargs;
      Option<Absyn.Modification> oldmod;
    case (nargs,_)
      equation
        SOME(mod) = modificationToAbsyn2(nargs);
      then
        SOME(mod);
    else inAbsynModificationOption;
  end matchcontinue;
end modificationToAbsyn;

protected function modificationToAbsyn2
"Helper function to modificationToAbsyn."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  outAbsynModificationOption:=
  match (inAbsynNamedArgLst)
    local
      Absyn.Exp exp;
      list<Absyn.NamedArg> xs;
      Absyn.Modification mod;
      Option<Absyn.Modification> res;
      Absyn.NamedArg x;
    case ({}) then NONE();
    case ((Absyn.NAMEDARG(argName = "binding",argValue = exp) :: _)) then SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,Absyn.dummyInfo)));
    case ((Absyn.NAMEDARG(argName = "modification",argValue = Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))) :: _)) then SOME(mod);
    case ((_ :: xs)) equation res = modificationToAbsyn2(xs); then res;
  end match;
end modificationToAbsyn2;

protected function selectAnnotation
"@author: adrpo
  Selects either the new annotation if is SOME or the old one"
  input Option<Absyn.Annotation> newAnn;
  input Option<Absyn.Annotation> oldAnn;
  output Option<Absyn.Annotation> outAnn;
algorithm
  outAnn := match(newAnn, oldAnn)
    case(SOME(_), _) then newAnn;
    case(NONE(),_) then oldAnn;
  end match;
end selectAnnotation;

protected function annotationListToAbsynComment
" This function takes a list of NamedArg and returns an absyn Comment.
   for instance {annotation = Placement( ...), comment=\"stringcomment\" }
   is converted to SOME(COMMENT(ANNOTATION(Placement(...), SOME(\"stringcomment\"))))"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm
  outAbsynCommentOption := matchcontinue (inAbsynNamedArgLst,inAbsynCommentOption)
    local
      Absyn.Comment ann;
      list<Absyn.NamedArg> nargs;
      String oldcmt,newcmt;
      Option<String> cmtOpt;
      Option<Absyn.Annotation> annOptOld, annOptNew, annOpt;

    // old annotation is NONE! take the new one.
    case (nargs,NONE())
      equation
        SOME(ann) = annotationListToAbsynComment2(nargs);
      then
        SOME(ann);

    // old annotation comment is NONE! take the new one.
    case (nargs,SOME(Absyn.COMMENT(annOptOld, NONE())))
      equation
        SOME(Absyn.COMMENT(annOptNew, cmtOpt)) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, cmtOpt));

    // old annotation comment is SOME and new is NONE! take the old one.
    case (nargs,SOME(Absyn.COMMENT(annOptOld, SOME(oldcmt))))
      equation
        SOME(Absyn.COMMENT(annOptNew, NONE())) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, SOME(oldcmt)));

    // old annotation comment is SOME and new is SOME! take the new one.
    case (nargs,SOME(Absyn.COMMENT(annOptOld, SOME(_))))
      equation
        SOME(Absyn.COMMENT(annOptNew, SOME(newcmt))) = annotationListToAbsynComment2(nargs);
        annOpt = selectAnnotation(annOptNew, annOptOld);
      then
        SOME(Absyn.COMMENT(annOpt, SOME(newcmt)));

    // no annotations from nargs
    else inAbsynCommentOption;
  end matchcontinue;
end annotationListToAbsynComment;

protected function annotationListToAbsynComment2
"Helper function to annotationListToAbsynComment2."
  input list<Absyn.NamedArg> inNamedArgs;
  output Option<Absyn.Comment> outComment;
protected
  list<Absyn.ElementArg> annargs;
  Option<String> ostrcmt;
  Absyn.Annotation ann;
algorithm
  ann as Absyn.ANNOTATION(annargs) := annotationListToAbsyn(inNamedArgs);
  ostrcmt := commentToAbsyn(inNamedArgs);

  outComment := match(ostrcmt, annargs)
    case (SOME(""), {}) then NONE();
    case (SOME(_), {}) then SOME(Absyn.COMMENT(NONE(), ostrcmt));
    case (NONE(), {}) then NONE();
    else SOME(Absyn.COMMENT(SOME(ann), ostrcmt));
  end match;
end annotationListToAbsynComment2;

protected function commentToAbsyn
"Helper function to annotationListToAbsynComment2."
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<String> outStringOption;
algorithm
  outStringOption:=
  match (inAbsynNamedArgLst)
    local
      String str;
      Option<String> res;
      list<Absyn.NamedArg> rest;
    case ((Absyn.NAMEDARG(argName = "comment",argValue = Absyn.STRING(value = str)) :: _))
        guard not stringEq(str, "")
      then
        SOME(str);
    case ((_ :: rest))
      equation
        res = commentToAbsyn(rest);
      then
        res;
    else NONE();
  end match;
end commentToAbsyn;

public function annotationListToAbsyn
"This function takes a list of NamedArg and returns an Absyn.Annotation.
  for instance {annotation = Placement( ...) } is converted to ANNOTATION(Placement(...))"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Annotation outAnnotation;
protected
  list<Absyn.ElementArg> args={};
algorithm
  for arg in inAbsynNamedArgLst loop
    args := match arg
      local
        Absyn.ElementArg eltarg;
        Absyn.Exp e;
        Absyn.Annotation annres;
        Absyn.NamedArg a;
        list<Absyn.NamedArg> al;
        String name;
      case Absyn.NAMEDARG(argName = "annotate",argValue = e)
        equation
          eltarg = recordConstructorToModification(e);
        then eltarg::args;
      case Absyn.NAMEDARG(argName = "comment") then args;
      else args;
    end match;
  end for;
  outAnnotation := Absyn.ANNOTATION(Dangerous.listReverseInPlace(args));
end annotationListToAbsyn;

protected function recordConstructorToModification
" This function takes a record constructor expression and translates
   it into a ElementArg. Since modifications must be named, only named
   arguments are treated in the record constructor."
  input Absyn.Exp inExp;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inExp)
    local
      list<Absyn.ElementArg> eltarglst;
      Absyn.ElementArg res,emod;
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp e;
      Absyn.Path p;

    /* Covers the case annotate=Diagram(1) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {e}, argNames = {})))
      equation
        p = Absyn.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(x=1,y=2) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        p = Absyn.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD(eltarglst,Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    /* Covers the case annotate=Diagram(SOMETHING(x=1,y=2)) */
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {(e as Absyn.CALL())},argNames = nargs)))
      equation
        eltarglst = List.map(nargs, namedargToModification);
        emod = recordConstructorToModification(e);
        p = Absyn.crefToPath(cr);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),p,SOME(Absyn.CLASSMOD((emod :: eltarglst),Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    else
      equation
        Print.printBuf("Interactive.recordConstructorToModification failed, exp=");
        Dump.printExp(inExp);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end recordConstructorToModification;

protected function namedargToModification
"This function takes a NamedArg and translates it into a ElementArg."
  input Absyn.NamedArg inNamedArg;
  output Absyn.ElementArg outElementArg;
algorithm
  outElementArg:=
  matchcontinue (inNamedArg)
    local
      list<Absyn.ElementArg> elts;
      Absyn.ComponentRef cr;
      Absyn.ElementArg res;
      String id;
      Absyn.Exp c,e;
      list<Absyn.NamedArg> nargs;
    case (Absyn.NAMEDARG(argName = id,argValue = (c as Absyn.CALL(functionArgs = Absyn.FUNCTIONARGS(args = {})))))
      equation
        Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(elts,_)), comment = NONE()) = recordConstructorToModification(c);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(id),SOME(Absyn.CLASSMOD(elts,Absyn.NOMOD())),NONE(),Absyn.dummyInfo);
      then
        res;
    case (Absyn.NAMEDARG(argName = id,argValue = e))
      equation
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(id),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(e,Absyn.dummyInfo /*Bad*/))),NONE(),Absyn.dummyInfo);
      then
        res;
    else
      equation
        Print.printBuf("- Interactive.namedargToModification failed\n");
      then
        fail();
  end matchcontinue;
end namedargToModification;

public function getContainedClassAndFile
" author: PA
   Returns the package or class in which the model is saved and the file
   name it is saved in. This is used to save a model in a package when the
   whole package is saved in a file.
   inputs:   (Absyn.Path, Absyn.Program)
   outputs:  (Absyn.Program, string /* filename */)"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm
  (outProgram,outString):=
  match (inPath,inProgram)
    local
      Absyn.Class cdef;
      String filename;
      Absyn.Program p_1,p_2,p;
      Absyn.Path classname;
    case (classname,p)
      equation
        cdef = getPathedClassInProgram(classname, p);
        filename = Absyn.classFilename(cdef);
        p_1 = getSurroundingPackage(classname, p);
        p_2 = removeInnerDiffFiledClasses(p_1);
      then
        (p_2,filename);
  end match;
end getContainedClassAndFile;

protected function removeInnerDiffFiledClasses
" author: PA
   Removes all inner classes that have different file name than the class
   itself. The filename of the class is passed as argument.
   inputs: (Absyn.Program /* package as program. */)
   outputs: Absyn.Program"
  input Absyn.Program inProgram;
  output Absyn.Program p = inProgram;
algorithm
  p := match p
    case Absyn.PROGRAM()
      equation
        p.classes = List.map(p.classes, removeInnerDiffFiledClass);
      then p;
  end match;
end removeInnerDiffFiledClasses;

protected function removeInnerDiffFiledClass
" author: PA
   Helper function to removeInnerDiffFiledClasses, removes all local
   classes in class that does not have the same filename as the class
   iteself."
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm
  outClass:=
  match (inClass)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String a,file,baseClassName;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      SourceInfo file_info;
      list<Absyn.ElementArg> modifications;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = (file_info as SOURCEINFO(fileName = file))))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt),file_info);

    /* adrpo: handle also the case model extends X end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(baseClassName=baseClassName,
                                                 modifications = modifications,
                                                 parts = parts,
                                                 ann = ann,
                                                 comment = cmt),
                      info = (file_info as SOURCEINFO(fileName = file))))
      equation
        publst = getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann),file_info);
    // Short class definitions, etc
    else inClass;
  end match;
end removeInnerDiffFiledClass;

protected function classIsInFile
"returns true for the class that has the given filename
 returns true for anything else which does not have a filename"
  input String inFilename;
  input Absyn.ElementItem inElement;
  output Boolean outInFile;
algorithm
  outInFile := match(inElement)
    local
      String filename;

    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
        Absyn.CLASSDEF(class_ = Absyn.CLASS(info = SOURCEINFO(fileName = filename)))))
      then stringEq(inFilename, filename);

    else true;

  end match;
end classIsInFile;

protected function removeClassDiffFiledInElementitemlist
"author: PA
  This function takes an Element list and a filename
  and returns a modified element list where the elements
  not stored in filename are removed.
  inputs: (Absyn.ElementItem list, string /* filename */)
  outputs: Absyn.ElementItem list"
  input list<Absyn.ElementItem> inElements;
  input String inFilename;
  output list<Absyn.ElementItem> outElements;
algorithm
  outElements := List.filterOnTrue(inElements,
    function classIsInFile(inFilename = inFilename));
end removeClassDiffFiledInElementitemlist;

protected function getSurroundingPackage
" author: PA
   This function investigates the surrounding packages and returns
   the outermost package that has the same filename as the class"
  input Absyn.Path classpath;
  input Absyn.Program inProgram;
  output Absyn.Program p = inProgram;
algorithm
  p := matchcontinue p
    local
      Absyn.Class cdef,pdef;
      String filename1,filename2;
      Absyn.Path ppath;
      Absyn.Program res;
      Absyn.Within within_;

    case _
      equation
        cdef = getPathedClassInProgram(classpath, p);
        filename1 = Absyn.classFilename(cdef);
        ppath = Absyn.stripLast(classpath);
        pdef = getPathedClassInProgram(ppath, p);
        filename2 = Absyn.classFilename(pdef);
        true = stringEq(filename1, filename2);
        res = getSurroundingPackage(ppath, p);
      then
        res;

    /* No package with same filename */
    case Absyn.PROGRAM()
      equation
        p.classes = {getPathedClassInProgram(classpath, p)};
        p.within_ = buildWithin(classpath);
      then p;
  end matchcontinue;
end getSurroundingPackage;

public function transformFlatProgram
"Transforms component references in a Absyn.PROGRAM
  to same format as the variables of the flat program.
  i.e. a.b[3].c[2] becomes CREF_IDENT(\"a.b[3].c\",[INDEX(ICONST(2))])"
input Absyn.Program p;
output Absyn.Program newP;
algorithm
  newP := match(p)
    case _ equation
      ((newP,_,_)) = AbsynUtil.traverseClasses(p,NONE(), transformFlatClass, 0, true) "traverse protected" ;
      then newP;
  end match;
end transformFlatProgram;

protected function transformFlatClass
"This is the visitor function for traversing a class in transformFlatProgram."
  input tuple<Absyn.Class, Option<Absyn.Path>,Integer > inTuple;
  output tuple<Absyn.Class, Option<Absyn.Path>, Integer> outTuple;
algorithm
  outTuple:= matchcontinue (inTuple)
    local
      Absyn.Ident id;
      Option<Absyn.Path> pa;
      Boolean a,b,c;
      Absyn.Restriction d;
      SourceInfo file_info;
      Absyn.ClassDef cdef,cdef1;
      Integer i;

    case((Absyn.CLASS(id, a,b,c,d,cdef,file_info),pa,i))
      equation
        cdef1 = transformFlatClassDef(cdef);
      then ((Absyn.CLASS(id,a,b,c,d,cdef1,file_info),pa,i));

    else
      equation
        print("Interactive.transformFlatClass failed\n");
      then fail();
  end matchcontinue;
end transformFlatClass;

protected function transformFlatClassDef
"Help function to transformFlatClass."
  input Absyn.ClassDef cdef;
  output Absyn.ClassDef outCdef;
algorithm
  outCdef := matchcontinue(cdef)
    local
      list<Absyn.ClassPart> parts,partsTransformed;
      String baseClassName;
      list<Absyn.ElementArg> modifications;
      Option<String> cmt;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    case(Absyn.DERIVED()) then cdef;
    case(Absyn.ENUMERATION()) then cdef;
    case(Absyn.OVERLOAD()) then cdef;
    case(Absyn.PDER()) then cdef;
    case(Absyn.PARTS(typeVars,classAttrs,parts,ann,cmt))
      equation
        partsTransformed = List.map(parts,transformFlatPart);
      then
        Absyn.PARTS(typeVars,classAttrs,partsTransformed,ann,cmt);
    /*
     * adrpo: TODO! are we sure we shouldn't handle also the parts in model extends X parts end X; ??!!
                    how about the modifications also??
     *        before it was: case (cdef as Absyn.CLASS_EXTENDS(baseClassName = _) then cdef;
     */
    case(Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                     modifications = modifications,
                                     comment = cmt,
                                     ann = ann,
                                     parts = parts))
      equation
        partsTransformed = List.map(parts,transformFlatPart);
      then
        Absyn.CLASS_EXTENDS(baseClassName, modifications, cmt, partsTransformed, ann);
    else equation print("Interactive.transformFlatClassDef failed\n");
      then fail();
  end matchcontinue;
end transformFlatClassDef;

public function transformFlatPart
"Help function to transformFlatClassDef."
  input Absyn.ClassPart part;
  output Absyn.ClassPart outPart;
algorithm
  outPart := matchcontinue(part)
    local
      list<Absyn.ElementItem> eitems, eitems1;
      list<Absyn.EquationItem> eqnitems, eqnitems1;
      list<Absyn.AlgorithmItem> algitems,algitems1;
    case(Absyn.PUBLIC(eitems))
      equation
        eitems1 = List.map(eitems,transformFlatElementItem);
      then Absyn.PUBLIC(eitems1);
    case(Absyn.PROTECTED(eitems))
      equation
        eitems1 = List.map(eitems,transformFlatElementItem);
      then Absyn.PROTECTED(eitems1);
    case(Absyn.EQUATIONS(eqnitems))
      equation
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then Absyn.EQUATIONS(eqnitems1);
    case(Absyn.INITIALEQUATIONS(eqnitems))
      equation
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then Absyn.INITIALEQUATIONS(eqnitems1);
    case(Absyn.ALGORITHMS(algitems))
      equation
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then Absyn.ALGORITHMS(algitems1);
    case(Absyn.INITIALALGORITHMS(algitems))
      equation
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then Absyn.INITIALALGORITHMS(algitems1);
    case(Absyn.EXTERNAL(_,_)) then part;
    else
      equation print("Interactive.transformFlatPart failed\n");
      then fail();
  end matchcontinue;
end transformFlatPart;

protected function transformFlatElementItem
"Help function to transformFlatParts"
  input Absyn.ElementItem eitem;
  output Absyn.ElementItem outEitem;
algorithm
  outEitem := match(eitem)
  local Absyn.Element elt,elt1;
    case(Absyn.ELEMENTITEM(elt)) equation elt1 = transformFlatElement(elt); then (Absyn.ELEMENTITEM(elt1));
  end match;
end transformFlatElementItem;

protected function transformFlatElement
"Help function to transformFlatElementItem"
  input Absyn.Element elt;
  output Absyn.Element outElt;
algorithm
  outElt := match(elt)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      Absyn.ElementSpec spec,spec1;
      SourceInfo info ;
      Option<Absyn.ConstrainClass> constr;
    case (Absyn.TEXT()) then elt;
    case(Absyn.ELEMENT(f,r,io,spec,info,constr))
      equation
        spec1=transformFlatElementSpec(spec);
        //TODO: constr clause might need transformation too.
      then
        Absyn.ELEMENT(f,r,io,spec1,info,constr);
  end match;
end transformFlatElement;

protected function transformFlatElementSpec
"Helper to transformFlatElement"
  input Absyn.ElementSpec eltSpec;
  output Absyn.ElementSpec outEltSpec;
algorithm
  outEltSpec := match(eltSpec)
    local
      Boolean r;
      Absyn.Class cl,cl1;
      Absyn.Path path;
      Absyn.TypeSpec tp;
      list<Absyn.ElementArg> eargs,eargs1;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> comps,comps1;
      Option<Absyn.Annotation> annOpt;

    case(Absyn.CLASSDEF(r,cl))
      equation
        ((cl1,_,_)) = transformFlatClass((cl,NONE(),0));
      then Absyn.CLASSDEF(r,cl1);

    case(Absyn.EXTENDS(path,eargs,annOpt))
      equation
        eargs1 = List.map(eargs,transformFlatElementArg);
      then Absyn.EXTENDS(path,eargs1,annOpt);

    case(Absyn.IMPORT()) then eltSpec;

    case(Absyn.COMPONENTS(attr,tp,comps))
      equation
        comps1 = List.map(comps,transformFlatComponentItem);
      then Absyn.COMPONENTS(attr,tp,comps1);

  end match;
end transformFlatElementSpec;

protected function transformFlatComponentItem
"Help function to transformFlatElementSpec"
  input Absyn.ComponentItem compitem;
  output Absyn.ComponentItem outCompitem;
algorithm
  outCompitem := match(compitem)
    local
      Option<Absyn.ComponentCondition> cond;
      Option<Absyn.Comment> cmt;
      Absyn.Component comp,compTransformed;
    case(Absyn.COMPONENTITEM(comp,cond,cmt))
      equation
        compTransformed = transformFlatComponent(comp);
      then
        Absyn.COMPONENTITEM(compTransformed,cond,cmt);
  end match;
end transformFlatComponentItem;

protected function transformFlatComponent
"Help function to transformFlatComponentItem"
  input Absyn.Component comp;
  output Absyn.Component outComp;
algorithm
  outComp := match(comp)
    local
      Absyn.ArrayDim arraydim,arraydimTransformed;
      Option<Absyn.Modification> mod,modTransformed;
      Absyn.Ident id;
    case(Absyn.COMPONENT(id,arraydim,mod))
      equation
        modTransformed = transformFlatModificationOption(mod);
        arraydimTransformed = transformFlatArrayDim(arraydim);
    then
      Absyn.COMPONENT(id,arraydimTransformed,modTransformed);
  end match;
end transformFlatComponent;

protected function transformFlatArrayDim
"Help function to transformFlatComponent"
  input Absyn.ArrayDim ad;
  output  Absyn.ArrayDim outAd;
algorithm
  outAd := match(ad)
    local Absyn.ArrayDim adTransformed;
    case _
      equation
        adTransformed = List.map(ad,transformFlatSubscript);
      then adTransformed;
  end match;
end transformFlatArrayDim;

protected function transformFlatSubscript
"Help function to TransformFlatArrayDim"
  input Absyn.Subscript s;
  output Absyn.Subscript outS;
algorithm
  outS := match(s)
    local Absyn.Exp e,e1;
    case(Absyn.NOSUB()) then Absyn.NOSUB();
    case(Absyn.SUBSCRIPT(e))
      equation
        (e1,_) = Absyn.traverseExp(e,transformFlatExp,0);
      then
        Absyn.SUBSCRIPT(e1);
  end match;
end transformFlatSubscript;

protected function transformFlatElementArg
"Helper function to e.g. transformFlatElementSpec"
  input Absyn.ElementArg eltArg;
  output Absyn.ElementArg outEltArg;
algorithm
  outEltArg := match(eltArg)
    local
      Boolean f;
      Absyn.Each e;
      Option<Absyn.Modification> mod,mod1;
      Option<String> cmt;
      SourceInfo info;
      Absyn.Path p;

    case(Absyn.MODIFICATION(f,e,p,mod,cmt,info))
      equation
        mod1 = transformFlatModificationOption(mod);
      then
        Absyn.MODIFICATION(f,e,p,mod1,cmt,info);
    // redeclarations not in flat Modelica
    case(Absyn.REDECLARATION())
      then eltArg;
  end match;
end transformFlatElementArg;

protected function transformFlatModificationOption
"Help function to transformFlatElementArg"
  input Option<Absyn.Modification> mod;
  output Option<Absyn.Modification> outMod;
algorithm
  outMod := match(mod)
    local
      SourceInfo info;
      Absyn.Exp e,e1;
      list<Absyn.ElementArg> eltArgs,eltArgs1;
    case (SOME(Absyn.CLASSMOD(eltArgs,Absyn.EQMOD(e,info))))
      equation
        eltArgs1=List.map(eltArgs,transformFlatElementArg);
        (e1,_) = Absyn.traverseExp(e,transformFlatExp,0);
      then SOME(Absyn.CLASSMOD(eltArgs1,Absyn.EQMOD(e1,info)));
    case (SOME(Absyn.CLASSMOD(eltArgs,Absyn.NOMOD())))
      equation
        eltArgs1=List.map(eltArgs,transformFlatElementArg);
      then SOME(Absyn.CLASSMOD(eltArgs1,Absyn.NOMOD()));
    case(NONE()) then NONE();
  end match;
end transformFlatModificationOption;

protected function transformFlatComponentRef
"Help function to e.g. transformFlatElementArg and transformFlatExp"
  input Absyn.ComponentRef cr;
  output Absyn.ComponentRef outCr;
algorithm
  outCr := match(cr)
  local Absyn.ComponentRef cr1;
    list<Absyn.Subscript> ss;
    String s;
    case _ equation
      ss = Absyn.crefLastSubs(cr);
      cr1 = Absyn.crefStripLastSubs(cr);
      s = Dump.printComponentRefStr(cr1);
    then Absyn.CREF_IDENT(s,ss);
  end match;
end transformFlatComponentRef;

protected function transformFlatEquationItem
"Help function to transformFlatParts"
  input Absyn.EquationItem eqnitem;
  output Absyn.EquationItem outEqnitem;
algorithm
  outEqnitem := match(eqnitem)
    local
      Option<Absyn.Comment> cmt;
      Absyn.Equation eqn,eqn1;
      SourceInfo info;
    case(Absyn.EQUATIONITEM(eqn,cmt,info))
      equation
        eqn1 = transformFlatEquation(eqn);
      then Absyn.EQUATIONITEM(eqn1,cmt,info);
  end match;
end transformFlatEquationItem;

protected function transformFlatEquation
"Help function to transformFlatEquationItem"
  input Absyn.Equation eqn;
  output Absyn.Equation outEqn;
algorithm
  outEqn := match(eqn)
    local
      Absyn.Exp e1,e2,e11,e21;
      Absyn.Ident id;
      Absyn.ComponentRef name;
      list<Absyn.EquationItem> thenpart,thenpart1,elsepart,elsepart1,forEqns,forEqns1,whenEqns,whenEqns1;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifpart,elseifpart1,elseWhenEqns,elseWhenEqns1;
      Absyn.ComponentRef cr1,cr2,cr11,cr21;
      Absyn.FunctionArgs fargs,fargs1;

    case(Absyn.EQ_IF(e1,thenpart,elseifpart,elsepart))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        thenpart1 = List.map(thenpart,transformFlatEquationItem);
        elsepart1 = List.map(elsepart,transformFlatEquationItem);
        elseifpart1 = List.map(elseifpart,transformFlatElseIfPart);
      then
        Absyn.EQ_IF(e11,thenpart1,elseifpart1,elsepart1);

    case(Absyn.EQ_EQUALS(e1,e2))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        (e21,_) = Absyn.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.EQ_EQUALS(e11,e21);

    case(Absyn.EQ_PDE(e1,e2,cr1))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        (e21,_) = Absyn.traverseExp(e2,transformFlatExp,0);
        cr11 = transformFlatComponentRef(cr1);
      then
        Absyn.EQ_PDE(e11,e21,cr11);

    case(Absyn.EQ_CONNECT(cr1,cr2))
      equation
        cr11 = transformFlatComponentRef(cr1);
        cr21 = transformFlatComponentRef(cr2);
      then
        Absyn.EQ_CONNECT(cr11,cr21);

    case(Absyn.EQ_FOR({Absyn.ITERATOR(id,NONE(),SOME(e1))},forEqns))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        forEqns1 = List.map(forEqns,transformFlatEquationItem);
      then
        Absyn.EQ_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},forEqns1);

    case(Absyn.EQ_WHEN_E(e1,whenEqns,elseWhenEqns))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        elseWhenEqns1 = List.map(elseWhenEqns,transformFlatElseIfPart);
        whenEqns1 = List.map(whenEqns,transformFlatEquationItem);
      then
        Absyn.EQ_WHEN_E(e11,whenEqns1,elseWhenEqns1);

    case(Absyn.EQ_NORETCALL(name,fargs))
      equation
        fargs1 = transformFlatFunctionArgs(fargs);
      then
        Absyn.EQ_NORETCALL(name,fargs1);
  end match;
end transformFlatEquation;

protected function transformFlatElseIfPart
"Help function to transformFlatEquation"
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> elseIfPart;
  output tuple<Absyn.Exp, list<Absyn.EquationItem>> outElseIfPart;
algorithm
  outElseIfPart := match(elseIfPart)
    local
      Absyn.Exp e1,e11;
      list<Absyn.EquationItem> eqnitems,eqnitems1;
    case((e1,eqnitems))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        eqnitems1 = List.map(eqnitems,transformFlatEquationItem);
      then
        ((e11,eqnitems1));
  end match;
end transformFlatElseIfPart;

protected function transformFlatFunctionArgs
"Help function to e.g. transformFlatEquation"
  input Absyn.FunctionArgs fargs;
  output Absyn.FunctionArgs outFargs;
algorithm
  outFargs := match(fargs)
    local
      list<Absyn.Exp> expl,expl1;
      list<Absyn.NamedArg> namedArgs,namedArgs1;
    case( Absyn.FUNCTIONARGS(expl,namedArgs))
      equation
        (expl1,_) = List.mapFoldTuple(expl, transformFlatExpTrav, 0);
        namedArgs1 = List.map(namedArgs,transformFlatNamedArg);
      then
        Absyn.FUNCTIONARGS(expl1,namedArgs1);
    case(Absyn.FOR_ITER_FARG())
      then fargs;
  end match;
end transformFlatFunctionArgs;

protected function transformFlatNamedArg
"Helper functin to e.g. transformFlatFunctionArgs"
  input Absyn.NamedArg namedArg;
  output Absyn.NamedArg outNamedArg;
algorithm
  outNamedArg := match(namedArg)
    local Absyn.Exp e1,e11; Absyn.Ident id;
    case(Absyn.NAMEDARG(id,e1))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
      then Absyn.NAMEDARG(id,e11);
  end match;
end transformFlatNamedArg;

protected function transformFlatExpTrav
"Transforms a flat expression by calling traverseExp"
  input tuple<Absyn.Exp,Integer> inExp;
  output tuple<Absyn.Exp,Integer> outExp;
algorithm
  outExp := match(inExp)
    local
      Absyn.Exp e,e1;
      Integer i;
    case( (e,i))
      equation
        (e1,i) = Absyn.traverseExp(e,transformFlatExp,0);
      then ((e1,i));
  end match;
end transformFlatExpTrav;

protected function transformFlatExp
  input Absyn.Exp inExp;
  input Integer inDummy;
  output Absyn.Exp outExp;
  output Integer outDummy;
algorithm
  (outExp,outDummy) := matchcontinue(inExp,inDummy)
    local
      Absyn.ComponentRef cr,cr1;
      Absyn.Exp e; Integer i;
    case (Absyn.CREF(cr),i)
      equation
        cr1 = transformFlatComponentRef(cr);
      then (Absyn.CREF(cr1),i);
    else (inExp,inDummy);
  end matchcontinue;
end transformFlatExp;

protected function transformFlatAlgorithmItem
  input Absyn.AlgorithmItem algitem;
  output Absyn.AlgorithmItem outAlgitem;
algorithm
  outAlgitem := match(algitem)
    local
      Option<Absyn.Comment> cmt;
      Absyn.Algorithm alg,alg1;
      SourceInfo info;
    case(Absyn.ALGORITHMITEM(alg,cmt,info))
      equation
        alg1 = transformFlatAlgorithm(alg);
      then Absyn.ALGORITHMITEM(alg1,cmt,info);
  end match;
end transformFlatAlgorithmItem;

protected function transformFlatAlgorithm
"Help function to transformFlatAlgorithmItem"
  input Absyn.Algorithm alg;
  output Absyn.Algorithm outAlg;
algorithm
  outAlg := match(alg)
    local Absyn.Exp e1,e11,e2,e21;
      Absyn.ComponentRef cr,cr1;
      list<Absyn.AlgorithmItem> body,body1,thenPart,thenPart1,elsePart,elsePart1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfPart,elseIfPart1,whenBranch,whenBranch1;
      Absyn.Ident id;
      Absyn.FunctionArgs fargs,fargs1;
    case (Absyn.ALG_ASSIGN(Absyn.CREF(cr),e1))
      equation
        (_,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        cr1 = transformFlatComponentRef(cr);
      then
        Absyn.ALG_ASSIGN(Absyn.CREF(cr1),e1);
    case (Absyn.ALG_ASSIGN(e1 as Absyn.TUPLE(_),e2))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        (e21,_) = Absyn.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.ALG_ASSIGN(e11,e21);
    case (Absyn.ALG_IF(e1,thenPart,elseIfPart,elsePart))
      equation
        thenPart1 = List.map(thenPart,transformFlatAlgorithmItem);
        elseIfPart1 =  List.map(elseIfPart,transformFlatElseIfAlgorithm);
        elsePart1 = List.map(elsePart,transformFlatAlgorithmItem);
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
    then
      Absyn.ALG_IF(e11,thenPart1,elseIfPart1,elsePart1);
    case (Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e1))},body))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
      then
        Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},body1);
    case(Absyn.ALG_WHILE(e1,body))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
      then
        Absyn.ALG_WHILE(e11,body1);
    case (Absyn.ALG_WHEN_A(e1,body,whenBranch))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
        whenBranch1 =  List.map(whenBranch,transformFlatElseIfAlgorithm);
      then
        Absyn.ALG_WHEN_A(e11,body1,whenBranch1);
    case (Absyn.ALG_NORETCALL(cr,fargs))
      equation
        cr1 = transformFlatComponentRef(cr);
        fargs1 = transformFlatFunctionArgs(fargs);
      then
        Absyn.ALG_NORETCALL(cr1,fargs1);
    case (Absyn.ALG_BREAK()) then Absyn.ALG_BREAK();
    case (Absyn.ALG_RETURN()) then Absyn.ALG_RETURN();

  end match;
end transformFlatAlgorithm;

protected function transformFlatElseIfAlgorithm
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> elseIfbranch;
  output tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> outElseIfbranch;
algorithm
  outElseIfbranch := match(elseIfbranch)
    local
      Absyn.Exp e1,e11;
      list<Absyn.AlgorithmItem> algitems,algitems1;
    case((e1,algitems))
      equation
        (e11,_) = Absyn.traverseExp(e1,transformFlatExp,0);
        algitems1 = List.map(algitems,transformFlatAlgorithmItem);
      then ((e11,algitems1));
  end match;
end transformFlatElseIfAlgorithm;

/* Start getDefinitions */

protected function getDefinitions
"This function dumps the defined packages, classes and functions to a string.
 The function is used by org.openmodelica.corba.parser.DefinitionsCreator."
  input  Absyn.Program ast "The AST to dump";
  input  Boolean addFunctions;
  output String res "An easily parsed string containing all definitions";
algorithm
  res := match (ast,addFunctions)
    local
      list<Absyn.Class> classes;
      list<String> toPrint;
      Integer handle;
      Absyn.Class cl;

    case (_,_)
      equation
        Absyn.PROGRAM(classes = classes) = MetaUtil.createMetaClassesInProgram(ast);
        handle = Print.saveAndClearBuf();
        Print.printBuf("\"(\n");
        toPrint = getDefinitions2(classes,addFunctions);
        List.map_0(toPrint, printWithNewline);
        cl = getPathedClassInProgram(Absyn.IDENT("SourceInfo"), ast);
        toPrint = getDefinitions2({cl},false);
        List.map_0(toPrint, printWithNewline);
        Print.printBuf("\n)\"");
        res = Print.getString();
        Print.restoreBuf(handle);
      then res;

  end match;
end getDefinitions;

protected function getLocalVariables
"Returns the string list of local varibales defined with in the algorithm."
  input Absyn.Class inClass;
  input Boolean inBoolean;
  input FCore.Graph inEnv;
  output String outList;
algorithm
  outList := match(inClass, inBoolean, inEnv)
    local
      String strList;
      FCore.Graph env;
      Boolean b;
      list<Absyn.ClassPart> parts;
      case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
    // check also the case model extends X end X;
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)), b, env)
      equation
        strList = getLocalVariablesInClassParts(parts, b, env);
      then
        strList;
  end match;
end getLocalVariables;

protected function getLocalVariablesInClassParts
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  input FCore.Graph inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynClassPartLst, inBoolean, inEnv)
    local
      FCore.Graph env;
      Boolean b;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.ClassPart> xs;
      String strList, strList1, strList2;
    case (Absyn.ALGORITHMS(contents = algs) :: xs, b, env)
      equation
        strList1 = getLocalVariablesInAlgorithmsItems(algs, b, env);
        strList = getLocalVariablesInClassParts(xs, b, env);
        strList2 = if strList == "" then strList1 else stringAppendList({strList1, ",", strList});
      then
        strList2;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInClassParts(xs, b, env);
      then
        strList;
    case ({}, _, _) then "";
  end matchcontinue;
end getLocalVariablesInClassParts;

protected function getLocalVariablesInAlgorithmsItems
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input Boolean inBoolean;
  input FCore.Graph inEnv;
  output String outList;
algorithm
  outList := matchcontinue (inAbsynAlgorithmItemLst, inBoolean, inEnv)
    local
      FCore.Graph env;
      Boolean b;
      String strList;
      list<Absyn.AlgorithmItem> xs;
      Absyn.Algorithm alg;
    case (Absyn.ALGORITHMITEM(algorithm_ = alg) :: _, b, env)
      equation
        strList = getLocalVariablesInAlgorithmItem(alg, b, env);
      then
        strList;
    case ((_ :: xs), b, env)
      equation
        strList = getLocalVariablesInAlgorithmsItems(xs, b, env);
      then
        strList;
    case ({}, _, _) then "";
  end matchcontinue;
end getLocalVariablesInAlgorithmsItems;

protected function getLocalVariablesInAlgorithmItem
  input Absyn.Algorithm inAbsynAlgorithmItem;
  input Boolean inBoolean;
  input FCore.Graph inEnv;
  output String outList;
algorithm
  outList := match (inAbsynAlgorithmItem, inBoolean, inEnv)
    local
      FCore.Graph env;
      Boolean b;
      String strList;
      list<Absyn.ElementItem> elsItems;
      list<Absyn.Element> els;
    case (Absyn.ALG_ASSIGN(value = Absyn.MATCHEXP(localDecls = elsItems)), b, env)
      equation
        els = getComponentsInElementitems(elsItems);
        strList = getComponentsInfo(els, b, "public", env);
      then
        strList;
    case (_, _, _) then "";
  end match;
end getLocalVariablesInAlgorithmItem;

protected function printWithNewline
  input String s;
algorithm
  Print.printBuf(s);
  Print.printBuf("\n");
end printWithNewline;

protected function getDefinitions2
  input  list<Absyn.Class> classes;
  input  Boolean addFunctions;
  output list<String> res;
algorithm
  res := match (classes,addFunctions)
    local
      list<Absyn.Class> rest;
      Absyn.Class class_;
      String str;
    case ({},_) then {};
    case (class_::rest,_) equation
      str = getDefinitionsClass(class_, addFunctions);
      res = getDefinitions2(rest, addFunctions);
    then str::res;
  end match;
end getDefinitions2;

protected function getDefinitionsClass
  input Absyn.Class class_;
  input Boolean addFunctions;
  output String res;
algorithm
  res := matchcontinue (class_,addFunctions)
    local
      list<Absyn.ClassPart> parts;
      String ident,  tyStr;
      list<String> strs;
      Absyn.TypeSpec ts;
      Absyn.ElementAttributes attr;
      Integer numDim;
      Integer index;
      Absyn.Path path;
      String indexArg, pathArg;
      Absyn.ClassDef body;

    case (Absyn.CLASS(name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_PACKAGE()),_)
      equation
        ident = "(package " + ident;
        strs = getDefinitionParts(body.classParts, body.typeVars, addFunctions);
        strs = ident :: strs;
      then stringDelimitList(strs, "\n");
    case (Absyn.CLASS(partialPrefix = true, name = ident, body = Absyn.PARTS(), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE()))),_)
      equation
        strs = {"(partial impure function", ident, ")"};
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = true, name = ident, body = Absyn.PARTS(), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(_))),_)
      equation
        strs = {"(partial function", ident, ")"};
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = false, name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE()))),true)
      equation
        strs = getDefinitionParts(body.classParts, body.typeVars, true);
        strs = "(impure function" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = false, name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION())),true)
      equation
        strs = getDefinitionParts(body.classParts, body.typeVars, true);
        strs = "(function" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(partialPrefix = false, name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION())),true)
      equation
        strs = getDefinitionParts(body.classParts, body.typeVars, true);
        strs = "(operator function" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.PARTS(), restriction = Absyn.R_UNIONTYPE()),_)
      equation
        strs = {"(uniontype", ident, ")"};
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_RECORD()),_)
      equation
        strs = getDefinitionParts(body.classParts, body.typeVars, false);
        strs = "(record" :: ident :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = body as Absyn.PARTS(), restriction = Absyn.R_METARECORD(name = path, index = index)),_)
      equation
        indexArg = intString(index);
        pathArg = Absyn.pathLastIdent(path);
        strs = getDefinitionParts(body.classParts, body.typeVars, false);
        strs = "(metarecord" :: ident :: indexArg :: pathArg :: strs;
      then stringDelimitList(strs, " ");
    case (Absyn.CLASS(name = ident, body = Absyn.DERIVED(typeSpec = ts, attributes = attr)),_)
      equation
        numDim = getDefinitionDimensions(ts,attr);
        tyStr = (if numDim == 0 then "" else "[" + intString(numDim)) + getDefinitionTypeSpecPathString(ts);
        strs = {"(type", ident, tyStr, ")"};
      then stringDelimitList(strs, " ");
    // Do enumerations really work properly in OMC?
    //case Absyn.CLASS(name = ident, body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(el))) equation
    //  enumList = List.map(el, getEnumerationLiterals);
    //then "enumeration " + ident + "(" + stringDelimitList(enumList, ",") + ")";
    else "";
  end matchcontinue;
end getDefinitionsClass;

protected function getDefinitionsReplaceableClass
  input Absyn.Class class_;
  output String res;
algorithm
  res := match (class_)
  local
    String ident;
    case Absyn.CLASS(name = ident, body = Absyn.DERIVED(typeSpec = Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE())), restriction = Absyn.R_TYPE())
    then "(replaceable type " + ident + ")";
  end match;
end getDefinitionsReplaceableClass;

protected function getEnumerationLiterals
  input Absyn.EnumLiteral el;
  output String out;
algorithm
  out := match el
    case Absyn.ENUMLITERAL(literal = out)
      equation
        out = stringAppendList({"\"",out,"\""});
      then
        out;
  end match;
end getEnumerationLiterals;

protected function getDefinitionPathString
  input Absyn.Path path;
  output String out;
algorithm
  out := match (path)
    // Doesn't work because we only know the AST after parsing... case (Absyn.FULLYQUALIFIED(path)) then "#" + Absyn.pathString(path);
    // Thus, scope/lookup is done by the application recieving this information
    case _ then Absyn.pathString(path);
  end match;
end getDefinitionPathString;

public function getDefinitionTypeSpecPathString
  input Absyn.TypeSpec tp;
  output String s;
algorithm s := matchcontinue(tp)
  local
    Absyn.Path p;
    list<Absyn.TypeSpec> tspecs;
    list<String> tspecsStr;
  case(Absyn.TCOMPLEX(path = p, typeSpecs = {})) equation
  then getDefinitionPathString(p);
  case(Absyn.TCOMPLEX(path = p, typeSpecs = tspecs)) equation
    tspecsStr = List.map(tspecs, getDefinitionTypeSpecPathString);
  then getDefinitionPathString(p) + "<" + stringDelimitList(tspecsStr,",") + ">";
  case(Absyn.TPATH(path = p)) then getDefinitionPathString(p);
end matchcontinue;
end getDefinitionTypeSpecPathString;

protected function getDefinitionDimensions
  input Absyn.TypeSpec ts;
  input Absyn.ElementAttributes attr;
  output Integer out;
algorithm
  out := match(ts,attr)
  local
    list<Absyn.Subscript> l1,l2;
    case (Absyn.TPATH(arrayDim = SOME(l1)), Absyn.ATTR(arrayDim = l2)) then listLength(l1)+listLength(l2);
    case (Absyn.TCOMPLEX(arrayDim = SOME(l1)), Absyn.ATTR(arrayDim = l2)) then listLength(l1)+listLength(l2);
    case (Absyn.TPATH(arrayDim = NONE()), Absyn.ATTR(arrayDim = l2)) then listLength(l2);
    case (Absyn.TCOMPLEX(arrayDim = NONE()), Absyn.ATTR(arrayDim = l2)) then listLength(l2);
    else 0;
  end match;
end getDefinitionDimensions;

protected function getDefinitionParts
  input  list<Absyn.ClassPart> parts;
  input list<String> inTypeVars;
  input  Boolean isFunction;
  output list<String> res;
algorithm
  res := matchcontinue (parts, isFunction)
  local
    list<Absyn.ClassPart> rest;
    list<Absyn.ElementItem> contents;
    case ({},_) then getDefinitionTypeVars(inTypeVars, {")"});
    case (Absyn.PUBLIC(contents)::rest,_)
    then listAppend(getDefinitionContent(contents,isFunction,true), getDefinitionParts(rest,inTypeVars,isFunction));
    case (Absyn.PROTECTED(contents)::rest,_)
    then listAppend(getDefinitionContent(contents,isFunction,false), getDefinitionParts(rest,inTypeVars, isFunction));
    case (_::rest,_) then getDefinitionParts(rest,inTypeVars,isFunction);
  end matchcontinue;
end getDefinitionParts;

protected function getDefinitionContent
  input list<Absyn.ElementItem> contents;
  input Boolean addFunctions;
  input Boolean isPublic;
  output list<String> res;
algorithm
  res := matchcontinue (contents,addFunctions,isPublic)
  local
    list<Absyn.ElementItem> rest;
    String ident, typeStr, dirStr,  str;
    Absyn.Class class_;
    Absyn.Path path;
    list<Absyn.ComponentItem> components;
    Absyn.Direction direction;
    Absyn.TypeSpec ts;
    Absyn.Variability variability;
    Absyn.ElementAttributes attr;
    list<String> res2;

    case ({},_,_) then {};
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(replaceable_ = false, class_ = class_)))::rest,_,_)
      equation
        res = getDefinitionContent(rest,addFunctions,isPublic);
        str = getDefinitionsClass(class_,addFunctions);
      then str::res;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(replaceable_ = true, class_ = class_)))::rest,_,_)
      equation
        res = getDefinitionContent(rest,addFunctions,isPublic);
        ident = getDefinitionsReplaceableClass(class_);
      then ident :: res;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = ts,components = components, attributes = (attr as Absyn.ATTR(direction = direction, variability = variability)))))::rest,_,true)
      equation
        typeStr = getDefinitionTypeSpecPathString(ts);
        dirStr = getDefinitionDirString(direction, variability, addFunctions);
        res = getDefinitionComponents(typeStr, dirStr, getDefinitionDimensions(ts,attr), components);
        res2 = getDefinitionContent(rest,addFunctions,isPublic);
      then listAppend(res,res2);
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path)))::rest,false,true)
      equation
        typeStr = "(extends " + getDefinitionPathString(path) + ")";
        res = getDefinitionContent(rest,addFunctions,isPublic);
      then typeStr :: res;
    case (_::rest,_,_)
      then getDefinitionContent(rest,addFunctions,isPublic);
  end matchcontinue;
end getDefinitionContent;

protected function getDefinitionDirString
  input Absyn.Direction dir;
  input Absyn.Variability variability;
  input Boolean isFunction;
  output String res;
algorithm
  res := match (dir, variability, isFunction)
    case (Absyn.INPUT(),_,true) then "input ";
    case (Absyn.OUTPUT(),_,true) then "output ";
    case (_, _,false)
      equation
        failure(Absyn.CONST() = variability);
      then "";
  end match;
end getDefinitionDirString;

protected function getDefinitionComponents
  input String typeStr;
  input String dirStr;
  input Integer numDim;
  input list<Absyn.ComponentItem> components;
  output list<String> res;
algorithm
  res := matchcontinue (typeStr,dirStr,numDim,components)
  local
    list<Absyn.ComponentItem> rest;
    String ident;
    list<Absyn.Subscript> l;
    Integer sumDim;

    case (_,_,_,{}) then {};
    case (_,_,_,Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = ident, arrayDim = l))::rest) equation
      sumDim = numDim + listLength(l);
      ident = dirStr + (if numDim == 0 then "" else ("[" + intString(sumDim))) + typeStr + " " + ident;
      ident = "(" + ident + ")";
      res = getDefinitionComponents(typeStr,dirStr,numDim,rest);
    then ident :: res;
    case (_,_,_,_::rest) then getDefinitionComponents(typeStr,dirStr,numDim,rest);
  end matchcontinue;
end getDefinitionComponents;

protected function getDefinitionTypeVars
  input list<String> inTypeVars;
  input list<String> inDefinitions;
  output list<String> outDefinitions = inDefinitions;
algorithm
  for ty_var in listReverse(inTypeVars) loop
    outDefinitions := ("(replaceable type " + ty_var + ")") :: outDefinitions;
  end for;
end getDefinitionTypeVars;

/* End getDefinitions */

public function parseFile
"@author adrpo
 This function just parses a file and report contents ONLY if the
 file is newer than the one already loaded."
  input String fileName               "Filename to load";
  input String encoding;
  input Boolean updateProgram=false;
  output list<Absyn.Path> topClassNamesQualified "The names of the classes from file, qualified!";
protected
  Absyn.Program parsed;
  String dir,filename;
  Boolean lveStarted;
  Option<Integer> lveInstance = NONE();
algorithm
  if not System.regularFileExists(fileName) then
    topClassNamesQualified := {};
    return;
  end if;
  (dir,filename) := Util.getAbsoluteDirectoryAndFile(fileName);
  if filename == "package.moc" then
    (lveStarted, lveInstance) := Parser.startLibraryVendorExecutable(dir);
    if not lveStarted then
      topClassNamesQualified := {};
      return;
    end if;
  end if;
  parsed := Parser.parse(fileName,encoding,dir,lveInstance);
  if (lveStarted) then
    Parser.stopLibraryVendorExecutable(lveInstance);
  end if;
  parsed := MetaUtil.createMetaClassesInProgram(parsed);
  topClassNamesQualified := getTopQualifiedClassnames(parsed);
  if updateProgram then
    SymbolTable.setAbsyn(.Interactive.updateProgram(parsed, SymbolTable.getAbsyn()));
  end if;
end parseFile;

//he-mag begin
protected function getElementName
"returns the element name"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString := match (inElementSpec)
    local
      String str;
      Absyn.TypeSpec typeSpec;
      list<String> names;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;

    case (Absyn.COMPONENTS(components = lst))
      equation
        names = getComponentItemsNameAndComment(lst,false);
        str = stringDelimitList(names, ", ");
        //print("names: " + str + "\n");
      then
        str;
  end match;
end getElementName;

protected function getElementTypeName
"get the name of the type of the element"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm
  outString:=
  match (inElementSpec)
    local
      String str;
      Absyn.TypeSpec typeSpec;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
 /*   case (Absyn.EXTENDS(path = path))
      equation
        path_str = Absyn.pathString(path);
        str = stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation
        import_str = getImportString(import_);
        str = stringAppendList({"elementtype=import, ",import_str});
      then
        str;*/
    case (Absyn.COMPONENTS(typeSpec = typeSpec))
      equation
        str = Dump.unparseTypeSpec(typeSpec);
//        names = getComponentItemsNameAndComment(lst);
      then
        str;
  end match;
end getElementTypeName;

public function getElementVisString ""
  input Absyn.ElementItem inElement;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:= match (inElement,inProgram)
    local
      String desc;
      Absyn.Element el;
      list<Absyn.ComponentItem> comps;
      Absyn.ElementSpec elementSpec;
      Absyn.Program p;
    case (Absyn.ELEMENTITEM(element = el),_)
      equation
        Absyn.ELEMENT(specification = elementSpec) = el;
        //p_class = Absyn.crefToPath(id);
//        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        //cl = getPathedClassInProgram(p_class, p);
        //comps = getComponentsInClass(cl);
        Absyn.COMPONENTS() = elementSpec;
//        Absyn.CLASSDEF(class_ = cl) = elementSpec;
        //comps = getComponentsInClass(cl);
        desc = getElementName(elementSpec);
        desc = desc + ":" + getElementTypeName(elementSpec);//getElementInfo(elitem);
      then
        desc;
  end match;
end getElementVisString;

protected function getDescIfVis ""
  input String in_type;
  input Absyn.ElementItem inElement;
  input Absyn.Program inProgram;
  //output Absyn.ElementItem outElement;
  output String outString;
algorithm
  outString:=
  match (in_type, inElement, inProgram)
    local
      Absyn.ElementItem tmp;
      Absyn.Program p;
      String res;
    case ("SimpleVisual.Position", tmp, p)
      equation
        res = getElementVisString(tmp, p);
      then
        res;
    case ("SimpleVisual.PositionSize", tmp, p)
      equation
        res = getElementVisString(tmp, p);
      then
        res;
    case ("SimpleVisual.PositionRotation", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.PositionRotationSize", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.PositionRotationSizeOffset", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
/*
    case ("SimpleVisual.Cube", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
    case ("SimpleVisual.Sphere", tmp,p)
      equation
        res = getElementVisString(tmp,p);
      then
        res;
*/
  end match;
end getDescIfVis;

protected function getNameFromElementIfVisType
""
  input Absyn.ElementItem inElementItem;
  input Absyn.Program inProgram;
  output String outString;
algorithm
  outString:= matchcontinue (inElementItem, inProgram)
    local
      String str,typename_str,varname_str;
      Absyn.ElementSpec elementSpec;
      list<String> tmp;
      Absyn.Program prog;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS()))),_) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      then
       "";
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = elementSpec)),prog) /* if is not a classdef, just follow the normal stuff */
      equation
        typename_str = getElementTypeName(elementSpec);
        varname_str = getElementName(elementSpec);
        (_::_) = Util.stringSplitAtChar(varname_str, ",");
        str = getDescIfVis(typename_str, inElementItem,prog);
      then
        str;
    else "";  /* for annotations we don\'t care */
  end matchcontinue;
end getNameFromElementIfVisType;

protected function constructVisTypesList
"visualization /he-mag"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Program inProgram;
  output list<String> outList;
algorithm
  outList:=
  matchcontinue (inAbsynElementItemLst, inProgram)
    local
      String  s1;
      list<String> res_list, list2;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;//, res_list, list2;
      Absyn.Program p;
    case ({}, _)
      equation
      then
        {};
    case ((current :: {}),p) /* deal with the last element */
      equation
        s1 = getNameFromElementIfVisType(current,p);
        res_list = List.create(s1);//, res_list);
      then
        res_list;
    case ((current :: rest),p)
      equation
        s1 = getNameFromElementIfVisType(current,p);
        res_list = List.create(s1);
        list2 = constructVisTypesList(rest,p);
        res_list = List.union(list2, res_list);
      then
        res_list;
  end matchcontinue;
end constructVisTypesList;

public function getElementsOfVisType
"For visualization! /he-mag"
  //input Absyn.ComponentRef inComponentRef;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output list<String> names;
  output String res;
algorithm
  (names,res) := match (inPath,inProgram)
    local
//      Absyn.Path modelpath;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list,protected_elementitem_list;
      Absyn.Path modelPath_;
      list<String> public_list, protected_list;
      list<String>  all_list;
      Absyn.Program prog;
    case (modelPath_,prog)
      equation
//        modelpath = Absyn.crefToPath(model_);
//        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = getPathedClassInProgram(modelPath_, prog);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_list = constructVisTypesList(public_elementitem_list, prog);
        protected_list = constructVisTypesList(protected_elementitem_list, prog);
        all_list = List.union(listAppend(public_list, protected_list), {});
      then (List.map(all_list, getVisElementNameFromStr),stringDelimitList(all_list,"\n"));

  end match;
end getElementsOfVisType;

protected function getVisElementNameFromStr
  input String str;
  output String outStr;
protected
  list<String> strs;
algorithm
  (_,strs as (_::outStr::_)) := System.regex(str,"([A-Za-z0-9().]*),",3,true,false);
end getVisElementNameFromStr;

protected function getComponentBindingMapable
"Returns the value of a component in a class.
  For example, the component
   Real x=1; returns 1.
  This can be used for both parameters, constants and variables.
   inputs: (Absyn.ComponentRef /* variable name */, Absyn.ComponentRef /* class name */, Absyn.Program)
   outputs: string"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm
  outString:= matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps,comps_1;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.ComponentItem compitem;
      Absyn.Exp exp;
      Absyn.ComponentRef cr,class_;
      Absyn.Program p;
    case (cr,class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(cr);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        exp = getVariableBindingInComponentitem(compitem);
        res = Dump.printExpStr(exp);
      then
        res;
    case (cr,class_,p)
      equation
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(cr);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = List.map(comps, getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, componentitemNamed, name);
        failure(_ = getVariableBindingInComponentitem(compitem));
      then "";
    else "Error";
  end matchcontinue;
end getComponentBindingMapable;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  output list<String> outString;
algorithm
  outString:=
  match (inPath,inProgram,inClass,inShowProtected,includeConstants)
    local
      list<String> strlist;
      list<Absyn.ClassPart> parts;
      Absyn.Path inmodel,path;
      Absyn.Program p;
      Boolean b,c;

    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then
        strlist;

    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)),b,c)
      equation
        strlist = getClassnamesInParts(parts,b,c);
      then strlist;

    case (_,_,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH())),_,_)
      equation
        //(cdef,newpath) = lookupClassdef(path, inmodel, p);
        //res = getClassnamesInClassList(newpath, p, cdef);
      then
        {};//res;

    case (_,_,Absyn.CLASS(body = Absyn.OVERLOAD()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.ENUMERATION()),_,_)
      equation
      then {};

    case (_,_,Absyn.CLASS(body = Absyn.PDER()),_,_)
      equation
      then {};

  end match;
end getClassnamesInClassList;

protected function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath := match (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      equation
        res = Absyn.joinPaths(r, Absyn.IDENT(c));
      then res;
  end match;
end joinPaths;

public function getClassNamesRecursive
"Returns a string with all the classes for a given path."
  input Option<Absyn.Path> inPath;
  input Absyn.Program inProgram;
  input Boolean inShowProtected;
  input Boolean includeConstants;
  input list<Absyn.Path> inAcc;
  output Option<Absyn.Path> opath;
  output list<Absyn.Path> paths;
algorithm
  (opath,paths) := matchcontinue (inPath,inProgram,inShowProtected,includeConstants,inAcc)
    local
      Absyn.Class cdef;
      String s1;
      list<String> strlst;
      Absyn.Path pp;
      Absyn.Program p;
      list<Absyn.Class> classes;
      list<Option<Absyn.Path>> result_path_lst;
      list<Absyn.Path> acc;
      Boolean b,c;

    case (SOME(pp),p,b,c,acc)
      equation
        acc = pp::acc;
        cdef = getPathedClassInProgram(pp, p);
        strlst = getClassnamesInClassList(pp, p, cdef, b, c);
        result_path_lst = List.map(List.map1(strlst, joinPaths, pp),Util.makeOption);
        (_,acc) = List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (NONE(),p as Absyn.PROGRAM(classes=classes),b,c,acc)
      equation
        strlst = List.map(classes, Absyn.getClassName);
        result_path_lst = List.mapMap(strlst, Absyn.makeIdentPathFromString, Util.makeOption);
        (_,acc) = List.map3Fold(result_path_lst, getClassNamesRecursive, p, b, c, acc);
      then (inPath,acc);
    case (SOME(pp),_,_,_,_)
      equation
        s1 = Absyn.pathString(pp);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,"<TOP>"});
      then (inPath,{});
  end matchcontinue;
end getClassNamesRecursive;

public function getSCodeClassNamesRecursive
"Returns a string with all the classes for a given path."
  input SCode.Program inProgram;
  output list<Absyn.Path> paths;
algorithm
  paths := List.fold1(inProgram,getSCodeClassNamesRecursiveWork,NONE(),{});
end getSCodeClassNamesRecursive;

protected function getSCodeClassNamesRecursiveWork
"Returns a string with all the classes for a given path."
  input SCode.Element inElement;
  input Option<Absyn.Path> inPath;
  input list<Absyn.Path> inAcc;
  output list<Absyn.Path> paths;
algorithm
  paths := match (inElement,inPath,inAcc)
    local
      list<SCode.Element> classes;
      list<Absyn.Path> acc;
      Absyn.Path path;
      String name;
    case (SCode.CLASS(name=name),NONE(),acc)
      equation
        path = Absyn.IDENT(name);
        acc = path::acc;
        classes = SCode.getClassElements(inElement);
        acc = List.fold1(classes,getSCodeClassNamesRecursiveWork,SOME(path),acc);
      then acc;
    case (SCode.CLASS(name=name),SOME(path),acc)
      equation
        path = Absyn.suffixPath(path,name);
        acc = path::acc;
        classes = SCode.getClassElements(inElement);
        acc = List.fold1(classes,getSCodeClassNamesRecursiveWork,SOME(path),acc);
      then acc;
    else inAcc;
  end match;
end getSCodeClassNamesRecursiveWork;

public function getPathedComponentElementInProgram "Returns a component given a path and a program. See also getPathedClassInProgram"
  input Absyn.Path path;
  input Absyn.Program prg;
  output Absyn.ElementSpec comp;
algorithm
  comp := match(path,prg)
  local Absyn.Class cl;
    case(_,_) equation
      cl = getPathedClassInProgram(Absyn.stripLast(path),prg);
      comp = getComponentElementInClass(cl,Absyn.pathLastIdent(path));
    then comp;
  end match;
end getPathedComponentElementInProgram;

protected function getComponentElementInClass
  input Absyn.Class cl;
  input Absyn.Ident compName;
  output Absyn.ElementSpec comp;
algorithm
 comp := match(cl,compName)
   local
     list<Absyn.ClassPart> parts;
     list<Absyn.ElementItem> publst;
   /* a class with parts */
   case(Absyn.CLASS(body=Absyn.PARTS(classParts=parts)), _) equation
     publst = getPublicList(parts);
     comp = getComponentsContainsName(Absyn.CREF_IDENT(compName,{}), publst);
   then comp;
   /* an extended class with parts: model extends M end M; */
   case(Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)), _) equation
     publst = getPublicList(parts);
     comp = getComponentsContainsName(Absyn.CREF_IDENT(compName,{}), publst);
   then comp;
 end match;
end getComponentElementInClass;

public function getFunctionsInProgram
  input Absyn.Program prog;
  output list<Absyn.Class> funcs;
protected
  list<Absyn.Class> classes;
  list<list<Absyn.Class>> classesList;
algorithm
  Absyn.PROGRAM(classes = classes) := prog;
  classesList := List.map(classes, getAllClassesInClass);
  funcs := List.fold(classes::classesList, getFunctionsInClasses, {});
end getFunctionsInProgram;

protected function getFunctionsInClasses
  input list<Absyn.Class> classes;
  input list<Absyn.Class> acc;
  output list<Absyn.Class> funcs;
algorithm
  funcs := match (classes,acc)
    local
      Absyn.Class cl;
      list<Absyn.Class> rest;

    case ({},_) then acc;
    case ((cl as Absyn.CLASS(restriction = Absyn.R_FUNCTION(_)))::rest,_)
      equation
        funcs = getFunctionsInClasses(rest,cl::acc);
      then funcs;
    case (_::rest,_) then getFunctionsInClasses(rest,acc);
  end match;
end getFunctionsInClasses;

protected function getAllClassesInClass
  input Absyn.Class class_;
  output list<Absyn.Class> outClasses;
algorithm
  outClasses := matchcontinue class_
    local
      list<Absyn.ClassPart> classParts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = classParts))
      then getClassesInParts(classParts);
    else {};
  end matchcontinue;
end getAllClassesInClass;

public function getAllInheritedClasses
  input Absyn.Path inClassName;
  input Absyn.Program inProgram;
  output list<Absyn.Path> outBaseClassNames;
algorithm
  outBaseClassNames :=
  matchcontinue (inClassName,inProgram)
    local
      Absyn.Path p_class;
      list<Absyn.Path> paths;
      Absyn.Class cdef;
      list<Absyn.ElementSpec> exts;
      Absyn.Program p;

    case (p_class,p)
      equation
        cdef = getPathedClassInProgram(p_class, p);
        exts = getExtendsElementspecInClass(cdef);
        paths = List.map(exts, getBaseClassNameFromExtends);
      then
        paths;
    else {};
  end matchcontinue;
end getAllInheritedClasses;

protected function getBaseClassNameFromExtends
"function: getBaseClassNameFromExtends"
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outBaseClassPath;
algorithm
  outBaseClassPath := match (inElementSpec)
    local
      Absyn.Path path;

    case (Absyn.EXTENDS(path = path)) then path;
  end match;
end getBaseClassNameFromExtends;

public function printIstmtStr "Prints an interactive statement to a string."
  input GlobalScript.Statements inStatements;
  output String strIstmt;
algorithm
  strIstmt := GlobalScriptDump.printIstmtsStr(inStatements);
end printIstmtStr;

protected function getClassEnvNoElaboration " Retrieves the environment of the class, including the frame of the class
   itself by partially instantiating it.

   If partial instantiation fails, a full instantiation is performed.

   This can happen e.g. for
   model A
   model Resistor
    Pin p,n;
    constant Integer n_conn = cardinality(p);
    equation connect(p,n);
   end A;

   where partial instantiation fails since cardinality(p) can not be determined."
  input Absyn.Program inProgram;
  input Absyn.Path inClassPath;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
protected
  SCode.Element cl;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  FCore.Graph env;
  ClassInf.State ci_state;
  FCore.Cache cache;
algorithm
  (cache, (cl as SCode.CLASS(name = id, encapsulatedPrefix = encflag, restriction = restr)), env) :=
    Lookup.lookupClass(FCore.emptyCache(), inEnv, inClassPath);
  env := FGraph.openScope(env, encflag, id, FGraph.restrictionToScopeType(restr));
  ci_state := ClassInf.start(restr, FGraph.getGraphName(env));

  // First try partial instantiation
  try
    (_, outEnv) := Inst.partialInstClassIn(cache, env, InnerOuter.emptyInstHierarchy,
      DAE.NOMOD(), Prefix.NOPRE(), ci_state, cl, SCode.PUBLIC(), {}, 0);
  else
    (_, outEnv) := Inst.instClassIn(cache, env, InnerOuter.emptyInstHierarchy,
      UnitAbsyn.noStore, DAE.NOMOD(), Prefix.NOPRE(), ci_state, cl,
      SCode.PUBLIC(), {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY,
      Connect.emptySet, NONE());
  end try;
end getClassEnvNoElaboration;

protected function setComponentDimensions
  "Sets a component dimensions."
  input Absyn.ComponentRef inClass;
  input Absyn.ComponentRef inComponentName;
  input list<Absyn.Exp> inDimensions;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outResult;
protected
  Absyn.Path p_class;
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    p_class := Absyn.crefToPath(inClass);
    within_ := buildWithin(p_class);
    cls := getPathedClassInProgram(p_class, inProgram);
    cls := setComponentDimensionsInClass(cls, inComponentName, inDimensions);
    outProgram := updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := "Ok";
  else
    outProgram := inProgram;
    outResult := "Error";
  end try;
end setComponentDimensions;

protected function setComponentDimensionsInClass
" Sets the dimensions on a component in a class."
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentName;
  input list<Absyn.Exp> inDimensions;
  output Absyn.Class outClass = inClass;
algorithm
  (outClass, true) := Absyn.traverseClassComponents(inClass,
    function setComponentDimensionsInCompitems(inComponentName = inComponentName, inDimensions = inDimensions), false);
end setComponentDimensionsInClass;

protected function setComponentDimensionsInCompitems
"Helper function to setComponentDimensions.
 Sets the dimensions in a ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input Absyn.ComponentRef inComponentName;
  input list<Absyn.Exp> inDimensions;
  output list<Absyn.ComponentItem> outComponents = {};
  output Boolean outFound;
  output Boolean outContinue;
protected
  Absyn.ComponentItem item;
  list<Absyn.ComponentItem> rest_items = inComponents;
  Absyn.Component comp;
  list<Absyn.ElementArg> args_old, args_new;
  Absyn.EqMod eqmod_old, eqmod_new;
  String comp_id;
algorithm
  comp_id := Absyn.crefFirstIdent(inComponentName);

  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if Absyn.componentName(item) == comp_id then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.arrayDim := List.map(inDimensions, Absyn.makeSubscript);
            item.component := comp;
          then
            ();
      end match;

      // Reassemble the item list and return.
      outComponents := List.append_reverse(outComponents, item :: rest_items);
      outFound := true;
      outContinue := false;
      return;
    end if;
    outComponents := item :: outComponents;
  end while;

  // Component not found, continue looking.
  outComponents := inComponents;
  outFound := false;
  outContinue := true;
end setComponentDimensionsInCompitems;


protected function mergeClasses
"@author adrpo
 merge two classes cNew and cOld in the following way:
 1. get all the inner class definitions from cOld that were loaded from a different file than itself
 2. append all elements from step 1 to class cNew public list!"
   input  Absyn.Class cNew;
   input  Absyn.Class cOld;
   output Absyn.Class c;
algorithm
  c := matchcontinue(cNew, cOld)
    local
      list<Absyn.ClassPart> partsC1, partsC2;
      list<Absyn.ElementItem> pubElementsC1, pubElementsC2;
      String file;
      Absyn.Ident n; Boolean p; Boolean f; Boolean e; Absyn.Restriction r; Absyn.Info i;
      list<list<Absyn.ElementItem>> llEls;
      list<String> typeVars1, typeVars2;
      list<Absyn.NamedArg> classAttrs1, classAttr2;
      list<Absyn.Annotation> ann1, ann2;
      Option<String> cmt1, cmt2;


    // if cOld has no parts then just return cNew
    case (_, Absyn.CLASS(body = Absyn.PARTS(classParts = {}))) then cNew;
    case (_, Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = {}))) then cNew;

    // if cNew and cOld has parts, get the foreign elements (loaded from other file) from cOld
    // and append them to the public list of cNew
    case (Absyn.CLASS(n, p, f, e, r, Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1), i),
          Absyn.CLASS(body = Absyn.PARTS(classParts = partsC2), info = SOURCEINFO(fileName = file)))
      equation
        pubElementsC2 = getPublicList(partsC2);
        pubElementsC2 = excludeElementsFromFile(file, pubElementsC2);
        pubElementsC1 = getPublicList(partsC1);
        pubElementsC1 = mergeElements(pubElementsC1, pubElementsC2);
        partsC1 = replacePublicList(partsC1, pubElementsC1);
        c = Absyn.CLASS(n, p, f, e, r, Absyn.PARTS(typeVars1,classAttrs1,partsC1,ann1,cmt1), i);
      then c;

    // TODO! FIXME! handle also CLASS_EXTENDS!
    // if the class cNew or cOld is not containing parts then don't bother, just replace the entire class!
    case (_, _) then cNew;
  end matchcontinue;
end mergeClasses;

function mergeElement
"@author adrpo
 merge the element given as second argument with the element from the first list with same name.
  if no such elements are in the first list, just append it at the end"
  input  list<Absyn.ElementItem> inEls;
  input  Absyn.ElementItem inEl;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := matchcontinue(inEls, inEl)
    local
      String n1,n2;
      list<Absyn.ElementItem> rest, filtered;
      Absyn.ElementItem e1,e2;
      Boolean r;
      Boolean f;
      Option<Absyn.RedeclareKeywords> redecl;
      Absyn.InnerOuter innout ;
      String name;
      Absyn.Info i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Class c1, c2;
    case ({}, _) then inEl::{};
    // not found put it at the end
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1 as Absyn.CLASS(name = n1)), i, cc)) :: rest,
          Absyn.ELEMENTITEM(Absyn.ELEMENT(specification = Absyn.CLASSDEF(_,c2 as Absyn.CLASS(name = n2)))))
      equation
        true = stringEqual(n1, n2);
         // element found, merge it!
        c1 = mergeClasses(c1, c2);
      then
        Absyn.ELEMENTITEM(Absyn.ELEMENT(f, redecl, innout, Absyn.CLASSDEF(r, c1), i, cc)) :: rest;
    case (e1 :: rest, e2)
      equation
        // try the second from the first list
        filtered = mergeElement(rest, e2);
      then
         e1::filtered;
  end matchcontinue;
end mergeElement;


function mergeElements
  "@author adrpo see merge element"
   input  list<Absyn.ElementItem> inEls1;
   input  list<Absyn.ElementItem> inEls2;
   output list<Absyn.ElementItem> outEls;
  algorithm
    outEls := matchcontinue(inEls1, inEls2)
    local
      String n1,n2;
      list<Absyn.ElementItem> rest, merged;
      Absyn.ElementItem e1,e2;
      case ({}, _) then inEls2;
      case (_, {}) then inEls1;
      case (_, e2::rest)
        equation
          merged = mergeElement(inEls1, e2);
          merged = mergeElements(merged, rest);
        then merged;
    end matchcontinue;
end mergeElements;

function excludeElementsFromFile
"exclude all elements which are part of the given file"
  input  String inFile;
  input  list<Absyn.ElementItem> inEls;
  output list<Absyn.ElementItem> outEls;
algorithm
  outEls := matchcontinue (inFile,inEls)
    local
      Absyn.ElementItem e;
      list<Absyn.ElementItem> rest, filtered;
      String f,file;
    case (_,{}) then {};
    case (file,(e as Absyn.ELEMENTITEM(Absyn.ELEMENT(info = SOURCEINFO(fileName = f))))::rest)
      equation
        false = stringEqual(file, f); // not from this file, use it!
        filtered = excludeElementsFromFile(file, rest);
      then e::filtered;
    case (file,(Absyn.ELEMENTITEM(Absyn.ELEMENT(info = SOURCEINFO(fileName = f))))::rest)
      equation
        true = stringEqual(file, f); // is from this file, discard!
        filtered = excludeElementsFromFile(file, rest);
      then filtered;
  end matchcontinue;
end excludeElementsFromFile;

public function getInstantiatedParametersAndValues
  input Option<DAE.DAElist> odae;
  output list<String> parametersAndValues = {};
protected
  list<DAE.Element> els, params;
  list<String> strs = {};
  String s;
  Option<DAE.Exp> oe;
algorithm
  parametersAndValues := match(odae)
    case SOME(DAE.DAE(els))
      algorithm
       params := DAEUtil.getParameters(els, {});
       for p in params loop
         DAE.VAR(binding=oe) := p;
         s := DAEUtil.varName(p) + DAEDump.dumpVarBindingStr(oe);
         strs := s::strs;
       end for;
     then
       listReverse(strs);
    else strs;
  end match;
end getInstantiatedParametersAndValues;

public function getAccessAnnotation
  "Returns the Protection(access=) annotation of a class.
  This is annotated with the annotation:
  annotation(Protection(access = Access.documentation)); in the class definition"
  input Absyn.Path className;
  input Absyn.Program p;
  output String access;
algorithm
  access := match(className,p)
    local
      String accessStr;
    case(_,_)
      equation
        accessStr = getNamedAnnotation(className, p, Absyn.IDENT("Protection"), SOME(""), getAccessAnnotationString);
      then
        accessStr;
    else "";
  end match;
end getAccessAnnotation;

protected function getAccessAnnotationString
  "Extractor function for getAccessAnnotation"
  input Option<Absyn.Modification> mod;
  output String access;
algorithm
  access := match (mod)
    local
      list<Absyn.ElementArg> arglst;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then getAccessAnnotationString2(arglst);

  end match;
end getAccessAnnotationString;

protected function getAccessAnnotationString2
  "Extractor function for getAccessAnnotation"
  input list<Absyn.ElementArg> eltArgs;
  output String access;
algorithm
  access := match eltArgs
    local
      list<Absyn.ElementArg> xs;
      Absyn.ComponentRef cref;
      String name;
      Absyn.Info info;

    case ({}) then "";

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name="access"),
          modification = SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.CREF(cref)))))::_)
      equation
        name = Dump.printComponentRefStr(cref);
      then name;

    case (_::xs)
      equation
        name = getAccessAnnotationString2(xs);
      then name;

    end match;
end getAccessAnnotationString2;

public function checkAccessAnnotationAndEncryption
  input Absyn.Path path;
  input Absyn.Program p;
  output Values.Value val;
protected
  String access, fileName;
  Boolean encryptedClass;
algorithm
  try
    Absyn.CLASS(info=SOURCEINFO(fileName=fileName)) := getPathedClassInProgram(path, p);
    encryptedClass := Util.endsWith(fileName, ".moc");
    if encryptedClass then
      access := getAccessAnnotation(path, p);
      if access == "Access.hide" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("hide"))), 1);
      elseif access == "Access.icon" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("icon"))), 2);
      elseif access == "Access.documentation" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("documentation"))), 3);
      elseif access == "Access.diagram" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("diagram"))), 4);
      elseif access == "Access.nonPackageText" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("nonPackageText"))), 5);
      elseif access == "Access.nonPackageDuplicate" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("nonPackageDuplicate"))), 6);
      elseif access == "Access.packageText" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("packageText"))), 7);
      elseif access == "Access.packageDuplicate" then
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("packageDuplicate"))), 8);
      elseif not Absyn.pathIsIdent(path) then // if the class doesn't have the access annotation then look for it in the parent class.
        val := checkAccessAnnotationAndEncryption(Absyn.stripLast(path), p);
      else // if a class is encrypted and no Protection annotation is defined, the access annotation has the default value Access.documentation
        val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("documentation"))), 3);
      end if;
    else
      val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("all"))), 9);
    end if;
  else
   val := Values.ENUM_LITERAL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Access", Absyn.IDENT("all"))), 9);
  end try;
end checkAccessAnnotationAndEncryption;

public function astContainsEncryptedClass
  input Absyn.Program inProgram;
  output Boolean containsEncryptedClass = false;
protected
  list<Absyn.Class> classes;
  Absyn.Program p;
  String fileName;
algorithm
  classes := match(inProgram)
    case p as Absyn.PROGRAM()
      then p.classes;
  end match;
  for c in classes loop
    Absyn.CLASS(info=SOURCEINFO(fileName=fileName)) := c;
    containsEncryptedClass := containsEncryptedClass or Util.endsWith(fileName, ".moc");
    if containsEncryptedClass then break; end if;
  end for;
end astContainsEncryptedClass;

annotation(__OpenModelica_Interface="backend");
end Interactive;
