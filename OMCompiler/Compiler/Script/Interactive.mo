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
import ConnectionGraph;
import DAE;
import FCore;
import Global;
import SCode;
import AbsynToSCode;
import Settings;
import Values;


// protected imports
protected

import Ceval;
import CevalScript;
import ClassInf;
import ClockIndexes;
import Config;
import DAE.Connect;
import DAEDump;
import DAEUtil;
import Dump;
import Error;
import ErrorExt;
import ExpressionDump;
import ExpressionSimplify;
import FGraph;
import Flags;
import FlagsUtil;
import GCExt;
import GlobalScriptDump;
import InnerOuter;
import Inst;
import InstHashTable;
import InstTypes;
import InstUtil;
import InteractiveUtil;
import List;
import Lookup;
import MetaUtil;
import Mod;
import NFApi;
import Parser;
import Print;
import Refactor;
import SCodeUtil;
import StackOverflow;
import Static;
import StaticScript;
import StringUtil;
import SymbolTable;
import System;
import Testsuite;
import Types;
import UnitAbsyn;
import Util;
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

type Access = enumeration(hide, icon, documentation, diagram, nonPackageText, nonPackageDuplicate, packageText, packageDuplicate, all);

public function evaluate
"This function evaluates expressions or statements feed interactively to the compiler.
  inputs:   (GlobalScript.Statements, bool /* verbose */)
  outputs:   string:
                     The resulting string after evaluation. If an error has occurred, this string
                     will be empty. The error messages can be retrieved by calling print_messages_str()
                     in Error.mo."
  input GlobalScript.Statements inStatements;
  input Boolean verbose;
  output String outString;
protected
  Boolean semicolon;
  String res;
  list<String> resl = {};
algorithm
  for stmt in inStatements.interactiveStmtLst loop
    semicolon := inStatements.semicolon;
    showStatement(stmt, semicolon, true);
    res := evaluate2(stmt);

    if getEcho() and (verbose or not semicolon) then
      resl := res :: resl;
    end if;

    showStatement(stmt, semicolon, false);
  end for;

  outString := stringAppendList(Dangerous.listReverseInPlace(resl));
end evaluate;

public function evaluateToStdOut
"This function evaluates expressions or statements feed interactively to the compiler.
  The resulting string after evaluation is printed.
  If an error has occurred, this string will be empty.
  The error messages can be retrieved by calling print_messages_str() in Error.mo."
  input GlobalScript.Statements statements;
  input Boolean verbose;
protected
  Boolean semicolon;
  String res;
algorithm
  semicolon := statements.semicolon;

  for stmt in statements.interactiveStmtLst loop
    showStatement(stmt, semicolon, true);
    res := evaluate2(stmt);

    if getEcho() and (verbose or not semicolon) then
      print(res);
    end if;

    showStatement(stmt, semicolon, false);
  end for;
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

protected function getEcho
"Return echo variable, which determines
  if result should be printed or not."
  output Boolean outBoolean;
algorithm
  outBoolean := 0 <> Settings.getEcho();
end getEcho;

public function evaluate2
"Helper function to evaluate."
  input GlobalScript.Statement inStatement;
  output String outString;
protected
  String str, str_1;
algorithm
  try /* Stack overflow */
  outString := matchcontinue inStatement
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
        str = evaluateGraphicalApi(inStatement, partialInst, gen, evalfunc, keepArrays);
        str_1 = stringAppend(str, "\n");
      then str_1;

    // Evaluate algorithm statements in evaluateAlgStmt()
    case GlobalScript.IALG(algItem = (algitem as Absyn.ALGORITHMITEM()))
      equation
        InstHashTable.init();
        str = evaluateAlgItem(algitem);
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
    GCExt.gcollect();
    str := StackOverflow.getReadableMessage();
    if Testsuite.isRunning() then
      /* It's useful to print the name of the component we failed on.
       * But we crash in different places, so for the testsuite we skip this.
       */
      Error.clearCurrentComponent();
    end if;
    Error.addMessage(Error.STACK_OVERFLOW_DETAILED, {GlobalScriptDump.printIstmtStr(inStatement), str});
    Error.clearCurrentComponent();
    outString := "\n";
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
end evaluate2;

protected function evaluateAlgItem
"This function takes an AlgorithmItem, i.e. a statement located in an
  algorithm section, and a symboltable as input arguments. The statements
  are recursivly evalutated and a new interactive symbol table is returned."
  input Absyn.AlgorithmItem alg;
  output String result;
algorithm
  result := match alg
    case Absyn.AlgorithmItem.ALGORITHMITEM() then evaluateAlgStmt(alg.algorithm_, alg.info);
    else "";
  end match;
end evaluateAlgItem;

protected function evaluateAlgStmt
  input Absyn.Algorithm alg;
  input SourceInfo info;
  output String result;
protected
  FCore.Graph env;
  FCore.Cache cache;
  Absyn.Exp cond, msg, exp;
  DAE.Exp dcond, dmsg, dexp;
  String str, ident;
  Absyn.ComponentRef cr;
  Values.Value value;
  list<Values.Value> values;
  DAE.Type ty;
  list<Absyn.Subscript> subs;
  list<DAE.Subscript> dsubs;
  list<Absyn.Exp> expl;
  DAE.Properties prop;
  list<DAE.Type> types;
  list<DAE.ComponentRef> crefs;
  list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> branches;
  Values.Value startv, stepv, stopv;
  Absyn.Exp starte, stepe, stope;
algorithm
  result := matchcontinue alg
    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
                             functionArgs = Absyn.FUNCTIONARGS(args = {cond,_}))
      algorithm
        env := SymbolTable.buildEnv();
        (cache, dcond, _) := StaticScript.elabExp(FCore.emptyCache(), env, cond, true, true, DAE.NOPRE(), info);
        (_,Values.BOOL(true)) := CevalScript.ceval(cache,env, dcond, true, Absyn.MSG(info), 0);
      then
        "";

    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
                             functionArgs = Absyn.FUNCTIONARGS(args = {_, msg}))
      algorithm
        env := SymbolTable.buildEnv();
        (cache, dmsg,_) := StaticScript.elabExp(FCore.emptyCache(), env, msg, true, true, DAE.NOPRE(), info);
        (_,Values.STRING(str)) := CevalScript.ceval(cache,env, dmsg, true, Absyn.MSG(info), 0);
      then
        str;

    case Absyn.ALG_NORETCALL()
      algorithm
        env := SymbolTable.buildEnv();
        exp := Absyn.CALL(alg.functionCall, alg.functionArgs, {});
        (cache, dexp) := StaticScript.elabExp(FCore.emptyCache(), env, exp, true, true, DAE.NOPRE(), info);
        (_, _) := CevalScript.ceval(cache, env, dexp, true, Absyn.MSG(info), 0);
      then
        "";

    // Special case to lookup fields of records.
    // SimulationResult, etc are not in the environment,
    // but it's nice to be able to script them anyway
    case Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(Absyn.CREF_IDENT(name = ident, subscripts = {})),
                          value = Absyn.CREF(cr))
      algorithm
        value := getVariableValueLst(AbsynUtil.pathToStringList(AbsynUtil.crefToPath(cr)), SymbolTable.getVars());
        str := ValuesUtil.valString(value);
        ty := Types.typeOfValue(value);
        SymbolTable.addVar(DAE.CREF_IDENT(ident, ty, {}), value, FGraph.empty());
      then
        str;

    case Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(Absyn.CREF_IDENT(name = ident, subscripts = subs)))
      algorithm
        env := SymbolTable.buildEnv();
        (cache, dexp, DAE.PROP(_,_)) := StaticScript.elabExp(FCore.emptyCache(), env, alg.value, true, true, DAE.NOPRE(), info);
        (_, value) := CevalScript.ceval(cache, env, dexp, true, Absyn.MSG(info), 0);
        (_, dsubs, _) := Static.elabSubscripts(cache, env, subs, true, DAE.NOPRE(), info);

        ty := Types.typeOfValue(value) "This type can be more specific than the elaborated type; if the dimensions are unknown...";
        str := ValuesUtil.valString(value);
        SymbolTable.addVar(DAE.CREF_IDENT(ident, ty, dsubs), value, env);
      then
        str;

    // Since expressions cannot be tuples an empty string is returned
    case Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = expl))
      algorithm
        env := SymbolTable.buildEnv();
        (cache, dexp, prop) := StaticScript.elabExp(FCore.emptyCache(), env, alg.value, true, true, DAE.NOPRE(), info);
        DAE.T_TUPLE(types = types) := Types.getPropType(prop);
        crefs := makeTupleCrefs(expl, types, env, cache, info);
        (_, Values.TUPLE(values)) := CevalScript.ceval(cache, env, dexp, true, Absyn.MSG(info), 0);
        SymbolTable.addVars(crefs, values, env);
      then "";

    // if statement
    case Absyn.ALG_IF()
      algorithm
        branches := (alg.ifExp, alg.trueBranch) :: alg.elseIfAlgorithmBranch;
        branches := List.appendElt((Absyn.BOOL(true), alg.elseBranch), branches);
        evaluateIfStatementLst(branches, info);
      then
        "";

    // while-statement
    case Absyn.ALG_WHILE()
      algorithm
        value := evaluateExpr(alg.boolExpr, info);
        evaluateWhileStmt(value, alg.boolExpr, alg.whileBody, info);
      then
        "";

    // for-statement, optimized case, e.g.: for i in 1:1000 loop
    case Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(ident, NONE(), SOME(Absyn.RANGE(start=starte, step=NONE(), stop=stope)))})
      algorithm
        startv := evaluateExpr(starte, info);
        stopv := evaluateExpr(stope, info);
        evaluateForStmtRangeOpt(ident, startv, Values.INTEGER(1), stopv, alg.forBody);
     then
       "";

    // for-statement, optimized case, e.g.: for i in 7.3:0.4:1000.3 loop
    case Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(ident, NONE(), SOME(Absyn.RANGE(start=starte, step=SOME(stepe), stop=stope)))})
      algorithm
        startv := evaluateExpr(starte, info);
        stepv := evaluateExpr(stepe, info);
        stopv := evaluateExpr(stope, info);
        evaluateForStmtRangeOpt(ident, startv, stepv, stopv, alg.forBody);
      then
        "";

    // for-statement, general case
    case Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(ident, NONE(), SOME(exp))})
      algorithm
        Values.ARRAY(valueLst = values) := evaluateExpr(exp, info);
        evaluateForStmt(ident, values, alg.forBody);
      then
        "";

    // for-statement - not an array type
    case Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(range = SOME(exp))})
      algorithm
        str := stringRepresOfExpr(exp);
        Error.addSourceMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {str}, info);
      then
        fail();
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
    evaluateAlgItem(algitem);
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
      then getVariableValueLst(AbsynUtil.pathToStringList(AbsynUtil.crefToPath(cr)), SymbolTable.getVars());

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
  outCrefs := list(makeTupleCref(c, t, inEnv, inCache, inInfo) threaded for c in inCrefs, t in inTypes);
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
      Absyn.FUNCTIONARGS(args = args))) then list(AbsynUtil.stripCommentExpressions(arg) for arg in args);
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
  Integer n;
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
  Access access;
algorithm
  fn_name := getApiFunctionNameInfo(inStatement);
  p := SymbolTable.getAbsyn();
  args := getApiFunctionArgs(inStatement);

  outResult := match(fn_name)
    case "getElementsOfVisType"
      algorithm
        {Absyn.CREF(componentRef = cr)} := args;
        (_, outResult) := getElementsOfVisType(AbsynUtil.crefToPath(cr), p);
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
        path := AbsynUtil.crefToPath(cr);
        cls := InteractiveUtil.getPathedClassInProgram(path, p);
        env := SymbolTable.buildEnv();
        if Flags.isSet(Flags.NF_API) then
          genv := GRAPHIC_ENV_FULL_CACHE(p, path, FCore.emptyCache(), FGraph.empty());
        else
          genv := GRAPHIC_ENV_FULL_CACHE(p, path, FCore.emptyCache(), env);
        end if;
      then
        InteractiveUtil.getLocalVariables(cls, useQuotes(nargs), genv);

  end match;
end evaluateGraphicalApi_dispatch;

protected function extractAllComponentreplacements
"author: x02lucpo
  extracts all the componentreplacementrules from program.
  This is done by extracting all the components and then
  extracting the rules"
  input Absyn.Program p;
  input Absyn.Path classPath;
  input Absyn.ComponentRef oldName;
  input Absyn.ComponentRef newName;
  output GlobalScript.ComponentReplacementRules comp_reps;
protected
  GlobalScript.Components comps;
  GlobalScript.ComponentReplacementRules comp_repsrules;
algorithm
  try
    ErrorExt.setCheckpoint("Interactive.extractAllComponentreplacements");
    comps := extractAllComponents(p, classPath) "class in package" ;
    // rollback errors if we succeed
    ErrorExt.rollBack("Interactive.extractAllComponentreplacements");
    false := isClassReadOnly(InteractiveUtil.getPathedClassInProgram(classPath,p));
    comp_repsrules := GlobalScript.COMPONENTREPLACEMENTRULES({GlobalScript.COMPONENTREPLACEMENT(classPath,oldName,newName)},1);
    comp_reps := getComponentreplacementsrules(comps, comp_repsrules, 0);
  else
    // keep errors if we fail!
    ErrorExt.delCheckpoint("Interactive.extractAllComponentreplacements");
    fail();
  end try;
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

public function renameComponent
  "This function renames a component in a class."
  input Absyn.Path classPath;
  input Absyn.ComponentRef oldName;
  input Absyn.ComponentRef newName;
  input output Absyn.Program program;
        output Values.Value result;
protected
  GlobalScript.ComponentReplacementRules comp_reps;
  list<Absyn.Path> paths;
algorithm
  try
    if isClassReadOnly(InteractiveUtil.getPathedClassInProgram(classPath, program)) then
      result := ValuesUtil.makeCodeTypeNameStr("Error: class: " + AbsynUtil.pathString(classPath) + " is in a read only file!");
      return;
    end if;

    comp_reps := extractAllComponentreplacements(program, classPath, oldName, newName);
    program := renameComponentFromComponentreplacements(program, comp_reps);
    paths := extractRenamedClassesAsStringList(comp_reps);
    result := ValuesUtil.makeCodeTypeNameArray(paths);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end renameComponent;

public function renameComponentOnlyInClass
  "This function renames a component ONLY in the given class"
  input Absyn.Path classPath;
  input Absyn.ComponentRef oldName;
  input Absyn.ComponentRef newName;
  input output Absyn.Program program;
        output Values.Value result;
protected
  Absyn.Class cl;
  Absyn.Within w;
algorithm
  try
    if isClassReadOnly(InteractiveUtil.getPathedClassInProgram(classPath, program)) then
      result := ValuesUtil.makeCodeTypeNameStr("Error: class: " + AbsynUtil.pathString(classPath) + " is in a read only file!");
      return;
    end if;

    cl := InteractiveUtil.getPathedClassInProgram(classPath, program);
    cl := renameComponentInClass(cl, oldName, newName);
    w := InteractiveUtil.buildWithin(AbsynUtil.makeFullyQualified(classPath));
    program := InteractiveUtil.updateProgram(Absyn.PROGRAM({cl}, w), program);
    result := ValuesUtil.makeCodeTypeNameArray({classPath});
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end renameComponentOnlyInClass;

protected function extractRenamedClassesAsStringList
  "Returns the list of classes changed by the given component replacement rules."
  input GlobalScript.ComponentReplacementRules rules;
  output list<Absyn.Path> outPaths = {};
algorithm
  outPaths := list(rule.which1 for rule in rules.componentReplacementLst);
  outPaths := List.uniqueOnTrue(outPaths, AbsynUtil.pathEqual);
end extractRenamedClassesAsStringList;

protected function renameComponentFromComponentreplacements
  input output Absyn.Program program;
  input GlobalScript.ComponentReplacementRules rules;
algorithm
  for rule in rules.componentReplacementLst loop
    ((program, _, _)) := AbsynUtil.traverseClasses(program, NONE(), renameComponentVisitor, rule, true);
  end for;
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
        path_1 = AbsynUtil.joinPaths(pa, Absyn.IDENT(id));
        true = AbsynUtil.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,SOME(pa),
          GlobalScript.COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case (((class_ as Absyn.CLASS(name = id)),NONE(),GlobalScript.COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation
        path_1 = Absyn.IDENT(id);
        true = AbsynUtil.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,NONE(),
          GlobalScript.COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case ((class_,opath,args)) then ((class_,opath,args));
  end matchcontinue;
end renameComponentVisitor;

protected function renameComponentInClass
  input output Absyn.Class cls;
  input Absyn.ComponentRef oldName;
  input Absyn.ComponentRef newName;
protected
  Absyn.ClassDef body;
algorithm
  () := match cls
    case Absyn.CLASS(body = body as Absyn.PARTS())
      algorithm
        body.classParts := renameComponentInParts(body.classParts, oldName, newName);
        cls.body := body;
      then
        ();

    case Absyn.CLASS(body = body as Absyn.CLASS_EXTENDS())
      algorithm
        body.parts := renameComponentInParts(body.parts, oldName, newName);
        cls.body := body;
      then
        ();

    else ();
  end match;
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
        old_comp_path = AbsynUtil.crefToPath(old_comp);
        old_comp_string = AbsynUtil.pathString(old_comp_path);
        true = stringEq(name, old_comp_string);
        new_comp_path = AbsynUtil.crefToPath(new_comp);
        new_comp_string = AbsynUtil.pathString(new_comp_path);
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
        p_1 = AbsynUtil.crefToPath(replaceStartInComponentRef(AbsynUtil.pathToCref(p), old_comp, new_comp));
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,p_1,
          SOME(Absyn.CLASSMOD(element_args_1,Absyn.EQMOD(exp_1,info))),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,path = p,modification = SOME(Absyn.CLASSMOD(element_args,Absyn.NOMOD())),comment = str, info = mod_info),old_comp,new_comp)
      equation
        p_1 = AbsynUtil.crefToPath(replaceStartInComponentRef(AbsynUtil.pathToCref(p), old_comp, new_comp));
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,p_1,SOME(Absyn.CLASSMOD(element_args_1,Absyn.NOMOD())),str,mod_info);
    case (Absyn.MODIFICATION(finalPrefix = b,eachPrefix = each_,path = p,modification = NONE(),comment = str, info = mod_info),old_comp,new_comp)
      equation
        p_1 = AbsynUtil.crefToPath(replaceStartInComponentRef(AbsynUtil.pathToCref(p), old_comp, new_comp));
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
        Absyn.CALL(cref,func_args,inExp1.typeVars);
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
        cr_from_1 = AbsynUtil.joinCrefs(cr, cr_from);
        cr_to_1 = AbsynUtil.joinCrefs(cr, cr_to);
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
        true = AbsynUtil.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation
        ((comp as GlobalScript.EXTENDSITEM(_,comp_path))) = firstComponent(comps);
        true = AbsynUtil.pathEqual(comp_path, path);
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
        p_1 = AbsynToSCode.translateAbsyn2SCode(p);
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
        path_1 = AbsynUtil.joinPaths(pa, Absyn.IDENT(id));
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
        cdef = InteractiveUtil.getPathedClassInProgram(path, p);
        comps = InteractiveUtil.getComponentsInClass(cdef);
        compelts = list(InteractiveUtil.getComponentitemsInElement(c) for c guard isParameterElement(c) in comps);
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
  output GraphicEnvCache env_2;
protected
   Option<list<tuple<Absyn.Program, Absyn.Path, GraphicEnvCache>>> ocache;
   list<tuple<Absyn.Program, Absyn.Path, GraphicEnvCache>> cache, lcache = {};
   Absyn.Program po;
   Absyn.Path patho;
   GraphicEnvCache envo;
   Boolean invalidate = false;
   FCore.Cache fcache;
   FCore.Graph env;
