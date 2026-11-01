/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFInteractive
" file:        NFInteractive.mo
  package:     NFInteractive
  description: Evaluates script statements with the new frontend (-d=nfScripting).

  Script variables stay in SymbolTable, where the scripting API reads them. A
  name the new frontend does not find otherwise is looked up there through
  BackendInterface.lookupScriptVariable and stands for its value."

public
import Absyn;
import GlobalScript;

protected
import AbsynUtil;
import BackendInterface;
import DAE;
import Error;
import ErrorTypes;
import Expression;
import FGraph;
import Global;
import InteractiveTypes;
import List;
import MutableWeak;
import NFCall;
import NFCeval;
import NFExpression;
import NFFunction.Function;
import NFInst;
import NFInstanceAPI;
import NFInstContext;
import NFInstNode.InstNode;
import NFTyping;
import SymbolTable;
import System;
import Types;
import TypesDump;
import Util;
import Values;
import ValuesDump;
import ValuesUtil;

constant NFInstContext.Type CONTEXT = NFInstContext.SCRIPTING;

public
function evaluate
  "Evaluates a statement and returns what it prints. An expression that fails
   prints nothing; a failing statement fails, as in the old frontend's loop."
  input GlobalScript.Statement statement;
  output String result;
algorithm
  try
    result := evaluateStatement(statement);
  else
    releaseClearedScope();
    fail();
  end try;
  releaseClearedScope();
end evaluate;

function evaluateStatement
  input GlobalScript.Statement statement;
  output String result;
protected
  Absyn.Algorithm alg;
  SourceInfo info;
algorithm
  result := match statement
    case GlobalScript.IEXP()
      algorithm
        try
          result := ValuesDump.valString(evaluateExp(statement.exp, statement.info));
        else
          result := "";
        end try;
      then
        result;

    case GlobalScript.IALG(algItem = Absyn.ALGORITHMITEM(algorithm_ = alg, info = info))
      then evaluateAlgorithm(alg, info);

    else "";
  end match;
end evaluateStatement;

function releaseClearedScope
  "clear() and clearProgram() drop the top scope but leave its nodes to the
   end of the statement, which may still be evaluating in it."
algorithm
  if listEmpty(getGlobalRoot(Global.instNFNodeCacheIndex)) then
    MutableWeak.clearRoots();
  end if;
end releaseClearedScope;

function lookupVariable
  "The value of a script variable, or of a field of one, as an expression;
   subscripts on the last part of the name are kept. Fails if the name is not
   a script variable."
  input Absyn.ComponentRef cref;
  output Absyn.Exp exp;
protected
  list<Absyn.Subscript> subs;
algorithm
  false := AbsynUtil.crefHasSubscripts(AbsynUtil.crefStripLastSubs(cref));
  exp := Expression.unelabExp(ValuesUtil.valueExp(variableValue(
    AbsynUtil.pathToStringList(AbsynUtil.crefToPathIgnoreSubs(cref)), SymbolTable.getVars())));
  // Absyn holds strings as written, with escape sequences.
  (exp, _) := AbsynUtil.traverseExp(exp, escapeString, 0);
  subs := AbsynUtil.crefLastSubs(cref);

  if not listEmpty(subs) then
    exp := Absyn.SUBSCRIPTED_EXP(exp, subs);
  end if;
end lookupVariable;

protected
function escapeString
  input output Absyn.Exp exp;
  input output Integer dummy;
algorithm
  exp := match exp
    case Absyn.STRING() then Absyn.STRING(System.escapedString(exp.value, false));
    else exp;
  end match;
end escapeString;

function variableValue
  input list<String> names;
  input list<InteractiveTypes.Variable> vars;
  output Values.Value value;
protected
  String name;
  list<String> rest;
  list<String> fields;
  list<Values.Value> values;
