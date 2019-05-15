/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
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

encapsulated package DAEToMid

public
import MidCode;
import SimCodeFunction;

function DAEFunctionsToMid
  input list<SimCodeFunction.Function> simfuncs;
  output list<MidCode.Function> midfuncs;
algorithm
  midfuncs := list(DAEFunctionToMid(simfunc) for simfunc in simfuncs);
end DAEFunctionsToMid;

protected
import DAE;
import DAEDump;
import MidToMid;
import SimCode;
import Expression;
import ExpressionDump;
import ComponentReference;
import System;
import DoubleEndedList;
import Mutable;
import BaseHashTable;
import HashTableMidVar;
import List;
import Error;

uniontype State
  record STATE
    DoubleEndedList<MidCode.Var> locals;
    DoubleEndedList<MidCode.VarBuf> localBufs;
    DoubleEndedList<MidCode.VarBufPtr> localBufPtrs;
    DoubleEndedList<MidCode.Block> blocks;
    DoubleEndedList<MidCode.Stmt> stmts;
    Mutable.Mutable<Integer> blockid;
    Mutable.Mutable<list<Integer>> continuejumps;
    Mutable.Mutable<list<Integer>> breakjumps;
    Mutable.Mutable<HashTableMidVar.HashTable> vars;
  end STATE;
end State;

function listZip<X,Y>
  "List.threadTuple fails for lists of unequal length
   but truncating is the more common semantics."
  input  list<X>          xs;
  input  list<Y>          ys;
  output list<tuple<X,Y>> zs;
protected
  list<X> xs_;
  list<Y> ys_;
  X x;
  Y y;
algorithm
  zs := match (xs,ys)
    case ({}   ,  _)    then {};
    case (_    , {})    then {};
    case (x::xs_, y::ys_) then (x,y) :: listZip(xs_,ys_);
  end match;
end listZip;

function GenTmpVar
  input DAE.Type ty;
  input State state;
  output MidCode.Var var;
algorithm
  var := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)), ty, false);
  DoubleEndedList.push_back(state.locals, var);
end GenTmpVar;

function GenTmpVarVolatile
  input DAE.Type ty;
  input State state;
  output MidCode.Var var;
algorithm
  var := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)), ty, true);
  DoubleEndedList.push_back(state.locals, var);
end GenTmpVarVolatile;

function GenTmpVarBuf
  /*
  Uses same naming scheme as variables.
  Doesn't have to as long as they don't collide.
  */
  input State state;
  output MidCode.VarBuf var;
algorithm
  var := MidCode.VARBUF("_jmpbuf_" + intString(System.tmpTickIndex(47)));
  DoubleEndedList.push_back(state.localBufs, var);
end GenTmpVarBuf;

function GenTmpVarBufPtr
  /*
  Uses same naming scheme as variables.
  Doesn't have to as long as they don't collide.
  */
  input State state;
  output MidCode.VarBufPtr var;
algorithm
  var := MidCode.VARBUFPTR("_tmp_" + intString(System.tmpTickIndex(46)));
  DoubleEndedList.push_back(state.localBufPtrs, var);
end GenTmpVarBufPtr;

function GenBlockId
  output Integer id;
algorithm
  id := System.tmpTickIndex(45);
end GenBlockId;

function ConvertSimCodeVars
  input SimCodeFunction.Variable simcodevar;
  input State state;
  output MidCode.Var var;
algorithm
  var := match simcodevar
    local
    MidCode.Var midcodevar;
    case SimCodeFunction.VARIABLE(__)
    algorithm
      midcodevar := CrefToMidVar(simcodevar.name, state);
      () := match simcodevar.value
        local
          DAE.Exp exp;
        case NONE() then ();
        case SOME(exp)
        algorithm
          stateAddStmt(MidCode.ASSIGN(midcodevar, ExpToMid(exp, state)), state);
        then ();
      end match;
    then midcodevar;
  end match;
end ConvertSimCodeVars;

function GetCrefIndexVar
  input DAE.ComponentRef cref;
  input State state;
  output Option<MidCode.Var> var;
protected
  list<DAE.Subscript> subscripts;
algorithm
  subscripts := ComponentReference.crefLastSubs(cref);

  var := match subscripts
    local
      DAE.Subscript subscript;
      MidCode.Var indexvar;
    case {} then NONE();
    case {subscript as DAE.INDEX(__)}
    algorithm
      indexvar := RValueToVar(ExpToMid(subscript.exp, state), state);
    then SOME(indexvar);
  end match;
end GetCrefIndexVar;

function CrefToMidVar
  //TODO: handle scopes better
  input DAE.ComponentRef cref;
  input State state;
  output MidCode.Var var;
protected
  String ident;
  DAE.Type ty;
algorithm
  if not BaseHashTable.hasKey(cref, Mutable.access(state.vars)) then
    (ident, ty) := match cref
    local
      String ident_;
      DAE.Type ty_;
    case DAE.CREF_IDENT(ident_, ty_, _) then (ident_, ty_);
    else
    algorithm
      Error.addInternalError("CrefToMidVar error", sourceInfo());
    then fail();
    end match;
    Mutable.update(state.vars, BaseHashTable.add((cref, MidCode.VAR(ident, Types.complicateType(ty), false)), Mutable.access(state.vars)));
  end if;
  var := BaseHashTable.get(cref, Mutable.access(state.vars));
end CrefToMidVar;

function RValueType
  input MidCode.RValue rvalue;
  output DAE.Type ty;
algorithm
  ty := match rvalue
    case MidCode.VARIABLE(__) then rvalue.src.ty;
    //TODO: move comparisons to separate?
    case MidCode.BINARYOP(__) then match rvalue.op
      case MidCode.LESS() then DAE.T_BOOL_DEFAULT;
      case MidCode.LESSEQ() then DAE.T_BOOL_DEFAULT;
      case MidCode.GREATER() then DAE.T_BOOL_DEFAULT;
      case MidCode.GREATEREQ() then DAE.T_BOOL_DEFAULT;
      case MidCode.EQUAL() then DAE.T_BOOL_DEFAULT;
      case MidCode.NEQUAL() then DAE.T_BOOL_DEFAULT;
      else then rvalue.lsrc.ty;
      end match;
    case MidCode.UNARYOP(MidCode.BOX(),_) then Types.boxIfUnboxedType(rvalue.src.ty);
    case MidCode.UNARYOP(MidCode.UNBOX(),_) then Types.unboxedType(rvalue.src.ty);
    //TODO: separate CAST? since has new type
    case MidCode.UNARYOP(__) then rvalue.src.ty;
    case MidCode.LITERALINTEGER(__) then DAE.T_INTEGER_DEFAULT;
    case MidCode.LITERALREAL(__) then DAE.T_REAL_DEFAULT;
    case MidCode.LITERALBOOLEAN(__) then DAE.T_BOOL_DEFAULT;
    case MidCode.LITERALSTRING(__) then DAE.T_STRING_DEFAULT;
    case MidCode.LITERALMETATYPE(__) then rvalue.ty;
    case MidCode.METAFIELD(__) then rvalue.ty;
    case MidCode.UNIONTYPEVARIANT(__) then DAE.T_INTEGER_DEFAULT;
    case MidCode.ISCONS(__) then DAE.T_BOOL_DEFAULT;
    case MidCode.ISSOME(__) then DAE.T_BOOL_DEFAULT;
    else
    algorithm
      Error.addInternalError("Could not find the correct type of an RValue.\n", sourceInfo());
    then fail();
  end match;
end RValueType;

