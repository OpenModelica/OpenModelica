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
import AbsynUtil;
import DAE;
import FCore;
import Global;
import SCode;
import Settings;
import Values;

// protected imports
protected

import Ceval;
import CevalScript;
import ClockIndexes;
import Config;
import Dump;
import Error;
import ErrorExt;
import ExpressionDump;
import FGraph;
import Flags;
import FlagsUtil;
import GC;
import GlobalScriptDump;
import InstHashTable;
import InteractiveUtil;
import List;
import Parser;
import Print;
import Refactor;
import StackOverflow;
import Static;
import StaticScript;
import SymbolTable;
import System;
import Testsuite;
import Types;
import ValuesUtil;

import MetaModelica.Dangerous;

public uniontype AnnotationType
  record ICON_ANNOTATION end ICON_ANNOTATION;
  record DIAGRAM_ANNOTATION end DIAGRAM_ANNOTATION;
end AnnotationType;

public uniontype GraphicEnvCache
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
    Absyn.Program program;
    Absyn.Path modelPath;
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

  testsuite := Testsuite.isRunning();

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

public function printIstmtStr "Prints an interactive statement to a string."
  input GlobalScript.Statements inStatements;
  output String strIstmt;
algorithm
  strIstmt := GlobalScriptDump.printIstmtsStr(inStatements);
