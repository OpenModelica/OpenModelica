/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
import MidCodeUtil;
import MidToMid;
import SimCode;
import SimCodeFunction;

function daeProgramToMid
    input String name;
    input list<SimCodeFunction.Function> simFuncs;
    input list<SimCodeFunction.RecordDeclaration> recordDeclarations;
    output MidCode.Program outProgram;
protected
  list<MidCode.Function> funcs = DAEFunctionsToMid(simFuncs);
  list<MidCode.Record> records = daeRecordsToMid(recordDeclarations);
algorithm
  if Flags.isSet(Flags.DUMP_MIDCODE) then
    try
      print(MidCodeUtil.dumpProgram(MidCode.PROGRAM("dump", funcs, records)));
    else
      Error.addInternalError("Failed to dump MidCode\n", sourceInfo());
      fail();
    end try;
  end if;
  outProgram := MidCode.PROGRAM(name, funcs, records);
end daeProgramToMid;

function daeRecordsToMid
  "Converts DAE records to corresponding MidCode records"
    input list<SimCodeFunction.RecordDeclaration> recordDeclarations;
    output list<MidCode.Record> midRecords;
algorithm
  midRecords := list(genRecordDecl(r) for r in recordDeclarations);
end daeRecordsToMid;

function DAEFunctionToMid
  input SimCodeFunction.Function simfunc;
  output MidCode.Function midfunc;
protected
  State state;
  DoubleEnded.MutableList<MidCode.Var> inputs;
  DoubleEnded.MutableList<MidCode.Var> outputs;
  MidCode.Var tmpVar;
  MidCode.Block block_;
  Absyn.Path path;
  Integer labelFirst;
  Integer labelNext;
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
    list<SimCodeFunction.Variable> inVars;
    list<SimCodeFunction.Variable> biVars;
    list<DAE.Statement> body;
    list<SimCodeFunction.SimExtArg> extArgs;
    list<String> includes;
    list<MidCode.Var> midOutVars;
    SCode.Visibility visibility;
    SourceInfo info;
    String extName;
    SimCodeFunction.SimExtArg extReturn;
  case SimCodeFunction.FUNCTION(name, outVars, functionArguments, variableDeclarations, body, visibility, info)
    algorithm
    labelFirst := GenBlockId();
    path := name;
    inputs := DoubleEnded.fromList({});
    outputs := DoubleEnded.fromList({});
    state := STATE(DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   Mutable.create(labelFirst),
                   Mutable.create({}),
                   Mutable.create({}),
                   Mutable.create(HashTableMidVar.emptyHashTable()));
    for simcodeVar in outVars loop
      tmpVar := ConvertSimCodeVars(simcodeVar, state, true);
      DoubleEnded.push_back(outputs, tmpVar);
    end for;
    for simcodeVar in variableDeclarations loop
      tmpVar := ConvertSimCodeVars(simcodeVar, state, true);
      DoubleEnded.push_back(state.locals, tmpVar);
    end for;
    for simcodeVar in functionArguments loop
      DoubleEnded.push_back(inputs, ConvertSimCodeVars(simcodeVar, state));
    end for;
    StmtsToMid(body, state);
    stateTerminate(-1, MidCode.RETURN(), state);
    midfunc := MidCode.FUNCTION(name=path,
                                locals=DoubleEnded.toListAndClear(state.locals),
                                localBufs=DoubleEnded.toListAndClear(state.localBufs),
                                localBufPtrs=DoubleEnded.toListAndClear(state.localBufPtrs),
                                inputs=DoubleEnded.toListAndClear(inputs),
                                outputs=DoubleEnded.toListAndClear(outputs),
                                body=DoubleEnded.toListAndClear(state.blocks),
                                entryId=labelFirst,
                                exitId=GenBlockId());
    midfunc := MidToMid.longJmpGoto(midfunc);
  then ();
  /*TODO: Not completed
     Add more external languages and more options here. Needs to be completed.*/
  case SimCodeFunction.EXTERNAL_FUNCTION(name,extName,functionArguments,extArgs,extReturn,inVars,outVars,biVars,includes,_,"C",_,_,_)
  algorithm
    /*TODO: This will be needed in more then one place, a function should be written.*/
    labelFirst := GenBlockId();
    path := name;
    inputs := DoubleEnded.fromList({});
    outputs := DoubleEnded.fromList({});
    state := STATE(DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   DoubleEnded.fromList({}),
                   Mutable.create(labelFirst),
                   Mutable.create({}),
                   Mutable.create({}),
                   Mutable.create(HashTableMidVar.emptyHashTable()));
    /*For now only functions with outputs are handled.*/
    outputs := DoubleEnded.fromList({});
    for simcodeVar in outVars loop
      DoubleEnded.push_back(outputs, ConvertSimCodeVars(simcodeVar, state));
    end for;
    labelNext := GenBlockId();
    midOutVars := DoubleEnded.toListAndClear(outputs);
    /*TODO:For now call the external function.*/
    stateTerminate(labelNext,MidCode.CALL(Absyn.IDENT(extName)
                                          ,true
                                          ,{}
                                          ,List.map(midOutVars, MidCodeUtil.varToOutVar)
                                          ,labelNext
                                          ,DAE.T_REAL_DEFAULT /* Should be output variable */)
                   ,state);
    /* After call assign result to temporary variables */
    stateTerminate(-1, MidCode.RETURN(), state);
    midfunc := MidCode.FUNCTION(name=path,
                                locals=DoubleEnded.toListAndClear(state.locals),
                                localBufs=DoubleEnded.toListAndClear(state.localBufs),
                                localBufPtrs=DoubleEnded.toListAndClear(state.localBufPtrs),
                                inputs=DoubleEnded.toListAndClear(inputs),
                                outputs=midOutVars,
                                body=DoubleEnded.toListAndClear(state.blocks),
                                entryId=labelFirst,
                                exitId=GenBlockId());
    midfunc := MidToMid.longJmpGoto(midfunc);
  then();
  else
  algorithm
    Error.addInternalError("Unsupported SimCodeFunction.Function type\n", sourceInfo());
    Error.addInternalError("DAEToMidDump " + anyString(simfunc) + "\n", sourceInfo());
    fail();
  then ();
  end match;
end DAEFunctionToMid;

protected
import Absyn;
import AbsynUtil;
import BaseHashTable;
import ComponentReference;
import DAE;
import DAEDump;
import DAEUtil;
import DoubleEnded;
import Error;
import Expression;
import ExpressionDump;
import HashTableMidVar;
import List;
import Mutable;
import System;
import Types;

uniontype State
  record STATE
    DoubleEnded.MutableList<MidCode.Var> locals;
    DoubleEnded.MutableList<MidCode.VarBuf> localBufs;
    DoubleEnded.MutableList<MidCode.VarBufPtr> localBufPtrs;
    DoubleEnded.MutableList<MidCode.Block> blocks;
    DoubleEnded.MutableList<MidCode.Stmt> stmts;
    Mutable.Mutable<Integer> blockid;
    Mutable.Mutable<list<Integer>> continuejumps;
    Mutable.Mutable<list<Integer>> breakjumps;
    Mutable.Mutable<HashTableMidVar.HashTable> vars;
  end STATE;
end State;

/*
function listZip<X,Y>
  "List.zip fails for lists of unequal length
   but truncating is the more common semantics."
  input  list<X>          xs;
  input  list<Y>          ys;
  output list<tuple<X,Y>> zs;
*/