function RValueToVar
  input MidCode.RValue rvalue;
  input State state;
  output MidCode.Var var;
algorithm
var := match rvalue
  local
    MidCode.Var tmpvar;
  case MidCode.VARIABLE(__) then rvalue.src;
  else
  algorithm
    tmpvar := GenTmpVar(Types.complicateType(RValueType(rvalue)),state);
    DoubleEndedList.push_back(state.stmts, MidCode.ASSIGN(tmpvar, rvalue));
  then tmpvar;
end match;
end RValueToVar;

function DAEFunctionToMid
  input SimCodeFunction.Function simfunc;
  output MidCode.Function midfunc;
protected
  State state;
  DoubleEndedList<MidCode.Var> inputs;
  DoubleEndedList<MidCode.Var> outputs;
  MidCode.Block block_;
  Absyn.Path path;
  Integer labelFirst;

algorithm
  System.tmpTickReset(47); //jump buffers
  System.tmpTickReset(46); //variables
  System.tmpTickReset(45); //block ids

  () := match simfunc
  local
    Absyn.Path name;
    list<SimCodeFunction.Variable> outVars;
    list<SimCodeFunction.Variable> functionArguments;
    list<SimCodeFunction.Variable> variableDeclarations;
    list<DAE.Statement> body;
    SCode.Visibility visibility;
    SourceInfo info;

  case SimCodeFunction.FUNCTION(name, outVars, functionArguments, variableDeclarations, body, visibility, info)
  algorithm
    labelFirst := GenBlockId();
    path := name;
    inputs := DoubleEndedList.fromList({});
    outputs := DoubleEndedList.fromList({});
    state := STATE(DoubleEndedList.fromList({}),
                   DoubleEndedList.fromList({}),
                   DoubleEndedList.fromList({}),
                   DoubleEndedList.fromList({}),
                   DoubleEndedList.fromList({}),
                   Mutable.create(labelFirst),
                   Mutable.create({}),
                   Mutable.create({}),
                   Mutable.create(HashTableMidVar.emptyHashTable()));
    for simcodeVar in variableDeclarations loop
      DoubleEndedList.push_back(state.locals, ConvertSimCodeVars(simcodeVar, state));
    end for;
    for simcodeVar in outVars loop
      DoubleEndedList.push_back(outputs, ConvertSimCodeVars(simcodeVar, state));
    end for;
    for simcodeVar in functionArguments loop
      DoubleEndedList.push_back(inputs, ConvertSimCodeVars(simcodeVar, state));
    end for;

    StmtsToMid(body, state);
  then ();
  else
  algorithm
    Error.addInternalError("Unsupported SimCodeFunction.Function type\n", sourceInfo());
    fail();
  then ();
  end match;

  stateTerminate(-1, MidCode.RETURN(), state);

  midfunc := MidCode.FUNCTION(name=path,
                              locals=DoubleEndedList.toListAndClear(state.locals),
                              localBufs=DoubleEndedList.toListAndClear(state.localBufs),
                              localBufPtrs=DoubleEndedList.toListAndClear(state.localBufPtrs),
                              inputs=DoubleEndedList.toListAndClear(inputs),
                              outputs=DoubleEndedList.toListAndClear(outputs),
                              body=DoubleEndedList.toListAndClear(state.blocks),
                              entryId=labelFirst,
                              exitId=GenBlockId());
  midfunc := MidToMid.longJmpGoto(midfunc);
end DAEFunctionToMid;

function StmtsToMid
  input list<DAE.Statement> daestmts;
  input State state;
algorithm
  () := match daestmts
  local
    DAE.Statement stmt;
    list<DAE.Statement> tail;
  case ({}) then ();
  case (stmt::tail)
    algorithm
      () := match stmt
      local
        DAE.Type ty;
        DAE.Exp exp1;
        DAE.Exp exp;
        DAE.ComponentRef cref;
        DAE.Pattern pattern;
        list<DAE.Statement> daestmtLst;
        list<DAE.Exp> expLst;
        list<MidCode.Var> indexesLst;
        MidCode.Var varCref;
        MidCode.Var varArray;
        MidCode.Var varIndex;
        MidCode.Var varValue;
        MidCode.Var varCondition;
        MidCode.Var varIter;
        MidCode.Var varLast;
        MidCode.Var varStep;
        MidCode.Var varMessage;
        MidCode.Var varLevel;
        MidCode.Var varRHS;
        MidCode.OutVar outvar;
        MidCode.Block block_;
        Integer labelBody;
        Integer labelNext;
        Integer labelCondition;
        Integer labelStep;
        DAE.Else else_;
        DoubleEndedList<MidCode.OutVar> outvars;
        String iter;
        Integer index;
        list<DAE.Subscript> subscripts;
        MidCode.Stmt midstmt;
        MidCode.RValue rvalue;
        array<list<MidCode.Stmt>> assignBlock;
      case DAE.STMT_ASSIGN(_, exp1 as DAE.CREF(__), exp, _)
      algorithm
        cref := ComponentReference.crefLastCref(exp1.componentRef); //gå runt CREF_QUAL tills vidare
        varCref := CrefToMidVar(cref,state);

        stateAddStmt(MidCode.ASSIGN(varCref, ExpToMid(exp, state)), state);
      then ();
      case DAE.STMT_ASSIGN(_, exp1 as DAE.ASUB(__), exp, _)
      algorithm
        varArray := RValueToVar(ExpToMid(exp1.exp, state), state);
        varIndex := match exp1.sub
          local
            DAE.Exp indexexp;
          case {indexexp} then RValueToVar(ExpToMid(indexexp, state), state);
        end match;
        varValue := RValueToVar(ExpToMid(exp, state), state);

        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.CALL(Absyn.IDENT("arrayUpdate"), true, {varArray, varIndex, varValue}, {}, labelNext), state);
      then ();
      case DAE.STMT_ASSIGN(_, DAE.PATTERN(pattern), exp, _)
      algorithm
        varRHS  := RValueToVar(ExpToMid(exp,state),state);
        patternToMidCode(matches={(varRHS,pattern)},labelNoMatch=1,state=state); // pattern match
      then ();
      case DAE.STMT_ASSIGN(__)
      algorithm
        Error.addInternalError("DAE.STMT_ASSIGN to Mid conversion failed " + ExpressionDump.dumpExpStr(stmt.exp1,0) + "\n", sourceInfo());
      then fail();
      case DAE.STMT_TUPLE_ASSIGN(_, expLst, exp, _)
      algorithm
        outvars := DoubleEndedList.fromList({});
        for exp1 in expLst loop
          () := match exp1
            case DAE.CREF(DAE.WILD())
            algorithm
              DoubleEndedList.push_back(outvars, MidCode.OUT_WILD());
            then ();
            case DAE.CREF(__)
            algorithm
              varCref := CrefToMidVar(exp1.componentRef, state);
              DoubleEndedList.push_back(outvars, MidCode.OUT_VAR(varCref));
            then ();
            else
            algorithm
              Error.addInternalError("outvars convertion failed " + ExpressionDump.dumpExpStr(exp1,0) + "\n", sourceInfo());
            then fail();
          end match;
        end for;
        () := match exp
        case DAE.CALL(__)
        algorithm
          CallToMid(exp, DoubleEndedList.toListAndClear(outvars), state);
        then ();
        case DAE.MATCHEXPRESSION(__)
        algorithm
          MatchExpressionToMid(exp, DoubleEndedList.toListAndClear(outvars), state);
        then ();
        end match;
      then ();
      case DAE.STMT_IF(__)
      algorithm
        IfToMid(stmt.exp, stmt.statementLst, stmt.else_, state);
      then ();
      case DAE.STMT_WHILE(__)
      algorithm
        labelCondition := GenBlockId();
        labelBody := GenBlockId();
        labelNext := GenBlockId();

        Mutable.update(state.continuejumps, labelCondition :: Mutable.access(state.continuejumps));
        Mutable.update(state.breakjumps, labelNext :: Mutable.access(state.breakjumps));

        stateTerminate(labelCondition, MidCode.GOTO(labelCondition), state);

        varCondition := RValueToVar(ExpToMid(stmt.exp, state), state);
        stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);

        StmtsToMid(stmt.statementLst, state);
        stateTerminate(labelNext, MidCode.GOTO(labelCondition), state);

        Mutable.update(state.continuejumps, listRest(Mutable.access(state.continuejumps)));
        Mutable.update(state.breakjumps, listRest(Mutable.access(state.breakjumps)));

      then ();
      case DAE.STMT_FOR(__)
      algorithm
        ForToMid(stmt.type_, stmt.iter, stmt.range, stmt.statementLst, state);
      then ();
      case DAE.STMT_BREAK(_)
      algorithm
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.GOTO(listHead(Mutable.access(state.breakjumps))), state);
      then ();
      case DAE.STMT_CONTINUE(_)
      algorithm
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.GOTO(listHead(Mutable.access(state.continuejumps))), state);
      then ();
      case DAE.STMT_RETURN(_)
      algorithm
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.RETURN(), state);
      then ();
      case DAE.STMT_NORETCALL(__)
      algorithm
        () := match stmt.exp
          case DAE.CALL(__)
          algorithm
            CallToMid(stmt.exp, {}, state);
          then ();
          case DAE.MATCHEXPRESSION(__)
          algorithm
            MatchExpressionToMid(stmt.exp, {}, state);
          then ();
        end match;
      then ();
      case DAE.STMT_ASSERT(__)
      algorithm
        varCondition := RValueToVar(ExpToMid(stmt.cond, state), state);
        varMessage := RValueToVar(ExpToMid(stmt.msg, state), state);
        varLevel := RValueToVar(ExpToMid(stmt.level, state), state);

        labelNext := GenBlockId();

        stateTerminate(labelNext, MidCode.ASSERT(varCondition, varMessage, varLevel, labelNext), state);
      then ();
      case DAE.STMT_TERMINATE(__)
      algorithm
        varMessage := RValueToVar(ExpToMid(stmt.msg, state), state);

        labelNext := GenBlockId();

        stateTerminate(labelNext, MidCode.TERMINATE(varMessage), state);
      then ();
      else
      algorithm
        Error.addInternalError("DAE.Statement to Mid conversion failed " + DAEDump.ppStatementStr(stmt), sourceInfo());
      then fail();

      end match;

      StmtsToMid(tail, state);
    then ();
  end match;