end printIstmtStr;

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
  outString := match (inSemicolon,inVerbose,inEcho)
    case (_    , _   , false) then "";  // echo off always empty string
    case (_    , true, _    ) then inString;  // .. verbose on always return str
    case (true , _   , _    ) then "";   // ... semicolon, no resultstr
    case (false, _   , _    ) then inString; // no semicolon
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
        gen = FlagsUtil.set(Flags.GEN, false);
        evalfunc = FlagsUtil.set(Flags.EVAL_FUNC, false);
        keepArrays = Flags.getConfigBool(Flags.KEEP_ARRAYS);
        FlagsUtil.setConfigBool(Flags.KEEP_ARRAYS, false);
        InstHashTable.init();
        str = evaluateGraphicalApi(stmt, partialInst, gen, evalfunc, keepArrays);
        str_1 = stringAppend(str, "\n");
      then str_1;

    // Evaluate algorithm statements in evaluateAlgStmt()
    case GlobalScript.IALG(algItem = (algitem as Absyn.ALGORITHMITEM()))
      equation
        InstHashTable.init();
        str = evaluateAlgStmt(algitem);
        str_1 = stringAppend(str, "\n");
      then str_1;

    // Evaluate expressions in evaluate_exprToStr()
    case GlobalScript.IEXP(exp = exp, info = info)
      equation
        InstHashTable.init();
        str = evaluateExprToStr(exp, info);
        str_1 = stringAppend(str, "\n");
      then str_1;
  end matchcontinue;
  else
    str := "";
    str_1 := "";
    GC.gcollect();
    str := StackOverflow.getReadableMessage();
    if Testsuite.isRunning() then
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
        (cache,econd,_) = StaticScript.elabExp(FCore.emptyCache(), env, cond, true, true, DAE.NOPRE(), info);
        (_,Values.BOOL(true)) = CevalScript.ceval(cache,env, econd, true, Absyn.MSG(info), 0);
      then "";

    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
          functionArgs = Absyn.FUNCTIONARGS(args = {_,msg})))
      equation
        env = SymbolTable.buildEnv();
        (cache,msg_1,_) = StaticScript.elabExp(FCore.emptyCache(), env, msg, true, true, DAE.NOPRE(), info);
        (_,Values.STRING(str)) = CevalScript.ceval(cache,env, msg_1, true, Absyn.MSG(info), 0);
      then str;

    case Absyn.ALGORITHMITEM(info=info,algorithm_ = Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs))
      equation
        env = SymbolTable.buildEnv();
        exp = Absyn.CALL(cr,fargs,{});
        (cache,sexp,_) = StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, DAE.NOPRE(), info);
        (_,_) = CevalScript.ceval(cache, env, sexp, true, Absyn.MSG(info), 0);
      then "";

    // Special case to lookup fields of records.
    // SimulationResult, etc are not in the environment,
    // but it's nice to be able to script them anyway
    case Absyn.ALGORITHMITEM(algorithm_ =
          Absyn.ALG_ASSIGN(assignComponent =
          Absyn.CREF(Absyn.CREF_IDENT(name = ident,subscripts = {})),value = Absyn.CREF(cr)))
      equation
        value = InteractiveUtil.getVariableValueLst(AbsynUtil.pathToStringList(AbsynUtil.crefToPath(cr)), SymbolTable.getVars());
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
        (cache,sexp,DAE.PROP(_,_)) = StaticScript.elabExp(FCore.emptyCache(),env, exp, true, true, DAE.NOPRE(),info);
        (_,value) = CevalScript.ceval(cache,env, sexp, true,Absyn.MSG(info),0);
        (_, dsubs, _) = Static.elabSubscripts(cache, env, asubs, true, DAE.NOPRE(), info);

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
        (cache,srexp,rprop) = StaticScript.elabExp(FCore.emptyCache(),env, rexp, true, true, DAE.NOPRE(),info);
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
      then InteractiveUtil.getVariableValueLst(AbsynUtil.pathToStringList(AbsynUtil.crefToPath(cr)), SymbolTable.getVars());

    case (exp,_)
      equation
        env = SymbolTable.buildEnv();
        (cache,sexp,_) = StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, DAE.NOPRE(), info);
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
  (_, sexp, prop) := StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, DAE.NOPRE(), AbsynUtil.dummyInfo);
  (_, sexp, prop) := Ceval.cevalIfConstant(FCore.emptyCache(), env, sexp, prop, true, AbsynUtil.dummyInfo);
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
        (_, dsubs, _) = Static.elabSubscripts(inCache, inEnv, asubs, true, DAE.NOPRE(), inInfo);
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
  FlagsUtil.set(Flags.GEN, flagGen);
  FlagsUtil.set(Flags.EVAL_FUNC, flagEvalFunc);
  FlagsUtil.setConfigBool(Flags.KEEP_ARRAYS, flagKeepArrays);

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
  Boolean addFunctions, graphicsExpMode, warningsAsErrors;
  FCore.Graph env;
  GraphicEnvCache genv;
  Absyn.Exp exp;
  list<Absyn.Exp> dimensions;
  Absyn.CodeNode cn;
  Absyn.Element el;
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
        (p, outResult) := InteractiveUtil.setComponentModifier(class_, cr, mod, p);
      then
        outResult;

    case "setElementModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.CODE(code = cn)} := args;
        mod := match cn
          case Absyn.C_MODIFICATION(modification = mod) then mod;
          case Absyn.C_ELEMENT(element = el) then fail();
        end match;
        (p, outResult) := InteractiveUtil.setElementModifier(class_, cr, mod, p);
      then
        outResult;

    case "setParameterValue"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = crident), exp} := args;
        (p, outResult) := InteractiveUtil.setParameterValue(class_, crident, exp, p);
      then
        outResult;

    case "setComponentDimensions"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.ARRAY(dimensions)} := args;
        (p, outResult) := InteractiveUtil.setComponentDimensions(class_, cr, dimensions, p);
      then
        outResult;

    case "createModel"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        p := InteractiveUtil.createModel(cr, p);
      then
        "true";

    case "newModel"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = cr)} := args;
        path := AbsynUtil.crefToPath(cr);
        p := InteractiveUtil.updateProgram(
          Absyn.PROGRAM({
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),AbsynUtil.dummyParts,AbsynUtil.dummyInfo)
          }, Absyn.WITHIN(path)), p);
      then
        "true";

    // Not moving this yet as it could break things...
    case "deleteClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        (outResult, p) := InteractiveUtil.deleteClass(cr, p);
      then
        outResult;

    case "addComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} := args;
        nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
        p := InteractiveUtil.addComponent(name, tp, model_, nargs, p);
        Print.clearBuf();
      then
        "true";

    case "updateComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = tp),
         Absyn.CREF(componentRef = model_)} := args;
        nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
        (p, outResult) := InteractiveUtil.updateComponent(name, tp, model_, nargs, p);
      then
        outResult;

    case "deleteComponent"
      algorithm
        {Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = name)),
         Absyn.CREF(componentRef = model_)} := args;
        {} := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
        p := InteractiveUtil.deleteOrUpdateComponent(name, model_, p, NONE());
        Print.clearBuf();
      then "true";

    case "deleteComponent"
      then "false";

    case "getComponentCount"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        intString(InteractiveUtil.getComponentCount(cr, p));

    case "getNthComponent"
      algorithm
        {Absyn.CREF(componentRef = cr),Absyn.INTEGER(value = n)} := args;
      then
        InteractiveUtil.getNthComponent(cr, p, n);

    case "getComponents"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 2) then // i.e., Access.icon
          nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getComponents");
          end if;
          outResult := InteractiveUtil.getComponents(cr, InteractiveUtil.useQuotes(nargs), access);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getComponents");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getElements"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 2) then // i.e., Access.icon
          nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getElements");
          end if;
          outResult := InteractiveUtil.getElements(cr, InteractiveUtil.useQuotes(nargs), access);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getElements");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getComponentAnnotations"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 2) then // i.e., Access.icon
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getComponentAnnotations");
          end if;
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := InteractiveUtil.getComponentAnnotations(cr, p, access);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getComponentAnnotations");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getElementAnnotations"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getElementAnnotations");
          end if;
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := InteractiveUtil.getElementAnnotations(cr, p, access);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getElementAnnotations");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getNthComponentAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getNthComponentAnnotation");
        end if;
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := InteractiveUtil.getNthComponentAnnotation(cr, p, n);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getNthComponentAnnotation");
        end if;
      then
        outResult;

    case "getNthComponentModification"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        InteractiveUtil.getNthComponentModification(cr, p, n);

    case "getNthComponentCondition"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        InteractiveUtil.getNthComponentCondition(cr, p, n);

    case "getInheritanceCount"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        intString(InteractiveUtil.getInheritanceCount(cr, p));

    case "getNthInheritedClass"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        InteractiveUtil.getNthInheritedClass(cr, n);

    case "setConnectionComment"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.STRING(value = cmt)} := args;
        (p, outResult) := InteractiveUtil.setConnectionComment(cr, cr1, cr2, cmt, p);
      then
        outResult;

    case "addConnection"
      algorithm
        {Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.CREF(componentRef = cr)} := args;
        nargs := getApiFunctionNamedArgs(inStatement);
        (outResult, p) := InteractiveUtil.addConnection(cr, cr1, cr2, nargs, p);
      then
        outResult;

    case "deleteConnection"
      algorithm
        {Absyn.CREF(componentRef = cr1),
         Absyn.CREF(componentRef = cr2),
         Absyn.CREF(componentRef = cr)} := args;
        (outResult, p) := InteractiveUtil.deleteConnection(cr, cr1, cr2, p);
      then
        outResult;

    case "getNthConnectionAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          ErrorExt.setCheckpoint("getNthConnectionAnnotation");
          path := AbsynUtil.crefToPath(cr);
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          Config.setEvaluateParametersInAnnotations(true);
          outResult := InteractiveUtil.getNthConnectionAnnotation(path, p, n);
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
        InteractiveUtil.getConnectorCount(cr, p);

    case "getNthConnector"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
      then
        InteractiveUtil.getNthConnector(AbsynUtil.crefToPath(cr), p, n);

    case "getNthConnectorIconAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getNthConnectorIconAnnotation");
        end if;
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := InteractiveUtil.getNthConnectorIconAnnotation(AbsynUtil.crefToPath(cr), p, n);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getNthConnectorIconAnnotation");
        end if;
      then
        outResult;

    case "getIconAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 2) then // i.e., Access.icon
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getIconAnnotation");
          end if;
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          graphicsExpMode := Config.getGraphicsExpMode();
          Config.setEvaluateParametersInAnnotations(true);
          Config.setGraphicsExpMode(true);
          outResult := InteractiveUtil.getIconAnnotation(AbsynUtil.crefToPath(cr), p);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          Config.setGraphicsExpMode(graphicsExpMode);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getIconAnnotation");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getDiagramAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        Values.ENUM_LITERAL(index=access) := InteractiveUtil.checkAccessAnnotationAndEncryption(AbsynUtil.crefToPath(cr), p);
        if (access >= 4) then // i.e., Access.diagram
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.setCheckpoint("getDiagramAnnotation");
          end if;
          evalParamAnn := Config.getEvaluateParametersInAnnotations();
          graphicsExpMode := Config.getGraphicsExpMode();
          Config.setEvaluateParametersInAnnotations(true);
          Config.setGraphicsExpMode(true);
          outResult := InteractiveUtil.getDiagramAnnotation(AbsynUtil.crefToPath(cr), p);
          Config.setEvaluateParametersInAnnotations(evalParamAnn);
          Config.setGraphicsExpMode(graphicsExpMode);
          if not Flags.isSet(Flags.NF_API_NOISE) then
            ErrorExt.rollBack("getDiagramAnnotation");
          end if;
        else
          Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
          outResult := "";
        end if;
      then
        outResult;

    case "getNthInheritedClassIconMapAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getNthInheritedClassIconMapAnnotation");
        end if;
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := InteractiveUtil.getNthInheritedClassMapAnnotation(AbsynUtil.crefToPath(cr), n, p, "IconMap");
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getNthInheritedClassIconMapAnnotation");
        end if;
      then
        outResult;

    case "getNthInheritedClassDiagramMapAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.INTEGER(value = n)} := args;
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getNthInheritedClassDiagramMapAnnotation");
        end if;
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := InteractiveUtil.getNthInheritedClassMapAnnotation(AbsynUtil.crefToPath(cr), n, p, "DiagramMap");
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getNthInheritedClassDiagramMapAnnotation");
        end if;
      then
        outResult;

    case "getNamedAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = Absyn.CREF_IDENT(name, {}))} := args;
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getNamedAnnotation");
        end if;
        evalParamAnn := Config.getEvaluateParametersInAnnotations();
        Config.setEvaluateParametersInAnnotations(true);
        outResult := InteractiveUtil.getNamedAnnotation(AbsynUtil.crefToPath(cr), p,
            Absyn.IDENT(name), SOME("{}"), InteractiveUtil.getAnnotationValue);
        Config.setEvaluateParametersInAnnotations(evalParamAnn);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getNamedAnnotation");
        end if;
      then
        outResult;

    case "refactorClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;

        try
          cls := InteractiveUtil.getPathedClassInProgram(AbsynUtil.crefToPath(cr), p);
          cls := Refactor.refactorGraphicalAnnotation(p, cls);
          p := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, Absyn.TOP()), p);
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
        path := AbsynUtil.crefToPath(cr);
        cls := InteractiveUtil.getPathedClassInProgram(path, p);
        cls := Refactor.refactorGraphicalAnnotation(p, cls);
      then
        InteractiveUtil.getAnnotationInClass(cls, ICON_ANNOTATION(), p, path);

    case "refactorDiagramAnnotation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := AbsynUtil.crefToPath(cr);
        cls := InteractiveUtil.getPathedClassInProgram(path, p);
        cls := Refactor.refactorGraphicalAnnotation(p, cls);
      then
        InteractiveUtil.getAnnotationInClass(cls, DIAGRAM_ANNOTATION(), p, path);

    case "getShortDefinitionBaseClassInformation"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        InteractiveUtil.getShortDefinitionBaseClassInformation(cr, p);

    case "getExternalFunctionSpecification"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        InteractiveUtil.getExternalFunctionSpecification(cr, p);

    case "isPrimitive"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(InteractiveUtil.isPrimitive(cr, p));

    case "isParameter"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(InteractiveUtil.isParameter(cr, class_, p));

    case "isProtected"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(InteractiveUtil.isProtected(cr, class_, p));

    case "isConstant"
      algorithm
        {Absyn.CREF(componentRef = cr), Absyn.CREF(componentRef = class_)} := args;
      then
        boolString(InteractiveUtil.isConstant(cr, class_, p));

    case "isReplaceable"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.STRING(value = name)} := args;
      then
        boolString(InteractiveUtil.isReplaceable(class_, name, p));

    case "getEnumerationLiterals"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := AbsynUtil.crefToPath(cr);
        cls := InteractiveUtil.getPathedClassInProgram(path, p);
      then
        InteractiveUtil.getEnumLiterals(cls);

    case "existClass"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(InteractiveUtil.existClass(cr, p));

    case "existModel"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        path := AbsynUtil.crefToPath(cr);
      then
        boolString(InteractiveUtil.existClass(cr, p) and InteractiveUtil.isModel(path, p));

    case "existPackage"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        boolString(InteractiveUtil.existClass(cr, p) and InteractiveUtil.isPackage(AbsynUtil.crefToPath(cr), p));

    case "renameClass"
      algorithm
        {Absyn.CREF(componentRef = old_cname), Absyn.CREF(componentRef = new_cname)} := args;
        // For now, renaming a class clears all caches...
        // Substantial analysis required to find out what to keep in cache and what must be thrown out
        (outResult, p) := InteractiveUtil.renameClass(p, old_cname, new_cname);
      then
        outResult;

    case "renameComponent"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = old_cname),
         Absyn.CREF(componentRef = new_cname)} := args;
        (outResult, p) := InteractiveUtil.renameComponent(p, cr, old_cname, new_cname);
      then outResult;

    case "renameComponentInClass"
      algorithm
        {Absyn.CREF(componentRef = cr),
         Absyn.CREF(componentRef = old_cname),
         Absyn.CREF(componentRef = new_cname)} := args;
        (outResult, p) := InteractiveUtil.renameComponentOnlyInClass(p, cr, old_cname, new_cname);
      then outResult;

    case "getCrefInfo"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        InteractiveUtil.getCrefInfo(cr, p);

    case "setExtendsModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident),
         Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))} := args;
        (p, outResult) := InteractiveUtil.setExtendsModifierValue(class_, crident, subident, mod, p);
      then
        outResult;

    case "getExtendsModifierNames"
      algorithm
        {Absyn.CREF(componentRef = class_), Absyn.CREF(componentRef = cr)} := args;
        nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.setCheckpoint("getExtendsModifierNames");
        end if;
        outResult := InteractiveUtil.getExtendsModifierNames(class_, cr, InteractiveUtil.useQuotes(nargs), p);
        if not Flags.isSet(Flags.NF_API_NOISE) then
          ErrorExt.rollBack("getExtendsModifierNames");
        end if;
      then
        outResult;

    case "getExtendsModifierValue"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident)} := args;
      then
        InteractiveUtil.getExtendsModifierValue(class_, crident, subident, p);

    case "isExtendsModifierFinal"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = crident),
         Absyn.CREF(componentRef = subident)} := args;
      then
        InteractiveUtil.isExtendsModifierFinal(class_, crident, subident, p);

    case "getDefaultComponentName"
      algorithm
        {Absyn.CREF(componentRef = class_)} := args;
      then
        InteractiveUtil.getDefaultComponentName(AbsynUtil.crefToPath(class_), p);

    case "getDefaultComponentPrefixes"
      algorithm
        {Absyn.CREF(componentRef = class_)} := args;
      then
        InteractiveUtil.getDefaultComponentPrefixes(AbsynUtil.crefToPath(class_), p);

    case "getComponentComment"
      algorithm
        {Absyn.CREF(componentRef = class_),Absyn.CREF(componentRef = cr)} := args;
        outResult := InteractiveUtil.getComponentComment(class_, cr, p);
        outResult := stringAppendList({"\"", outResult, "\""});
      then
        outResult;

    case "setComponentComment"
      algorithm
        {Absyn.CREF(componentRef = class_),
         Absyn.CREF(componentRef = cr),
         Absyn.STRING(value = cmt)} := args;
        (outResult, p) := InteractiveUtil.setComponentComment(class_, cr, cmt, p);
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

        (outResult, p) := InteractiveUtil.setComponentProperties(AbsynUtil.crefToPath(class_), cr,
            finalPrefix, flowPrefix, streamPrefix, protected_, repl,
            /*parallelism,*/ variability, {dref1,dref2}, causality, p/*, isField*/);
      then
        outResult;

    case "getElementsInfo"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
      then
        InteractiveUtil.getElementsInfo(cr, p);

    case "getElementsOfVisType"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        (_, outResult) := InteractiveUtil.getElementsOfVisType(AbsynUtil.crefToPath(cr), p);
      then
        outResult;

    case "getDefinitions"
      algorithm
        {Absyn.BOOL(addFunctions)} := args;
      then
        InteractiveUtil.getDefinitions(p, addFunctions);

    case "getLocalVariables"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        nargs := InteractiveUtil.getApiFunctionNamedArgs(inStatement);
        path := AbsynUtil.crefToPath(cr);
        cls := InteractiveUtil.getPathedClassInProgram(path, p);
        env := SymbolTable.buildEnv();
        if Flags.isSet(Flags.NF_API) then
          genv := GRAPHIC_ENV_FULL_CACHE(p, path, FCore.emptyCache(), FGraph.empty());
        else
          genv := GRAPHIC_ENV_FULL_CACHE(p, path, FCore.emptyCache(), env);
        end if;
      then
        InteractiveUtil.getLocalVariables(cls, InteractiveUtil.useQuotes(nargs), genv);

    // adrpo added 2006-10-16 - i think this function is needed here!
    //             2020-06-11 - remove this after 1.16 to use the one in Ceval*
    case "getErrorString"
      algorithm
        warningsAsErrors := match args
          case {Absyn.BOOL(warningsAsErrors)} then warningsAsErrors;
          else false;
        end match;
        outResult := Error.printMessagesStr(warningsAsErrors);
        outResult := System.escapedString(outResult,false);
      then
        stringAppendList({"\"", outResult, "\""});

  end match;

  SymbolTable.setAbsyn(p);
end evaluateGraphicalApi_dispatch;

annotation(__OpenModelica_Interface="backend");
end Interactive;