protected
function getSimCodeVarName
  input SimCodeFunction.Variable simV;
  output DAE.ComponentRef cref;
algorithm
  cref := match simV
    case SimCodeFunction.VARIABLE(__) then simV.name;
    else fail();
  end match;
end getSimCodeVarName;

function GenTmpVar
  input DAE.Type ty;
  input State state;
  output MidCode.Var var;
algorithm
  var := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)), ty, false);
  DoubleEnded.push_back(state.locals, var);
end GenTmpVar;

function GenTmpVarVolatile
  input DAE.Type ty;
  input State state;
  output MidCode.Var var;
algorithm
  var := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)), ty, true);
  DoubleEnded.push_back(state.locals, var);
end GenTmpVarVolatile;

function GenTmpVarBuf
  input State state;
  output MidCode.VarBuf var;
algorithm
  var := MidCode.VARBUF("_jmpbuf_" + intString(System.tmpTickIndex(47)));
  DoubleEnded.push_back(state.localBufs, var);
end GenTmpVarBuf;

function GenTmpVarBufPtr
  " Uses same naming scheme as variables.
     Doesn't have to as long as they don't collide.
  "
  input State state;
  output MidCode.VarBufPtr var;
algorithm
  var := MidCode.VARBUFPTR("_tmp_" + intString(System.tmpTickIndex(46)));
  DoubleEnded.push_back(state.localBufPtrs, var);
end GenTmpVarBufPtr;

function GenBlockId
  output Integer id;
algorithm
  id := System.tmpTickIndex(45);
end GenBlockId;

function ConvertSimCodeVars //Observe that variables can be in three places. Sometimes it seem that variables in outputs are duplicated in locals.
  input SimCodeFunction.Variable simcodevar;
  input State state;
  input Boolean isLocalOrOutputVar = false "If the variable is either an output or local variable extra array logic is needed";
  output MidCode.Var var;
algorithm
  var := match simcodevar
    local
    MidCode.Var midcodevar;
    case SimCodeFunction.VARIABLE(__)
    algorithm
      midcodevar := crefToMidVar(simcodevar.name, state);
      if isLocalOrOutputVar and Types.isArray(midcodevar.ty) then //Special code need to be generated for Arrays
        genAllocaLogicForArray(midcodevar,state);
      end if;
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

function genAllocaLogicForArray
  input MidCode.Var var;
  input State state;
protected
  list<DAE.Exp> dims;
  list<MidCode.Var> args;
  MidCode.Var dimSize;
algorithm
  dims := List.map(MidCodeUtil.getDimensions(var.ty),Expression.dimensionSizeExpHandleUnkown);
  dimSize := rValueToVar(ExpToMid(DAE.ICONST(listLength(dims)),state),state);
  args := List.map1(List.map1(dims,ExpToMid,state),rValueToVar,state);
  stateAddStmt(MidCode.ALLOC_ARRAY(getArrayAllocaCall(DAEUtil.expTypeElementType(var.ty))
                                  ,var
                                  ,dimSize
                                  ,args), state);
end genAllocaLogicForArray;

function GetCrefIndexVar
  "Returns a MidCode.Var with the value of a DAE index present in a component ref."
  input DAE.ComponentRef cref;
  input State state;
  output Option<MidCode.Var> var1;
  output Option<MidCode.Var> var2;
protected
  list<DAE.Subscript> subscripts;
algorithm
  subscripts := ComponentReference.crefLastSubs(cref);
  (var1,var2) := match subscripts
    local
      DAE.Subscript subscript1;
      DAE.Subscript subscript2;
      MidCode.Var indexvar1;
      MidCode.Var indexvar2;
    case {} then (NONE(),NONE());
    case {subscript1 as DAE.INDEX(__)}
    algorithm
      indexvar1 := rValueToVar(ExpToMid(subscript1.exp, state), state);
    then (SOME(indexvar1),NONE());
    case {subscript1 as DAE.INDEX(__),subscript2 as DAE.INDEX(__)}
    algorithm
      indexvar1 := rValueToVar(ExpToMid(subscript1.exp, state), state);
      indexvar2 := rValueToVar(ExpToMid(subscript2.exp, state), state);
    then (SOME(indexvar1),SOME(indexvar2));
  end match;
end GetCrefIndexVar;

function crefToMidVar
  "Converts a DAE.ComponentReference to a MidVar.
   Besides doing this conversion the hashtable for the variables
   is updated.
   Qualified component references are generated with .
  "
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
    case DAE.CREF_QUAL(_, ty, _)
    algorithm
      ident_ := ComponentReference.crefStr(cref.componentRef);
      then (ident_, ty);
    else
    algorithm
      Error.addInternalError("crefToMidVar error", sourceInfo());
      Error.addInternalError(anyString(cref) + "\n", sourceInfo());
    then fail();
    end match;
    Mutable.update(state.vars, BaseHashTable.add((cref, MidCode.VAR(ident, Types.complicateType(ty), false)), Mutable.access(state.vars)));
  end if;
  var := BaseHashTable.get(cref, Mutable.access(state.vars));
end crefToMidVar;

function crefToMidVarAddToLocal
  "Same operation as crefToMidVar. However, it also adds creates a new local variable in state."
  //TODO: handle scopes better (From my understanding so far 2018-04 Scopes does not seem to be handled at all...  -John)
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
      Error.addInternalError("crefToMidVar error", sourceInfo());
    then fail();
    end match;
    Mutable.update(state.vars, BaseHashTable.add((cref, MidCode.VAR(ident, Types.complicateType(ty), false)), Mutable.access(state.vars)));
  end if;
  var := BaseHashTable.get(cref, Mutable.access(state.vars));
  DoubleEnded.push_back(state.locals,var);
end crefToMidVarAddToLocal;

function RValueType
  "Returns the DAE type of an RValue."
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
    //TODO: move to separate BOX/UNBOX?
    //TODO: separate CAST? since has new type
    //TODO: need to check and separate string etc. boxing vs. metaboxed
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
    case MidCode.LITERALARRAY(__) then rvalue.ty;
    case MidCode.DEREFERENCE(__) then rvalue.ty;
    else
    algorithm
      Error.addInternalError("Could not find the correct type of an RValue.\n", sourceInfo());
    then fail();
  end match;
end RValueType;

function rValueToVar
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
    DoubleEnded.push_back(state.stmts, MidCode.ASSIGN(tmpvar, rvalue));
  then tmpvar;
end match;
end rValueToVar;

/*Added by johti139 TODO: Refactor together with the method above in some way*/
function rValueToVarCast
  input MidCode.RValue rvalue;
  input DAE.Type ty "The type we cast to.";
  input State state;
  output MidCode.Var var;
algorithm
var := match rvalue
  local
    MidCode.Var tmpvar;
  case MidCode.VARIABLE(__)
  //Create a variable with the casted type.
  then MidCode.VAR(rvalue.src.name,ty/*Another type is specified*/,rvalue.src.volatile);
  else
  algorithm
    tmpvar := GenTmpVar(ty,state);
    DoubleEnded.push_back(state.stmts, MidCode.ASSIGN(tmpvar, rvalue));
  then tmpvar;
end match;
end rValueToVarCast;


function genRecordDecl
  input SimCodeFunction.RecordDeclaration rDecl;
  output MidCode.Record midCodeRecord;