end StmtsToMid;

function ExpToMid
  input DAE.Exp exp;
  input State state;
  output MidCode.RValue rval;
algorithm
  rval := match exp
  local
    MidCode.Var varExp;
    MidCode.Var varExp2;
    MidCode.Var varCref;
    MidCode.Var varCar;
    MidCode.Var varCdr;
    MidCode.Var varTmp;
    MidCode.BinaryOp binop;
    MidCode.UnaryOp unop;
    DAE.Exp exp1;
    DAE.Exp exp2;
    DAE.Exp exp3;
    DAE.Operator operator;
    DAE.Type ty;
    DAE.ComponentRef cref;
    Integer labelBody;
    Integer labelElse;
    Integer labelNext;
    Integer index;
    Integer length;
    Integer numTailTypes;
    MidCode.Block block_;
    MidCode.Terminator terminator;
    Absyn.Path path;
    list<DAE.Exp> expLst;
    DoubleEndedList<MidCode.Var> values;
    list<MidCode.OutVar> outvars;
    Option<DAE.Exp> option;
    DAE.CallAttributes callattrs;
    list<DAE.Subscript> subscripts;
    MidCode.RValue rvalue;
  case DAE.ICONST(__) then MidCode.LITERALINTEGER(exp.integer);
  case DAE.ENUM_LITERAL(__) then MidCode.LITERALINTEGER(exp.index);
  case DAE.RCONST(__) then MidCode.LITERALREAL(exp.real);
  case DAE.SCONST(__) then MidCode.LITERALSTRING(exp.string);
  case DAE.SHARED_LITERAL(__) then ExpToMid(exp.exp, state); //don't bother with shared support yet
  case DAE.BOX(__)
  algorithm
    varExp := RValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.UNARYOP(MidCode.BOX(), varExp);
  case DAE.UNBOX(__)
  algorithm
    varExp := RValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.UNARYOP(MidCode.UNBOX(), varExp);
  case DAE.BCONST(__) then MidCode.LITERALBOOLEAN(exp.bool);
  case DAE.META_OPTION(SOME(exp1))
  algorithm
    varExp := RValueToVar(ExpToMid(exp1, state), state);
  then MidCode.LITERALMETATYPE({varExp}, Types.complicateType(DAE.T_METAOPTION(varExp.ty)));
  case DAE.META_OPTION(NONE())
  then MidCode.LITERALMETATYPE({}, Types.complicateType(DAE.T_NONE_DEFAULT));
  case DAE.META_TUPLE(expLst)
  algorithm
    values := DoubleEndedList.fromList({});
    for exp in expLst loop
      varExp := RValueToVar(ExpToMid(exp, state), state);
      DoubleEndedList.push_back(values, varExp);
    end for;
  then MidCode.LITERALMETATYPE(DoubleEndedList.toListAndClear(values), Types.complicateType(Expression.typeof(exp)));
  case DAE.METARECORDCALL(_, expLst, _, _, _)
  algorithm
    values := DoubleEndedList.fromList({});
    for exp in expLst loop
      varExp := RValueToVar(ExpToMid(exp, state), state);
      DoubleEndedList.push_back(values, varExp);
    end for;
  then MidCode.LITERALMETATYPE(DoubleEndedList.toListAndClear(values), Types.complicateType(Expression.typeof(exp)));
  case DAE.CONS(__)
  algorithm
    varCar := RValueToVar(ExpToMid(exp.car, state), state);
    varCdr := RValueToVar(ExpToMid(exp.cdr, state), state);
  then MidCode.LITERALMETATYPE({varCar, varCdr}, Types.complicateType(DAE.T_METALIST(varCar.ty)));
  case DAE.LIST(expLst)
  algorithm
    expLst := listReverse(expLst);

    varCdr := GenTmpVar(DAE.T_METALIST_DEFAULT,state);
    DoubleEndedList.push_back(state.stmts, MidCode.ASSIGN(varCdr, MidCode.LITERALMETATYPE({}, DAE.T_METALIST_DEFAULT)));
    for exp in expLst loop
      varCar := RValueToVar(ExpToMid(exp, state), state);
      varTmp := GenTmpVar(DAE.T_METALIST(Types.complicateType(varCar.ty)),state);
      DoubleEndedList.push_back(state.stmts, MidCode.ASSIGN(varTmp, MidCode.LITERALMETATYPE({varCar, varCdr},  Types.complicateType(DAE.T_METALIST(varCar.ty)))));
      varCdr := varTmp;
    end for;
  then MidCode.VARIABLE(varCdr);
  case DAE.CREF(cref, _)
  algorithm
    varCref := CrefToMidVar(cref, state);

    rvalue := match GetCrefIndexVar(cref, state)
      local
        MidCode.Var indexvar;
      case NONE() then MidCode.VARIABLE(varCref);
      case SOME(indexvar)
      algorithm
        labelNext := GenBlockId();

        varTmp := GenTmpVar(Types.complicateType(Expression.typeof(exp)),state);

        stateTerminate(labelNext,
          MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varCref,indexvar}, {MidCode.OUT_VAR(varTmp)}, labelNext),
          state);
      then MidCode.VARIABLE(varTmp);
    end match;
  then rvalue;
  case DAE.ASUB(exp1, expLst)
  algorithm
    varExp := RValueToVar(ExpToMid(exp1, state), state);
    varExp2 := match expLst
      local
        DAE.Exp indexexp;
      case {indexexp} then RValueToVar(ExpToMid(indexexp, state), state);
    end match;

    varTmp := GenTmpVar(Types.complicateType(Expression.typeof(exp)),state);

    labelNext := GenBlockId();

    stateTerminate(labelNext,
      MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varExp, varExp2}, {MidCode.OUT_VAR(varTmp)}, labelNext),
      state);
  then MidCode.VARIABLE(varTmp);
  case DAE.TSUB(exp1 as DAE.CALL(_,_,callattrs), 1, _)
  algorithm
    /* stupid special case */
    (ty,numTailTypes) := match callattrs.ty
      local
        DAE.Type actualType;
        list<DAE.Type> tailTypes;
      case DAE.T_TUPLE(actualType::tailTypes) then (actualType, listLength(tailTypes));
      else fail();
    end match;

    varTmp := GenTmpVar(Types.complicateType(ty),state);

    outvars := {};
    for i in 1:numTailTypes loop
      outvars := MidCode.OUT_WILD() :: outvars;
    end for;
    outvars := MidCode.OUT_VAR(varTmp) :: outvars;
    CallToMid(exp1, outvars, state);
  then MidCode.VARIABLE(varTmp);
  case DAE.TSUB(__)
  algorithm
    varExp := RValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.METAFIELD(varExp, exp.ix, Types.complicateType(exp.ty));
  case DAE.RSUB(__)
  algorithm
    varExp := RValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.METAFIELD(varExp, exp.ix, Types.complicateType(exp.ty));
  case DAE.CAST(ty, exp1)
  algorithm
    varExp := RValueToVar(ExpToMid(exp1, state), state);
  then MidCode.UNARYOP(MidCode.MOVE(), varExp); //TODO: return type?
  case DAE.LUNARY(operator, exp1)
  algorithm
    varExp := RValueToVar(ExpToMid(exp1, state), state);
  then MidCode.UNARYOP(MidCode.NOT(), varExp);
  case DAE.LBINARY(exp1, operator, exp2)
  algorithm
    labelElse := GenBlockId();
    labelNext := GenBlockId();

    ty := match operator
      case DAE.AND(__) then operator.ty;
      case DAE.OR(__) then operator.ty;
    end match;
    varTmp := GenTmpVar(ty,state);

    terminator := match operator
      case DAE.AND(_) then MidCode.BRANCH(varTmp, labelElse, labelNext);
      case DAE.OR(_) then MidCode.BRANCH(varTmp, labelNext, labelElse);
    end match;

    stateAddStmt(MidCode.ASSIGN(varTmp, ExpToMid(exp1, state)), state);
    stateTerminate(labelElse, terminator, state);

    stateAddStmt(MidCode.ASSIGN(varTmp, ExpToMid(exp2, state)), state);
    stateTerminate(labelNext, MidCode.GOTO(labelNext), state);

  then MidCode.VARIABLE(varTmp);
  case DAE.UNARY(operator,exp1)
  algorithm
    unop := match operator
    case DAE.UMINUS(__) then MidCode.UMINUS();
    end match;

    varExp := RValueToVar(ExpToMid(exp1, state), state);
  then MidCode.UNARYOP(unop, varExp);
  case DAE.BINARY(exp1, operator, exp2)
  algorithm
    binop := match operator
    case DAE.ADD(__) then MidCode.ADD();
    case DAE.SUB(__) then MidCode.SUB();
    case DAE.MUL(__) then MidCode.MUL();
    case DAE.DIV(__) then MidCode.DIV();
    case DAE.POW(__) then MidCode.POW();
    end match;

    varExp := RValueToVar(ExpToMid(exp1, state), state);
    varExp2 := RValueToVar(ExpToMid(exp2, state), state);
  then MidCode.BINARYOP(binop, varExp, varExp2);
  case DAE.RELATION(exp1, operator, exp2, _, _)
  algorithm
    binop := match operator
      case DAE.LESS(__)      then MidCode.LESS();
      case DAE.LESSEQ(__)    then MidCode.LESSEQ();
      case DAE.GREATER(__)   then MidCode.GREATER();
      case DAE.GREATEREQ(__) then MidCode.GREATEREQ();
      case DAE.EQUAL(__)     then MidCode.EQUAL();
      case DAE.NEQUAL(__)    then MidCode.NEQUAL();
    end match;

    varExp := RValueToVar(ExpToMid(exp1, state), state);
    varExp2 := RValueToVar(ExpToMid(exp2, state), state);
  then MidCode.BINARYOP(binop, varExp, varExp2);
  case DAE.IFEXP(exp1, exp2, exp3)
  algorithm

    labelBody := GenBlockId();
    labelElse := GenBlockId();
    labelNext := GenBlockId();

    varExp := RValueToVar(ExpToMid(exp1, state), state);

    varTmp := GenTmpVar(Types.complicateType(Expression.typeof(exp2)),state);

    stateTerminate(labelBody, MidCode.BRANCH(varExp, labelBody, labelElse), state);

    stateAddStmt(MidCode.ASSIGN(varTmp, ExpToMid(exp2, state)), state);
    stateTerminate(labelElse, MidCode.GOTO(labelNext), state);

    stateAddStmt(MidCode.ASSIGN(varTmp, ExpToMid(exp3, state)), state);
    stateTerminate(labelNext, MidCode.GOTO(labelNext), state);
  then MidCode.VARIABLE(varTmp);
  case DAE.CALL(_, _, callattrs)
  algorithm
    varTmp := GenTmpVar(Types.complicateType(callattrs.ty),state);
    CallToMid(exp, {MidCode.OUT_VAR(varTmp)}, state);
  then MidCode.VARIABLE(varTmp);
  case DAE.MATCHEXPRESSION(et=ty)
  algorithm
  varTmp := GenTmpVar(Types.complicateType(ty),state);
  () := match Types.complicateType(ty)
    case DAE.T_TUPLE(__)
    algorithm
      Error.addInternalError("Not supposed to get tuple here.\n", sourceInfo());
    then fail();
    else then ();
  end match;
  MatchExpressionToMid(exp,{MidCode.OUT_VAR(varTmp)},state);
  then MidCode.VARIABLE(varTmp);
  else
  algorithm
    Error.addInternalError("DAE.Exp to Mid conversion failed:\n" + ExpressionDump.dumpExpStr(exp,0) + "\n", sourceInfo());
  then fail();
  end match;