algorithm
  if Flags.isSet(Flags.NF_API) then
    env_2 := GRAPHIC_ENV_FULL_CACHE(p, p_class, FCore.emptyCache(), FGraph.empty());
    return;
  end if;

  // see if we have it already
  ocache := getGlobalRoot(Global.interactiveCache);
  if isSome(ocache) then
    SOME(cache) := ocache;
    for x in cache loop
      (po, patho, envo) := x;
      // found the path
      if AbsynUtil.pathEqual(patho, p_class) then
        // make sure the program did not change
        if referenceEq(po, p) then
          //print("Got it from cache: " + AbsynUtil.pathString(patho) + "\n");
          env_2 := envo;
          return;
        else // program not the same, invalidate cache
          //print("Invalidating: " + AbsynUtil.pathString(patho) + "\n");
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

  (fcache, env) := getClassEnv_dispatch(p, p_class);
  env_2 := GRAPHIC_ENV_FULL_CACHE(p, p_class, fcache, env);


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
  input tuple<Absyn.Program, Absyn.Path, GraphicEnvCache> entry;
  output Boolean matches;
protected
  Absyn.Path po;
algorithm
  (_, po, _) := entry;
  matches := AbsynUtil.pathEqual(po, p);
end matchPath;

public function getClassEnv_dispatch
" Retrieves the environment of the class,
   including the frame of the class itself
   by partially instantiating it."
  input Absyn.Program p;
  input Absyn.Path p_class;
  output FCore.Cache cache;
  output FCore.Graph env_2;
protected
  list<SCode.Element> p_1;
  FCore.Graph env,env_1,env2;
  SCode.Element cl;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  ClassInf.State ci_state;
algorithm
  p_1 := AbsynToSCode.translateAbsyn2SCode(p);
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
        (cache,env_2,_,_,_) =
          Inst.partialInstClassIn(cache,env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), DAE.NOPRE(), ci_state, cl, SCode.PUBLIC(), {}, 0);
      then env_2;

    else FGraph.empty();
  end matchcontinue;
end getClassEnv_dispatch;

uniontype ComponentProperties
  record PROPERTIES
    Boolean isFinal;
    Boolean isFlow;
    Boolean isStream;
    Boolean isProtected;
    Boolean isReplaceable;
    Absyn.Variability variability;
    Absyn.InnerOuter innerOuter;
    Absyn.Direction direction;
  end PROPERTIES;
end ComponentProperties;

public function setComponentProperties
  input Absyn.Path classPath;
  input String component;
  input list<Boolean> prefixes; // final, flow, [stream], protected, replaceable
  input String variability;
  input Boolean innerPrefix;
  input Boolean outerPrefix;
  input String direction;
  input output Absyn.Program program;
        output Values.Value result;
protected
  Boolean is_final, is_flow, is_stream, is_protected, is_replaceable;
  Absyn.Variability var;
  Absyn.InnerOuter io;
  Absyn.Direction dir;
  ComponentProperties props;
algorithm
  try
    if listLength(prefixes) == 5 then
      {is_final, is_flow, is_stream, is_protected, is_replaceable} := prefixes;
      // Creating a component that is both flow and stream will cause the Absyn
      // to SCode translation to fail, which breaks the scripting environment.
      false := is_flow and is_stream;
    else
      {is_final, is_flow, is_protected, is_replaceable} := prefixes;
      is_stream := false;
    end if;

    props := ComponentProperties.PROPERTIES(
      is_final, is_flow, is_stream, is_protected, is_replaceable,
      setElementVariability(variability),
      setInnerOuterAttributes(innerPrefix, outerPrefix),
      setElementCausality(direction)
    );

    program := transformPathedClassInProgram(classPath, program,
      function setComponentPropertiesInClass(component = component, properties = props));
    result := ValuesUtil.makeBoolean(true);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end setComponentProperties;

protected function setComponentPropertiesInClass
  input output Absyn.Class cls;
  input String component;
  input ComponentProperties properties;
protected
  Absyn.ClassDef body;
algorithm
  body := cls.body;

  cls.body := match body
    case Absyn.ClassDef.PARTS()
      algorithm
        body.classParts := setComponentPropertiesInClassparts(body.classParts, component, properties);
      then
        body;

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        body.parts := setComponentPropertiesInClassparts(body.parts, component, properties);
      then
        body;
  end match;
end setComponentPropertiesInClass;

protected function setComponentPropertiesInClassparts
  input list<Absyn.ClassPart> inParts;
  input String component;
  input ComponentProperties properties;
  output list<Absyn.ClassPart> outParts;
algorithm
  outParts := matchcontinue inParts
    local
      list<Absyn.ElementItem> publst, protlst, elts;
      Absyn.Element elt;
      list<Absyn.ClassPart> parts, rest;
      Absyn.ClassPart part;

    case {} then {};
    case parts guard properties.isProtected /* public moved to protected protected moved to public */
      algorithm
        publst := InteractiveUtil.getPublicList(parts);
        Absyn.ELEMENTITEM(elt) := List.getMemberOnTrue(component, publst, AbsynUtil.isElementItemNamed);
        elt := setComponentPropertiesInElement(elt, component, properties);
        publst := deleteOrUpdateComponentFromElementitems(component, publst, NONE()); // TODO: Do not move the component...
        protlst := InteractiveUtil.getProtectedList(parts);
        protlst := List.appendElt(Absyn.ELEMENTITEM(elt), protlst);
        parts := InteractiveUtil.replaceProtectedList(parts, protlst);
        parts := InteractiveUtil.replacePublicList(parts, publst);
      then
        parts;

    case parts guard not properties.isProtected /* protected moved to public protected attr not changed. */
      algorithm
        protlst := InteractiveUtil.getProtectedList(parts);
        Absyn.ELEMENTITEM(elt) := List.getMemberOnTrue(component, protlst, AbsynUtil.isElementItemNamed);
        elt := setComponentPropertiesInElement(elt, component, properties);
        protlst := deleteOrUpdateComponentFromElementitems(component, protlst, NONE()); // TODO: Do not move the component...
        publst := InteractiveUtil.getPublicList(parts);
        publst := List.appendElt(Absyn.ELEMENTITEM(elt), publst);
        parts := InteractiveUtil.replacePublicList(parts, publst);
        parts := InteractiveUtil.replaceProtectedList(parts, protlst);
      then
        parts;

    case Absyn.PUBLIC(contents = elts) :: rest /* protected attr not changed. protected attr not changed, 2. */
      algorithm
        rest := setComponentPropertiesInClassparts(rest, component, properties);
        elts := setComponentPropertiesInElementitems(elts, component, properties);
      then
        Absyn.PUBLIC(elts) :: rest;

    case Absyn.PROTECTED(contents = elts) :: rest /* protected attr not changed, 2. */
      algorithm
        rest := setComponentPropertiesInClassparts(rest, component, properties);
        elts := setComponentPropertiesInElementitems(elts, component, properties);
      then
        Absyn.PROTECTED(elts) :: rest;

    case part :: rest /* protected attr not changed, 3. */
      algorithm
        rest := setComponentPropertiesInClassparts(rest, component, properties);
      then
        part :: rest;

  end matchcontinue;
end setComponentPropertiesInClassparts;

protected function setComponentPropertiesInElementitems
  input output list<Absyn.ElementItem> items;
  input String component;
  input ComponentProperties properties;
algorithm
  items := List.findAndMap(items, function AbsynUtil.isElementItemNamed(name = component),
    function setComponentPropertiesInElementItem(component = component, properties = properties));
end setComponentPropertiesInElementitems;

protected function setComponentPropertiesInElementItem
  input output Absyn.ElementItem item;
  input String component;
  input ComponentProperties properties;
algorithm
  () := match item
    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        item.element := setComponentPropertiesInElement(item.element, component, properties);
      then
        ();
  end match;
end setComponentPropertiesInElementItem;

protected function setComponentPropertiesInElement
  input output Absyn.Element element;
  input String component;
  input ComponentProperties properties;
protected
  Absyn.ElementSpec spec;
algorithm
  () := match element
    case Absyn.Element.ELEMENT(specification = spec as Absyn.ElementSpec.COMPONENTS())
      algorithm
        element.finalPrefix := properties.isFinal;
        element.redeclareKeywords := setReplaceableKeywordAttributes(element.redeclareKeywords, properties.isReplaceable);
        element.innerOuter := properties.innerOuter;
        spec.attributes := setElementAttributes(spec.attributes, properties);
        element.specification := spec;
      then
        ();
  end match;
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
  input Boolean isInner;
  input Boolean isOuter;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  outInnerOuter := match (isInner, isOuter)
    case (false, false) then Absyn.NOT_INNER_OUTER();
    case (true , false) then Absyn.INNER();
    case (false, true)  then Absyn.OUTER();
    else Absyn.INNER_OUTER();
  end match;
end setInnerOuterAttributes;

protected function setElementVariability
"Sets Variability according to string value."
  input String inString;
  output Absyn.Variability outVariability;
algorithm
  outVariability := match inString
    case ""          then Absyn.VAR();
    case "discrete"  then Absyn.DISCRETE();
    case "parameter" then Absyn.PARAM();
    case "constant"  then Absyn.CONST();
  end match;
end setElementVariability;

protected function setElementCausality
"Sets Direction (causality) according to string value."
  input String inString;
  output Absyn.Direction outDirection;
algorithm
  outDirection := match inString
    case ""       then Absyn.BIDIR();
    case "input"  then Absyn.INPUT();
    case "output" then Absyn.OUTPUT();
  end match;
end setElementCausality;

protected function setElementAttributes
  input output Absyn.ElementAttributes attributes;
  input ComponentProperties properties;
algorithm
  attributes := Absyn.ElementAttributes.ATTR(
    properties.isFlow,
    properties.isStream,
    attributes.parallelism,
    properties.variability,
    properties.direction,
    attributes.isField,
    attributes.arrayDim
  );
end setElementAttributes;

public function getCrefInfo
" author: adrpo@ida
   date  : 2005-11-03, changed 2006-02-05 to match new SOURCEINFO
   Retrieves the Info attribute of a Class.
   When parsing classes, the source:
   file name + isReadOnly + start lineno + start columnno + end lineno + end columnno is added to the Class
   definition and to all Elements, see SourceInfo. This function retrieves the
   Info contents."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  SourceInfo info;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    info := cls.info;
    result := ValuesUtil.makeArray({
      ValuesUtil.makeCodeTypeNameStr(Testsuite.friendly(info.fileName)),
      ValuesUtil.makeCodeTypeNameStr(if info.isReadOnly then "readonly" else "writable"),
      ValuesUtil.makeInteger(info.lineNumberStart),
      ValuesUtil.makeInteger(info.columnNumberStart),
      ValuesUtil.makeInteger(info.lineNumberEnd),
      ValuesUtil.makeInteger(info.columnNumberEnd)
    });
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
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
        path_str = AbsynUtil.pathString(path);
        str = stringAppendList({"kind=named, id=",id,", path=",path_str});
      then
        str;
    case (Absyn.QUAL_IMPORT(path = path))
      equation
        path_str = AbsynUtil.pathString(path);
        str = stringAppendList({"kind=qualified, path=",path_str});
      then
        str;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation
        path_str = AbsynUtil.pathString(path);
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
  input Absyn.Element inElement;
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
        path_str = AbsynUtil.pathString(path);
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
        {names} = InteractiveUtil.getComponentItemsNameAndComment(lst, inElement);
        flowPrefixstr = InteractiveUtil.attrFlowStr(attr);
        streamPrefixstr = InteractiveUtil.attrStreamStr(attr);
        variability_str = InteractiveUtil.attrVariabilityStr(attr);
        dir_str = InteractiveUtil.attrDirectionStr(attr);
        names_str = stringDelimitList(names, ", ");
        str = stringAppendList({"elementtype=component, typename=",typename,", names={", names_str,"}, flow=",flowPrefixstr,
        ", stream=",streamPrefixstr,", variability=\"",variability_str,"\", direction=\"", dir_str, "\""});
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
      Absyn.Element el;

    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,restriction = restr,info = SOURCEINFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))))) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = InteractiveUtil.innerOuterStr(inout);
        str_restriction = AbsynUtil.restrString(restr) "compile the classdef string" ;
        element_str = stringAppendList(
          {"elementtype=classdef, classname=",id,
          ", classrestriction=",str_restriction});
        file = Testsuite.friendly(file);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = if isReadOnly then "readonly" else "writable";
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=\"",inout_str,"\", ",element_str});
      then
        str;
    case (Absyn.ELEMENTITEM(element = el as Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = inout,specification = elementSpec,info = SOURCEINFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))) /* if is not a classdef, just follow the normal stuff */
      equation
        finalPrefix = boolString(f);
        r_1 = keywordReplaceable(r);
        repl = boolString(r_1);
        inout_str = InteractiveUtil.innerOuterStr(inout);
        element_str = getElementType(elementSpec, el);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = if isReadOnly then "readonly" else "writable";
        file = Testsuite.friendly(file);
        str = stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",finalPrefix,
          ", replaceable=",repl,", inout=\"",inout_str,"\", ",element_str});
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
  input String visibility;
  input list<Absyn.ElementItem> elements;
  output String result;
protected
  list<String> elements_strl = {};
  String element_str;
algorithm
  for e in elements loop
    element_str := getElementInfo(e);
    element_str := stringAppendList({"{ rec(elementvisibility=", visibility, ", ", element_str, ") }"});
    elements_strl := element_str :: elements_strl;
  end for;

  elements_strl := Dangerous.listReverseInPlace(elements_strl);
  result := stringDelimitList(elements_strl, ",\n");

  if not listEmpty(elements) then
    result := result + "\n";
  end if;
end constructElementsInfo;

protected function appendNonEmptyStrings
" author: adrpo@ida
   date  : 2005-11-11
   helper to get_elements_info
   input: \"\", \"\", \",\" => \"\"
          \"some\", \"\", \",\" => \"some\"
          \"some\", \"some\", \",\" => \"some, some\""
  input String str1;
  input String str2;
  input String delim;
  output String outString;
algorithm
  if stringEmpty(str1) then
    outString := str2;
  elseif stringEmpty(str2) then
    outString := str1;
  else
    outString := stringAppendList({str1, delim, str2});
  end if;
end appendNonEmptyStrings;

public function getElementsInfo
" author: adrpo@ida
   date  : 2005-11-11, changed 2006-02-06 to mirror the new SOURCEINFO
   Retrieves the Info attribute of an element.
   When parsing elements of the class composition, the source:
    -> file name + readonly + start lineno + start columnno + end lineno + end columnno is added to the Element
   and to the Class definition, see SourceInfo.
   This function retrieves the Info contents of the elements of a class."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  String result_str, public_str, protected_str;
  Absyn.Class cls;
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> public_elems, protected_elems;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    parts := AbsynUtil.getClassPartsInClass(cls);
    public_str := constructElementsInfo("public", InteractiveUtil.getPublicList(parts));
    protected_str := constructElementsInfo("protected", InteractiveUtil.getProtectedList(parts));
    result_str := appendNonEmptyStrings(public_str, protected_str, ", ");
    result_str := stringAppendList({"{ ", result_str, " }"});
  else
    result_str := "Error";
  end try;

  // getElementsInfo uses a format that can't be represented as a Value, fake it with a CodeType.
  result := ValuesUtil.makeCodeTypeNameStr(result_str);
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
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        filename = AbsynUtil.classFilename(cdef);
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
        cdef = InteractiveUtil.getPathedClassInProgram(path, p);
        within_ = InteractiveUtil.buildWithin(path);
        cdef_1 = AbsynUtil.setClassFilename(cdef, filename);
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
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
      GraphicEnvCache env;
      Absyn.Program newp,p;

    case (p_class,inherit_class,p as Absyn.PROGRAM())
      equation
        within_ = InteractiveUtil.buildWithin(p_class);
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        cdef_1 = removeExtendsModifiersInClass(cdef, inherit_class, env, keepRedeclares);
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp, true);
    else (inProgram, false);
  end matchcontinue;
end removeExtendsModifiers;

protected function removeExtendsModifiersInClass
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input GraphicEnvCache inEnv;
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
      GraphicEnvCache env;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    /* a class with parts */
    case (outClass as Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),info = file_info),
          inherit_name, env)
      equation
        parts_1 = removeExtendsModifiersInClassparts(parts, inherit_name, env, keepRedeclares);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts_1,ann,cmt);
      then outClass;
    /* adrpo: handle also model extends M end M; */
    case (outClass as Absyn.CLASS(name = id,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,parts = parts,modifications=modif,ann=ann,comment = cmt),info = file_info),
          inherit_name, env)
      equation
        parts_1 = removeExtendsModifiersInClassparts(parts, inherit_name, env, keepRedeclares);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts_1,ann);
      then outClass;
  end match;
end removeExtendsModifiersInClass;

protected function removeExtendsModifiersInClassparts
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Path inPath;
  input GraphicEnvCache inEnv;
  input Boolean keepRedeclares;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inPath,inEnv, keepRedeclares)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      Absyn.Path inherit;
      GraphicEnvCache env;
      Absyn.ClassPart elt;

    case ({},_,_,_) then {};

    case ((Absyn.PUBLIC(contents = elts) :: rest), inherit, env, _)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env, keepRedeclares);
        elts_1 = removeExtendsModifiersInElementitems(elts, inherit, env, keepRedeclares);
      then
        (Absyn.PUBLIC(elts_1) :: res);

    case ((Absyn.PROTECTED(contents = elts) :: rest), inherit, env, _)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env, keepRedeclares);
        elts_1 = removeExtendsModifiersInElementitems(elts, inherit, env, keepRedeclares);
      then
        (Absyn.PROTECTED(elts_1) :: res);

    case ((elt :: rest), inherit, env, _)
      equation
        res = removeExtendsModifiersInClassparts(rest, inherit, env,  keepRedeclares);
      then
        (elt :: res);

  end matchcontinue;
end removeExtendsModifiersInClassparts;

protected function removeExtendsModifiersInElementitems
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Path inPath;
  input GraphicEnvCache inEnv;
  input Boolean keepRedeclares;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inPath,inEnv,keepRedeclares)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      Absyn.Path inherit;
      GraphicEnvCache env;
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
  input GraphicEnvCache inEnv;
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
      GraphicEnvCache env;
      Absyn.Element elt;
      Option<Absyn.Annotation> annOpt;

    case (Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = i,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs,annotationOpt=annOpt),info = info,constrainClass = constr),
      inherit,env)
      equation
        (_, path_1) = mkFullyQual(env, path);
        true = AbsynUtil.pathEqual(inherit, path_1);
        eargs = if not keepRedeclares then {} else list(e for e guard(match e case Absyn.REDECLARATION() then true; else false; end match) in eargs);
      then
        Absyn.ELEMENT(f,r,i,Absyn.EXTENDS(path,eargs,annOpt),info,constr);
    else inElement;
  end matchcontinue;
end removeExtendsModifiersInElement;

public function mkFullyQual
  input GraphicEnvCache env;
  input Absyn.Path ipath;
  output FCore.Cache ocache;
  output Absyn.Path opath;
protected
  Absyn.Path cpath;
  Absyn.Program program;
algorithm
  if Flags.isSet(Flags.NF_API) then
    ocache := cacheFromGraphicEnvCache(env);
    (program, cpath) := cacheProgramAndPath(env);
    opath := NFApi.mkFullyQual(program, cpath, ipath);
  else
    (ocache, opath) := Inst.makeFullyQualified(cacheFromGraphicEnvCache(env), envFromGraphicEnvCache(env), ipath);
  end if;
end mkFullyQual;

public function getExtendsModifierValue
" Return the submodifier value of an extends clause
   for instance,
   model test extends A(p1=3,p2(z=3));end test;
   getExtendsModifierValue(test,A,p1) => 3"
  input Absyn.Path classPath;
  input Absyn.Path extendsPath;
  input Absyn.Path modifierPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  list<Absyn.ElementArg> ext_mod;
algorithm
  try
    SOME(Absyn.EXTENDS(elementArg = ext_mod)) :=
      InteractiveUtil.getPathedExtendsInProgram(classPath, extendsPath, program);
    result := ValuesUtil.makeCodeTypeNameStr(Dump.printExpStr(getModificationValue(ext_mod, modifierPath)));
  else
    result := ValuesUtil.makeCodeTypeNameStr("");
  end try;