algorithm
  midCodeRecord := match rDecl
    local
      list<DAE.Var> fields = {};
      DAE.ComponentRef cref;
    case SimCodeFunction.RECORD_DECL_DEF(__) then
      MidCode.RECORD_DECLARATION(MidCodeUtil.encodeIdentifierDotPath(rDecl.path)
                                 ,MidCodeUtil.encodeIdentifierUnderscorePath(rDecl.path)
                                 ,rDecl.fieldNames);
    else
    algorithm
      Error.addInternalError("Unsupported SimCodeFunction.RecordDeclaration type\n",
                             sourceInfo());
      then fail();
    end match;
end genRecordDecl;

public function DAEFunctionsToMid
  input list<SimCodeFunction.Function> simfuncs;
  output list<MidCode.Function> midfuncs;
algorithm
  midfuncs := list(DAEFunctionToMid(simfunc) for simfunc in simfuncs);
end DAEFunctionsToMid;

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
        list<MidCode.Var> args;
        MidCode.Var varCref;
        MidCode.Var varArray;
        MidCode.Var varIndex;
        MidCode.Var varDim;
        MidCode.Var varValue;
        MidCode.Var varCondition;
        MidCode.Var varIter;
        MidCode.Var varLast;
        MidCode.Var varStep;
        MidCode.Var varMessage;
        MidCode.Var varLevel;
        MidCode.Var varRHS;
        MidCode.Var varTmp;
        MidCode.OutVar outvar;
        MidCode.Block block_;
        Integer labelBody;
        Integer labelNext;
        Integer labelCondition;
        Integer labelStep;
        Integer dimSize;
        DAE.Else else_;
        DoubleEnded.MutableList<MidCode.OutVar> outvars;
        String iter;
        Integer index;
        list<DAE.Subscript> subscripts;
        MidCode.Stmt midstmt;
        MidCode.RValue rvalue;
       /*Note that regular arrays can occur as regular assignments. TODO write to multidim arrays.*/
      case DAE.STMT_ASSIGN(ty, exp1 as DAE.CREF(__), exp, _)
        algorithm
         cref := ComponentReference.crefLastCref(exp1.componentRef);
         () := match cref
            local DAE.Type identType; list<DAE.Subscript> subscriptLst;
            /*Generates code for indexing Modelica arrays!*/
            case DAE.CREF_IDENT(_ ,DAE.T_ARRAY(__), subscriptLst)
            algorithm
              varArray := crefToMidVar(cref,state);
              args := List.map1(List.map1(subscriptLst,SubscriptToMid,state),rValueToVar,state);
              varIndex := rValueToVar(ExpToMid(DAE.ICONST(listLength(args) - 1),state),state);
              dimSize := listLength(args);
              varTmp := GenTmpVar(ty,state);
              varValue := GenTmpVar(cref.identType,state);
              args := varArray :: varIndex :: args;
              labelNext := GenBlockId();
              stateTerminate(labelNext,MidCode.CALL(Absyn.IDENT(genArrayIxFunction(ty,dimSize)),true,args
                                                    ,{MidCode.OUT_VAR(varValue)},labelNext,cref.identType), state);
              stateAddStmt(MidCode.ASSIGN(varTmp, ExpToMid(exp, state)), state);
              stateAddStmt(MidCode.ASSIGN(varValue, MidCode.VARIABLE(varTmp)), state);
            then();
            else //Assignment of other types, intent is primitive types for now (Boolean,String,Integer,Real)
              algorithm
                varCref := crefToMidVar(cref,state);
                stateAddStmt(MidCode.ASSIGN(varCref, ExpToMid(exp, state)), state);
              then ();
         end match;
      then ();
      case DAE.STMT_ASSIGN(_, exp1 as DAE.ASUB(__), exp, _) //Will only occur for MModelica arrays it seems.
      algorithm
        varArray := rValueToVar(ExpToMid(exp1.exp, state), state);
        varIndex := match exp1.sub
          local
            DAE.Exp indexexp;
          case {indexexp} then rValueToVar(ExpToMid(indexexp, state), state);
        end match;
        varValue := rValueToVar(ExpToMid(exp, state), state);
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.CALL(Absyn.IDENT("arrayUpdate"), true, {varArray, varIndex, varValue}, {}, labelNext,
                                               DAE.T_METAARRAY(varArray.ty)), state);
      then ();
      case DAE.STMT_ASSIGN(_, DAE.PATTERN(pattern), exp, _) //Seems to be incorrectly implemented for a couple of cases, ex: H::T := lst in alg sec.
      algorithm
        varRHS  := rValueToVar(ExpToMid(exp,state),state);
        patternToMidCode(matches={(varRHS,pattern)},labelNoMatch=1,state=state); // pattern match
      then ();
      case DAE.STMT_ASSIGN(__)
      algorithm
        Error.addInternalError("DAE.STMT_ASSIGN to Mid conversion failed " + ExpressionDump.dumpExpStr(stmt.exp1,0) + "\n", sourceInfo());
      then fail();
      case DAE.STMT_TUPLE_ASSIGN(_, expLst, exp, _)
      algorithm
        outvars := DoubleEnded.fromList({});
        for exp1 in expLst loop
          () := match exp1
            case DAE.CREF(DAE.WILD())
            algorithm
              DoubleEnded.push_back(outvars, MidCode.OUT_WILD());
            then ();
            case DAE.CREF(__)
            algorithm
              varCref := crefToMidVar(exp1.componentRef, state);
              DoubleEnded.push_back(outvars, MidCode.OUT_VAR(varCref));
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
          CallToMid(exp, DoubleEnded.toListAndClear(outvars), state);
        then ();
        case DAE.MATCHEXPRESSION(__)
        algorithm
          MatchExpressionToMid(exp, DoubleEnded.toListAndClear(outvars), state);
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
        varCondition := rValueToVar(ExpToMid(stmt.exp, state), state);
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
        varCondition := rValueToVar(ExpToMid(stmt.cond, state), state);
        varMessage := rValueToVar(ExpToMid(stmt.msg, state), state);
        varLevel := rValueToVar(ExpToMid(stmt.level, state), state);
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.ASSERT(varCondition, varMessage, varLevel, labelNext), state);
      then ();
      case DAE.STMT_TERMINATE(__)
      algorithm
        varMessage := rValueToVar(ExpToMid(stmt.msg, state), state);
        labelNext := GenBlockId();
        stateTerminate(labelNext, MidCode.TERMINATE(varMessage), state);
      then ();
      case DAE.STMT_ASSIGN_ARR(__) //Right side seem to be CREFS, LEFTSIDE seem to be SHARED_LITERAL, source can be ignored?.
      algorithm
        varCref := crefToMidVar(unpackCrefFromExp(stmt.lhs),state);
        stateAddStmt(MidCode.ASSIGN(varCref, ExpToMid(stmt.exp/*rhs*/, state)), state);
      then();
      else
      algorithm
        Error.addInternalError("DAE.Statement to Mid conversion failed " + DAEDump.ppStatementStr(stmt), sourceInfo());
      then fail();
      end match;
      StmtsToMid(tail, state);
      //tror inte WHEN eller REINIT behöver göras, troligtvis ej relevant för algorithm
      //REINIT verkar dock ganska lätt att implementera
      //WHEN verkar vara lite klurigare. Inte så mycket svårare än IF troligtvis
        //endast i SIMULATION_CONTEXT, så kanske ej behövs
        //STMT_FAILURE ej relevant för algorithm
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
    Absyn.Path path;
    DAE.CallAttributes callattrs;
    DAE.ComponentRef cref;
    DAE.Exp exp1;
    DAE.Exp exp2;
    DAE.Exp exp3;
    DAE.Operator operator;
    DAE.Type ty;
    DoubleEnded.MutableList<MidCode.RValue> rValues;
    DoubleEnded.MutableList<MidCode.Var> values;
    Integer index;
    Integer labelBody;
    Integer labelElse;
    Integer labelNext;
    Integer length;
    Integer numTailTypes;
    MidCode.BinaryOp binop;
    MidCode.Block block_;
    MidCode.RValue rvalue;
    MidCode.Terminator terminator;
    MidCode.UnaryOp unop;
    MidCode.Var varArray;
    MidCode.Var varCar;
    MidCode.Var varCdr;
    MidCode.Var varCref;
    MidCode.Var varExp2;
    MidCode.Var varExp;
    MidCode.Var varIndex;
    MidCode.Var varSize;
    MidCode.Var varTmp;
    Option<DAE.Exp> option;
    Option<MidCode.Var> optVarExp1;
    Option<MidCode.Var> optVarExp2;
    list<DAE.Exp> expLst;
    list<DAE.Subscript> subscripts;
    list<MidCode.OutVar> outvars;
  case DAE.SIZE(exp1,SOME(exp2)) //To options for size operator. We only generate code for the one with the argument.
    algorithm
      varIndex := rValueToVar(ExpToMid(exp2,state),state);
      varArray := rValueToVar(ExpToMid(exp1,state),state);
      varSize := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      labelNext := GenBlockId();
      stateTerminate(labelNext,MidCode.CALL(Absyn.IDENT("size_of_dimension_base_array")
                                            ,true
                                            ,{varArray,varIndex}
                                            ,{MidCode.OUT_VAR(varSize)}
                                            ,labelNext
                                            ,DAE.T_INTEGER_DEFAULT),state);
    then MidCode.VARIABLE(varSize);
  case DAE.ICONST(__) then MidCode.LITERALINTEGER(exp.integer);
  case DAE.ENUM_LITERAL(__) then MidCode.LITERALINTEGER(exp.index);
  case DAE.RCONST(__) then MidCode.LITERALREAL(exp.real);
  case DAE.SCONST(__) then MidCode.LITERALSTRING(exp.string);
  case DAE.SHARED_LITERAL(__) then ExpToMid(exp.exp, state);
  case DAE.ARRAY(__)  then fail(); //Not supported
  case DAE.MATRIX(__) then fail(); //Not supported
  case DAE.RECORD(__)
    // values := DoubleEnded.fromList({});
    // for exp in expLst loop
    //   varExp := rValueToVar(ExpToMid(exp, state), state);
    //   DoubleEnded.push_back(values, varExp);
    // end for;
    // then MidCode.LITERAL_RECORD(exp.path, values)
    then fail();
  case DAE.BOX(__)
  algorithm
    varExp := rValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.UNARYOP(MidCode.BOX(), varExp);
  case DAE.UNBOX(__)
  algorithm
    varExp := rValueToVar(ExpToMid(exp.exp, state), state);
    then MidCode.UNARYOP(MidCode.UNBOX(), varExp);
  case DAE.BCONST(__) then MidCode.LITERALBOOLEAN(exp.bool);
  case DAE.META_OPTION(SOME(exp1))
  algorithm
    varExp := rValueToVar(ExpToMid(exp1, state), state);
    then MidCode.LITERALMETATYPE({varExp}, Types.complicateType(DAE.T_METAOPTION(varExp.ty)));
  case DAE.META_OPTION(NONE())
    then MidCode.LITERALMETATYPE({}, Types.complicateType(DAE.T_NONE_DEFAULT));
  case DAE.META_TUPLE(expLst)
  algorithm
    values := DoubleEnded.fromList({});
    for exp in expLst loop
      varExp := rValueToVar(ExpToMid(exp, state), state);
      DoubleEnded.push_back(values, varExp);
    end for;
    then MidCode.LITERALMETATYPE(DoubleEnded.toListAndClear(values), Types.complicateType(Expression.typeof(exp)));
  case DAE.METARECORDCALL(_, expLst, _, _, _)
  algorithm
    values := DoubleEnded.fromList({});
    for exp in expLst loop
      varExp := rValueToVar(ExpToMid(exp, state), state);
      DoubleEnded.push_back(values, varExp);
    end for;
    then MidCode.LITERALMETATYPE(DoubleEnded.toListAndClear(values), Types.complicateType(Expression.typeof(exp)));
  case DAE.CONS(__)
  algorithm
    varCar := rValueToVar(ExpToMid(exp.car, state), state);
    varCdr := rValueToVar(ExpToMid(exp.cdr, state), state);
  then MidCode.LITERALMETATYPE({varCar, varCdr}, Types.complicateType(DAE.T_METALIST(varCar.ty)));
  case DAE.LIST(expLst)
  algorithm
    expLst := listReverse(expLst);
    varCdr := GenTmpVar(DAE.T_METALIST_DEFAULT,state);
    DoubleEnded.push_back(state.stmts, MidCode.ASSIGN(varCdr, MidCode.LITERALMETATYPE({}, DAE.T_METALIST_DEFAULT)));
    for exp in expLst loop
      varCar := rValueToVar(ExpToMid(exp, state), state);
      varTmp := GenTmpVar(DAE.T_METALIST(Types.complicateType(varCar.ty)),state);
      DoubleEnded.push_back(state.stmts, MidCode.ASSIGN(varTmp, MidCode.LITERALMETATYPE({varCar, varCdr}, Types.complicateType(DAE.T_METALIST(varCar.ty)))));
      varCdr := varTmp;
    end for;
  then MidCode.VARIABLE(varCdr);
  case DAE.CREF(cref, _) //Array indexing among other things.
  algorithm
    varCref := crefToMidVar(cref, state);
    //TODO This seems to be a bug in the compiler an intermediate step is needed before matching on tuples.
    (optVarExp1,optVarExp2) := GetCrefIndexVar(cref, state);
    rvalue := match (optVarExp1,optVarExp2)
      local
        MidCode.Var indexvar1,indexvar2,nDims;
      case (NONE(),NONE()) then MidCode.VARIABLE(varCref);
      case (SOME(indexvar1),NONE())
        algorithm
        labelNext := GenBlockId();
        varArray := GenTmpVar(varCref.ty,state);
        varTmp := GenTmpVar(DAEUtil.expTypeElementType(varCref.ty),state);
        nDims := rValueToVar(ExpToMid(DAE.ICONST(1),state),state);
        stateTerminate(labelNext,MidCode.CALL(Absyn.IDENT(genArrayIxFunction1D(DAEUtil.expTypeElementType(varCref.ty))), true, {varCref,nDims,indexvar1},
                                              {MidCode.OUT_VAR(varArray)}, labelNext,varCref.ty),state);
        stateAddStmt(MidCode.ASSIGN(varTmp,MidCode.DEREFERENCE(varArray,varCref.ty)),state);
        then MidCode.VARIABLE(varTmp);
        case (SOME(indexvar1),SOME(indexvar2))
        algorithm
        labelNext := GenBlockId();
        varArray := GenTmpVar(varCref.ty,state);
        varTmp := GenTmpVar(DAEUtil.expTypeElementType(varCref.ty),state);
        nDims := rValueToVar(ExpToMid(DAE.ICONST(2),state),state);
        stateTerminate(labelNext,MidCode.CALL(Absyn.IDENT(genArrayIxFunction2D(DAEUtil.expTypeElementType(varCref.ty))), true, {varCref,nDims,indexvar1,indexvar2},
                                              {MidCode.OUT_VAR(varArray)}, labelNext,varCref.ty),state);
        stateAddStmt(MidCode.ASSIGN(varTmp,MidCode.DEREFERENCE(varArray,varCref.ty)),state);
        then MidCode.VARIABLE(varTmp);
    end match;
  then rvalue;
  case DAE.ASUB(exp1, expLst) //Array subscripts are not supported.
  algorithm
    varExp := rValueToVar(ExpToMid(exp1, state), state);
    varExp2 := match expLst
      local
        DAE.Exp indexexp;
      case {indexexp} then rValueToVar(ExpToMid(indexexp, state), state);
    end match;
    varTmp := GenTmpVar(Types.complicateType(Expression.typeof(exp)),state);
    labelNext := GenBlockId();
    stateTerminate(labelNext,
      MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varExp, varExp2}, {MidCode.OUT_VAR(varTmp)}, labelNext,DAE.T_ARRAY_INT_NODIM),
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
    varExp := rValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.METAFIELD(varExp, exp.ix, Types.complicateType(exp.ty));
  case DAE.RSUB(__)
  algorithm
    varExp := rValueToVar(ExpToMid(exp.exp, state), state);
  then MidCode.METAFIELD(varExp, exp.ix, Types.complicateType(exp.ty));
  case DAE.CAST(ty, exp1)
  algorithm
    varExp := rValueToVar(ExpToMid(exp1,state),state); //Will the expression to cast.
    varTmp := GenTmpVar(ty,state); //Tmp variable of the variable we want to cast the expression to.
    stateAddStmt(MidCode.ASSIGN(varTmp,MidCode.UNARYOP(MidCode.MOVE(Expression.typeof(exp1)),varExp)),state); //Assign to variable
  then MidCode.VARIABLE(varTmp);
  case DAE.LUNARY(operator, exp1)
  algorithm
    varExp := rValueToVar(ExpToMid(exp1, state), state);
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
    varExp := rValueToVar(ExpToMid(exp1, state), state);
  then MidCode.UNARYOP(unop, varExp);
  case DAE.BINARY(exp1, operator, exp2)
  algorithm
    binop := match operator
    case DAE.ADD(__) then MidCode.ADD();
    case DAE.SUB(__) then MidCode.SUB();
    case DAE.MUL(__) then MidCode.MUL();
    case DAE.DIV(__) then MidCode.DIV();
    case DAE.POW(__) then MidCode.POW();
    else algorithm Error.addInternalError("Unsupported DAE.BINARY operation:" + anyString(operator) + "\n", sourceInfo()); then fail();
    end match;
    varExp := rValueToVar(ExpToMid(exp1, state), state);
    varExp2 := rValueToVar(ExpToMid(exp2, state), state);
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
      else algorithm Error.addInternalError("Unsupported DAE.RELATION operation:" + anyString(operator) + "\n", sourceInfo()); then fail();
    end match;
    varExp := rValueToVar(ExpToMid(exp1, state), state);
    varExp2 := rValueToVar(ExpToMid(exp2, state), state);
  then MidCode.BINARYOP(binop, varExp, varExp2);
  case DAE.IFEXP(exp1, exp2, exp3)
  algorithm
    labelBody := GenBlockId();
    labelElse := GenBlockId();
    labelNext := GenBlockId();
    varExp := rValueToVar(ExpToMid(exp1, state), state);
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
  then MidCode.VARIABLE(varTmp); //TODO: call-rvalue?
  case DAE.MATCHEXPRESSION(et=ty) // TODO: matchtype
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
  //TODO: maybe handle isFunctionPointerCall/isImpure. Also check for tail recursion.
  () := match call
  local
    Absyn.Path path;
    list<DAE.Exp> expLst;
    DAE.CallAttributes callattr;
    Integer labelNext;
    DoubleEnded.MutableList<MidCode.Var> inputs;
    MidCode.Var var1;
    MidCode.Var var2;
    MidCode.Block block_;
  /*If noEvent. Do not generate the call*/
  case DAE.CALL(Absyn.IDENT("noEvent"), expLst, callattr)
  algorithm
    labelNext := GenBlockId();
    assert(listLength(outvars) == 1, "MidCode: Length of output is assumed to be 1 for builtin calls of type noEvent");
    for exp1 in expLst loop
      var1 := rValueToVar(ExpToMid(exp1, state), state);
    end for;
    var2 := MidCodeUtil.outVarToVar(listHead(outvars));
    stateAddStmt(MidCode.ASSIGN(var2, MidCode.VARIABLE(var1)), state);
    stateTerminate(labelNext,
                   MidCode.GOTO(labelNext),
                   state);
  then();
  case DAE.CALL(path, expLst, callattr)
  algorithm
    labelNext := GenBlockId();
    inputs := DoubleEnded.fromList({});
    for exp1 in expLst loop
      var1 := rValueToVar(ExpToMid(exp1, state), state);
      DoubleEnded.push_back(inputs, var1);
    end for;
    stateTerminate(labelNext,
                    MidCode.CALL(path,callattr.builtin,DoubleEnded.toListAndClear(inputs),outvars,labelNext,callattr.ty),
                    state);
  then ();
  end match;