end ExpToMid;

function CallToMid
  input DAE.Exp call;
  input list<MidCode.OutVar> outvars;
  input State state;
algorithm
  //TODO: maybe handle isFunctionPointerCall/isImpure
  () := match call
  local
    Absyn.Path path;
    list<DAE.Exp> expLst;
    DAE.CallAttributes callattr;
    Integer labelNext;
    DoubleEndedList<MidCode.Var> inputs;
    MidCode.Var var1;
    MidCode.Block block_;
  case DAE.CALL(path, expLst, callattr)
  algorithm
    labelNext := GenBlockId();

    inputs := DoubleEndedList.fromList({});
    for exp1 in expLst loop
      var1 := RValueToVar(ExpToMid(exp1, state), state);
      DoubleEndedList.push_back(inputs, var1);
    end for;

    stateTerminate(labelNext,
                    MidCode.CALL(path,callattr.builtin,DoubleEndedList.toListAndClear(inputs),outvars,labelNext),
                    state);

  then ();
  end match;
end CallToMid;

function ForToMid
  input DAE.Type type_;
  input String iter;
  input DAE.Exp range;
  input list<DAE.Statement> daestmtLst;
  input State state;
protected
  MidCode.Var varCref;
  MidCode.Var varCondition;
  Integer labelCondition;
  Integer labelStep;
  Integer labelBody;
  Integer labelNext;