end getExtendsModifierValue;

public function isExtendsModifierFinal
  "Returns true if the given modifier on an extends clause is final, for instance:
     model test extends A(final p1 = 3); end test;
     isExtendsModifierFinal(test, A, p1) => true"
  input Absyn.Path classPath;
  input Absyn.Path extendsPath;
  input Absyn.Path modifierPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  list<Absyn.ElementArg> ext_mod;
algorithm
  try
    SOME(Absyn.EXTENDS(elementArg = ext_mod)) :=
      InteractiveUtil.getPathedExtendsInProgram(classPath, extendsPath, program);
    result := ValuesUtil.makeBoolean(isModifierfinal(ext_mod, modifierPath));
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
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
    case ((Absyn.MODIFICATION(finalPrefix = f,path = p1,modification = SOME(_)) :: _),p2) guard AbsynUtil.pathEqual(p1, p2)
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

function makeExtendsFullyQualified
" Makes an EXTENDS ElementSpec having a
   fully qualified extends path."
  input Absyn.ElementSpec inElementSpec;
  input GraphicEnvCache inEnv;
  output Absyn.ElementSpec outElementSpec;
algorithm
  outElementSpec:=
  match (inElementSpec,inEnv)
    local
      Absyn.Path path_1,path;
      list<Absyn.ElementArg> earg;
      GraphicEnvCache env;
      Option<Absyn.Annotation> annOpt;

    case (Absyn.EXTENDS(path = path,elementArg = earg,annotationOpt=annOpt),env)
      equation
        (_, path_1) = mkFullyQual(env, path);
      then
        Absyn.EXTENDS(path_1,earg,annOpt);
  end match;
end makeExtendsFullyQualified;

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
    within_ := InteractiveUtil.buildWithin(path);
    cls := InteractiveUtil.getPathedClassInProgram(path, inProgram);
    cls := InteractiveUtil.clearComponentModifiersInClass(cls, inComponentName, keepRedeclares);
    outProgram := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := true;
  else
    outProgram := inProgram;
    outResult := false;
  end try;
end removeComponentModifiers;

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
    cls_path := AbsynUtil.crefToPath(classRef);
    name := AbsynUtil.crefIdent(varRef);
    cls := InteractiveUtil.getPathedClassInProgram(cls_path, program);
    Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification =
      SOME(Absyn.CLASSMOD(elementArgLst = args)))) := InteractiveUtil.getComponentInClass(cls, name);
    valueStr := Dump.printExpStr(getModificationValue(args, AbsynUtil.crefToPath(subModRef)));
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
      case Absyn.MODIFICATION() guard AbsynUtil.pathEqual(arg.path, path)
        algorithm
          SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = value))) := arg.modification;
        then
          true;

      case Absyn.MODIFICATION(path = Absyn.IDENT(name = name))
          guard name == AbsynUtil.pathFirstIdent(path)
        algorithm
          SOME(Absyn.CLASSMOD(elementArgLst = rest_args)) := arg.modification;
          value := getModificationValue(rest_args, AbsynUtil.pathRest(path));
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
        p_class = AbsynUtil.crefToPath(class_);
        Absyn.IDENT(name) = AbsynUtil.crefToPath(ident);
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        comps = InteractiveUtil.getComponentsInClass(cdef);
        compelts = List.map(comps, InteractiveUtil.getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(component=Absyn.COMPONENT(modification=SOME(Absyn.CLASSMOD(elementArgLst=elementArgLst))))} = List.select1(compelts_1, InteractiveUtil.componentitemNamed, name);
        mod = getModificationValues(elementArgLst, AbsynUtil.crefToPath(subident));
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
    case ((Absyn.MODIFICATION(path = p1,modification = SOME(mod)) :: _),p2) guard AbsynUtil.pathEqual(p1, p2)
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
        cdef = InteractiveUtil.getPathedClassInProgram(path, p);
        comps = InteractiveUtil.getComponentsInClass(cdef);
        compelts = List.map(comps, InteractiveUtil.getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,SOME(Absyn.CLASSMOD(mod,_))),_,_)} = List.select1(compelts_1, InteractiveUtil.componentitemNamed, inComponentName);
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
        name = AbsynUtil.pathString(p);
        names = getModificationNames(rest);
      then
        (name :: names);
        // modifier with submodifiers -and- binding, e.g. m(...)=2, add also m to list
    case ((Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,Absyn.EQMOD()))) :: rest))
      equation
        name = AbsynUtil.pathString(p);
        names2 = list(stringAppend(stringAppend(name, "."), n) for n in getModificationNames(args));
        names = getModificationNames(rest);
        res = listAppend(names2, names);
      then
        name::res;
      // modifier with submodifiers, e.g. m(...)
    case ((Absyn.MODIFICATION(path = p,modification = SOME(Absyn.CLASSMOD(args,_))) :: rest))
      equation
        name = AbsynUtil.pathString(p);
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
    cls := InteractiveUtil.getPathedClassInProgram(path, program);
    component := InteractiveUtil.getComponentInClass(cls, parameterName);
    bindingStr := Dump.printExpStr(InteractiveUtil.getVariableBindingInComponentitem(component));
  else
    bindingStr := "";
  end try;
end getComponentBinding;

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

public function renameClass
  "This function renames a class (given as a qualified path name) to a
   new name -in the same scope-. All references to the class name in the
   program is updated to the new name. The function does not allow a
   renaming that will move the class to another package. To do this, the
   class must be copied."
  input Absyn.Path oldName;
  input Absyn.Path newName;
  input output Absyn.Program program;
        output Values.Value result;
protected
  FCore.Graph env;
  Absyn.Path new_name;
  list<Absyn.Path> paths;
algorithm
  if AbsynUtil.pathIsQual(newName) then
    result := ValuesUtil.makeBoolean(false);
  end if;

  if AbsynUtil.pathIsQual(oldName) then
    new_name := AbsynUtil.joinPaths(AbsynUtil.stripLast(oldName), newName);
  else
    new_name := newName;
  end if;

  // For now, renaming a class clears all caches...
  // Substantial analysis required to find out what to keep in cache and what must be thrown out
  (_, env) := Inst.makeEnvFromProgram(SymbolTable.getSCode());
  ((program, _, (_, _, _, paths, _))) :=
    AbsynUtil.traverseClasses(program, NONE(), renameClassVisitor, (oldName, new_name, program, {}, env), true);
  result := ValuesUtil.makeCodeTypeNameArray(paths);
end renameClass;

protected function renameClassVisitor
" This visitor renames a class given a new name.
   It returns a list of strings of renamed classes.
   The 'traversal-tuple' is therefore
   tuple<oldname, newname, program, string list, env>."
  input output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<Absyn.Path>, FCore.Graph>> tup;
algorithm
  tup := matchcontinue tup
    local
      Absyn.Path path_1,pa,old_class_path,new_class_path;
      String new_name,id;
      Boolean changed;
      SourceInfo file_info;
      Absyn.Program p;
      list<Absyn.Path> path_lst;
      FCore.Graph env,cenv;
      Absyn.Class class_1,class_;
      tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<Absyn.Path>, FCore.Graph> args;

    // Skip readonly classes.
    case ((class_ as Absyn.CLASS(info = file_info), _, _))
      guard isReadOnly(file_info)
      then tup;

    case ((class_ as Absyn.CLASS(name = id), SOME(pa), (old_class_path,new_class_path,p,path_lst,env)))
      algorithm
        path_1 := AbsynUtil.joinPaths(pa, Absyn.IDENT(id));
        true := AbsynUtil.pathEqual(old_class_path, path_1);
        new_name := AbsynUtil.pathLastIdent(new_class_path);
        class_.name := new_name;
      then
        ((class_,SOME(pa), (old_class_path,new_class_path,p, new_class_path :: path_lst, env)));

    case ((class_ as Absyn.CLASS(name = id), NONE(), (old_class_path,new_class_path,p,path_lst,env)))
      algorithm
        path_1 := Absyn.IDENT(id);
        true := AbsynUtil.pathEqual(old_class_path, path_1);
        new_name := AbsynUtil.pathLastIdent(new_class_path);
        class_.name := new_name;
      then
        ((class_,NONE(), (old_class_path,new_class_path,p, new_class_path :: path_lst, env)));

    case (((class_ as Absyn.CLASS(name = id)), SOME(pa), (old_class_path,new_class_path,p,path_lst,env)))
      algorithm
        path_1 := AbsynUtil.joinPaths(pa, Absyn.IDENT(id));
        cenv := getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) := renameClassInClass(class_, old_class_path, new_class_path, cenv);

        if changed then
          path_lst := path_1 :: path_lst;
        end if;
      then
        ((class_1,SOME(pa), (old_class_path,new_class_path,p, path_lst, env)));

    case (((class_ as Absyn.CLASS(name = id)), NONE(), (old_class_path,new_class_path,p,path_lst,env)))
      algorithm
        path_1 := Absyn.IDENT(id);
        cenv := getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) := renameClassInClass(class_, old_class_path, new_class_path, cenv);

        if changed then
          path_lst := path_1 :: path_lst;
        end if;
      then
        ((class_1,NONE(), (old_class_path,new_class_path,p, path_lst, env)));

    else tup;
  end matchcontinue;
end renameClassVisitor;

protected function renameClassInClass
  "helper function to renameClassVisitor
   renames all the references to a class to another"
  input output Absyn.Class cls;
  input Absyn.Path oldName;
  input Absyn.Path newName;
  input FCore.Graph env;
        output Boolean changed;
protected
  list<Absyn.ClassPart> parts;
  String name;
  Absyn.Path path;
  FCore.Graph cenv;
  FCore.Cache cache;
  Absyn.ClassDef body;
  Absyn.TypeSpec ty;
algorithm
  body := cls.body;

  changed := matchcontinue body
    case Absyn.PARTS(classParts = parts)
      algorithm
        (parts, changed) := renameClassInParts(parts, oldName, newName, env);
        body.classParts := parts;
        cls.body := body;
      then
        changed;

    case Absyn.CLASS_EXTENDS(parts = parts)
      algorithm
        (parts, changed) := renameClassInParts(parts, oldName, newName, env);
        body.parts := parts;
        cls.body := body;
      then
        changed;

    case Absyn.DERIVED(typeSpec = ty as Absyn.TPATH())
      algorithm
        (cache, SCode.CLASS(name=name),cenv) := Lookup.lookupClass(FCore.emptyCache(), env, ty.path);
        path := Absyn.IDENT(name);
        (_, path) := Inst.makeFullyQualified(cache, cenv, path);
        true := AbsynUtil.pathEqual(path, oldName);
        ty.path := changeLastIdent(path, newName);
        body.typeSpec := ty;
        cls.body := body;
      then
        true;

    else false;
  end matchcontinue;
end renameClassInClass;

protected function renameClassInParts
"author: x02lucpo
  helper function to renameClassVisitor"
  input list<Absyn.ClassPart> parts;
  input Absyn.Path oldName;
  input Absyn.Path newName;
  input FCore.Graph env;
  output list<Absyn.ClassPart> outParts = {};
  output Boolean changed = false;
protected
  Boolean c;
  list<Absyn.ElementItem> elems;
algorithm
  for part in parts loop
    part := match part
      case Absyn.ClassPart.PUBLIC()
        algorithm
          (elems, c) := renameClassInElements(part.contents, oldName, newName, env);
          part.contents := elems;
          changed := changed or c;
        then
          part;

      case Absyn.ClassPart.PROTECTED()
        algorithm
          (elems, c) := renameClassInElements(part.contents, oldName, newName, env);
          part.contents := elems;
          changed := changed or c;
        then
          part;

      else part;
    end match;

    outParts := part :: outParts;
  end for;

  outParts := Dangerous.listReverseInPlace(outParts);
end renameClassInParts;

protected function renameClassInElements
  input list<Absyn.ElementItem> items;
  input Absyn.Path oldName;
  input Absyn.Path newName;
  input FCore.Graph env;
  output list<Absyn.ElementItem> outItems = {};
  output Boolean changed = false;
protected
  Absyn.Element elem;
  Absyn.ElementSpec spec;
  Boolean c;
algorithm
  for item in items loop
    (outItems, changed) := matchcontinue item
      case Absyn.ElementItem.ELEMENTITEM(element = elem as Absyn.Element.ELEMENT())
        algorithm
          (spec, c) := renameClassInElementSpec(elem.specification, oldName, newName, env);
          elem.specification := spec;
          item.element := elem;
        then
          (item :: outItems, changed or c);

      else (item :: outItems, changed);
    end matchcontinue;
  end for;

  outItems := Dangerous.listReverseInPlace(outItems);
end renameClassInElements;

protected function renameClassInElementSpec
  input output Absyn.ElementSpec spec;
  input Absyn.Path oldName;
  input Absyn.Path newName;
  input FCore.Graph env;
        output Boolean changed = false;
protected
  Absyn.TypeSpec ty;
  FCore.Cache cache;
  String id;
  FCore.Graph cenv;
  Absyn.Path path, qpath;
  Absyn.Import imp;
algorithm
  changed := matchcontinue spec
    case Absyn.COMPONENTS(typeSpec = ty as Absyn.TPATH())
      algorithm
        (cache, SCode.CLASS(name = id), cenv) := Lookup.lookupClass(FCore.emptyCache(), env, ty.path);
        (_, qpath) := Inst.makeFullyQualified(cache, cenv, Absyn.IDENT(id));

        if AbsynUtil.pathEqual(qpath, oldName) then
          ty.path := changeLastIdent(qpath, newName);
          spec.typeSpec := ty;
          changed := true;
        end if;
      then
        changed;

    case Absyn.EXTENDS()
      algorithm
        (cache, _, cenv) := Lookup.lookupClass(FCore.emptyCache(), env, spec.path);
        (_, qpath) := Inst.makeFullyQualified(cache, cenv, spec.path);

        if AbsynUtil.pathEqual(qpath, oldName) then
          spec.path := changeLastIdent(spec.path, newName);
          changed := true;
        end if;
      then
        changed;

    case Absyn.IMPORT()
      algorithm
        path := AbsynUtil.importPath(spec.import_);
        (cache, _, cenv) := Lookup.lookupClass(FCore.emptyCache(), env, path);
        (_, qpath) := Inst.makeFullyQualified(cache, cenv, path);

        if AbsynUtil.pathEqual(qpath, oldName) then
          path := changeLastIdent(path, newName);
          spec.import_ := AbsynUtil.setImportPath(spec.import_, path);
          changed := true;
        end if;
      then
        changed;

    else false;
  end matchcontinue;
end renameClassInElementSpec;

public function refactorClass
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cls;
    Absyn.Program p;
    String str;
  algorithm
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    cls := Refactor.refactorGraphicalAnnotation(program, cls);
    p := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, Absyn.TOP()), program);
    SymbolTable.setAbsyn(p);
    str := Dump.unparseStr(Absyn.PROGRAM({cls}, Absyn.TOP()), false);
    result := ValuesUtil.makeString(str);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl,
    evaluateParams = true, graphicsExpMode = true, accessLevel = Access.icon);
end refactorClass;

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
        b_1 = AbsynUtil.pathLastIdent(p2);
      then
        Absyn.IDENT(b_1);
    case ((p1 as Absyn.QUALIFIED()),(p2 as Absyn.IDENT()))
      equation
        a_1 = AbsynUtil.stripLast(p1);
        res = AbsynUtil.joinPaths(a_1, p2);
      then
        res;
    case ((p1 as Absyn.QUALIFIED()),(p2 as Absyn.QUALIFIED()))
      equation
        a_1 = AbsynUtil.stripLast(p1);
        b_1 = AbsynUtil.pathLastIdent(p2);
        res = AbsynUtil.joinPaths(a_1, Absyn.IDENT(b_1));
      then
        res;
  end match;
end changeLastIdent;

public function isPrimitive
"Thisfunction takes a component reference and a program.
  It returns the true if the refrenced type is a primitive
  type, otherwise it returns false."
  input Absyn.Path className;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm
  outBoolean := match className
    local
      Absyn.Class class_;
    /* Instead of elaborating and lookup these in env, we optimize a bit and just return true for these */
    case Absyn.IDENT(name = "Real") then true;
    case Absyn.IDENT(name = "Integer") then true;
    case Absyn.IDENT(name = "String") then true;
    case Absyn.IDENT(name = "Boolean") then true;
    case _
      algorithm
        class_ := InteractiveUtil.getPathedClassInProgram(className, inProgram);
      then
        isPrimitiveClass(class_, inProgram);
    else false;
  end match;
end isPrimitive;

public function createModel
  input Absyn.Path className;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
protected
  Absyn.Ident name;
  Absyn.Within w;
  Absyn.Path wp;
algorithm
  if AbsynUtil.pathIsIdent(className) then
    name := AbsynUtil.pathFirstIdent(className);
    w := Absyn.TOP();
  else
    (wp, Absyn.IDENT(name)) := AbsynUtil.splitQualAndIdentPath(className);
    w := Absyn.WITHIN(wp);
  end if;

  outProgram := InteractiveUtil.updateProgram(Absyn.PROGRAM({
    Absyn.CLASS(name, false, false, false, Absyn.R_MODEL(), AbsynUtil.dummyParts,
        {}, {}, AbsynUtil.dummyInfo)}, w), inProgram);
end createModel;

public function newModel
  input Absyn.Path className;
  input Absyn.Path withinPath;
  input output Absyn.Program program;
algorithm
  program := createModel(AbsynUtil.joinPaths(withinPath, className), program);
end newModel;

public function deleteClass
  "Deletes the given class from the program."
  input Absyn.Path classPath;
  input Absyn.Program inProgram;
  output Boolean success;
  output Absyn.Program outProgram = inProgram;
algorithm
  (success, outProgram) := matchcontinue inProgram
    local
      Absyn.Path parentcpath,parentparentcpath;
      Absyn.Class cdef,parentcdef,parentcdef_1;

    case _
      equation
        //Class inside another class, inside another class
        parentcpath = AbsynUtil.stripLast(classPath);
        parentparentcpath = AbsynUtil.stripLast(parentcpath);
        cdef = InteractiveUtil.getPathedClassInProgram(classPath, inProgram);
        parentcdef = InteractiveUtil.getPathedClassInProgram(parentcpath, inProgram);
        parentcdef_1 = InteractiveUtil.removeInnerClass(cdef, parentcdef);
        outProgram = InteractiveUtil.updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.WITHIN(parentparentcpath)), inProgram);
      then
        (true, outProgram);
    case _
      equation
        // Class inside other class
        parentcpath = AbsynUtil.stripLast(classPath);
        cdef = InteractiveUtil.getPathedClassInProgram(classPath, inProgram);
        parentcdef = InteractiveUtil.getPathedClassInProgram(parentcpath, inProgram);
        parentcdef_1 = InteractiveUtil.removeInnerClass(cdef, parentcdef);
        outProgram = InteractiveUtil.updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.TOP()), inProgram);
      then
        (true, outProgram);
    case _
      algorithm
        // Top level class
        cdef := InteractiveUtil.getPathedClassInProgram(classPath, inProgram);
        outProgram.classes := List.deleteMemberOnTrue(AbsynUtil.className(cdef),
          outProgram.classes, AbsynUtil.isClassNamed);
      then
        (true, outProgram);

    else (false,inProgram);
  end matchcontinue;
end deleteClass;

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
        within_ = InteractiveUtil.buildWithin(p_class);
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        cdef_1 = setClassCommentInClass(cdef, str);
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,true);

    else (inProgram,false);
  end matchcontinue;
end setClassComment;

protected function setClassCommentInClass
  "Helper function to setClassComment"
  input output Absyn.Class cls;
  input String commentString;
algorithm
  cls.body := setClassCommentInClassdef(cls.body, commentString);
end setClassCommentInClass;

protected function setClassCommentInClassdef
  "Helper function to setClassCommentInClass"
  input output Absyn.ClassDef classDef;
  input String commentString;
protected
  Option<String> cmt_str;