end CallToMid;

function ForToMid
  input DAE.Type type_; //skicka cref i stället, hämta typ därifrån?
  input String iter;
  input DAE.Exp range;
  input list<DAE.Statement> daestmtLst;
  input State state;
protected
  Integer labelBody;
  Integer labelCondition;
  Integer labelNext;
  Integer labelStep;
  MidCode.Var varCondition;
  MidCode.Var varCref;
algorithm
  varCref := crefToMidVar(DAE.CREF_IDENT(iter, type_, {}), state);
  DoubleEnded.push_back(state.locals, varCref);
  labelCondition := GenBlockId();
  labelStep := GenBlockId();
  labelBody := GenBlockId();
  labelNext := GenBlockId();
  Mutable.update(state.continuejumps, labelStep :: Mutable.access(state.continuejumps));
  Mutable.update(state.breakjumps, labelNext :: Mutable.access(state.breakjumps));
  varCondition := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
  () := match range //TODO, add sum over real arrays.
    local
      DAE.Exp start;
      DAE.Exp stop;
      DAE.Type rangeTy;
      Integer labelBody2;
      Integer labelCondition2;
      MidCode.RValue rvalueStep;
      MidCode.Var varFirst;
      MidCode.Var varIter;
      MidCode.Var varLast;
      MidCode.Var varRange;
      MidCode.Var varStep;
      Option<DAE.Exp> step;
    case DAE.RANGE(rangeTy, start, step, stop) //TODO Only supports integer ranges, seem to be boolean ranges etc aswell...
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
      stateTerminate(labelCondition2, /*TODO Is it really an integer all the time?*/
        MidCode.CALL(Absyn.IDENT("in_range_integer"), true, {varIter, varFirst, varLast}, {MidCode.OUT_VAR(varCondition)}, labelCondition2,DAE.T_BOOL({})),
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
      varRange := rValueToVar(ExpToMid(range, state), state);
      () := match varRange.ty
        case DAE.T_METATYPE(_)
        algorithm
          Error.addInternalError("metatype error", sourceInfo());
        then fail();
        case rangeTy as DAE.T_ARRAY(__)
        algorithm
          labelBody2 := GenBlockId();
          varIter := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varLast := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varStep := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.LITERALINTEGER(1)), state);
          stateAddStmt(MidCode.ASSIGN(varStep, MidCode.LITERALINTEGER(1)), state);
          stateTerminate(labelCondition,
            MidCode.CALL(Absyn.IDENT("arrayLength"), true, {varRange}, {MidCode.OUT_VAR(varLast)}, labelCondition, DAE.T_INTEGER_DEFAULT),
            state);
          stateAddStmt(MidCode.ASSIGN(varCondition, MidCode.BINARYOP(MidCode.LESSEQ(), varIter, varLast)), state);
          stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);
          stateTerminate(labelBody2,
            MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varRange, varIter}, {MidCode.OUT_VAR(varCref)}, labelBody2,rangeTy),
            state);
          StmtsToMid(daestmtLst, state);
          stateTerminate(labelStep, MidCode.GOTO(labelStep), state);
          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.BINARYOP(MidCode.ADD(), varIter, varStep)), state);
          stateTerminate(labelNext, MidCode.GOTO(labelCondition), state);
        then ();
        /*MetaArray will occur as Metaboxed, e.g when the intent is MetaArray*/
        case rangeTy as DAE.T_METABOXED(__)
        algorithm
          labelBody2 := GenBlockId();
          varIter := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varLast := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          varStep := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.LITERALINTEGER(1)), state);
          stateAddStmt(MidCode.ASSIGN(varStep, MidCode.LITERALINTEGER(1)), state);
          stateTerminate(labelCondition,
            MidCode.CALL(Absyn.IDENT("arrayLength"), true, {varRange}, {MidCode.OUT_VAR(varLast)}, labelCondition, DAE.T_INTEGER_DEFAULT),
            state);
          stateAddStmt(MidCode.ASSIGN(varCondition, MidCode.BINARYOP(MidCode.LESSEQ(), varIter, varLast)), state);
          stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);
          stateTerminate(labelBody2,
            MidCode.CALL(Absyn.IDENT("arrayGet"), true, {varRange, varIter}, {MidCode.OUT_VAR(varCref)}, labelBody2,rangeTy),
            state);
          StmtsToMid(daestmtLst, state);
          stateTerminate(labelStep, MidCode.GOTO(labelStep), state);
          stateAddStmt(MidCode.ASSIGN(varIter, MidCode.BINARYOP(MidCode.ADD(), varIter, varStep)), state);
          stateTerminate(labelNext, MidCode.GOTO(labelCondition), state);
        then ();
        case rangeTy as DAE.T_METALIST(_)
        algorithm
          labelBody2 := GenBlockId();
          varIter := varRange;
          stateTerminate(labelCondition, MidCode.GOTO(labelCondition), state);
          stateAddStmt(MidCode.ASSIGN(varCondition, MidCode.ISCONS(varIter)), state);
          stateTerminate(labelBody, MidCode.BRANCH(varCondition, labelBody, labelNext), state);
          stateTerminate(labelBody2,
            MidCode.CALL(Absyn.IDENT("listHead"), true, {varIter}, {MidCode.OUT_VAR(varCref)}, labelBody2,rangeTy),
            state);
          StmtsToMid(daestmtLst, state);
          stateTerminate(labelStep, MidCode.GOTO(labelStep), state);
          stateTerminate(labelNext,
            MidCode.CALL(Absyn.IDENT("listRest"), true, {varIter}, {MidCode.OUT_VAR(varIter)}, labelCondition,rangeTy),
            state);
        then ();
        else
        algorithm
          Error.addInternalError("Unknown type in for statement " + DAEDump.daeTypeStr(varRange.ty) + "\n", sourceInfo());
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
  var1 := rValueToVar(ExpToMid(exp, state), state);
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
  DoubleEnded.push_back(state.stmts, stmt);