algorithm
  varCref := CrefToMidVar(DAE.CREF_IDENT(iter, type_, {}), state);
  DoubleEndedList.push_back(state.locals, varCref);

  labelCondition := GenBlockId();
  labelStep := GenBlockId();
  labelBody := GenBlockId();
  labelNext := GenBlockId();

  Mutable.update(state.continuejumps, labelStep :: Mutable.access(state.continuejumps));
  Mutable.update(state.breakjumps, labelNext :: Mutable.access(state.breakjumps));

  varCondition := GenTmpVar(DAE.T_BOOL_DEFAULT,state);

  () := match range
    local
      DAE.Exp start;
      Option<DAE.Exp> step;
      DAE.Exp stop;
      MidCode.Var varRange;
      MidCode.Var varFirst;
      MidCode.Var varIter;
      MidCode.Var varLast;
      MidCode.Var varStep;
      Integer labelBody2;
      Integer labelCondition2;
      MidCode.RValue rvalueStep;
    case DAE.RANGE(_, start, step, stop)
    algorithm
      labelCondition2 := GenBlockId();

      varFirst := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      varIter := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      varLast := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      varStep := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);

      stateAddStmt(MidCode.ASSIGN(varFirst, ExpToMid(start, state)), state);
      stateAddStmt(MidCode.ASSIGN(varIter, ExpToMid(start, state)), state);
      stateAddStmt(MidCode.ASSIGN(varLast, ExpToMid(stop, state)), state);

      rvalueStep := match step
        local
          DAE.Exp stepexp;
        case NONE() then MidCode.LITERALINTEGER(1);
        case SOME(stepexp) then ExpToMid(stepexp, state);
      end match;

      stateAddStmt(MidCode.ASSIGN(varStep, rvalueStep), state);
      stateTerminate(labelCondition, MidCode.GOTO(labelCondition), state);

      stateTerminate(labelCondition2,
        MidCode.CALL(Absyn.IDENT("in_range_integer"), true, {varIter, varFirst, varLast}, {MidCode.OUT_VAR(varCondition)}, labelCondition2),
        state);

      stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);

      stateAddStmt(MidCode.ASSIGN(varCref, MidCode.VARIABLE(varIter)), state);
      StmtsToMid(daestmtLst, state);
      stateTerminate(labelStep, MidCode.GOTO(labelStep), state);

      stateAddStmt(MidCode.ASSIGN(varIter, MidCode.BINARYOP(MidCode.ADD(), varIter, varStep)), state);
      stateTerminate(labelNext, MidCode.GOTO(labelCondition), state);
    then ();
    else
      algorithm
      varRange := RValueToVar(ExpToMid(range, state), state);
      () := match varRange.ty
        case DAE.T_METATYPE(_)
        algorithm
          Error.addInternalError("metatype error", sourceInfo());
        then fail();
        case DAE.T_METAARRAY(_)
        algorithm
          labelBody2 := GenBlockId();

          varIter := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varLast := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varStep := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);

          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.LITERALINTEGER(1)), state);
          stateAddStmt(MidCode.ASSIGN(varStep, MidCode.LITERALINTEGER(1)), state);
          stateTerminate(labelCondition,
            MidCode.CALL(Absyn.IDENT("arrayLength"), true, {varRange}, {MidCode.OUT_VAR(varLast)}, labelCondition),
            state);

          stateAddStmt(MidCode.ASSIGN(varCondition, MidCode.BINARYOP(MidCode.LESSEQ(), varIter, varLast)), state);
          stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);

          stateTerminate(labelBody2,
            MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varRange, varIter}, {MidCode.OUT_VAR(varCref)}, labelBody2),
            state);

          StmtsToMid(daestmtLst, state);
          stateTerminate(labelStep, MidCode.GOTO(labelStep), state);

          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.BINARYOP(MidCode.ADD(), varIter, varStep)), state);
          stateTerminate(labelNext, MidCode.GOTO(labelCondition), state);
        then ();
        case DAE.T_METALIST(_)
        algorithm
          labelBody2 := GenBlockId();

          varIter := varRange;
          stateTerminate(labelCondition, MidCode.GOTO(labelCondition), state);

          stateAddStmt(MidCode.ASSIGN(varCondition, MidCode.ISCONS(varIter)), state);
          stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);

          stateTerminate(labelBody2,
            MidCode.CALL(Absyn.IDENT("listHead"), true, {varIter}, {MidCode.OUT_VAR(varCref)}, labelBody2),
            state);

          StmtsToMid(daestmtLst, state);
          stateTerminate(labelStep, MidCode.GOTO(labelStep), state);

          stateTerminate(labelNext,
            MidCode.CALL(Absyn.IDENT("listRest"), true, {varIter}, {MidCode.OUT_VAR(varIter)}, labelCondition),
            state);
        then ();
        else
        algorithm
          Error.addInternalError("unknown for type " + DAEDump.daeTypeStr(varRange.ty) + "\n", sourceInfo());
        then fail();
      end match;
    then ();
  end match;

  Mutable.update(state.continuejumps, listRest(Mutable.access(state.continuejumps)));
  Mutable.update(state.breakjumps, listRest(Mutable.access(state.breakjumps)));
end ForToMid;

function IfToMid
  input DAE.Exp exp;
  input list<DAE.Statement> daestmtLst;
  input DAE.Else else_;
  input State state;
protected
  Integer labelBody;
  Integer labelElse;
  Integer labelNext;
  MidCode.Var var1;
  MidCode.Block block_;
algorithm
  labelBody := GenBlockId();
  labelElse := GenBlockId();
  labelNext := GenBlockId();

  var1 := RValueToVar(ExpToMid(exp, state), state);

  stateTerminate(labelBody, MidCode.BRANCH(var1, labelBody, labelElse), state);

  StmtsToMid(daestmtLst, state);
  stateTerminate(labelElse, MidCode.GOTO(labelNext), state);

  () := match else_
  local
    DAE.Exp subexp;
    list<DAE.Statement> subdaestmtLst;
    DAE.Else subelse;
  case DAE.NOELSE() then ();
  case DAE.ELSEIF(subexp, subdaestmtLst, subelse)
  algorithm
    IfToMid(subexp, subdaestmtLst, subelse, state);
  then ();
  case DAE.ELSE(subdaestmtLst)
  algorithm
    StmtsToMid(subdaestmtLst, state);
  then ();
  end match;

  stateTerminate(labelNext, MidCode.GOTO(labelNext), state);
end IfToMid;


function stateGetCurrentLabel
  input State state;
  output Integer label;
algorithm
  label := Mutable.access(state.blockid);
end stateGetCurrentLabel;