algorithm
  cmt_str := if stringEmpty(commentString) then NONE() else SOME(commentString);

  () := match classDef
    case Absyn.ClassDef.PARTS()
      algorithm
        classDef.comment := cmt_str;
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        classDef.comment := AbsynUtil.setCommentString(classDef.comment, cmt_str);
      then
        ();

    case Absyn.ClassDef.ENUMERATION()
      algorithm
        classDef.comment := AbsynUtil.setCommentString(classDef.comment, cmt_str);
      then
        ();

    case Absyn.ClassDef.OVERLOAD()
      algorithm
        classDef.comment := AbsynUtil.setCommentString(classDef.comment, cmt_str);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        classDef.comment := cmt_str;
      then
        ();

    case Absyn.ClassDef.PDER()
      algorithm
        classDef.comment := AbsynUtil.setCommentString(classDef.comment, cmt_str);
      then
        ();

    else ();
  end match;
end setClassCommentInClassdef;

public function getShortDefinitionBaseClassInformation
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.TypeSpec ty;
  Absyn.ElementAttributes attr;
  list<Values.Value> vals = {};
algorithm
  try
    Absyn.CLASS(body = Absyn.DERIVED(typeSpec = ty, attributes = attr as Absyn.ATTR())) :=
      InteractiveUtil.getPathedClassInProgram(classPath, program);
    vals := ValuesUtil.makeArray(InteractiveUtil.dimensionListValues(AbsynUtil.typeSpecDimensions(ty))) :: vals;
    vals := ValuesUtil.makeString(InteractiveUtil.attrDirectionStr(attr)) :: vals;
    vals := ValuesUtil.makeString(InteractiveUtil.attrVariabilityStr(attr)) :: vals;
    vals := ValuesUtil.makeString(if attr.streamPrefix then "stream" else "") :: vals;
    vals := ValuesUtil.makeString(if attr.flowPrefix then "flow" else "") :: vals;
    vals := ValuesUtil.makeCodeTypeName(AbsynUtil.typeSpecPath(ty)) :: vals;
  else
    vals := {};
  end try;

  result := ValuesUtil.makeArray(vals);
end getShortDefinitionBaseClassInformation;

public function getExternalFunctionSpecification
  input Absyn.Path functionName;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  Absyn.ExternalDecl ext_decl;
  Option<Absyn.Annotation> ann;
  list<Values.Value> vals = {};
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(functionName, program);
    Absyn.EXTERNAL(ext_decl, ann) := AbsynUtil.getExternalDecl(cls);

    vals := ValuesUtil.makeString(Dump.unparseAnnotationOption(ann)) :: vals;
    vals := ValuesUtil.makeString(Dump.unparseAnnotationOption(ext_decl.annotation_)) :: vals;
    vals := ValuesUtil.makeString(Dump.printExpLstStr(ext_decl.args)) :: vals;
    vals := ValuesUtil.makeString(Util.getOptionOrDefault(ext_decl.funcName, "")) :: vals;
    vals := ValuesUtil.makeString(Util.applyOptionOrDefault(ext_decl.output_, Dump.printComponentRefStr, "")) :: vals;
    vals := ValuesUtil.makeString(Util.getOptionOrDefault(ext_decl.lang, "")) :: vals;
  else
    vals := {};
  end try;

  result := ValuesUtil.makeArray(vals);
end getExternalFunctionSpecification;

protected function getClassDimensions
  "Returns the dimensions of a class as vector of dimension sizes in a string.
   Note: A class can only have dimensions if it is a short class definition."
  input Absyn.ClassDef cdef;
  output String str;
protected
  Absyn.ArrayDim ad;
algorithm
  str := match cdef
    case Absyn.DERIVED(typeSpec = Absyn.TPATH(arrayDim = SOME(ad)))
      then List.toString(ad, Dump.printSubscriptStr, "", "{", ",", "}");
    else "{}";
  end match;
end getClassDimensions;

public function getClassRestriction
  "Returns the class restriction of a class as a string."
  input Absyn.Path path;
  input Absyn.Program program;
  output String outRestriction;
protected
  Absyn.Restriction restr;
algorithm
  try
    Absyn.CLASS(restriction = restr) := InteractiveUtil.getPathedClassInProgram(path, program);
    outRestriction := Dump.unparseRestrictionStr(restr);
  else
    outRestriction := "";
  end try;
end getClassRestriction;

public function isType
  "Returns true if the referenced class has the restriction 'type', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_TYPE() then true;
    else false;
  end match;
end isType;

public function isConnector
  "Returns true if the referenced class has the restriction 'connector' or
  'expandable connector', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_CONNECTOR() then true;
    case Absyn.R_EXP_CONNECTOR() then true;
    else false;
  end match;
end isConnector;

public function isModel
  "Returns true if the referenced class has the restriction 'model', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_MODEL() then true;
    else false;
  end match;
end isModel;

public function isOperator
  "Returns true if the referenced class has the restriction 'operator', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_OPERATOR() then true;
    else false;
  end match;
end isOperator;

public function isOperatorRecord
  "Returns true if the referenced class has the restriction 'operator record', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_OPERATOR_RECORD() then true;
    else false;
  end match;
end isOperatorRecord;

public function isOperatorFunction
  "Returns true if the referenced class has the restriction 'operator function', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()) then true;
    else false;
  end match;
end isOperatorFunction;

public function isRecord
  "Returns true if the referenced class has the restriction 'record', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_RECORD() then true;
    else false;
  end match;
end isRecord;

public function isBlock
  "Returns true if the referenced class has the restriction 'block', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_BLOCK() then true;
    else false;
  end match;
end isBlock;

public function isOptimization
  "Returns true if the referenced class has the restriction 'optimization', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_OPTIMIZATION() then true;
    else false;
  end match;
end isOptimization;

public function isFunction
  "Returns true if the referenced class has the restriction 'function', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION()) then true;
    else false;
  end match;
end isFunction;

public function isPackage
  "Returns true if the referenced class has the restriction 'package', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_PACKAGE() then true;
    else false;
  end match;
end isPackage;

public function isClass
  "Returns true if the referenced class has the restriction 'class', otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  res := match InteractiveUtil.getPathedClassRestriction(path, program)
    case Absyn.R_CLASS() then true;
    else false;
  end match;
end isClass;

public function isPartial
  "Returns true if the referenced class is partial, otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  try
    Absyn.CLASS(partialPrefix=true) := InteractiveUtil.getPathedClassInProgram(path, program);
    res := true;
  else
    res := false;
  end try;
end isPartial;

public function isReplaceable
  "Returns true if the referenced element is replaceable, otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  try
    res := AbsynUtil.isElementReplaceable(InteractiveUtil.getPathedElementInProgram(path, program));
  else
    res := false;
  end try;
end isReplaceable;

public function isRedeclare
  "Returns true if the referenced element is a redeclare, otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  try
    res := AbsynUtil.isElementRedeclare(InteractiveUtil.getPathedElementInProgram(path, program));
  else
    res := false;
  end try;
end isRedeclare;

public function isParameter
  "This function takes a class and a component reference and a program
   and returns true if the component referenced is a parameter."
  input Absyn.Path componentName;
  input Absyn.Path className;
  input Absyn.Program program;
  output Boolean res;
protected
  Absyn.Path path;
  Absyn.Element elem;
algorithm
  try
    path := AbsynUtil.joinPaths(className, componentName);
    Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.PARAM()))) :=
      InteractiveUtil.getPathedElementInProgram(path, program);
    res := true;
  else
    res := false;
  end try;
end isParameter;

public function isConstant
  "This function takes a class and a component reference and a program
   and returns true if the component referenced is a constant."
  input Absyn.Path componentName;
  input Absyn.Path className;
  input Absyn.Program program;
  output Boolean res;
protected
  Absyn.Path path;
  Absyn.Element elem;
algorithm
  try
    path := AbsynUtil.joinPaths(className, componentName);
    Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.CONST()))) :=
      InteractiveUtil.getPathedElementInProgram(path, program);
    res := true;
  else
    res := false;
  end try;
end isConstant;

public function isProtected
  "This function takes a class and a component reference and a program
   and returns true if the component referenced is in a protected section."
  input Absyn.Path componentName;
  input Absyn.Path className;
  input Absyn.Program program;
  output Boolean res;
protected
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> items;
algorithm
  try
    parts := AbsynUtil.getClassPartsInClass(InteractiveUtil.getPathedClassInProgram(className, program));
    items := InteractiveUtil.getProtectedList(parts);
    getComponentsContainsName(AbsynUtil.pathToCref(componentName), items);
    res := true;
  else
    res := false;
  end try;
end isProtected;

public function isEnumeration
  "Returns true if the referenced class is an enumeration, otherwise false."
  input Absyn.Path path;
  input Absyn.Program program;
  output Boolean res;
algorithm
  try
    Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.ENUMERATION()) :=
      InteractiveUtil.getPathedClassInProgram(path, program);
    res := true;
  else
    res := false;
  end try;
end isEnumeration;

public function isProtectedClass
  "Returns true if the class referenced by className within path is protected.
   Only look to Element Items of inComponentRef1 for components use getComponents."
  input Absyn.Path path;
  input String className;
  input Absyn.Program program;
  output Boolean res;
protected
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> items;
algorithm
  try
    parts := AbsynUtil.getClassPartsInClass(InteractiveUtil.getPathedClassInProgram(path, program));
    items := InteractiveUtil.getProtectedList(parts);
    res := isProtectedClassInElements(items, className);
  else
    res := false;
  end try;
end isProtectedClass;

protected function isProtectedClassInElements
  "Helper function to isProtectedClass."
  input list<Absyn.ElementItem> items;
  input String className;
  output Boolean res = false;
protected
  String name;
algorithm
  for item in items loop
    res := match item
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
            Absyn.CLASSDEF(class_ = Absyn.CLASS(name = name))))
        then name == className;
      else false;
    end match;

    if res then
      break;
    end if;
  end for;
end isProtectedClassInElements;

public function getEnumerationLiterals
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  list<Absyn.EnumLiteral> literals;
  list<String> names;
algorithm
  try
    Absyn.CLASS(body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = literals))) :=
      InteractiveUtil.getPathedClassInProgram(classPath, program);
    names := list(AbsynUtil.enumLiteralName(l) for l in literals);
  else
    names := {};
  end try;

  result := ValuesUtil.makeStringArray(names);
end getEnumerationLiterals;

public function getDerivedClassModifierNames
  "Returns the derived class modifier names."
  input Absyn.Class inClass;
  output list<String> outString;
protected
  list<Absyn.ElementArg> args;
algorithm
  outString := match inClass
    case Absyn.CLASS(restriction = Absyn.R_TYPE(), body = Absyn.DERIVED(arguments = args))
      then getModificationNames(args);
    else {};
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
  "Returns true if the referenced class exists in the program, otherwise false."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Boolean res;
algorithm
  try
    InteractiveUtil.getPathedClassInProgram(classPath, program);
    res := true;
  else
    res := false;
  end try;
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
        inmodel = AbsynUtil.crefToPath(Absyn.CREF_IDENT(cname,{}));
        (cdef,_) = lookupClassdef(path, inmodel, p);
        res = isPrimitiveClass(cdef, p);
      then
        res;
    else false;
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
        newpath = AbsynUtil.joinPaths(path, path2);
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
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 1 Looking for: " + AbsynUtil.pathString(path) + " in: " + AbsynUtil.pathString(inmodel));
        // remove self reference, otherwise we go into an infinite loop!
        path = InstUtil.removeSelfReference(AbsynUtil.pathLastIdent(inmodel),path);
        inmodeldef = InteractiveUtil.getPathedClassInProgram(inmodel, p) "Look first inside \'inmodel\'" ;
        cdef = InteractiveUtil.getPathedClassInProgram(path, Absyn.PROGRAM({inmodeldef},Absyn.TOP()));
        newpath = AbsynUtil.joinPaths(inmodel, path);
      then
        (cdef,newpath);

    case (path,inmodel,p) /* Then look inside next level */
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 2 Looking for: " + AbsynUtil.pathString(path) + " in: " + AbsynUtil.pathString(inmodel));
        innewpath = AbsynUtil.stripLast(inmodel);
        (cdef,respath) = lookupClassdef(path, innewpath, p);
      then
        (cdef,respath);

    case (path,_,p)
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 3 Looking for: " + AbsynUtil.pathString(path) + " in: " + AbsynUtil.pathString(inmodel));
        cdef = InteractiveUtil.getPathedClassInProgram(path, p) "Finally look in top level" ;
      then
        (cdef,path);

    case (Absyn.IDENT(name = "Real"),_,_) then (Absyn.CLASS("Real",false,false,false,Absyn.R_PREDEFINED_REAL(),
          AbsynUtil.dummyParts,{},{},AbsynUtil.dummyInfo),Absyn.IDENT("Real"));

    case (Absyn.IDENT(name = "Integer"),_,_) then (Absyn.CLASS("Integer",false,false,false,Absyn.R_PREDEFINED_INTEGER(),
          AbsynUtil.dummyParts,{},{},AbsynUtil.dummyInfo),Absyn.IDENT("Integer"));

    case (Absyn.IDENT(name = "String"),_,_) then (Absyn.CLASS("String",false,false,false,Absyn.R_PREDEFINED_STRING(),
          AbsynUtil.dummyParts,{},{},AbsynUtil.dummyInfo),Absyn.IDENT("String"));

    case (Absyn.IDENT(name = "Boolean"),_,_) then (Absyn.CLASS("Boolean",false,false,false,Absyn.R_PREDEFINED_BOOLEAN(),
          AbsynUtil.dummyParts,{},{},AbsynUtil.dummyInfo),Absyn.IDENT("Boolean"));
    // BTH
    case (Absyn.IDENT(name = "Clock"),_,_)
      equation
        true = Config.synchronousFeaturesAllowed();
      then (Absyn.CLASS("Clock",false,false,false,Absyn.R_PREDEFINED_CLOCK(),
          AbsynUtil.dummyParts,{},{},AbsynUtil.dummyInfo),Absyn.IDENT("Clock"));

    case (path,inmodel,_)
      equation
        //fprintln(Flags.INTER, "Interactive.lookupClassdef 8 Looking for: " + AbsynUtil.pathString(path) + " in: " + AbsynUtil.pathString(inmodel));
        s1 = AbsynUtil.pathString(path);
        s2 = AbsynUtil.pathString(inmodel);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,s2});
      then
        fail();
  end matchcontinue;
end lookupClassdef;

protected function deleteOrUpdateComponent
" This function deletes a component from a class given the name of the
   component instance, the model in which the component is instantiated in,
   and the Program. Both public and protected lists are searched."
  input String componentName;
  input Absyn.Path classPath;
  input output Absyn.Program program;
  input Option<tuple<Absyn.Path, Absyn.ComponentItem>> item;
protected
  Absyn.Within w;
  Absyn.Class cls;
algorithm
  w := if AbsynUtil.pathIsIdent(classPath) then Absyn.Within.TOP() else Absyn.Within.WITHIN(AbsynUtil.stripLast(classPath));
  cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
  cls := deleteOrUpdateComponentFromClass(componentName, cls, item);
  program := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, w), program);
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
    case (name,outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann = ann,comment = cmt),
                           info = file_info))
      equation
        publst = InteractiveUtil.getPublicList(parts);
        (publst2, success) = deleteOrUpdateComponentFromElementitems(name, publst, item);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        if (/*delete case*/(intEq(l1_1, l2) and boolNot(isSome(item)) and success) or
            /*update case*/(boolNot(intEq(l1_1, l2)) and isSome(item)) and success) then
          parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        else
          protlst = InteractiveUtil.getProtectedList(parts);
          protlst2 = deleteOrUpdateComponentFromElementitems(name, protlst, item);
          parts2 = InteractiveUtil.replaceProtectedList(parts, protlst2);
        end if;
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then outClass;

     // adrpo search also in model extends X end X
    case (name,outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                           body = Absyn.CLASS_EXTENDS(baseClassName=bcpath, modifications=mod, parts = parts,ann = ann,comment = cmt),
                           info = file_info))
      equation
        publst = InteractiveUtil.getPublicList(parts);
        (publst2, success) = deleteOrUpdateComponentFromElementitems(name, publst, item);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        if (/*delete case*/(intEq(l1_1, l2) and boolNot(isSome(item)) and success) or
            /*update case*/(boolNot(intEq(l1_1, l2)) and isSome(item)) and success) then
          parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        else
          protlst = InteractiveUtil.getProtectedList(parts);
          protlst2 = deleteOrUpdateComponentFromElementitems(name, protlst, item);
          parts2 = InteractiveUtil.replaceProtectedList(parts, protlst2);
        end if;
        outClass.body = Absyn.CLASS_EXTENDS(bcpath,mod,cmt,parts2,ann);
      then outClass;
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
                if AbsynUtil.pathEqual(tppath, AbsynUtil.typeSpecPath(spec.typeSpec)) then
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

public function addComponent
  "Adds a component to the program."
  input String componentName;
  input Absyn.Path typeName;
  input Absyn.Path classPath;
  input Absyn.Exp bindingExp;
  input Absyn.Modification modifier;
  input Absyn.Exp commentExp;
  input Absyn.Exp annotationExp;
  input output Absyn.Program program;
  output Boolean success = true;
protected
  String name, filename;
  Absyn.Class cdef;
  Option<Absyn.Comment> annotation_;
  Option<Absyn.Modification> modification;
  Absyn.Within w;
  Absyn.InnerOuter io;
  Option<Absyn.RedeclareKeywords> redecl;
  Absyn.ElementAttributes attr;
  SourceInfo info;
  Absyn.Path ty_path;
algorithm
  try
    w := match classPath
      case Absyn.IDENT() then Absyn.TOP();
      else Absyn.WITHIN(AbsynUtil.stripLast(classPath));
    end match;

    (cdef as Absyn.CLASS(info=SOURCEINFO(fileName=filename))) :=
      InteractiveUtil.getPathedClassInProgram(classPath, program);
    info := SOURCEINFO(filename, false, 0, 0, 0, 0, 0.0);

    annotation_ := InteractiveUtil.makeCommentFromArgs(commentExp, annotationExp);
    modification := InteractiveUtil.makeModifierFromArgs(bindingExp, modifier, info);
    (io, redecl, attr) := getDefaultPrefixes(program, typeName);

    ty_path := AbsynUtil.pathStripSamePrefix(typeName, classPath);

    if AbsynUtil.pathContains(classPath, AbsynUtil.pathFirstIdent(ty_path)) then
      // Keep the full type name if the first identifier of the stripped name
      // is part of the class path, to avoid name collisions.
      ty_path := typeName;
    end if;

    cdef := addToPublic(cdef,
      Absyn.ELEMENTITEM(
        Absyn.ELEMENT(false, redecl, io,
          Absyn.COMPONENTS(attr, Absyn.TPATH(ty_path, NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(componentName, {}, modification), NONE(), annotation_)}),
          info, NONE())
      )
    );
    program := InteractiveUtil.updateProgram(Absyn.PROGRAM({cdef}, w), program);
  else
    success := false;
  end try;
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
      str = getNamedAnnotationExp(className,p,Absyn.IDENT("defaultComponentPrefixes"),SOME("{}"),getDefaultComponentPrefixesModStr);
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

public function getDefaultComponentPrefixesModStr "Extractor function for defaultComponentPrefixes modifier"
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

public function updateComponent
" This function updates a component in a class. The reason for having
   thisfunction is that a deletion followed by an addition would mean that
   all optional arguments must be present to the add_componentfunction
   in order to get the same component attributes,etc. as previous."
  input String componentName;
  input Absyn.Path typeName;
  input Absyn.Path classPath;
  input Absyn.Exp bindingExp;
  input Absyn.Modification modifier;
  input Absyn.Exp commentExp;
  input Absyn.Exp annotationExp;
  input output Absyn.Program program;
  output Boolean success = true;
protected
  list<Absyn.ClassPart> parts;
  list<Absyn.ElementItem> publst, protlst;
  list<Absyn.ComponentItem> items;
  Absyn.ArrayDim arrayDimensions;
  Option<Absyn.Modification> mod, modification;
  Option<Absyn.Exp> cond;
  Option<Absyn.Comment> ann, annotation_;