end stateAddStmt;

function stateTerminate
  "Called when a terminator is encountered.
  clears the statement list in the state with all statments encountered so far.
  A basic block containing said statements is created. The label for the next basic block is set."
  input Integer newLabel;
  input MidCode.Terminator terminator;
  input State state;
protected
  MidCode.Block block_;
algorithm
  block_ := MidCode.BLOCK(stateGetCurrentLabel(state),
                          DoubleEnded.toListAndClear(state.stmts),
                          terminator);
  DoubleEnded.push_back(state.blocks, block_); //Add the block to the list of blocks.
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
  list<DAE.Element> localDecls;
algorithm
  /*
    I assume the Else case is a case with top level wild patterns (_,_,_).
  */
  // match just to get match elements
  () := match matchexpression
    case DAE.MATCHEXPRESSION(matchType=matchType, cases=cases, inputs=inputsCref, aliases=aliases,localDecls=localDecls)
    algorithm
      labelInit := stateGetCurrentLabel(state);
      labelMux := GenBlockId();
      labelFin := GenBlockId();
      matchContinue := match matchType
        case DAE.MATCHCONTINUE() then true;
        case DAE.MATCH() then false;
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
    for daeExp_aliasList in List.zip(inputsCref,aliases) loop
      (daeExp,aliasList) := daeExp_aliasList;
      srcVar := rValueToVar(ExpToMid(daeExp, state), state);
      ty := RValueType(MidCode.VARIABLE(srcVar));
      inputsMidVar := srcVar :: inputsMidVar;
      for alias in aliasList loop
        aliasVar := MidCode.VAR(name=alias, ty=ty, volatile=false);
        DoubleEnded.push_back(state.locals, aliasVar);
        stateAddStmt( MidCode.ASSIGN(aliasVar, MidCode.VARIABLE(srcVar) ), state );
      end for;
    end for;
    /*
    init:
      state = 0
      #IF MATCHCONTINUE
        PUSHJMP(J_old,J_new)
      goto mux
    */
    //JOHN: All local variables in the match expression must be added to the list of variables...
    listOfElementsToMidCodeVars(localDecls,state); //Create variables for all local variables in the MATCHEXPRESSION
    // volatile since we mutate it after setjmp
    muxState := GenTmpVarVolatile(DAE.T_INTEGER_DEFAULT, state);
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
      stateTerminate(labelFin, MidCode.SWITCH( muxState, List.zip( List.intRange(listLength(cases)+1), listAppend(caseLabels,{labelFin}) )  ), state);
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
        goto next;
    */

    /*
      We make the label for the next; thing we generate after the match expression.
      We replace this in the case loop as we add more cases.
    */
    labelFail := GenBlockId();
    labelFin2 := GenBlockId();
    labelOut := GenBlockId();
    if matchContinue
    then
      one := GenTmpVar(DAE.T_INTEGER_DEFAULT,state);
      stateAddStmt(MidCode.ASSIGN(one, MidCode.LITERALINTEGER(1)) ,state);
      stateAddStmt(MidCode.ASSIGN(muxState, MidCode.BINARYOP(MidCode.ADD(),muxState,one)),state);
      stateTerminate(labelFin, MidCode.SWITCH( muxState, List.threadTuple( List.intRange(listLength(cases)+1), listAppend(caseLabels,{labelFin}) )  ), state);
    else
      stateTerminate(labelFin, MidCode.GOTO(if not listEmpty(caseLabels) then listHead(caseLabels) else labelFail), state);
    end if;
    /*
    fin:
      #IF MATCHCONTINUE
        POPJMP(J_old)
      if state == nr_cases+1
        longjmp
      else
        goto next;
    */
    if matchContinue
    then
      stateTerminate(labelFin2, MidCode.POPJMP( muxOldBuf, labelFin2  ), state);
    else
      stateTerminate(labelFin2, MidCode.GOTO(labelFin2), state);
    end if;
    midvar := rValueToVar(MidCode.LITERALINTEGER(listLength(cases)+1), state);
    midvar2 := rValueToVar(MidCode.BINARYOP(MidCode.EQUAL(), muxState, midvar), state);
    stateTerminate(labelFail, MidCode.BRANCH(midvar2, labelFail, labelOut), state);
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
        case {} then (); /* No more cases to process. */
        case (DAE.CASE(patterns=patterns,body=daeBody,patternGuard=patternGuard,result=caseResult)::cases) // note: modifies cases
        algorithm
          // first do checks and assignments
          // NOTE: If the guard fails we will have made pattern assignments for a failing case. This is how it was done before as far as I can tell.
          if matchContinue
          then /*I think and I am pretty sure the patterns have to be reversed first because of the recursion - John*/
            patternToMidCode(state=state, matches=List.zip(inputsMidVar,listReverse(patterns)), labelNoMatch=labelMux);
          else
            patternToMidCode(state=state, matches=List.zip(inputsMidVar,listReverse(patterns)),
                             labelNoMatch= if not listEmpty(caseLabelIterator) then listHead(caseLabelIterator) else labelFail);
          end if;
          // then guard
          () := match patternGuard
            case (NONE())
            algorithm
              // No guard.
            then ();
            case (SOME(daeExp))
            algorithm
              midvar := rValueToVar(ExpToMid(daeExp,state),state);
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
          So we define and use listZip instead of List.zip.

          TODO: Document the unintuitive undocumented interface somewhere.
          */
          () := match (caseResult, outvars)
            local
              list<DAE.Exp> expList;
            case (SOME(DAE.TUPLE(expList)),_)
            algorithm
              for outvarDaeExp in MidCodeUtil.listZip(outvars, expList) loop
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
            case (NONE(), {}) // No result.
              then ();
            /* This occurs if we return fail() in a then. for a else*/
            case (NONE(), _)
            algorithm
              stateTerminate(labelFin2, MidCode.CALL(AbsynUtil. stringPath("fail"), true,
                             {}, {}, labelFin, DAE.T_NORETCALL_DEFAULT), state);
              then ();//fail();
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
  the next; case. Except for the last case where
  failure is a longjmp."
  input list<tuple<MidCode.Var,DAE.Pattern>> matches "List of variables and their corresponding patterns";
  input Integer labelNoMatch "where to go on a failed match";
  input State state;
  output array<list<MidCode.Stmt>> assignBlock "A block of assignments to perform for a pattern.";