function stateSetCurrentLabel
  input Integer label;
  input State state;
algorithm
  Mutable.update(state.blockid, label);
end stateSetCurrentLabel;

function stateAddStmt
  input MidCode.Stmt stmt;
  input State state;
algorithm
  DoubleEndedList.push_back(state.stmts, stmt);
end stateAddStmt;

function stateTerminate
  input Integer newLabel;
  input MidCode.Terminator terminator;
  input State state;
protected
  MidCode.Block block_;
algorithm
  block_ := MidCode.BLOCK(stateGetCurrentLabel(state),
                          DoubleEndedList.toListAndClear(state.stmts),
                          terminator);
  DoubleEndedList.push_back(state.blocks, block_);

  stateSetCurrentLabel(newLabel, state);
end stateTerminate;

// helper
function stateAddBailOnFalse
  input MidCode.Var var;
  input Integer labelBail;
  input State state;
protected
  Integer labelTmp;
algorithm
  labelTmp := GenBlockId();
  stateTerminate(labelTmp,MidCode.BRANCH(var,onFalse=labelBail,onTrue=labelTmp), state);
end stateAddBailOnFalse;

function unpackCrefFromExp
  input DAE.Exp exp;
  output DAE.ComponentRef cref;
algorithm
  cref := match exp
    case DAE.CREF(cref)
    then cref;
  end match;
end unpackCrefFromExp;


//TODO: stuff needs to be volatile for setjmp.
//TODO: could handle match separately from matchcontinue and add more simplifications
/*
The term matchexpression is used to include both matchcontinue and match.
*/
function MatchExpressionToMid
  input DAE.Exp matchexpression;
  input list<MidCode.OutVar> outvars;
  input State state;
protected
  Integer labelFin, labelMux, labelInit, labelFail, labelFin2, labelOut, caseLabel;
  list<Integer> caseLabels;
  MidCode.Var muxState, one, midvar,midvar2;
  MidCode.VarBufPtr muxOldBuf;
  MidCode.VarBuf muxNewBuf;
  MidCode.OutVar outvar;
  Boolean matchContinue;
  DAE.MatchType matchType;
  list<DAE.MatchCase> cases;
  list<DAE.Exp> inputsCref;
  list<list<String>> aliases; // list of (list of alias) where each outer list corresponds to a input
  MidCode.Var srcVar, aliasVar;
  list<String> aliasList;
  DAE.Type ty;
  DAE.ComponentRef cref;
  list<MidCode.Var> inputsMidVar;
  DAE.Exp daeExp;
  list<Integer> caseLabelIterator;
algorithm
  /*
  I assume the Else case is a case with top level wild patterns (_,_,_).
  */

  // match just to get match elements
  () := match matchexpression
  case DAE.MATCHEXPRESSION(matchType=matchType, cases=cases, inputs=inputsCref, aliases=aliases)
  algorithm
    labelInit := stateGetCurrentLabel(state);
    labelMux := GenBlockId();
    labelFin := GenBlockId();

    matchContinue := match matchType
      case DAE.MATCHCONTINUE() then true;
      case DAE.MATCH()         then false;
    end match;

    // caseLabels <- sequence $ repeat (length cases) genBlockId
    // can write with list comprehension if I can make a range
    caseLabels := {};
    for i in 1:listLength(cases) loop
      caseLabels := GenBlockId() :: caseLabels;
    end for;

    /*
    First we evaluate all inputs to the matchcontinue.
    We must also bind the aliases that were sent.
    If an input does not have an alias we must create a MidCode.Var for it to use.

    zip inputs aliases : [(input,[alias])]
      where
        length inputs = length aliases

    */

    assert( listLength(inputsCref) == listLength(aliases), "MatchExpressionToMid: incorrect input: listLength(inputs) != listLength(aliases)" );
    inputsMidVar := {};
    for daeExp_aliasList in List.threadTuple(inputsCref,aliases) loop

      (daeExp,aliasList) := daeExp_aliasList;
      srcVar := RValueToVar(ExpToMid(daeExp, state), state);
      ty := RValueType(MidCode.VARIABLE(srcVar));
      inputsMidVar := srcVar :: inputsMidVar;
      for alias in aliasList loop
        aliasVar := MidCode.VAR(name=alias, ty=ty, volatile=false);
        DoubleEndedList.push_back(state.locals, aliasVar);
        stateAddStmt( MidCode.ASSIGN(aliasVar, MidCode.VARIABLE(srcVar) ), state );
      end for;
    end for;

    // inputsMidVar := list(CrefToMidVar(unpackCrefFromExp(expCref),state) for expCref in inputsCref);

    /*
    init:
      state = 0
      #IF MATCHCONTINUE
        PUSHJMP(J_old,J_new)
      goto mux
    */

    muxState := GenTmpVarVolatile(DAE.T_INTEGER_DEFAULT,state); // volatile since we mutate it after setjmp
    stateAddStmt(MidCode.ASSIGN(muxState, MidCode.LITERALINTEGER(0)), state);

    if matchContinue
    then
      muxOldBuf := GenTmpVarBufPtr(state);
      muxNewBuf := GenTmpVarBuf(state);
      stateTerminate(labelMux, MidCode.PUSHJMP(muxOldBuf,muxNewBuf,labelMux),state);
    else
      stateTerminate(labelMux, MidCode.GOTO(labelMux),state);
    end if;

    /*
    mux:
    #IF MATCHCONTINUE
      state+=1
      switch (state) {1:case1, 2:case2, ...,n:case_n,n+1:fin}
    #IF MATCH
      goto first case or fail if no case
    */
    if matchContinue
    then
      one := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      stateAddStmt(MidCode.ASSIGN(one, MidCode.LITERALINTEGER(1)) ,state);
      stateAddStmt(MidCode.ASSIGN(muxState, MidCode.BINARYOP(MidCode.ADD(),muxState,one)),state);
      stateTerminate(labelFin, MidCode.SWITCH( muxState, List.threadTuple( List.intRange(listLength(cases)+1), listAppend(caseLabels,{labelFin}) )  ), state);
    else
      stateTerminate(labelFin, MidCode.GOTO(if not listEmpty(caseLabels) then listHead(caseLabels) else labelFin), state);
    end if;
    /*
    fin:
      #IF MATCHCONTINUE
        POPJMP(J_old)
      if state == nr_cases+1
        longjmp
      else
        goto next
    */

    /*
    We make the label for the next thing we generate after the match expression.
    We replace this in the case loop as we add more cases.
    */
    labelFail := GenBlockId();
    labelFin2 := GenBlockId();
    labelOut := GenBlockId();

    if matchContinue
    then
      stateTerminate(labelFin2, MidCode.POPJMP( muxOldBuf, labelFin2  ), state);
    else
      stateTerminate(labelFin2, MidCode.GOTO(labelFin2), state);
    end if;

    midvar  := RValueToVar(MidCode.LITERALINTEGER(listLength(cases)+1),state);
    midvar2 := RValueToVar(MidCode.BINARYOP(MidCode.EQUAL(),muxState, midvar),state);
    stateTerminate(labelFail, MidCode.BRANCH(midvar2, labelFail, labelOut),state);

    stateTerminate(labelOut, MidCode.LONGJMP(),state);

    caseLabelIterator := caseLabels;

    // for each case
    while not listEmpty(caseLabelIterator) loop
      caseLabel         := listHead(caseLabelIterator);
      caseLabelIterator := listRest(caseLabelIterator);
      stateSetCurrentLabel(caseLabel, state);
      // left to right - depth first - through all patterns in the case
      () := match cases
        local
          list<DAE.Pattern> patterns;
          list<DAE.Statement> daeBody;
          Option<DAE.Exp> patternGuard;
          Option<DAE.Exp> caseResult;
        case {}
        algorithm
          // No more cases.
        then ();
        case (DAE.CASE(patterns=patterns,body=daeBody,patternGuard=patternGuard,result=caseResult)::cases) // note: modifies cases
        algorithm
          // first do checks and assignments
          // NOTE: If the guard fails we will have made pattern assignments for a failing case. This is how it was done before as far as I can tell.
          if matchContinue
          then
            patternToMidCode(state=state, matches=List.threadTuple(inputsMidVar,patterns), labelNoMatch=labelMux);
          else
          patternToMidCode(state=state, matches=List.threadTuple(inputsMidVar,patterns)
                          ,labelNoMatch= if not listEmpty(caseLabelIterator) then listHead(caseLabelIterator) else labelFail);
          end if;
          // then guard
          () := match patternGuard
            case (NONE())
            algorithm
              // No guard.
            then ();
            case (SOME(daeExp))
            algorithm
              midvar := RValueToVar(ExpToMid(daeExp,state),state);
              if matchContinue
              then
                stateAddBailOnFalse(midvar,labelMux,state);
              else
                stateAddBailOnFalse(midvar,
                                    if not listEmpty(caseLabelIterator) then listHead(caseLabelIterator) else labelFail,
                                    state);
              end if;
            then ();
          end match;
          // followed by body
          StmtsToMid(daeBody,state);
          /*
          instead of caseResult being a list of exps there are 3 cases.
            - No result.
              NONE()

            - One result.
              SOME(result)

            - More results.
              SOME(TUPLE(result0,result1,...))

          Also outvars is unexpectedly removed of trailing wildcards and can be shorter than expList,
          including tuples of length 1 (probably 0 too, but who knows).
          So we define and use listZip instead of threadTuple.

          TODO: Document the unintuitive undocumented interface somewhere.
          */
          () := match (caseResult, outvars)
            local
              list<DAE.Exp> expList;
            case (SOME(DAE.TUPLE(expList)),_)
            algorithm
              for outvarDaeExp in listZip(outvars, expList) loop
                (outvar, daeExp) := outvarDaeExp;
                () := match outvar
                  local
                    MidCode.Var var;
                  case MidCode.OUT_VAR(var)
                  algorithm
                    stateAddStmt(MidCode.ASSIGN(var, ExpToMid(daeExp,state)),state);
                  then ();
                  case MidCode.OUT_WILD() then ();
                end match;

              end for;

            then ();
            case (SOME(daeExp as DAE.CALL(__)), _)
            algorithm
              CallToMid(daeExp, outvars, state);
            then ();
            case (SOME(daeExp as DAE.MATCHEXPRESSION(__)), _)
            algorithm
              MatchExpressionToMid(daeExp, outvars, state);
            then ();
            case (SOME(daeExp), {MidCode.OUT_VAR(midvar)})
            algorithm
              stateAddStmt(MidCode.ASSIGN(midvar, ExpToMid(daeExp,state)),state);
            then ();
            case (SOME(daeExp), _)
            algorithm
              Error.addInternalError("Match expression output to Mid conversion failed:\n" + ExpressionDump.dumpExpStr(daeExp,0) + "\n", sourceInfo());
            then ();
            case (NONE(), {})
            algorithm
              // No result.
            then ();
            case (NONE(), _)
            algorithm
              Error.addInternalError("case fail", sourceInfo());
            then fail();
          end match;
          // finally go to end
          stateTerminate(labelOut, MidCode.GOTO(labelFin),state);
        then ();
      end match;
    end while;
  then ();
  end match;