algorithm
  try
    Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) := InteractiveUtil.getPathedClassInProgram(classPath, program);
    publst := InteractiveUtil.getPublicList(parts);
    protlst := InteractiveUtil.getProtectedList(parts);
    Absyn.ELEMENT(_,_,_,Absyn.COMPONENTS(_,Absyn.TPATH(_,_),items),_,_) := getElementContainsName(Absyn.CREF_IDENT(componentName,{}), listAppend(publst, protlst));
    Absyn.COMPONENTITEM(Absyn.COMPONENT(_,arrayDimensions,mod),cond,ann) := getCompitemNamed(Absyn.CREF_IDENT(componentName,{}), items);
    annotation_ := InteractiveUtil.makeCommentFromArgs(commentExp, annotationExp, ann);
    modification := InteractiveUtil.makeModifierFromArgs(bindingExp, modifier, AbsynUtil.dummyInfo, mod);
    program := deleteOrUpdateComponent(componentName, classPath, program, SOME((typeName, Absyn.COMPONENTITEM(Absyn.COMPONENT(componentName,arrayDimensions,modification),cond,annotation_))));
  else
    success := false;
    /* adrpo: TODO!: handle also model extends M end M; i.e. CLASS_EXTENDS */
  end try;
end updateComponent;

public function deleteComponent
  "Deletes a component from the program."
  input String componentName;
  input Absyn.Path classPath;
  input output Absyn.Program program;
  output Boolean success = true;
algorithm
  try
    program := deleteOrUpdateComponent(componentName, classPath, program, NONE());
  else
    success := false;
  end try;
end deleteComponent;

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
  class_path := AbsynUtil.crefToPath(inClass);
  cls := InteractiveUtil.getPathedClassInProgram(class_path, inProgram);
  cls := addClassAnnotationToClass(cls, InteractiveUtil.annotationListToAbsyn(inAnnotation));
  class_within := if AbsynUtil.pathIsIdent(class_path) then
    Absyn.TOP() else Absyn.WITHIN(AbsynUtil.stripLast(class_path));
  outProgram := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, class_within), inProgram);
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
        body.ann := {List.fold(body.ann, AbsynUtil.mergeAnnotations, inAnnotation)};
      then
        body;

    case Absyn.DERIVED()
      algorithm
        body.comment := AbsynUtil.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.ENUMERATION()
      algorithm
        body.comment := AbsynUtil.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.OVERLOAD()
      algorithm
        body.comment := AbsynUtil.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;

    case Absyn.CLASS_EXTENDS()
      algorithm
        body.ann := {List.fold(body.ann, AbsynUtil.mergeAnnotations, inAnnotation)};
      then
        body;

    case Absyn.PDER()
      algorithm
        body.comment := AbsynUtil.mergeCommentAnnotation(inAnnotation, body.comment);
      then
        body;
  end match;

  outClass := AbsynUtil.setClassBody(inClass, body);
end addClassAnnotationToClass;

protected function getInheritedClassesHelper
"Helper function to getInheritedClasses."
  input SCode.Element inClass1;
  input Absyn.Class inClass2;
  input FCore.Graph inEnv4;
  output list<Absyn.Path> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inClass1,inClass2,inEnv4)
    local
      list<Absyn.Path> lst;
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
        if SCodeUtil.isDerivedClass(c) then
          // for derived classes search in the parent
          env_2 := env;
        else
          // for non-derived classes search from self
          env2 := FGraph.openScope(env, encflag, id, FGraph.restrictionToScopeType(restr));
          ci_state := ClassInf.start(restr, FGraph.getGraphName(env2));
          (_,env_2,_,_,_) :=
            Inst.partialInstClassIn(FCore.emptyCache(),env2,InnerOuter.emptyInstHierarchy,
            DAE.NOMOD(), DAE.NOPRE(), ci_state, c, SCode.PUBLIC(), {}, 0);
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
  if Flags.isSet(Flags.NF_API) then
    outPaths := NFApi.getInheritedClasses(inPath, SymbolTable.getAbsyn());
    return;
  end if;

try

  if not Flags.isSet(Flags.NF_API_NOISE) then
    ErrorExt.setCheckpoint("getInheritedClasses");
  end if;

  outPaths := matchcontinue inPath
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<SCode.Element> p_1;
      FCore.Graph env,env_1;
      SCode.Element c;
      list<Absyn.Path> lst;
      Absyn.Program p;
      list<Absyn.ElementSpec> extendsLst;
      FCore.Cache cache;
      list<Absyn.Path> paths;

    case (modelpath)
      equation
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        p_1 = SymbolTable.getSCode();
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,(c as SCode.CLASS()),env_1) = Lookup.lookupClass(cache,env, modelpath);
        paths = getInheritedClassesHelper(c, cdef, env_1);
        failure({} = paths);
      then
        paths;
    case (modelpath) /* if above fails, baseclass not defined. return its name */
      equation
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, SymbolTable.getAbsyn());
        extendsLst = getExtendsInClass(cdef);
        paths = List.map(extendsLst, AbsynUtil.elementSpecToPath);
      then
        paths;
    else {};
  end matchcontinue;

  if not Flags.isSet(Flags.NF_API_NOISE) then
    ErrorExt.rollBack("getInheritedClasses");
  end if;

else
  if not Flags.isSet(Flags.NF_API_NOISE) then
    ErrorExt.rollBack("getInheritedClasses");
  end if;
end try;

end getInheritedClasses;

public function getInheritanceCount
"This function takes a Path and a Program and
  returns the number of inherited classes in the class
  referenced by the Path."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  Integer count;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    result := ValuesUtil.makeInteger(countBaseClasses(cls));
  else
    result := ValuesUtil.makeInteger(0);
  end try;
end getInheritanceCount;

public function getNthInheritedClass
"This function takes a Path, an integer and a Program and returns
  the nth inherited class in the class referenced by the Path."
  input Absyn.Path classPath;
  input Integer n;
  output Values.Value result;
protected
  Absyn.Class cls;
  FCore.Graph env;
  FCore.Cache cache;
  SCode.Element elem;
  Absyn.Path path;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, SymbolTable.getAbsyn());
    (cache, env) := Inst.makeEnvFromProgram(SymbolTable.getSCode());

    try
      (_, elem as SCode.CLASS(), env) := Lookup.lookupClass(cache, env, classPath);
      result := ValuesUtil.makeCodeTypeName(getNthInheritedClass2(elem, cls, n, env));
    else
      // if above fails, baseclass not defined. return its name
      Absyn.EXTENDS(path = path) := listGet(getExtendsInClass(cls), n);
      result := ValuesUtil.makeCodeTypeName(path);
    end try;
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
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
        p_1 = AbsynToSCode.translateAbsyn2SCode(p);
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
        s = AbsynUtil.pathString(path);
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

public function getNthInheritedClassIconMapAnnotation
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Integer n;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  algorithm
    result := getNthInheritedClassMapAnnotation(classPath, n, program, "IconMap");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, function impl(n = n), evaluateParams = true);
end getNthInheritedClassIconMapAnnotation;

public function getNthInheritedClassDiagramMapAnnotation
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Integer n;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  algorithm
    result := getNthInheritedClassMapAnnotation(classPath, n, program, "DiagramMap");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, function impl(n = n), evaluateParams = true);
end getNthInheritedClassDiagramMapAnnotation;

protected function getNthInheritedClassMapAnnotation
"This function takes a Path, an integer and a Program and returns
  the ANNOTATION on the extends of the nth inherited class in the class referenced by the ComponentRef."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  input String mapType "IconMap or DiagramMap";
  output Values.Value result;
protected
  Absyn.Class cls;
  String s, annStr;
  Option<Absyn.Annotation> opt_ann;
  list<Absyn.ElementArg> args;
algorithm
  cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
  (s, opt_ann) := getNthInheritedClassAnnotationOpt(classPath, n, cls, program);

  annStr := match opt_ann
    case SOME(Absyn.ANNOTATION(args)) then getMapAnnotationStr(args, mapType, cls, program, classPath);
    else "{}";
  end match;

  result := InteractiveUtil.makeAnnotationArrayValue({s, annStr});
end getNthInheritedClassMapAnnotation;

protected function getExtendsInClass
  "Returns all ElementSpec of EXTENDS in a class."
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outExtends;
protected
  list<Absyn.ClassPart> parts;
algorithm
  outExtends := match inClass
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) then getExtendsInParts(parts);
    /* adrpo: TODO! how about model extends M(modifications) end M??
                    should we report EXTENDS(IDENT(M), modifications)? */
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)) then getExtendsInParts(parts);
    else {};
  end match;
end getExtendsInClass;

protected function getExtendsInParts
  input list<Absyn.ClassPart> parts;
  output list<Absyn.ElementSpec> outExtends = {};
protected
  Absyn.ElementSpec spec;
algorithm
  for part in parts loop
    for el in AbsynUtil.getElementItemsInClassPart(part) loop
      outExtends := match el
        case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = spec as Absyn.EXTENDS()))
          then spec :: outExtends;
        else outExtends;
      end match;
    end for;
  end for;

  outExtends := Dangerous.listReverseInPlace(outExtends);
end getExtendsInParts;

protected function getNthInheritedClass2
"Helper function to getNthInheritedClass."
  input SCode.Element element;
  input Absyn.Class cls;
  input Integer n;
  input FCore.Graph env;
  output Absyn.Path baseClass;
protected
  String id;
  SCode.Encapsulated enc;
  SCode.Restriction restr;
  list<Absyn.Path> extends_lst;
  FCore.Graph cenv;
  ClassInf.State ci_state;
  Absyn.Class c;
algorithm
  SCode.CLASS(name = id, encapsulatedPrefix = enc, restriction = restr) := element;

  if SCodeUtil.isDerivedClass(element) then
    // for derived classes, search in parents
    extends_lst := getBaseClasses(cls, env);
  else
    // for non-derived classes, search from inside the class
    cenv := FGraph.openScope(env, enc, id, FGraph.restrictionToScopeType(restr));
    ci_state := ClassInf.start(restr, FGraph.getGraphName(cenv));
    (_, cenv, _, _, _) := Inst.partialInstClassIn(FCore.emptyCache(), cenv,
      InnerOuter.emptyInstHierarchy, DAE.NOMOD(), DAE.NOPRE(), ci_state,
      element, SCode.PUBLIC(), {}, 0);
    extends_lst := getBaseClasses(cls, cenv);
  end if;

  baseClass := listGet(extends_lst, n);
end getNthInheritedClass2;

public function getComponentCount
" This function takes a ComponentRef and a Program and returns the
   number of public components in the class referenced by the ComponentRef."
  input Absyn.Path model_;
  input Absyn.Program p;
  output Integer count;
protected
  Absyn.Class cdef;
algorithm
  cdef := InteractiveUtil.getPathedClassInProgram(model_, p);
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
      Absyn.Class cdef;

    // a class with parts
    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        c1 = countComponents(cdef);
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        c1 = countComponents(cdef);
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.PARTS(classParts = (_ :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        res = countComponents(cdef);
      then
        res;

    case Absyn.CLASS(body = Absyn.PARTS(classParts = {})) then 0;

    // adrpo: handle also an extended class with parts: model extends M end M;
    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PUBLIC(contents = elt) :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        c1 = countComponents(cdef);
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (Absyn.PROTECTED(contents = elt) :: lst),ann=ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        c1 = countComponents(cdef);
        c2 = countComponentsInElts(elt, 0);
      then
        c1 + c2;

    case cdef as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                     body = Absyn.CLASS_EXTENDS(parts = (_ :: lst),ann = ann,comment = cmt),info = file_info)
      equation
        cdef.body = Absyn.PARTS({},{},lst,ann,cmt);
        res = countComponents(cdef);
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

public function getNthComponent
  "This function takes a class path, a program, and an int and returns the name,
   type and comment of that component."
  input Absyn.Path classPath;
  input Absyn.Program program;
  input Integer n;
  output Values.Value result;
protected
  GraphicEnvCache genv;
  Absyn.Class cdef;
algorithm
  try
    genv := InteractiveUtil.createEnvironment(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath);
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);
    result := getNthComponent2(cdef, n, genv);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end getNthComponent;

protected function getNthComponent2
  "Helper function to getNthComponent."
  input Absyn.Class inClass;
  input Integer n;
  input GraphicEnvCache genv;
  output Values.Value result;
protected
  Absyn.Element comp;
  String comp_name, cmt;
  Absyn.Path ty;
algorithm
  comp := InteractiveUtil.getNthComponentInClass(inClass, n);
  (comp_name, ty, cmt) := getComponentInfoOld(comp, genv);

  result := Values.ARRAY({
    ValuesUtil.makeCodeTypeName(ty),
    Values.CODE(Absyn.CodeNode.C_VARIABLENAME(Absyn.ComponentRef.CREF_IDENT(comp_name, {}))),
    ValuesUtil.makeString(cmt)
  }, {3});
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

public function insertQuotesToList
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
  input Absyn.Path classPath;
  input Boolean useQuotes;
  input Absyn.Program program;
  output Values.Value result;
algorithm
  result := getElements(classPath, useQuotes, program, onlyComponents = true);
end getComponents;

public function getElements
  input Absyn.Path classPath;
  input Boolean useQuotes;
  input Absyn.Program program;
  input Boolean onlyComponents = false;
  output Values.Value result;
protected
  Access access;
  Absyn.Class cls;
  Interactive.GraphicEnvCache env;
  Boolean silent;
  list<Values.Value> infos;
  list<Absyn.Element> elems;
algorithm
  try
    access := checkAccessAnnotationAndEncryption(classPath, program);

    if access < Access.icon then // Access.icon
      Error.addMessage(Error.ACCESS_ENCRYPTED_PROTECTED_CONTENTS, {});
      result := ValuesUtil.makeBoolean(false);
      return;
    end if;

    silent := not Flags.isSet(Flags.NF_API_NOISE);
    if silent then
      ErrorExt.setCheckpoint(getInstanceName());
    end if;

    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    env := InteractiveUtil.createEnvironment(program, SOME(SymbolTable.getSCode()), classPath);

    if access >= Access.diagram then // Access.diagram
      elems := InteractiveUtil.getProtectedElementsInClass(cls);
      infos := InteractiveUtil.getElementsInfo(elems, false, useQuotes, onlyComponents, env);
    end if;

    elems := InteractiveUtil.getPublicElementsInClass(cls);
    infos := InteractiveUtil.getElementsInfo(elems, true, useQuotes, onlyComponents, env, infos);

    result := ValuesUtil.makeArray(infos);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;

  if silent then
    ErrorExt.rollBack(getInstanceName());
  end if;
end getElements;

public function getComponentAnnotations " This function takes a `Path\', a `Program\' and
   returns a list of all component annotations, as returned by
   get_nth_component_annotation.
   Both public and protected components are returned, but they need to
   be in the same order as get_componentsfunctions, i.e. first public
   components then protected ones."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cdef;
    list<Absyn.Element> comps;

    OpenModelica.AutoCompletion.Annotations.Access access;
  algorithm
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);

    if accessLevel >= Access.diagram then
      comps := InteractiveUtil.getProtectedComponentsInClass(cdef);
    end if;

    comps := listAppend(InteractiveUtil.getPublicComponentsInClass(cdef), comps);
    result := InteractiveUtil.getElementAnnotationsFromElts(comps, cdef, program, classPath);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl, evaluateParams = true);
end getComponentAnnotations;

public function getElementAnnotations " This function takes a `Path\', a `Program\' and
   returns a list of all element annotations.
   Both public and protected components are returned, but they need to
   be in the same order as get_componentsfunctions, i.e. first public
   components then protected ones."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cdef;
    list<Absyn.Element> elts;
  algorithm
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);

    if accessLevel >= Access.diagram then
      elts := InteractiveUtil.getProtectedElementsInClass(cdef);
    end if;

    elts := listAppend(InteractiveUtil.getPublicElementsInClass(cdef), elts);
    result := InteractiveUtil.getElementAnnotationsFromElts(elts, cdef, program, classPath);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl, evaluateParams = true);
end getElementAnnotations;

public function getNthComponentAnnotation "
   This function takes a `Path\', a `Program\' and an int and
   returns a comma separated string of values corresponding to the flat
   record for component annotations.
"
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Integer n;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cdef;
    Absyn.Element comp;
  algorithm
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);
    comp := InteractiveUtil.getNthComponentInClass(cdef, n);
    result := InteractiveUtil.getElementAnnotationsFromElts({comp}, cdef, program, classPath);

    // Only return an array of arrays if there are multiple components in the same declaration.
    if ValuesUtil.isArray(result) and ValuesUtil.arraySize(result) == 1 then
      result := ValuesUtil.arrayScalar(result);
    end if;
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, function impl(n = n), evaluateParams = true);
end getNthComponentAnnotation;

public function getNthComponentModification
  "Returns the modifier for the n:th component in the given class."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  Absyn.Element comp;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    comp := InteractiveUtil.getNthComponentInClass(cls, n);
    result := getComponentModification(comp);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end getNthComponentModification;

public function getNthComponentCondition
  "Returns the condition of the n:th component in the given class as a string."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  Absyn.Element comp;
  String str;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    comp := InteractiveUtil.getNthComponentInClass(cls, n);
    str := getComponentCondition(comp);
    str := System.trim(str, " ");
    result := ValuesUtil.makeString(str);
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
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
        modelpath = AbsynUtil.crefToPath(model_);
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
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

public function addConnection
  "Adds a connect equation to the model, i.e. connect(c1,c2)"
  input Absyn.Path classPath;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input Absyn.Exp commentExp;
  input Absyn.Exp annotationExp;
  input output Absyn.Program program;
        output Boolean success;
protected
  Absyn.EquationItem eq;
  Option<Absyn.Comment> cmt;
algorithm
  try
    cmt := InteractiveUtil.makeCommentFromArgs(commentExp, annotationExp);
    eq := Absyn.EquationItem.EQUATIONITEM(Absyn.Equation.EQ_CONNECT(connector1, connector2),
      cmt, AbsynUtil.dummyInfo);
    program := transformPathedClassInProgram(classPath, program,
      function addToEquation(inEquationItem = eq));
    success := true;
  else
    success := false;
  end try;
end addConnection;

public function deleteConnection
  "Deletes the connection connect(c1,c2) from a model."
  input Absyn.Path classPath;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input output Absyn.Program program;
        output Boolean success;
algorithm
  try
    program := transformPathedClassInProgram(classPath, program,
      function deleteConnectionInClass(connector1 = connector1, connector2 = connector2));
    success := true;
  else
    success := false;
  end try;
end deleteConnection;

protected function deleteConnectionInClass
"Helper function to deleteConnection."
  input output Absyn.Class cls;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
protected
  list<Absyn.EquationItem> eqlst;
  Absyn.ClassDef cdef;
algorithm
  () := match cls
    /* a class with parts */
    case Absyn.CLASS(body = cdef as Absyn.PARTS())
      algorithm
        eqlst := InteractiveUtil.getEquationList(cdef.classParts);
        eqlst := deleteEquationInEqlist(eqlst, connector1, connector2);
        cdef.classParts := InteractiveUtil.replaceEquationList(cdef.classParts, eqlst);
        cls.body := cdef;
      then
        ();
    /* an extended class with parts: model extends M end M;  */
    case Absyn.CLASS(body = cdef as Absyn.CLASS_EXTENDS())
      algorithm
        eqlst := InteractiveUtil.getEquationList(cdef.parts);
        eqlst := deleteEquationInEqlist(eqlst, connector1, connector2);
        cdef.parts := InteractiveUtil.replaceEquationList(cdef.parts, eqlst);
        cls.body := cdef;
      then
        ();
  end match;
end deleteConnectionInClass;