algorithm
  name :: rest := names;
  InteractiveTypes.IVAR(value = value) :=
    List.getMemberOnTrue(name, vars, isVariableNamed);

  for field in rest loop
    Values.RECORD(orderd = values, comp = fields) := value;
    value := listGet(values, List.position(field, fields));
  end for;
end variableValue;

function isVariableNamed
  input String name;
  input InteractiveTypes.Variable var;
  output Boolean res;
algorithm
  res := match var
    case InteractiveTypes.IVAR() then stringEq(name, var.varIdent);
  end match;
end isVariableNamed;

function evaluateExp
  "A call to a scripting API function returns the API's value as it is, since
   many of them return values their declared output type does not describe."
  input Absyn.Exp absynExp;
  input SourceInfo info;
  output Values.Value value;
protected
  InstNode top;
  NFExpression exp;
  NFCeval.EvalTarget target = NFCeval.EvalTarget.new(info, CONTEXT);
algorithm
  (_, top) := NFInstanceAPI.mkTop(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), "<interactive>");
  exp := NFInst.instExp(absynExp, top, CONTEXT, info);
  (exp, _) := NFTyping.typeExp(exp, CONTEXT, info);

  value := match exp
    local
      Function fn;
      list<NFExpression> args;

    case NFExpression.CALL(call = NFCall.TYPED_CALL(fn = fn, arguments = args))
      guard Function.isBuiltin(fn) and Function.isScripting(fn)
      then BackendInterface.evalScriptingFunction(
        AbsynUtil.pathFirstIdent(Function.nameConsiderBuiltin(fn)),
        list(NFExpression.toDAEValue(NFCeval.evalExp(arg, target)) for arg in args), info);

    else NFExpression.toDAEValue(NFCeval.evalExp(exp, target));
  end match;
end evaluateExp;

function evaluateAlgorithm
  input Absyn.Algorithm alg;
  input SourceInfo info;
  output String result = "";
protected
  Values.Value value;
  list<Values.Value> values;
  Absyn.ComponentRef cref;
  list<Absyn.Exp> lhs;
algorithm
  () := match alg
    case Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF(cref as Absyn.CREF_IDENT()))
      algorithm
        value := evaluateExp(alg.value, info);
        assignVariable(cref, value, info);
        result := ValuesDump.valString(value);
      then
        ();

    case Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = lhs))
      algorithm
        Values.TUPLE(valueLst = values) := evaluateExp(alg.value, info);

        for e in lhs loop
          value :: values := values;

          () := match e
            case Absyn.CREF(Absyn.CREF_IDENT())
              algorithm
                assignVariable(e.componentRef, value, info);
              then
                ();

            case Absyn.CREF(Absyn.WILD()) then ();
          end match;
        end for;
      then
        ();

    case Absyn.ALG_NORETCALL()
      algorithm
        _ := evaluateExp(Absyn.CALL(alg.functionCall, alg.functionArgs, {}), info);
      then
        ();

    case Absyn.ALG_IF()
      algorithm
        evaluateIf((alg.ifExp, alg.trueBranch) :: alg.elseIfAlgorithmBranch, alg.elseBranch, info);
      then
        ();

    case Absyn.ALG_WHILE()
      algorithm
        while evaluateCondition(alg.boolExpr, info, Error.WHILE_CONDITION_TYPE_ERROR) loop
          evaluateAlgorithmItems(alg.whileBody);
        end while;
      then
        ();

    case Absyn.ALG_FOR(iterators = {Absyn.ITERATOR(guardExp = NONE(), range = SOME(_))})
      algorithm
        evaluateFor(listHead(alg.iterators), alg.forBody, info);
      then
        ();
  end match;
end evaluateAlgorithm;

function evaluateIf
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> branches;
  input list<Absyn.AlgorithmItem> elseBranch;
  input SourceInfo info;
algorithm
  for branch in branches loop
    if evaluateCondition(Util.tuple21(branch), info, Error.IF_CONDITION_TYPE_ERROR) then
      evaluateAlgorithmItems(Util.tuple22(branch));
      return;
    end if;
  end for;

  evaluateAlgorithmItems(elseBranch);