end MatchExpressionToMid;

function patternToMidCode
  "
  Performs pattern matching.

  The state will be left so that if the
  matching was successful then we
  continue in the active block. And
  variables in pattern will be bound.
  But failures will have jumped to
  labelNoMatch. And nothing will be bound.

  For example in a match a failure means handling
  the next case. Except for the last case where
  failure is a longjmp.
  "
  input list<tuple<MidCode.Var,DAE.Pattern>> matches "List of variables and their corresponding patterns";
  input Integer labelNoMatch "where to go on a failed match";
  input State state;
  output array<list<MidCode.Stmt>> assignBlock "A block of assignments to perform for a pattern.";
algorithm
  assignBlock := arrayCreate(1,{});

  patternToMidCode2(state=state,matches=matches,labelNoMatch=labelNoMatch,assignBlock=assignBlock);

  for stmt in listReverse(arrayGet(assignBlock,1)) loop
    stateAddStmt(stmt,state);
  end for;
end patternToMidCode;

function patternToMidCode2
  "
  Recursive worker function for
  patternToMidCode handling.
  "
  input State state;
  input list<tuple<MidCode.Var,DAE.Pattern>> matches;
  input Integer labelNoMatch; /* where to go on a failed match*/
  input array<list<MidCode.Stmt>> assignBlock; /* A block of assignments to perform for a pattern. */
protected
    Absyn.Path name;
    Integer index;
    list<DAE.Pattern> morePatterns, iterator;
    list<DAE.Var> fields;
    list<DAE.Type> typeVars;
    Boolean knownSingleton;
    Integer fieldNr;