protected function deleteEquationInEqlist
"Helper function to deleteConnection."
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm
  outAbsynEquationItemLst := match (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> res,xs,loopRes,forEqList;
      Absyn.ForIterators forIterator;
      Absyn.ComponentRef cn1,cn2,c1,c2;
      Absyn.EquationItem x;

    case ({},_,_) then {};
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = cn1,connector2 = cn2)) :: xs),c1,c2)
      guard
        AbsynUtil.crefEqual(c1,cn1) and AbsynUtil.crefEqual(c2,cn2)
      then
        deleteEquationInEqlist(xs, c1, c2);
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR(forEquations = forEqList, iterators = forIterator)) :: xs),c1,c2)
      equation
        res = deleteEquationInEqlist(xs, c1, c2);
        loopRes = deleteEquationInEqlist(forEqList, c1, c2);

        if not listEmpty(loopRes) then
          loopRes = { Absyn.EQUATIONITEM(Absyn.EQ_FOR(forIterator, loopRes), NONE(), AbsynUtil.dummyInfo) };
        end if;
      then
        listAppend(loopRes, res);
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
  (b,outProgram) := addTransitionWithAnnotation(inComponentRef, from, to, condition, immediate, reset, synchronize, priority, InteractiveUtil.annotationListToAbsyn(inAbsynNamedArgLst), inProgram);
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
        modelpath = AbsynUtil.crefToPath(model_);
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        GlobalScript.ISTMTS({GlobalScript.IEXP(conditionExp, _)}, _) = Parser.parsestringexp(condition_);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("transition", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(from_, {})), Absyn.CREF(Absyn.CREF_IDENT(to_, {})),
                                conditionExp}, {Absyn.NAMEDARG("immediate", Absyn.BOOL(immediate_)),
                                Absyn.NAMEDARG("reset", Absyn.BOOL(reset_)), Absyn.NAMEDARG("synchronize", Absyn.BOOL(synchronize_)),
                                Absyn.NAMEDARG("priority", Absyn.INTEGER(priority_))})), cmt, AbsynUtil.dummyInfo));
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},p.within_), p);
      then
        (true, newp);

    case ((model_ as Absyn.CREF_QUAL()), from_, to_, condition_, immediate_, reset_, synchronize_, priority_, ann,(p as Absyn.PROGRAM()))
      equation
        modelpath = AbsynUtil.crefToPath(model_);
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        package_ = AbsynUtil.stripLast(modelpath);
        cmt = SOME(Absyn.COMMENT(SOME(ann), NONE()));
        GlobalScript.ISTMTS({GlobalScript.IEXP(conditionExp, _)}, _) = Parser.parsestringexp(condition_);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("transition", {}),
                                Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(from_, {})), Absyn.CREF(Absyn.CREF_IDENT(to_, {})),
                                conditionExp}, {Absyn.NAMEDARG("immediate", Absyn.BOOL(immediate_)),
                                Absyn.NAMEDARG("reset", Absyn.BOOL(reset_)), Absyn.NAMEDARG("synchronize", Absyn.BOOL(synchronize_)),
                                Absyn.NAMEDARG("priority", Absyn.INTEGER(priority_))})), cmt, AbsynUtil.dummyInfo));
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
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
        modelpath = AbsynUtil.crefToPath(model_);
        modelwithin = AbsynUtil.stripLast(modelpath);
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        newcdef = deleteTransitionInClass(cdef, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (true, newp);
    case (model_, from_, to_, condition_, immediate_, reset_, synchronize_, priority_ ,(p as Absyn.PROGRAM()))
      equation
        modelpath = AbsynUtil.crefToPath(model_);
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        newcdef = deleteTransitionInClass(cdef, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        newp = InteractiveUtil.updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
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
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,ann=ann,comment = cmt),
                      info = file_info), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst_1 = deleteTransitionInEqlist(eqlst, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;
    /* an extended class with parts: model extends M end M;  */
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = bcname,modifications=modif,parts = parts,ann = ann,comment = cmt)
                      ,info = file_info), from_, to_, condition_, immediate_, reset_, synchronize_, priority_)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst_1 = deleteTransitionInEqlist(eqlst, from_, to_, condition_, immediate_, reset_, synchronize_, priority_);
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst_1);
        outClass.body = Absyn.CLASS_EXTENDS(bcname,modif,cmt,parts2,ann);
      then
        outClass;
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
      guard AbsynUtil.crefEqual(name, Absyn.CREF_IDENT("transition", {}))
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

public function getComponentComment
  "Get the component commment."
  input Absyn.Path classPath;
  input Absyn.Path componentName;
  input Absyn.Program program;
  output Values.Value comment;
protected
  Absyn.Path path;
  Absyn.Element elem;
  list<Absyn.ComponentItem> comps;
  Absyn.ComponentItem comp;
  String cmt, comp_name;
algorithm
  path := AbsynUtil.joinPaths(classPath, componentName);
  comp_name := AbsynUtil.pathLastIdent(componentName);
  elem := InteractiveUtil.getPathedElementInProgram(path, program);
  comps := AbsynUtil.getComponentItemsFromElement(elem);
  comp := List.find(comps, function AbsynUtil.isComponentItemNamed(name = comp_name));
  cmt := InteractiveUtil.getClassCommentInCommentOpt(comp.comment);
  comment := ValuesUtil.makeString(cmt);
end getComponentComment;

public function setComponentComment
  input Absyn.Path classPath;
  input Absyn.Path componentName;
  input String comment;
  input output Absyn.Program program;
        output Boolean success;
protected
  Absyn.Path path;
  String comp_name;
algorithm
  try
    path := AbsynUtil.joinPaths(classPath, componentName);
    comp_name := AbsynUtil.pathLastIdent(componentName);
    (program, _, success) := InteractiveUtil.transformPathedElementInProgram(path,
      function setComponentCommentInElement(componentName = comp_name, comment = comment), program);
  else
    success := false;
  end try;
end setComponentComment;

protected function setComponentCommentInElement
  input output Absyn.Element element;
  input String componentName;
  input String comment;
protected
  Absyn.ElementSpec spec;
  list<Absyn.ComponentItem> comps;

  function set_comment
    input output Absyn.ComponentItem item;
    input String comment;
  algorithm
    item.comment := AbsynUtil.setCommentString(item.comment, if stringEmpty(comment) then NONE() else SOME(comment));
  end set_comment;
algorithm
  () := match element
    case Absyn.Element.ELEMENT(specification = spec as Absyn.ElementSpec.COMPONENTS())
      algorithm
        (comps, true) := List.findAndMap(spec.components,
          function AbsynUtil.isComponentItemNamed(name = componentName),
          function set_comment(comment = comment));
        spec.components := comps;
        element.specification := spec;
      then
        ();
  end match;
end setComponentCommentInElement;

public function setConnectionComment
  input Absyn.Path classPath;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
  input output Absyn.Program program;
        output Boolean success;
algorithm
  try
    (program, _, success) := InteractiveUtil.transformPathedElementInProgram(classPath,
      function setConnectionCommentInElement(connector1 = connector1, connector2 = connector2, comment = comment),
      program);
  else
    success := false;
  end try;
end setConnectionComment;

protected function setConnectionCommentInElement
  input output Absyn.Element element;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
protected
  Absyn.ElementSpec spec;
  Absyn.Class cls;
algorithm
  () := match element
    case Absyn.Element.ELEMENT(specification = spec as Absyn.ElementSpec.CLASSDEF())
      algorithm
        cls := setConnectionCommentInClass(spec.class_, connector1, connector2, comment);
        spec.class_ := cls;
        element.specification := spec;
      then
        ();
  end match;
end setConnectionCommentInElement;

protected function setConnectionCommentInClass
  "Sets the comment on the connection of two connectors in a class."
  input output Absyn.Class cls;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
algorithm
  () := match cls
    local
      Absyn.ClassDef cdef;
      list<Absyn.ClassPart> parts;

    case Absyn.CLASS(body = cdef as Absyn.PARTS())
      algorithm
        parts := setConnectionCommentInParts(cdef.classParts, connector1, connector2, comment);
        cdef.classParts := parts;
        cls.body := cdef;
      then
        ();

    case Absyn.CLASS(body = cdef as Absyn.CLASS_EXTENDS())
      algorithm
        parts := setConnectionCommentInParts(cdef.parts, connector1, connector2, comment);
        cdef.parts := parts;
        cls.body := cdef;
      then
        ();
  end match;
end setConnectionCommentInClass;

protected function setConnectionCommentInParts
  input output list<Absyn.ClassPart> parts;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
algorithm
  (parts, true) := List.findMap(parts, function setConnectionCommentInEquationsPart(connector1 = connector1,
    connector2 = connector2, comment = comment));
end setConnectionCommentInParts;

protected function setConnectionCommentInEquationsPart
  input output Absyn.ClassPart part;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
        output Boolean found;
protected
  list<Absyn.EquationItem> eql;
algorithm
  (part, found) := match part
    case Absyn.EQUATIONS()
      algorithm
        (eql, found) := List.findMap(part.contents, function setConnectionCommentInEquation(
          connector1 = connector1, connector2 = connector2, comment = comment));
        part.contents := eql;
      then
        (part, found);

    else (part, false);
  end match;
end setConnectionCommentInEquationsPart;

protected function setConnectionCommentInEquation
  input output Absyn.EquationItem eq;
  input Absyn.ComponentRef connector1;
  input Absyn.ComponentRef connector2;
  input String comment;
        output Boolean success;
protected
  Absyn.ComponentRef c1, c2;
algorithm
  success := match eq
    case Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1, connector2 = c2))
      guard AbsynUtil.crefEqual(connector1, c1) and AbsynUtil.crefEqual(connector2, c2)
      algorithm
        eq.comment := AbsynUtil.setCommentString(eq.comment, if stringEmpty(comment) then NONE() else SOME(comment));
      then
        true;

    else false;
  end match;
end setConnectionCommentInEquation;

public function getNthConnectionAnnotation
"This function takes a ComponentRef and a Program and an int and
  returns a comma separated string  of values for the annotation of
  the nth connection."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Integer n;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cdef;
    Absyn.EquationItem conn;
  algorithm
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);
    conn := listGet(getConnections(cdef), n);
    result := getConnectionAnnotationStr(conn, cdef, program, classPath);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, function impl(n = n),
    evaluateParams = true, accessLevel = Access.diagram);
end getNthConnectionAnnotation;

public function getConnectorCount
"This function takes a ComponentRef and a Program and returns the number
  of connector components in the class given by the classname in the
  ComponentRef. A partial instantiation of the inheritance structure is
  performed in order to find all connectors of the class.
  inputs:  (Absyn.ComponentRef, Absyn.Program)
  outputs: string"
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cdef;
algorithm
  try
    //A complete instantiation is far too expensive. Instead we only
    //look through the components of the class for types declared using
    //the "connector" restricted class keyword. We also look in
    //base classes (recursively).
    cdef := InteractiveUtil.getPathedClassInProgram(classPath, program);
    result := ValuesUtil.makeInteger(countPublicConnectors(classPath, program, cdef));
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end getConnectorCount;

public function getNthConnector
  "Returns the name and type of the n:th connector in the given class."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  Absyn.Class cls;
  String name;
  Absyn.Path ty;
algorithm
  try
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    (SOME((name, ty)), _) := getNthPublicConnectorStr(classPath, cls, program, n);
    result := ValuesUtil.makeCodeTypeNameArray({Absyn.Path.IDENT(name), ty});
  else
    result := ValuesUtil.makeBoolean(false);
  end try;
end getNthConnector;

public function getNthConnectorIconAnnotation
  "Returns the Icon annotation of the type of the n:th public connector in the
   given class."
  input Absyn.Path classPath;
  input Integer n;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Integer n;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cls;
    Absyn.Element comp;
    Absyn.Path ty;
    String str;
  algorithm
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    (SOME((_, ty)), _) := getNthPublicConnectorStr(classPath, cls, program, n);
    result := getIconAnnotation(ty, program);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, function impl(n = n), evaluateParams = true);
end getNthConnectorIconAnnotation;

public function getIconAnnotation
"This function takes a Path and a Program and returns a comma separated
  string of values for the icon annotation for the class named by the
  first argument."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  algorithm
    result := getNamedAnnotationValue(classPath, program, "Icon");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl,
    evaluateParams = true, graphicsExpMode = true, accessLevel = Access.icon);
end getIconAnnotation;

public function refactorIconAnnotation
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cls;
  algorithm
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    cls := Refactor.refactorGraphicalAnnotation(program, cls);
    result := getNamedAnnotationValue(classPath, program, "Icon");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl,
    evaluateParams = true, graphicsExpMode = true, accessLevel = Access.icon);
end refactorIconAnnotation;

public function getDiagramAnnotation
"This function takes a Path and a Program and returns a comma separated
  string of values for the icon annotation for the class named by the
  first argument."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  algorithm
    result := getNamedAnnotationValue(classPath, program, "Diagram");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl,
    evaluateParams = true, graphicsExpMode = true, accessLevel = Access.icon);
end getDiagramAnnotation;

public function refactorDiagramAnnotation
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    Absyn.Class cls;
  algorithm
    cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
    cls := Refactor.refactorGraphicalAnnotation(program, cls);
    result := getNamedAnnotationValue(classPath, program, "Diagram");
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program, impl,
    evaluateParams = true, graphicsExpMode = true, accessLevel = Access.icon);
end refactorDiagramAnnotation;

public function getNamedAnnotation
  input Absyn.Path classPath;
  input Absyn.Path annotationPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  function impl
    input Absyn.Path classPath;
    input Absyn.Path annotationPath;
    input Absyn.Program program;
    input Access accessLevel;
    output Values.Value result;
  protected
    String str;
  algorithm
    str := getNamedAnnotationExp(classPath, program, annotationPath, SOME("{}"), getAnnotationValue);
    result := ValuesUtil.makeCodeTypeNameStr(str);
  end impl;
algorithm
  result := InteractiveUtil.accessClass(classPath, program,
    function impl(annotationPath = annotationPath), evaluateParams = true);
end getNamedAnnotation;

public function getNamedAnnotationExp
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
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        SOME(str) = AbsynUtil.getNamedAnnotationInClass(cdef,id,f);
      then
        str;

    case (_,_,_,SOME(str),_) then str;
  end matchcontinue;
end getNamedAnnotationExp;

public function getStringNamedAnnotation
"Calls getNamedAnnotationExp and makes sure we don't fail if annotation is not String type."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Path id;
  output String outString;
algorithm
  try
    Absyn.STRING(outString) := getNamedAnnotationExp(inPath, inProgram, id, SOME(Absyn.STRING("")), getAnnotationExp);
  else
    outString := "";
  end try;
end getStringNamedAnnotation;

public function getIntegerNamedAnnotation
"Reads the Integer annotation and converts it to String."
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Path id;
  output String outString;
protected
  Absyn.Class cdef;
  Option<Absyn.Exp> exp;
  Integer ann;
algorithm
  try
    cdef := InteractiveUtil.getPathedClassInProgram(inPath, inProgram);
    exp := AbsynUtil.getNamedAnnotationInClass(cdef,id,getAnnotationExp);
    if isSome(exp) then
      SOME(Absyn.INTEGER(ann)) := exp;
      outString := intString(ann);
    else
      outString := "";
    end if;
  else
    outString := "";
  end try;
end getIntegerNamedAnnotation;

function getNamedAnnotationValue
  input Absyn.Path classPath;
  input Absyn.Program program;
  input String name;
  output Values.Value result;
protected
  Absyn.Class cls;
algorithm
  cls := InteractiveUtil.getPathedClassInProgram(classPath, program);
  result := getNamedAnnotationValueInClass(classPath, cls, program, name);
end getNamedAnnotationValue;

function getNamedAnnotationValueInClass
  input Absyn.Path classPath;
  input Absyn.Class cls;
  input Absyn.Program program;
  input String name;
  output Values.Value result;
protected
  Option<Absyn.Modification> mod;
  Absyn.ElementArg arg;
  String str;
algorithm
  mod := AbsynUtil.lookupClassAnnotation(cls, name);

  result := match mod
    case SOME(Absyn.Modification.CLASSMOD())
      algorithm
        arg := Absyn.ElementArg.MODIFICATION(false, Absyn.Each.NON_EACH(),
          Absyn.Path.IDENT(name), mod, NONE(), AbsynUtil.dummyInfo);
        str := getAnnotationString(Absyn.ANNOTATION({arg}), cls, program, classPath);
      then
        InteractiveUtil.makeAnnotationArrayValue({str});

    else ValuesUtil.makeEmptyArray();
  end match;
end getNamedAnnotationValueInClass;

constant Absyn.Path USES_PATH = Absyn.Path.IDENT("uses");

public function getUsesAnnotation
  "Returns the uses-annotations of the top-level classes in the given program."
  input Absyn.Program program;
  output list<Annotation> outUses = {};

  type Annotation = tuple<Absyn.Path, String, list<String>, Boolean>;
protected
  Option<list<Annotation>> opt_uses;
  list<Annotation> uses;
  list<Absyn.Class> classes;
algorithm
  Absyn.PROGRAM(classes = classes) := program;

  for cls in classes loop
    opt_uses := AbsynUtil.getNamedAnnotationInClass(cls, USES_PATH, function getUsesAnnotationString(classOrigin=cls.name));

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
  output list<tuple<Absyn.Path,String,list<String>,Boolean>> usesStr;
protected
  list<Absyn.Path> paths;
  list<list<String>> strs;
  list<String> fromVersions;
algorithm
  usesStr := getUsesAnnotation(p);
  paths := List.map(usesStr,Util.tuple41);
  fromVersions := List.map(usesStr,Util.tuple42);
  strs := List.map(usesStr,Util.tuple43);
  usesStr := list((p,f,s,false) threaded for p in paths, f in fromVersions, s in strs);
end getUsesAnnotationOrDefault;

protected function getUsesAnnotationString
  input Option<Absyn.Modification> mod;
  input String classOrigin;
  output list<tuple<Absyn.Path,String,list<String>,Boolean>> usesStr;
algorithm
  usesStr := match (mod)
    local
      list<Absyn.ElementArg> arglst;

    case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
      then getUsesAnnotationString2(arglst, classOrigin);

  end match;
end getUsesAnnotationString;

protected function getUsesAnnotationString2
  input list<Absyn.ElementArg> eltArgs;
  input String classOrigin;
  output list<tuple<Absyn.Path,String,list<String>,Boolean>> strs;
algorithm
  strs := match eltArgs
    local
      list<Absyn.ElementArg> xs;
      String name,  version;
      list<tuple<Absyn.Path,String,list<String>,Boolean>> ss;
      Absyn.Info info;
      Option<Absyn.Modification> omod;

    case ({}) then {};

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = name),
      modification=SOME(Absyn.CLASSMOD(elementArgLst={
        Absyn.MODIFICATION(path = Absyn.IDENT(name="version"),modification = omod)
      })), info=info)::xs)
      equation
        version = match omod
          case SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.EXPRESSIONCOMMENT(exp=Absyn.STRING(version))))) then version;
          case SOME(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=Absyn.STRING(version)))) then version;
          else
            algorithm
              Error.addSourceMessage(Error.USES_MISSING_VERSION, {name}, info);
            then "default";
        end match;
        ss = getUsesAnnotationString2(xs, classOrigin);
      then (Absyn.IDENT(name),classOrigin,{version},false)::ss;

    case (_::xs)
      equation
        ss = getUsesAnnotationString2(xs, classOrigin);
      then ss;

    end match;
end getUsesAnnotationString2;

public function getUsedVersion
  "Returns the version of a library that the given class uses based on its uses-annotation."
  input Absyn.Class cls;
  input Absyn.Path library;
  output Option<String> version = NONE();
protected
  list<tuple<Absyn.Path, String, list<String>, Boolean>> uses;
  Absyn.Path lib;
  list<String> versions;
algorithm
  uses := getUsesAnnotationOrDefault(Absyn.Program.PROGRAM({cls}, Absyn.Within.TOP()), true);

  for u in uses loop
    (lib, _, versions, _) := u;

    if AbsynUtil.pathEqual(library, lib) then
      if not listEmpty(versions) then
        // Assume that a class can only use one version of a specific library.
        version := SOME(listHead(versions));
        return;
      end if;
    end if;
  end for;
end getUsedVersion;