end evaluateIf;

function evaluateAlgorithmItems
  input list<Absyn.AlgorithmItem> items;
algorithm
  for item in items loop
    () := match item
      case Absyn.ALGORITHMITEM()
        algorithm
          evaluateAlgorithm(item.algorithm_, item.info);
        then
          ();

      else ();
    end match;
  end for;
end evaluateAlgorithmItems;

function evaluateCondition
  input Absyn.Exp condition;
  input SourceInfo info;
  input ErrorTypes.Message errorMessage;
  output Boolean res;
protected
  Values.Value value;
algorithm
  value := evaluateExp(condition, info);

  res := match value
    case Values.BOOL() then value.boolean;
    else
      algorithm
        Error.addSourceMessage(errorMessage, {ValuesDump.valString(value),
          TypesDump.unparseTypeNoAttr(Types.typeOfValue(value))}, info);
      then
        fail();
  end match;
end evaluateCondition;

function evaluateFor
  "Evaluates a for loop; a range is stepped through without building it."
  input Absyn.ForIterator iterator;
  input list<Absyn.AlgorithmItem> body;
  input SourceInfo info;
protected
  String name;
  Absyn.Exp range;
  Values.Value value, step, stop;
  list<Values.Value> values;
algorithm
  Absyn.ITERATOR(name = name, range = SOME(range)) := iterator;

  () := match range
    case Absyn.RANGE()
      algorithm
        value := evaluateExp(range.start, info);
        step := match range.step
          local
            Absyn.Exp e;
          case SOME(e) then evaluateExp(e, info);
          else Values.INTEGER(1);
        end match;
        stop := evaluateExp(range.stop, info);

        while ValuesUtil.safeLessEq(value, stop) loop
          evaluateIteration(name, value, body);
          value := ValuesUtil.safeIntRealOp(value, step, Values.ADDOP());
        end while;
      then
        ();

    else
      algorithm
        value := evaluateExp(range, info);
        values := match value
          case Values.ARRAY(valueLst = values) then values;
          else
            algorithm
              Error.addSourceMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {ValuesDump.valString(value)}, info);
            then
              fail();
        end match;

        for v in values loop
          evaluateIteration(name, v, body);
        end for;
      then
        ();
  end match;
end evaluateFor;

function evaluateIteration
  input String name;
  input Values.Value value;
  input list<Absyn.AlgorithmItem> body;
algorithm
  SymbolTable.appendVar(name, value, Types.typeOfValue(value));

  try
    evaluateAlgorithmItems(body);
  else
    SymbolTable.deleteVarFirstEntry(name);
    fail();
  end try;

  SymbolTable.deleteVarFirstEntry(name);
end evaluateIteration;

function assignVariable
  input Absyn.ComponentRef cref;
  input Values.Value value;
  input SourceInfo info;
protected
  String name;
  list<Absyn.Subscript> subs;
algorithm
  Absyn.CREF_IDENT(name = name, subscripts = subs) := cref;
  SymbolTable.addVar(DAE.CREF_IDENT(name, Types.typeOfValue(value),
    list(evaluateSubscript(s, info) for s in subs)), value, FGraph.empty());
end assignVariable;

function evaluateSubscript
  input Absyn.Subscript sub;
  input SourceInfo info;
  output DAE.Subscript dsub;
protected
  Values.Value value;
algorithm
  dsub := match sub
    case Absyn.NOSUB() then DAE.WHOLEDIM();
    case Absyn.SUBSCRIPT()
      algorithm
        value := evaluateExp(sub.subscript, info);
      then
        match value
          case Values.INTEGER() then DAE.INDEX(DAE.ICONST(value.integer));
          case Values.ARRAY() then DAE.SLICE(ValuesUtil.valueExp(value));
        end match;
  end match;
end evaluateSubscript;

annotation(__OpenModelica_Interface="backend_main");
end NFInteractive;