algorithm
  assignBlock := arrayCreate(1,{});
  /*Yup...*/
  patternToMidCode2(state=state,matches=matches,labelNoMatch=labelNoMatch,assignBlock=assignBlock);
  for stmt in listReverse(arrayGet(assignBlock,1)) loop
    stateAddStmt(stmt,state);
  end for;
end patternToMidCode;
  /*
    TODO: This function gives incorrect results when matching against MetaModelica tuples, I will not put more time
    attempting to fix it. -John, e.g match (X,Y,Z) case (XX,YY,ZZ) then XX + YY + ZZ
    TODO: I fix I actually did fix this. Write a test to verify..
  */
function patternToMidCode2
  " Recursive worker function for
    patternToMidCode handling."
  input State state;
  input list<tuple<MidCode.Var,DAE.Pattern>> matches "List of variables and their corresponding patterns";
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
  */
  () := match matches
    local
      Boolean bool;
      DAE.Exp exp;
      DAE.Pattern pattern, headPattern, restPattern;
      DAE.Type ty;
      Integer integer;
      MidCode.Var ok; /* Just a MidCode boolean variable */
      MidCode.Var patCompareVar;
      MidCode.Var scrutinee, midvar, headVar, restVar;
      MidCode.Var scrutineeCompareVar;
      Option<DAE.Type> optType;
      Real real;
      String id;
      String string;
      list<DAE.Type> listTypes;
      list<tuple<MidCode.Var,DAE.Pattern>> restMatches, moreMatches;
    case {}
    algorithm
      // All patterns have been matched. Fall through to what happens on succesful match.
    then ();
    case (_,DAE.PAT_WILD()) :: restMatches
    algorithm
      patternToMidCode2(matches = restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();
    case (scrutinee,DAE.PAT_AS(id=id,ty=NONE(),pat=pattern)) :: restMatches
    algorithm
      ty := RValueType(MidCode.VARIABLE(scrutinee));
      midvar := MidCode.VAR(id, ty, false);
      arrayUpdate(assignBlock, 1, MidCode.ASSIGN(midvar, MidCode.VARIABLE(scrutinee))::arrayGet(assignBlock,1));
      patternToMidCode2(matches = (scrutinee, pattern) :: restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();
    case (scrutinee,DAE.PAT_AS(id=id,ty=SOME(ty),pat=pattern)) :: restMatches
    algorithm
      midvar := MidCode.VAR(id, ty, false);
      arrayUpdate(assignBlock, 1, MidCode.ASSIGN(midvar, MidCode.UNARYOP(MidCode.UNBOX(),scrutinee))::arrayGet(assignBlock,1));
      patternToMidCode2(matches = (scrutinee, pattern) :: restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();
    case (scrutinee, DAE.PAT_CONSTANT(ty=optType,exp=exp)) :: restMatches // TODO: what to do about optType
    algorithm
      //remove shared literal
      exp := match exp
      case DAE.SHARED_LITERAL(exp=exp) then exp;
      else                             then exp;
      end match;
      /* Unbox */
      scrutinee := match optType
      case NONE()   then scrutinee;
      case SOME(_) then rValueToVar(MidCode.UNARYOP(MidCode.UNBOX(),scrutinee),state);
      end match;
      // test
      () := match exp
        case DAE.BCONST(bool=bool)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := rValueToVar(MidCode.LITERALBOOLEAN(bool), state);
        then ();
        case DAE.ICONST(integer=integer)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := rValueToVar(MidCode.LITERALINTEGER(integer), state);
        then ();
        case DAE.RCONST(real=real)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := rValueToVar(MidCode.LITERALREAL(real), state);
        then ();
        case DAE.ENUM_LITERAL(index=integer)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := rValueToVar(MidCode.LITERALINTEGER(integer), state);
        then ();
        case DAE.LIST(valList = {})
        algorithm
          scrutineeCompareVar := rValueToVar(MidCode.ISCONS(scrutinee), state);
          patCompareVar := rValueToVar(MidCode.LITERALBOOLEAN(false), state);
        then ();
        case DAE.META_OPTION(exp = NONE())
        algorithm
          scrutineeCompareVar := rValueToVar(MidCode.ISSOME(scrutinee), state);
          patCompareVar := rValueToVar(MidCode.LITERALBOOLEAN(false), state);
        then ();
        case DAE.SCONST(string=string)
        algorithm
          scrutineeCompareVar := scrutinee;
          patCompareVar       := rValueToVar(MidCode.LITERALSTRING(string), state);
        then ();
        else
        algorithm
          Error.addInternalError("DAE.Exp to Mid conversion failed for pattern constant. Exp:" + ExpressionDump.dumpExpStr(exp,0) + ".\n", sourceInfo());
        then fail();
      end match;
      /* generic part of test */
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
      fieldNr := 0; // TODO: Should probably be 1 after changing metafield code generation
      while not listEmpty(iterator) loop
        midvar := rValueToVar(MidCode.METAFIELD(scrutinee,fieldNr,listHead(listTypes)),state);
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
      scrutineeCompareVar := rValueToVar(MidCode.ISSOME(scrutinee), state);
      patCompareVar       := rValueToVar(MidCode.LITERALBOOLEAN(true), state);
      stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
      stateAddBailOnFalse(ok, labelNoMatch, state);
      ty := match scrutinee.ty
        case DAE.T_METAOPTION(ty=ty)
        then ty;
        else algorithm Error.addInternalError("Wrong type of midvar in option pattern.\n", sourceInfo()); then fail();
      end match;
      midvar := rValueToVar(MidCode.METAFIELD(scrutinee,0,ty),state);
      patternToMidCode2(
        matches =  (midvar,pattern)::restMatches,
        state=state,
        assignBlock=assignBlock,
        labelNoMatch=labelNoMatch
        );
    then ();
    /*
       This is incorretly implemented, work in match expression gives cycles and other errors when used in the context of regular assignments with
       lists. E.g H::T := T and other variants such as true := a > 5, also gives issues //John.
    */
    case (scrutinee, DAE.PAT_CONS(head=headPattern,tail=restPattern)) :: restMatches
    algorithm
      scrutineeCompareVar := rValueToVar(MidCode.ISCONS(scrutinee), state);
      patCompareVar := rValueToVar(MidCode.LITERALBOOLEAN(true), state);
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
      headVar := rValueToVar(MidCode.METAFIELD(scrutinee,0,ty),state);
      restVar := rValueToVar(MidCode.METAFIELD(scrutinee,1,scrutinee.ty),state);
      patternToMidCode2(
        matches=(headVar,headPattern)::(restVar,restPattern)::restMatches,
        state=state,
        assignBlock=assignBlock,
        labelNoMatch=labelNoMatch
        );
    then ();
    /*The case when we have uniontypes of records without content.*/
    case (scrutinee, DAE.PAT_CALL(name, index, {}, {}, {}, knownSingleton)) :: restMatches
    algorithm /*TODO: We ignore the knowSingelton here*/
      ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
      scrutineeCompareVar := rValueToVar(MidCode.UNIONTYPEVARIANT(scrutinee) , state);
      patCompareVar := rValueToVar(MidCode.LITERALINTEGER(index) , state);
      stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
      stateAddBailOnFalse(ok, labelNoMatch, state);
      patternToMidCode2(matches = restMatches, state=state, assignBlock=assignBlock, labelNoMatch=labelNoMatch);
    then ();
    case (scrutinee,DAE.PAT_CALL(name,index,morePatterns,fields,typeVars,knownSingleton)) :: restMatches
    algorithm
      if not knownSingleton
      then
        ok := GenTmpVar(DAE.T_BOOL_DEFAULT,state);
        scrutineeCompareVar := rValueToVar(MidCode.UNIONTYPEVARIANT(scrutinee) , state);
        patCompareVar       := rValueToVar(MidCode.LITERALINTEGER(index) , state);
        stateAddStmt(MidCode.ASSIGN(ok, MidCode.BINARYOP(MidCode.EQUAL(),scrutineeCompareVar, patCompareVar )), state);
        stateAddBailOnFalse(ok, labelNoMatch, state);
      end if;
      listTypes := list(v.ty for v in fields);
      moreMatches := {};
      iterator := morePatterns;
      fieldNr := 1;
      while not listEmpty(iterator) loop
        midvar := rValueToVar(MidCode.METAFIELD(scrutinee,fieldNr,listHead(listTypes)),state);
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

function DAEElementToVar
  "Takes a DAE.Element and a DAEToMid.State.
   Converts the element to a MidCode variable in the local state."
  input DAE.Element element;
  input State state;
algorithm
  () := match element
    local
      DAE.Element elemVar;
      case elemVar as DAE.Element.VAR(__) algorithm crefToMidVarAddToLocal(elemVar.componentRef,state); then();
      else algorithm print("Error converting:"); DAEDump.dumpAlgorithm(element); Error.addInternalError("Element to MidCode.Var error",sourceInfo()); then();
  end match;
end DAEElementToVar;

function listOfElementsToMidCodeVars
  "Takes a List<DAE.Element>, for each element generate a MidCode variable in the local state"
  input list<DAE.Element> elements;
  input State state;
protected
  list<MidCode.Var> vars;
algorithm
  List.map1_0(elements,DAEElementToVar,state);
end listOfElementsToMidCodeVars;

function getIntLitFromExp
  input DAE.Exp exp;
  output Integer r;
algorithm
 r := match exp
    case DAE.ICONST(_) then exp.integer;
    else then fail();
  end match;
end getIntLitFromExp;

function genArrayIxFunction
  input DAE.Type ty;
  input Integer dimSize;
  output String funcName;
algorithm
  if dimSize == 1 then
    funcName := genArrayIxFunction1D(ty);
  elseif dimSize == 2 then
    funcName := genArrayIxFunction2D(ty);
  else
    print("Other dimSize in genArrayIxFunction Not supported\n");
    fail();
  end if;
end genArrayIxFunction;

function genArrayIxFunction1D
  "Generates the appropriate string describing the adressing function for 1D operations"
  input DAE.Type ty;
  output String funcName;
algorithm
  funcName := match ty
    case DAE.T_REAL(__) then "real_array_element_addr1";
    else algorithm print("ixArrayErrorError"); then fail(); //For now, more options can be added.
  end match;
end genArrayIxFunction1D;

function genArrayIxFunction2D
  input DAE.Type ty;
  output String funcName;
algorithm
  funcName := match ty
    case DAE.T_REAL(__) then "real_array_element_addr2";
    else algorithm print("ixArrayErrorError\n"); then fail();
  end match;
end genArrayIxFunction2D;

function getArrayAllocaCall
  input DAE.Type ty;
  output String functionName;
algorithm
  functionName := match ty
    case DAE.T_REAL(__) then "alloc_real_array";
    else algorithm Error.addInternalError("getArrayAllocaCall" , sourceInfo());
      then fail(); //TODO add more types.
  end match;
end getArrayAllocaCall;

function SubscriptToMid
  input DAE.Subscript subscript;
  input State state;
  output MidCode.RValue rVal;
algorithm
  rVal := match subscript
      case DAE.INDEX(__)
        then ExpToMid(subscript.exp,state);
      else algorithm Error.addInternalError("SubscriptToMid failed" , sourceInfo());
        then fail();
  end match;
end SubscriptToMid;

annotation(__OpenModelica_Interface="backendInterface");
end DAEToMid;