public function updateUsedVersion
  "Updates the uses annotation for a specific library in a class to a new
   version. If the class has no uses annotation for the given library nothing is
   done."
  input output Absyn.Class cls;
  input Absyn.Path library;
  input String newVersion;
protected
  function make_version_exp
    input Absyn.Exp exp;
    input String version;
    output Absyn.Exp outExp = Absyn.Exp.STRING(version);
  end make_version_exp;

  Option<Absyn.Annotation> opt_ann;
  Absyn.Annotation ann;
  Boolean found;
algorithm
  opt_ann := AbsynUtil.getClassAnnotation(cls);

  if isNone(opt_ann) then
    return;
  end if;

  SOME(ann) := opt_ann;
  (ann, found) := AbsynUtil.mapAnnotationBinding(ann,
    AbsynUtil.prefixPath("uses", AbsynUtil.joinPaths(library, Absyn.Path.IDENT("version"))),
    function make_version_exp(version = newVersion));

  if found then
    cls := AbsynUtil.setClassAnnotation(cls, SOME(ann));
  end if;
end updateUsedVersion;

public function getConversionAnnotation
  "Returns the conversion-annotations of the top-level classes in the given program."
  input Absyn.Class cls;
  output list<String> withoutConversion = {}, withConversion = {};
protected
  Option<tuple<list<String>,list<String>>> opt_conversion;
algorithm
  opt_conversion := AbsynUtil.getNamedAnnotationInClass(cls, Absyn.Path.IDENT("conversion"), getConversionAnnotationString);
  (withoutConversion,withConversion) := match opt_conversion
    case SOME((withoutConversion,withConversion)) then (withoutConversion,withConversion);
    else ({},{});
  end match;
end getConversionAnnotation;

protected function getConversionAnnotationString
  input Option<Absyn.Modification> mod;
  output tuple<list<String>,list<String>> result;
protected
  list<Absyn.ElementArg> args;
  list<String> without = {}, with = {};
  list<String> from;
  Option<String> script;
algorithm
  SOME(Absyn.CLASSMOD(elementArgLst = args)) := mod;

  for arg in args loop
    (from, _, script) := parseConversionAnnotationElement(arg);

    if isNone(script) then
      without := List.append_reverse(from, without);
    else
      with := List.append_reverse(from, with);
    end if;
  end for;

  result := (listReverse(without), listReverse(with));
end getConversionAnnotationString;

public function getConversionsInClass
  input Absyn.Class cls;
  output list<tuple<String, Option<String>, Option<String>>> result;
protected
  Option<list<tuple<String, Option<String>, Option<String>>>> res;
algorithm
  res := AbsynUtil.getNamedAnnotationInClass(cls, Absyn.Path.IDENT("conversion"), getConversionsInClassMod);
  result := Util.getOptionOrDefault(res, {});
end getConversionsInClass;

protected function getConversionsInClassMod
  input Option<Absyn.Modification> mod;
  output list<tuple<String, Option<String>, Option<String>>> res = {};
protected
  list<Absyn.ElementArg> args;
  list<String> from;
  Option<String> to, script;
algorithm
  SOME(Absyn.CLASSMOD(elementArgLst = args)) := mod;

  for arg in args loop
    (from, to, script) := parseConversionAnnotationElement(arg);

    for v in from loop
      res := (v, to, script) :: res;
    end for;
  end for;
end getConversionsInClassMod;

protected function parseConversionAnnotationElement
  input Absyn.ElementArg mod;
  output list<String> fromVersion = {};
  output Option<String> toVersion = NONE();
  output Option<String> scriptFilename = NONE();
protected
  list<Absyn.ElementArg> args;
  Option<Absyn.Modification> arg_mod;
  String name;
  SourceInfo info;
  Absyn.Exp exp;
algorithm
  () := match mod
    case Absyn.MODIFICATION(path = Absyn.IDENT(name = "noneFromVersion"))
      algorithm
        fromVersion := {AbsynUtil.expString(AbsynUtil.stripCommentExpressions(getAnnotationExp(mod.modification)))};
      then
        ();

    case Absyn.MODIFICATION(path = Absyn.IDENT(name = "from"),
        modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))
      algorithm
        for arg in args loop
          Absyn.MODIFICATION(path = Absyn.IDENT(name = name), modification = arg_mod, info = info) := arg;

          () := matchcontinue name
            case "version"
              algorithm
                exp := AbsynUtil.stripCommentExpressions(getAnnotationExp(arg_mod));

                fromVersion := match exp
                  case Absyn.STRING() then {exp.value};
                  case Absyn.ARRAY() then list(AbsynUtil.expString(e) for e in exp.arrayExp);
                end match;
              then
                ();

            case "to"
              algorithm
                toVersion := SOME(AbsynUtil.expString(AbsynUtil.stripCommentExpressions(getAnnotationExp(arg_mod))));
              then
                ();

            case "script"
              algorithm
                scriptFilename := SOME(AbsynUtil.expString(AbsynUtil.stripCommentExpressions(getAnnotationExp(arg_mod))));
              then
                ();

            else
              algorithm
                if not StringUtil.startsWith(name, "__") then
                  Error.addSourceMessage(Error.CONVERSION_UNKNOWN_ANNOTATION, {name}, info);
                end if;
              then
                ();
          end matchcontinue;

          if listEmpty(fromVersion) then
            Absyn.MODIFICATION(info = info) := mod;
            Error.addSourceMessage(Error.CONVERSION_MISSING_FROM_VERSION,
              {Dump.unparseElementArgStr(mod)}, info);
          end if;
        end for;
      then
        ();

    case Absyn.MODIFICATION(path = Absyn.IDENT(name = name), info = info)
      algorithm
        if not StringUtil.startsWith(name, "__") then
          Error.addSourceMessage(Error.CONVERSION_UNKNOWN_ANNOTATION, {name}, info);
        end if;
      then
        ();

    else ();
  end match;
end parseConversionAnnotationElement;

protected function filterIsVersionElement
  input Absyn.ElementArg eltArg;
  output Boolean b;
algorithm
  b := match eltArg
    case Absyn.MODIFICATION(path = Absyn.IDENT(name = "version")) then true;
    else false;
  end match;
end filterIsVersionElement;

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
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
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
  paths := List.map(getTopPackagesInProgram(p),AbsynUtil.makeIdentPathFromString);
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
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
    /* an extended class with parts: model extends M end M; */
    case (_,_,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        strlist = getPackagesInParts(parts);
      then List.map(strlist,AbsynUtil.makeIdentPathFromString);
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
        cdef = InteractiveUtil.getPathedClassInProgram(modelpath, p);
      then InteractiveUtil.getClassnamesInClass(modelpath, p, cdef, b, c);
    else {};
  end matchcontinue;
end getClassnamesInPath;

public function getTopClassnames
" This function takes a Path and a Program and returns a list of
   the names of the packages found at the top scope."
  input Absyn.Program p;
  output list<Absyn.Path> paths;
algorithm
  paths := List.map(getTopClassnamesInProgram(p),AbsynUtil.makeIdentPathFromString);
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
        p = AbsynUtil.joinWithinPath(w, Absyn.IDENT(id));
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w));
      then p::res;
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation
        res = getTopQualifiedClassnames(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopQualifiedClassnames;

protected function getBaseClasses
" This function gets all base classes of a class, NOT Recursive.
   It uses the environment to get the fully qualified names of the classes."
  input Absyn.Class cls;
  input FCore.Graph env;
  output list<Absyn.Path> baseClasses;
protected
  String base_class_name;
  list<Absyn.ClassPart> parts;
  FCore.Graph cenv;
  Option<Absyn.Path> env_path_opt;
  Absyn.Path env_path, path;
algorithm
  baseClasses := matchcontinue cls
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      then getBaseClassesFromParts(parts, env);

    // adrpo: handle the case for model extends baseClassName end baseClassName;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName = base_class_name, parts = parts))
      algorithm
        (_, _, cenv) := Lookup.lookupClassIdent(FCore.emptyCache(), env, base_class_name, SOME(cls.info));
        SOME(env_path) := FGraph.getScopePath(cenv);
        path := AbsynUtil.suffixPath(env_path, base_class_name);
      then
        path :: getBaseClassesFromParts(parts, env);

    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(path = path)))
      algorithm
        (_, _, cenv) := Lookup.lookupClass(FCore.emptyCache(), env, path, SOME(cls.info));
        env_path_opt := FGraph.getScopePath(cenv);

        if isSome(env_path_opt) then
          path := AbsynUtil.suffixPath(Util.getOption(env_path_opt), AbsynUtil.pathLastIdent(path));
        end if;
      then
        {path};

    else {};
  end matchcontinue;
end getBaseClasses;

protected function getBaseClassesFromParts
"Helper function to getBaseClasses."
  input list<Absyn.ClassPart> parts;
  input FCore.Graph env;
  output list<Absyn.Path> baseClasses = {};
algorithm
  for part in parts loop
    for el in AbsynUtil.getElementItemsInClassPart(part) loop
      baseClasses := getBaseClassesFromElt(el, env, baseClasses);
    end for;
  end for;

  baseClasses := Dangerous.listReverseInPlace(baseClasses);
end getBaseClassesFromParts;

protected function getBaseClassesFromElt
"Helper function to getBaseClassesFromParts."
  input Absyn.ElementItem element;
  input FCore.Graph env;
  input output list<Absyn.Path> baseClasses;
protected
  Absyn.Path path;
  SourceInfo info;
  FCore.Graph cenv;
  Option<Absyn.Path> env_path_opt;
algorithm
  baseClasses := matchcontinue element
    case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path), info = info))
      algorithm
        (_, _, cenv) := Lookup.lookupClass(FCore.emptyCache(), env, path, SOME(info));
        env_path_opt := FGraph.getScopePath(cenv);

        if isSome(env_path_opt) then
          path := AbsynUtil.suffixPath(Util.getOption(env_path_opt), AbsynUtil.pathLastIdent(path));
        end if;
      then
        path :: baseClasses;

    else baseClasses;
  end matchcontinue;
end getBaseClassesFromElt;

protected function countBaseClasses
" This function counts the number of base classes of a class"
  input Absyn.Class inClass;
  output Integer count;
protected
  list<Absyn.ClassPart> parts;
algorithm
  count := match inClass
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts)) then countBaseClassesFromParts(parts);
    // adrpo: add the case for model extends baseClassName extends SomeElseClass; end baseClassName;
    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts)) then countBaseClassesFromParts(parts);
    case Absyn.CLASS(body = Absyn.DERIVED()) then 1;
    else 0;
  end match;
end countBaseClasses;

protected function countBaseClassesFromParts
"Helper function to countBaseClasses."
  input list<Absyn.ClassPart> parts;
  output Integer count = 0;
algorithm
  for part in parts loop
    for el in AbsynUtil.getElementItemsInClassPart(part) loop
      if AbsynUtil.isElementItemExtends(el) then
        count := count + 1;
      end if;
    end for;
  end for;
end countBaseClassesFromParts;

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
        docStr = getNamedAnnotationExp(className,p,Absyn.IDENT("DocumentationClass"),SOME("false"),getDocumentationClassAnnotationModStr);
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

public function getDefaultComponentName
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  String str;
algorithm
  str := getStringNamedAnnotation(classPath, program, Absyn.IDENT("defaultComponentName"));
  result := ValuesUtil.makeString(str);
end getDefaultComponentName;

public function getDefaultComponentPrefixes
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Values.Value result;
protected
  String str;
algorithm
  str := getStringNamedAnnotation(classPath, program, Absyn.IDENT("defaultComponentPrefixes"));
  result := ValuesUtil.makeString(str);
end getDefaultComponentPrefixes;

protected function getAnnotationValue
  input Option<Absyn.Modification> mod;
  output String str;
protected
  Absyn.Exp exp;
algorithm
  str := matchcontinue mod
    case SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp)))
      then "{" + Dump.printExpStr(exp) + "}";

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
      Absyn.Exp exp;
    case (SOME(Absyn.CLASSMOD(elementArgLst = {}, eqMod=Absyn.EQMOD(exp=exp)))) then AbsynUtil.getString(exp);
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
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, DAE.NOPRE(), AbsynUtil.dummyInfo);
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
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, DAE.NOPRE(), AbsynUtil.dummyInfo);
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
        (_,dexp,_) = StaticScript.elabGraphicsExp(FCore.emptyCache(), FGraph.empty(), exp, true, DAE.NOPRE(), AbsynUtil.dummyInfo);
        (DAE.SCONST(s),_) = ExpressionSimplify.simplify(dexp);
      then s;
    case (_::xs)
      equation
        ss = getDocumentationAnnotationInfoHeader(xs);
      then ss;
    end matchcontinue;
end getDocumentationAnnotationInfoHeader;

protected function getNthPublicConnectorStr
  "Returns the n:th connector's name and type in the given class, or n minus
   the number of connectors found if n is too large."
  input Absyn.Path classPath;
  input Absyn.Class cls;
  input Absyn.Program program;
        output Option<tuple<String, Absyn.Path>> conn = NONE();
  input output Integer n;
protected
  list<Absyn.ClassPart> parts;
algorithm
  parts := AbsynUtil.getClassPartsInClass(cls);

  for part in parts loop
    (conn, n) := match part
      case Absyn.PUBLIC() then getNthConnectorInfo(program, classPath, part.contents, n);
      else (conn, n);
    end match;

    if n <= 0 then
      break;
    end if;
  end for;
end getNthPublicConnectorStr;

protected function getNthConnectorInfo
  "Returns the n:th connector's name and type in the given list of element
   items, or n minus the number of connectors found if n is too large."
  input Absyn.Program program;
  input Absyn.Path classPath;
  input list<Absyn.ElementItem> items;
        output Option<tuple<String, Absyn.Path>> conn = NONE();
  input output Integer n;
protected
  Absyn.Path tp, cls_path;
  Absyn.Class cls;
  list<Absyn.ComponentItem> comps;
  Integer comp_count;
  String name;
algorithm
  for item in items loop
    (conn, n) := match item
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp)))
        algorithm
          (cls, cls_path) := lookupClassdef(tp, classPath, program);
        then
          getNthPublicConnectorStr(cls_path, cls, program, n);

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(
             typeSpec = Absyn.TPATH(path = tp), components = comps)))
        algorithm
          (cls, _) := lookupClassdef(tp, classPath, program);

          if AbsynUtil.isConnector(cls) or AbsynUtil.isExpandableConnector(cls) then
            comp_count := listLength(comps);

            if n <= comp_count then
              name := AbsynUtil.componentName(listGet(comps, n));
              conn := SOME((name, tp));
            end if;

            n := n - comp_count;
          end if;
        then
          (conn, n);

      else (conn, n);
    end match;

    if n <= 0 then
      break;
    end if;
  end for;
end getNthConnectorInfo;

protected function countPublicConnectors
"This function takes a Class and counts the number of connector
  components in the class. This also includes counting in inherited classes."
  input Absyn.Path classPath;
  input Absyn.Program program;
  input Absyn.Class cls;
  output Integer count;
protected
  list<Absyn.ClassPart> parts;
  Absyn.Class cdef;
  Absyn.Path cls_name;
algorithm
  count := match cls
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      then countPublicConnectorsInParts(parts, classPath, program);

    case Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))
      then countPublicConnectorsInParts(parts, classPath, program);

    case Absyn.CLASS(body = Absyn.DERIVED(typeSpec = Absyn.TPATH(path = cls_name)))
      algorithm
        (cdef, _) := lookupClassdef(cls_name, classPath, program);
      then
        countPublicConnectors(classPath, program, cdef);

    else 0;
  end match;
end countPublicConnectors;

protected function countPublicConnectorsInParts
  input list<Absyn.ClassPart> parts;
  input Absyn.Path classPath;
  input Absyn.Program program;
  output Integer count = 0;
algorithm
  for part in parts loop
    count := match part
      case Absyn.ClassPart.PUBLIC() then count + countConnectors(classPath, program, part.contents);
      else count;
    end match;
  end for;
end countPublicConnectorsInParts;

protected function countConnectors
"This function takes a Path to the current model and a ElementItem
  list and returns the number of connector components in that list."
  input Absyn.Path classPath;
  input Absyn.Program program;
  input list<Absyn.ElementItem> items;
  output Integer count = 0;
protected
  Absyn.Class cls;
  Absyn.Path tp, cls_path;
  list<Absyn.ComponentItem> comps;
  Integer c;
algorithm
  for item in items loop
    c := matchcontinue item
      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp)))
        algorithm
          (cls, cls_path) := lookupClassdef(tp, classPath, program);
        then
          countPublicConnectors(cls_path, program, cls);

      case Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification =
             Absyn.COMPONENTS(typeSpec = Absyn.TPATH(tp), components = comps)))
        algorithm
          (cls, _) := lookupClassdef(tp, classPath, program);
        then
          if AbsynUtil.isConnector(cls) or AbsynUtil.isExpandableConnector(cls) then listLength(comps) else 0;

      else 0;
    end matchcontinue;

    count := count + c;
  end for;
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
        lineProgram = InteractiveUtil.modelicaAnnotationProgram(Config.getAnnotationVersion());
        fargs = createFuncargsFromElementargs(mod);
        p_1 = AbsynToSCode.translateAbsyn2SCode(lineProgram);
        (cache,env) = Inst.makeEnvFromProgram(p_1);
        (_,newexp,prop) = StaticScript.elabGraphicsExp(cache,env, Absyn.CALL(Absyn.CREF_IDENT(annName,{}),fargs,{}), false,DAE.NOPRE(), info) "impl" ;
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
  output Values.Value result;
protected
  String gexpstr;
  list<String> res;
  list<Absyn.ElementArg> annotations;
  SourceInfo info;
algorithm
  result := match inEquationItem
    case Absyn.EQUATIONITEM(info=info, equation_ = Absyn.EQ_CONNECT(),
        comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(annotations)))))
      algorithm
        res := getConnectionAnnotationStrElArgs(annotations, info, inClass, inFullProgram, inModelPath);
      then
        InteractiveUtil.makeAnnotationArrayValue(res);
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
  output list<Absyn.EquationItem> connections;
protected
  Absyn.ClassDef body = inClass.body;
algorithm
  connections := getConnectionsInClassparts(AbsynUtil.getClassPartsInClass(inClass));
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

public function getComponentModification
" This function takes an Element and returns a comma separated
   list of Code expression for the modification of the component."
  input Absyn.Element element;
  output Values.Value result;
protected
  list<Absyn.ComponentItem> comps;
  Option<Absyn.Modification> opt_mod;
  Absyn.Modification mod;
  list<Values.Value> vals = {};
algorithm
  result := match element
    case Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = comps))
      algorithm
        for c in comps loop
          opt_mod := c.component.modification;
          mod := if isSome(opt_mod) then Util.getOption(opt_mod) else Absyn.emptyMod;
          vals := Values.Value.CODE(Absyn.CodeNode.C_MODIFICATION(mod)) :: vals;
        end for;

        vals := Dangerous.listReverseInPlace(vals);
      then
        ValuesUtil.makeArray(vals);

    else ValuesUtil.makeEmptyArray();
  end match;
end getComponentModification;

public function cacheProgramAndPath
  input GraphicEnvCache inCache;
  output Absyn.Program outProgram;
  output Absyn.Path outPath;
algorithm
  (outProgram, outPath) := match inCache
    case GRAPHIC_ENV_FULL_CACHE() then (inCache.program, inCache.modelPath);
    case GRAPHIC_ENV_PARTIAL_CACHE() then (inCache.program, inCache.modelPath);
    case GRAPHIC_ENV_NO_CACHE() then (inCache.program, inCache.modelPath);
  end match;
end cacheProgramAndPath;

public function envFromGraphicEnvCache
  input GraphicEnvCache inEnvCache;
  output FCore.Graph env;
algorithm
  GRAPHIC_ENV_FULL_CACHE(env = env) := inEnvCache;
end envFromGraphicEnvCache;

protected function cacheFromGraphicEnvCache
  input GraphicEnvCache inEnvCache;
  output FCore.Cache cache;
algorithm
  GRAPHIC_ENV_FULL_CACHE(cache = cache) := inEnvCache;
end cacheFromGraphicEnvCache;