algorithm
  /*
  case0:
    check some pattern
    if not match then goto mux (e.g. METACONSTRUCTOR)
    extract scrutinees for sub-patterns (e.g. METAFIELD)
    note down if there is a binding to be done later (assignBlock)
    check another part of pattern
    ...
    if not guard expression
      goto mux
    else goto body0

  guard and body is handled in the caller, not here

  */

  () := match matches
    local
      list<tuple<MidCode.Var,DAE.Pattern>> restMatches, moreMatches;
      list<DAE.Type> listTypes;
      MidCode.Var ok; /* Just a MidCode boolean variable */
      MidCode.Var scrutinee, midvar, headVar, restVar;
      String id;
      DAE.Pattern pattern, headPattern, restPattern;
      DAE.Exp exp;
      DAE.Type ty;
      MidCode.Var scrutineeCompareVar;
      MidCode.Var patCompareVar;
      Option<DAE.Type> optType;

      Boolean bool;
      Integer integer;
      Real real;
      String string;

    case {}
    algorithm
      // All patterns have been matched. Fall through to what happens on succesful match.
    then ();

    case (scrutinee,DAE.PAT_WILD()) :: restMatches
    algorithm
      patternToMidCode2(matches = restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (scrutinee,DAE.PAT_AS(id=id,ty=NONE(),attr=_,pat=pattern)) :: restMatches
    algorithm
      ty := RValueType(MidCode.VARIABLE(scrutinee));
      midvar := MidCode.VAR(id, ty, false);
      arrayUpdate(assignBlock, 1, MidCode.ASSIGN(midvar, MidCode.VARIABLE(scrutinee))::arrayGet(assignBlock,1));
      patternToMidCode2(matches = (scrutinee, pattern) :: restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (scrutinee,DAE.PAT_AS(id=id,ty=SOME(ty),attr=_,pat=pattern)) :: restMatches
    algorithm
      // ty=SOME(_) means that the contained value needs unboxing
      midvar := MidCode.VAR(id, ty, false);
      arrayUpdate(assignBlock, 1, MidCode.ASSIGN(midvar, MidCode.UNARYOP(MidCode.UNBOX(),scrutinee))::arrayGet(assignBlock,1));
      patternToMidCode2(matches = (scrutinee, pattern) :: restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (scrutinee,DAE.PAT_CONSTANT(ty=optType,exp=exp)) :: restMatches // TODO: what to do about optType
    algorithm
      //remove shared literal
      exp := match exp
      case DAE.SHARED_LITERAL(exp=exp) then exp;
      else                             then exp;
      end match;

      //unbox
      scrutinee := match optType
      case NONE()   then scrutinee;
      case SOME(_) then RValueToVar(MidCode.UNARYOP(MidCode.UNBOX(),scrutinee),state);
      end match;

      // test
      () := match exp
        case DAE.BCONST(bool=bool)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := RValueToVar(MidCode.LITERALBOOLEAN(bool), state);
        then ();
        case DAE.ICONST(integer=integer)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := RValueToVar(MidCode.LITERALINTEGER(integer), state);
        then ();
        case DAE.RCONST(real=real)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := RValueToVar(MidCode.LITERALREAL(real), state);
        then ();
        case DAE.ENUM_LITERAL(index=integer)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := RValueToVar(MidCode.LITERALINTEGER(integer), state);
        then ();
        case DAE.LIST(valList = {})
        algorithm
          scrutineeCompareVar := RValueToVar(MidCode.ISCONS(scrutinee), state);
          patCompareVar := RValueToVar(MidCode.LITERALBOOLEAN(false), state);
        then ();
        case DAE.META_OPTION(exp = NONE())
        algorithm
          scrutineeCompareVar := RValueToVar(MidCode.ISSOME(scrutinee), state);
          patCompareVar := RValueToVar(MidCode.LITERALBOOLEAN(false), state);
        then ();
        case DAE.SCONST(string=string)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := RValueToVar(MidCode.LITERALSTRING(string), state);
        then ();
        else
        algorithm
          Error.addInternalError("DAE.Exp to Mid conversion failed for pattern constant. Exp:" + ExpressionDump.dumpExpStr(exp,0) + ".\n", sourceInfo());
        then fail();
      end match;

      // generic part of test
      ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);

      stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(), scrutineeCompareVar, patCompareVar )), state);
      stateAddBailOnFalse(ok, labelNoMatch, state);
      patternToMidCode2(matches = restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (scrutinee,DAE.PAT_META_TUPLE(morePatterns)) :: restMatches
    algorithm
      listTypes := match scrutinee.ty
        case DAE.T_METATUPLE(listTypes) then listTypes;
        else algorithm Error.addInternalError("Wrong type of midvar in tuple pattern: "  + DAEDump.daeTypeStr(scrutinee.ty) + ".\n", sourceInfo()); then fail();
      end match;

      moreMatches := {};
      iterator := morePatterns;
      fieldNr := 0;
      while not listEmpty(iterator) loop
        midvar := RValueToVar(MidCode.METAFIELD(scrutinee,fieldNr,listHead(listTypes)),state);
        moreMatches := (midvar, listHead(iterator)) :: moreMatches;
        fieldNr := fieldNr + 1;
        iterator := List.rest(iterator);
        listTypes := List.rest(listTypes);
      end while;
      moreMatches := listReverse(moreMatches);
      patternToMidCode2(matches = listAppend(moreMatches, restMatches), state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (scrutinee,DAE.PAT_SOME(pattern)) :: restMatches
    algorithm
      ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
      scrutineeCompareVar := RValueToVar(MidCode.ISSOME(scrutinee), state);
      patCompareVar       := RValueToVar(MidCode.LITERALBOOLEAN(true), state);
      stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
      stateAddBailOnFalse(ok, labelNoMatch, state);

      ty := match scrutinee.ty
        case DAE.T_METAOPTION(ty=ty)
        then ty;
        else algorithm Error.addInternalError("Wrong type of midvar in option pattern.\n", sourceInfo()); then fail();
      end match;

      midvar := RValueToVar(MidCode.METAFIELD(scrutinee,0,ty),state);
      patternToMidCode2(
        matches =  (midvar,pattern)::restMatches,
        state=state,
        assignBlock=assignBlock,
        labelNoMatch=labelNoMatch
        );
    then ();

    case (scrutinee,DAE.PAT_CONS(head=headPattern,tail=restPattern)) :: restMatches
    algorithm
      scrutineeCompareVar := RValueToVar(MidCode.ISCONS(scrutinee), state);
      patCompareVar := RValueToVar(MidCode.LITERALBOOLEAN(true), state);
      ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
      stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
      stateAddBailOnFalse(ok, labelNoMatch, state);

      ty := match scrutinee.ty
        case DAE.T_METALIST(ty=DAE.T_UNKNOWN())
        algorithm Error.addInternalError("Found list of unknown in cons pattern: " + DAEDump.daeTypeStr(scrutinee.ty) +".\n", sourceInfo()); then fail();
        case DAE.T_METALIST(ty=ty)
        then ty;
        else algorithm Error.addInternalError("Wrong type of midvar in option pattern.\n", sourceInfo()); then fail();
      end match;

      headVar := RValueToVar(MidCode.METAFIELD(scrutinee,0,ty),state);
      restVar := RValueToVar(MidCode.METAFIELD(scrutinee,1,scrutinee.ty),state);

      patternToMidCode2(
        matches=(headVar,headPattern)::(restVar,restPattern)::restMatches,
        state=state,
        assignBlock=assignBlock,
        labelNoMatch=labelNoMatch
        );

    then ();

    case (scrutinee,DAE.PAT_CALL(name,index,morePatterns,fields,typeVars,knownSingleton)) :: restMatches
    algorithm
      // TODO: Is this correct usage of knownSingleton?

      if not knownSingleton
      then
        ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
        scrutineeCompareVar := RValueToVar(MidCode.UNIONTYPEVARIANT(scrutinee) , state);
        patCompareVar       := RValueToVar(MidCode.LITERALINTEGER(index) , state);
        stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
        stateAddBailOnFalse(ok, labelNoMatch, state);
      end if;

      listTypes := list(v.ty for v in fields);

      moreMatches := {};
      iterator := morePatterns;
      fieldNr := 1;
      while not listEmpty(iterator) loop
        midvar := RValueToVar(MidCode.METAFIELD(scrutinee,fieldNr,listHead(listTypes)),state);
        moreMatches := (midvar, listHead(iterator)) :: moreMatches;
        fieldNr := fieldNr + 1;
        iterator := List.rest(iterator);
        listTypes := List.rest(listTypes);
      end while;
      moreMatches := listReverse(moreMatches);

      patternToMidCode2(matches = listAppend(moreMatches, restMatches), state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();

    case (_,DAE.PAT_AS_FUNC_PTR())::_
    algorithm
      Error.addInternalError("DAE.Pattern to Mid conversion failed. Unimplemented pattern: PAT_AS_FUNC_PTR.\n", sourceInfo());
    then fail();
    case (_,DAE.PAT_CALL_TUPLE())::_
    algorithm
      Error.addInternalError("DAE.Pattern to Mid conversion failed. Unimplemented pattern: PAT_CALL_TUPLE.\n", sourceInfo());
    then fail();
    case (_,DAE.PAT_CALL_NAMED())::_
    algorithm
      Error.addInternalError("DAE.Pattern to Mid conversion failed. Unimplemented pattern: PAT_CALL_NAMED.\n", sourceInfo());
    then fail();
    else
    algorithm
      Error.addInternalError("DAE.Pattern to Mid conversion failed\n", sourceInfo());
    then fail();
  end match;
end patternToMidCode2;

annotation(__OpenModelica_Interface="backend");

end DAEToMid;