protected function getAnnotationString
  "Renders an annotation as a string."
  input Absyn.Annotation inAnnotation;
  input Absyn.Class inClass;
  input Absyn.Program inFullProgram;
  input Absyn.Path inModelPath;
  output String outString;
protected
  list<Absyn.ElementArg> el = {}, acc = {};
  Absyn.Annotation ann;
algorithm

  if Flags.isSet(Flags.NF_API) then
    try
      outString := NFApi.evaluateAnnotation(inFullProgram, inModelPath, inAnnotation);
    else
      outString := Dump.unparseAnnotation(inAnnotation) + " ";
    end try;
    return;
  end if;

  outString := matchcontinue inAnnotation
    case Absyn.ANNOTATION(el)
      algorithm
        outString := listHead(InteractiveUtil.getElementitemsAnnotationsElArgs(el, FGraph.emptyGraph, inClass, GRAPHIC_ENV_NO_CACHE(inFullProgram, inModelPath), false));
      then
        outString;

    // If we fail, just return the annotation as it is.
    else Dump.unparseAnnotation(inAnnotation) + " ";
  end matchcontinue;
end getAnnotationString;

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
  input GraphicEnvCache inEnv;
  output String componentName;
  output Absyn.Path typeName;
  output String comment;
protected
  Absyn.ComponentItem comp;
algorithm
  (componentName, typeName, comment) := match inElement
    case Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeSpec = Absyn.TPATH(typeName, _), components = comp :: _))
      algorithm
        componentName := comp.component.name;
        typeName := InteractiveUtil.qualifyPath(inEnv, typeName);
        comment := InteractiveUtil.getComponentComment(comp, inElement);
      then
        (componentName, typeName, comment);
  end match;
end getComponentInfoOld;

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

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs=classAttrs,classParts = parts,comment = cmt,ann = ann),
                      info = file_info),eitem)
      equation
        publst = InteractiveUtil.getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,comment = cmt,ann=ann),
                      info = file_info),eitem)
      algorithm
        outClass.body := Absyn.PARTS(typeVars,classAttrs,(Absyn.PUBLIC({eitem}) :: parts),ann,cmt);
      then
        outClass;

    // adrpo: handle also the case model extends X end X;
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        publst = InteractiveUtil.getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        outClass.body = Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann);
      then outClass;

    // adrpo: handle also the case model extends X end X;
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      algorithm
        outClass.body := Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PUBLIC({eitem}) :: parts),ann);
      then outClass;

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

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,comment = cmt, ann = ann),
                      info = file_info),eitem)
      equation
        protlst = InteractiveUtil.getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = InteractiveUtil.replaceProtectedList(parts, protlst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then outClass;

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars,classAttrs = classAttrs,classParts = parts,comment = cmt, ann = ann),
                      info = file_info),eitem)
      algorithm
        outClass.body := Absyn.PARTS(typeVars,classAttrs,(Absyn.PROTECTED({eitem}) :: parts),ann,cmt);
      then outClass;

    // adrpo: handle also the case model extends X end X;
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt, ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        protlst = InteractiveUtil.getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = InteractiveUtil.replaceProtectedList(parts, protlst2);
        outClass.body = Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2, ann);
      then
        outClass;

    // adrpo: handle also the case model extends X end X;
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt, ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      algorithm
        outClass.body := Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,(Absyn.PROTECTED({eitem}) :: parts),ann);
      then outClass;

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

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = file_info),eitem)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst2 = listAppend(eqlst, {eitem});
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
        outClass.body = Absyn.PARTS(typeVars,classAttrs,newparts,ann,cmt);
      then
        outClass;

    /* adrpo: handle also the case model extends X end X; */
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 comment = cmt,
                                                 ann = ann,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        eqlst = InteractiveUtil.getEquationList(parts);
        eqlst2 = listAppend(eqlst, {eitem});
        parts2 = InteractiveUtil.replaceEquationList(parts, eqlst2);
        outClass.body = Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann);
      then
        outClass;

    /* adrpo: handle also the case model extends X end X; */
    case (outClass as Absyn.CLASS(name = i,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                                                 modifications = modifications,
                                                 ann = ann,
                                                 comment = cmt,
                                                 parts = parts),
                      info = file_info),eitem)
      equation
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
        outClass.body = Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,newparts,ann);
      then
        outClass;

  end matchcontinue;
end addToEquation;

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
    case ((Absyn.NAMEDARG(argName = "binding",argValue = exp) :: _)) then SOME(Absyn.CLASSMOD({},Absyn.EQMOD(exp,AbsynUtil.dummyInfo)));
    case ((Absyn.NAMEDARG(argName = "modification",argValue = Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))) :: _)) then SOME(mod);
    case ((_ :: xs)) equation res = modificationToAbsyn2(xs); then res;
  end match;
end modificationToAbsyn2;

protected function selectAnnotation
"@author: adrpo
  Selects either the new annotation if is SOME or the old one"
  input Option<Absyn.Annotation> newAnn;
  input Option<Absyn.Annotation> oldAnn;
  output Option<Absyn.Annotation> outAnn = if isSome(newAnn) then newAnn else oldAnn;
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
  ann as Absyn.ANNOTATION(annargs) := InteractiveUtil.annotationListToAbsyn(inNamedArgs);
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
        cdef = InteractiveUtil.getPathedClassInProgram(classname, p);
        filename = AbsynUtil.classFilename(cdef);
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

    case (outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann = ann,comment = cmt),
                      info = (file_info as SOURCEINFO(fileName = file))))
      equation
        publst = InteractiveUtil.getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        outClass.body = Absyn.PARTS(typeVars,classAttrs,parts2,ann,cmt);
      then
        outClass;

    /* adrpo: handle also the case model extends X end X; */
    case (outClass as Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(baseClassName=baseClassName,
                                                 modifications = modifications,
                                                 parts = parts,
                                                 ann = ann,
                                                 comment = cmt),
                      info = (file_info as SOURCEINFO(fileName = file))))
      equation
        publst = InteractiveUtil.getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = InteractiveUtil.replacePublicList(parts, publst2);
        outClass.body = Absyn.CLASS_EXTENDS(baseClassName,modifications,cmt,parts2,ann);
      then
        outClass;
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
        cdef = InteractiveUtil.getPathedClassInProgram(classpath, p);
        filename1 = AbsynUtil.classFilename(cdef);
        ppath = AbsynUtil.stripLast(classpath);
        pdef = InteractiveUtil.getPathedClassInProgram(ppath, p);
        filename2 = AbsynUtil.classFilename(pdef);
        true = stringEq(filename1, filename2);
        res = getSurroundingPackage(ppath, p);
      then
        res;

    /* No package with same filename */
    case Absyn.PROGRAM()
      equation
        p.classes = {InteractiveUtil.getPathedClassInProgram(classpath, p)};
        p.within_ = InteractiveUtil.buildWithin(classpath);
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
      Absyn.Class cl;

    case((cl as Absyn.CLASS(body=cdef),pa,i))
      equation
        cdef1 = transformFlatClassDef(cdef);
        cl.body = cdef1;
      then ((cl,pa,i));

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
        (e1,_) = AbsynUtil.traverseExp(e,transformFlatExp,0);
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
        (e1,_) = AbsynUtil.traverseExp(e,transformFlatExp,0);
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
      ss = AbsynUtil.crefLastSubs(cr);
      cr1 = AbsynUtil.crefStripLastSubs(cr);
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
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        thenpart1 = List.map(thenpart,transformFlatEquationItem);
        elsepart1 = List.map(elsepart,transformFlatEquationItem);
        elseifpart1 = List.map(elseifpart,transformFlatElseIfPart);
      then
        Absyn.EQ_IF(e11,thenpart1,elseifpart1,elsepart1);

    case(Absyn.EQ_EQUALS(e1,e2))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        (e21,_) = AbsynUtil.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.EQ_EQUALS(e11,e21);

    case(Absyn.EQ_PDE(e1,e2,cr1))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        (e21,_) = AbsynUtil.traverseExp(e2,transformFlatExp,0);
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
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        forEqns1 = List.map(forEqns,transformFlatEquationItem);
      then
        Absyn.EQ_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},forEqns1);

    case(Absyn.EQ_WHEN_E(e1,whenEqns,elseWhenEqns))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
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
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
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
        expl1 = list(AbsynUtil.traverseExp(e, transformFlatExp, 0) for e in expl);
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
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
      then Absyn.NAMEDARG(id,e11);
  end match;
end transformFlatNamedArg;

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
        (_,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        cr1 = transformFlatComponentRef(cr);
      then
        Absyn.ALG_ASSIGN(Absyn.CREF(cr1),e1);
    case (Absyn.ALG_ASSIGN(e1 as Absyn.TUPLE(_),e2))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        (e21,_) = AbsynUtil.traverseExp(e2,transformFlatExp,0);
      then
        Absyn.ALG_ASSIGN(e11,e21);
    case (Absyn.ALG_IF(e1,thenPart,elseIfPart,elsePart))
      equation
        thenPart1 = List.map(thenPart,transformFlatAlgorithmItem);
        elseIfPart1 =  List.map(elseIfPart,transformFlatElseIfAlgorithm);
        elsePart1 = List.map(elsePart,transformFlatAlgorithmItem);
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
    then
      Absyn.ALG_IF(e11,thenPart1,elseIfPart1,elsePart1);
    case (Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e1))},body))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
      then
        Absyn.ALG_FOR({Absyn.ITERATOR(id,NONE(),SOME(e11))},body1);
    case(Absyn.ALG_WHILE(e1,body))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
        body1 = List.map(body,transformFlatAlgorithmItem);
      then
        Absyn.ALG_WHILE(e11,body1);
    case (Absyn.ALG_WHEN_A(e1,body,whenBranch))
      equation
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
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
        (e11,_) = AbsynUtil.traverseExp(e1,transformFlatExp,0);
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
        cl = InteractiveUtil.getPathedClassInProgram(Absyn.IDENT("SourceInfo"), ast);
        toPrint = getDefinitions2({cl},false);
        List.map_0(toPrint, printWithNewline);
        Print.printBuf("\n)\"");
        res = Print.getString();
        Print.restoreBuf(handle);
      then res;

  end match;
end getDefinitions;

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
        pathArg = AbsynUtil.pathLastIdent(path);
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

protected function getDefinitionPathString
  input Absyn.Path path;
  output String out;
algorithm
  out := match (path)
    // Doesn't work because we only know the AST after parsing... case (Absyn.FULLYQUALIFIED(path)) then "#" + AbsynUtil.pathString(path);
    // Thus, scope/lookup is done by the application recieving this information
    case _ then AbsynUtil.pathString(path);
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
  Boolean lveStarted = false;
  Option<Integer> lveInstance = NONE();
  list<String> features;
  String libraryKey, licenseFile;
algorithm
  if not System.regularFileExists(fileName) then
    topClassNamesQualified := {};
    return;
  end if;
  (dir,filename) := Util.getAbsoluteDirectoryAndFile(fileName);
  if filename == "package.moc" then
    (lveStarted, lveInstance) := Parser.startLibraryVendorExecutable(dir);
    if not lveStarted then
      Error.addMessage(Error.INTERNAL_ERROR, {"Unable to start library vendor executable."});
      topClassNamesQualified := {};
      return;
    end if;
  end if;
  parsed := Parser.parse(fileName,encoding,dir,lveInstance);
  parsed := MetaUtil.createMetaClassesInProgram(parsed);
  topClassNamesQualified := getTopQualifiedClassnames(parsed);
  if (lveStarted) then
    Parser.stopLibraryVendorExecutable(lveInstance);
  end if;
  if updateProgram then
    SymbolTable.setAbsyn(InteractiveUtil.updateProgram(parsed, SymbolTable.getAbsyn()));
  end if;
end parseFile;

//he-mag begin
protected function getElementName
"returns the element name"
  input Absyn.ElementSpec inElementSpec;
  input Absyn.Element inElement;
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
        {names} = InteractiveUtil.getComponentItemsNameAndComment(lst, inElement);
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
        path_str = AbsynUtil.pathString(path);
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
        //p_class = AbsynUtil.crefToPath(id);
//        Absyn.IDENT(name) = AbsynUtil.crefToPath(ident);
        //cl = InteractiveUtil.getPathedClassInProgram(p_class, p);
        //comps = getComponentsInClass(cl);
        Absyn.COMPONENTS() = elementSpec;
//        Absyn.CLASSDEF(class_ = cl) = elementSpec;
        //comps = getComponentsInClass(cl);
        desc = getElementName(elementSpec, el);
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
      Absyn.Element el;

    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS()))),_) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */
      then
       "";
    case (Absyn.ELEMENTITEM(element = el as Absyn.ELEMENT(specification = elementSpec)),prog) /* if is not a classdef, just follow the normal stuff */
      equation
        typename_str = getElementTypeName(elementSpec);
        varname_str = getElementName(elementSpec, el);
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
//        modelpath = AbsynUtil.crefToPath(model_);
//        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = InteractiveUtil.getPathedClassInProgram(modelpath, p);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(classParts=parts),_) = InteractiveUtil.getPathedClassInProgram(modelPath_, prog);
        public_elementitem_list = InteractiveUtil.getPublicList(parts);
        protected_elementitem_list = InteractiveUtil.getProtectedList(parts);
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
        p_class = AbsynUtil.crefToPath(class_);
        Absyn.IDENT(name) = AbsynUtil.crefToPath(cr);
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        comps = InteractiveUtil.getComponentsInClass(cdef);
        compelts = List.map(comps, InteractiveUtil.getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, InteractiveUtil.componentitemNamed, name);
        exp = InteractiveUtil.getVariableBindingInComponentitem(compitem);
        res = Dump.printExpStr(exp);
      then
        res;
    case (cr,class_,p)
      equation
        p_class = AbsynUtil.crefToPath(class_);
        Absyn.IDENT(name) = AbsynUtil.crefToPath(cr);
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        comps = InteractiveUtil.getComponentsInClass(cdef);
        compelts = List.map(comps, InteractiveUtil.getComponentitemsInElement);
        compelts_1 = List.flatten(compelts);
        {compitem} = List.select1(compelts_1, InteractiveUtil.componentitemNamed, name);
        failure(_ = InteractiveUtil.getVariableBindingInComponentitem(compitem));
      then "";
    else "Error";
  end matchcontinue;
end getComponentBindingMapable;

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
        classes = SCodeUtil.getClassElements(inElement);
        acc = List.fold1(classes,getSCodeClassNamesRecursiveWork,SOME(path),acc);
      then acc;
    case (SCode.CLASS(name=name),SOME(path),acc)
      equation
        path = AbsynUtil.suffixPath(path,name);
        acc = path::acc;
        classes = SCodeUtil.getClassElements(inElement);
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
      cl = InteractiveUtil.getPathedClassInProgram(AbsynUtil.stripLast(path),prg);
      comp = getComponentElementInClass(cl,AbsynUtil.pathLastIdent(path));
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
     publst = InteractiveUtil.getPublicList(parts);
     comp = getComponentsContainsName(Absyn.CREF_IDENT(compName,{}), publst);
   then comp;
   /* an extended class with parts: model extends M end M; */
   case(Absyn.CLASS(body=Absyn.CLASS_EXTENDS(parts=parts)), _) equation
     publst = InteractiveUtil.getPublicList(parts);
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
      then InteractiveUtil.getClassesInParts(classParts);
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
        cdef = InteractiveUtil.getPathedClassInProgram(p_class, p);
        exts = InteractiveUtil.getExtendsElementspecInClass(cdef);
        paths = List.map(exts, InteractiveUtil.getBaseClassNameFromExtends);
      then
        paths;
    else {};
  end matchcontinue;
end getAllInheritedClasses;

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
      DAE.NOMOD(), DAE.NOPRE(), ci_state, cl, SCode.PUBLIC(), {}, 0);
  else
    (_, outEnv) := Inst.instClassIn(cache, env, InnerOuter.emptyInstHierarchy,
      UnitAbsyn.noStore, DAE.NOMOD(), DAE.NOPRE(), ci_state, cl,
      SCode.PUBLIC(), {}, false, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY,
      Connect.emptySet, NONE());
  end try;
end getClassEnvNoElaboration;

public function setComponentDimensions
  "Sets a component dimensions."
  input Absyn.Path inClass;
  input Absyn.Path inComponentName;
  input list<Absyn.Exp> inDimensions;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output Boolean outResult;
protected
  Absyn.Path p_class;
  Absyn.Within within_;
  Absyn.Class cls;
algorithm
  try
    within_ := InteractiveUtil.buildWithin(inClass);
    cls := InteractiveUtil.getPathedClassInProgram(inClass, inProgram);
    cls := setComponentDimensionsInClass(cls, inComponentName, inDimensions);
    outProgram := InteractiveUtil.updateProgram(Absyn.PROGRAM({cls}, within_), inProgram);
    outResult := true;
  else
    outProgram := inProgram;
    outResult := false;
  end try;
end setComponentDimensions;

protected function setComponentDimensionsInClass
" Sets the dimensions on a component in a class."
  input Absyn.Class inClass;
  input Absyn.Path inComponentName;
  input list<Absyn.Exp> inDimensions;
  output Absyn.Class outClass = inClass;
algorithm
  (outClass, true) := AbsynUtil.traverseClassComponents(inClass,
    function setComponentDimensionsInCompitems(inComponentName = inComponentName, inDimensions = inDimensions), false);
end setComponentDimensionsInClass;

protected function setComponentDimensionsInCompitems
"Helper function to setComponentDimensions.
 Sets the dimensions in a ComponentItem."
  input list<Absyn.ComponentItem> inComponents;
  input Boolean inFound;
  input Absyn.Path inComponentName;
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
  comp_id := AbsynUtil.pathFirstIdent(inComponentName);

  // Try to find the component we're looking for.
  while not listEmpty(rest_items) loop
    item :: rest_items := rest_items;

    if AbsynUtil.componentName(item) == comp_id then
      // Found component, propagate the modifier to it.
      _ := match item
        case Absyn.COMPONENTITEM(component = comp as Absyn.COMPONENT())
          algorithm
            comp.arrayDim := List.map(inDimensions, AbsynUtil.makeSubscript);
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
          strs := match p
            case DAE.VAR(componentRef = DAE.CREF_IDENT(s))
              then (s + DAEDump.dumpVarBindingStr(p.binding)) :: strs;

            else strs;
          end match;
        end for;
      then
        Dangerous.listReverseInPlace(strs);

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
        accessStr = getNamedAnnotationExp(className, p, Absyn.IDENT("Protection"), SOME(""), getAccessAnnotationString);
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
  output Access access;
protected
  String access_str, fileName;
  Boolean encryptedClass;
algorithm
  try
    Absyn.CLASS(info=SOURCEINFO(fileName=fileName)) := InteractiveUtil.getPathedClassInProgram(path, p);
    encryptedClass := StringUtil.endsWith(fileName, ".moc");
    if encryptedClass then
      access := match getAccessAnnotation(path, p)
        case "Access.hide" then Access.hide;
        case "Access.icon" then Access.icon;
        case "Access.documentation" then Access.documentation;
        case "Access.diagram" then Access.diagram;
        case "Access.nonPackageText" then Access.nonPackageText;
        case "Access.nonPackageDuplicate" then Access.nonPackageDuplicate;
        case "Access.packageText" then Access.packageText;
        case "Access.packageDuplicate" then Access.packageDuplicate;
        // If the class doesn't have the access annotation then look for it in the parent class.
        case _ guard not AbsynUtil.pathIsIdent(path)
          then checkAccessAnnotationAndEncryption(AbsynUtil.stripLast(path), p);
        // if a class is encrypted and no Protection annotation is defined, the
        // access annotation has the default value Access.documentation
        else Access.documentation;
      end match;
    else
      access := Access.all;
    end if;
  else
    access := Access.all;
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
    containsEncryptedClass := containsEncryptedClass or StringUtil.endsWith(fileName, ".moc");
    if containsEncryptedClass then break; end if;
  end for;
end astContainsEncryptedClass;

annotation(__OpenModelica_Interface="backend");
end Interactive;
