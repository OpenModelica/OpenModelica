package Flatten "flatten.rml"

import TCode;
import FCode;

protected
uniontype Scope
  record SCOPE
    FCode.Level level;
    FCode.Ident ident;
  end SCOPE;

end Scope;

protected
uniontype Bnd
  record VAR
    FCode.Level level;
    FCode.Record record_;
  end VAR;

  record PROC
    FCode.Ident ident;
  end PROC;

end Bnd;

protected constant list<tuple<String, Bnd>> envInit={("read",PROC("petrol_read")),
          ("write",PROC("petrol_write")),("trunc",PROC("petrol_trunc"))};

function lookup
  input list<tuple<String, Bnd>> inTplTypeATypeBLst;
  input String inTypeA;
  output Bnd outTypeB;
algorithm
  outTypeB:=
  matchcontinue (inTplTypeATypeBLst,inTypeA)
    local
      String key1,key0;
      Bnd bnd;
      list<tuple<String, Bnd>> env;
    case (((key1,bnd) :: env),key0)
      then if key1 == key0 then bnd else lookup(env, key0);
  end matchcontinue;
end lookup;

function map<Type_a,Type_b>
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input list<Type_a> inTypeALst;
  output list<Type_b> outTypeBLst;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
algorithm
  outTypeBLst:=
  matchcontinue (inFuncTypeTypeAToTypeB,inTypeALst)
    local
      Type_b y;
      list<Type_b> ys;
      FuncTypeType_aToType_b F;
      Type_a x;
      list<Type_a> xs;
    case (_,{}) then {};
    case (F,(x :: xs))
      equation
        y = F(x);
        ys = map(F, xs);
      then
        (y :: ys);
  end matchcontinue;
end map;

function transTy ""
  input TCode.Ty inTy;
  output FCode.Ty outTy;
algorithm
  outTy:=
  matchcontinue (inTy)
    local
      FCode.Ty ty_1;
      TCode.Ty ty;
      Integer sz,stamp;
      FCode.Record r_1;
      TCode.Record r;
    case (TCode.CHAR()) then FCode.CHAR();
    case (TCode.INT()) then FCode.INT();
    case (TCode.REAL()) then FCode.REAL();
    case (TCode.PTR(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PTR(ty_1);
    case (TCode.ARR(sz,ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.ARR(sz,ty_1);
    case (TCode.REC(r))
      equation
        r_1 = transRec(r);
      then
        FCode.REC(r_1);
    case (TCode.UNFOLD(stamp)) then FCode.UNFOLD(stamp);
  end matchcontinue;
end transTy;

function transRec
  input TCode.Record inRecord;
  output FCode.Record outRecord;
algorithm
  outRecord:=
  matchcontinue (inRecord)
    local
      list<FCode.Var> bnds_1;
      Integer stamp;
      list<TCode.Var> bnds;
    case (TCode.RECORD(stamp,bnds))
      equation
        bnds_1 = map(transVar, bnds);
      then
        FCode.RECORD(stamp,bnds_1);
  end matchcontinue;
end transRec;

function transVar
  input TCode.Var inVar;
  output FCode.Var outVar;
algorithm
  outVar:=
  matchcontinue (inVar)
    local
      FCode.Ty ty_1;
      String id;
      TCode.Ty ty;
    case (TCode.VAR(id,ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.VAR(id,ty_1);
  end matchcontinue;
end transVar;

function transTyopt
  input Option<TCode.Ty> inTCodeTyOption;
  output Option<FCode.Ty> outFCodeTyOption;
algorithm
  outFCodeTyOption:=
  matchcontinue (inTCodeTyOption)
    local
      FCode.Ty ty_1;
      TCode.Ty ty;
    case NONE() then NONE();
    case (SOME(ty))
      equation
        ty_1 = transTy(ty);
      then
        SOME(ty_1);
  end matchcontinue;
end transTyopt;

function transUnop
  input TCode.UnOp inUnOp;
  output FCode.UnOp outUnOp;
algorithm
  outUnOp:=
  matchcontinue (inUnOp)
    local
      FCode.Ty ty_1;
      TCode.Ty ty;
      FCode.Record r_1;
      TCode.Record r;
      String id;
    case (TCode.CtoI()) then FCode.CtoI();
    case (TCode.ItoR()) then FCode.ItoR();
    case (TCode.RtoI()) then FCode.RtoI();
    case (TCode.ItoC()) then FCode.ItoC();
    case (TCode.PtoI()) then FCode.PtoI();
    case (TCode.TOPTR(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.TOPTR(ty_1);
    case (TCode.LOAD(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.LOAD(ty_1);
    case (TCode.OFFSET(r,id))
      equation
        r_1 = transRec(r);
      then
        FCode.OFFSET(r_1,id);
  end matchcontinue;
end transUnop;

function transBinop
  input TCode.BinOp inBinOp;
  output FCode.BinOp outBinOp;
algorithm
  outBinOp:=
  matchcontinue (inBinOp)
    local
      FCode.Ty ty_1;
      TCode.Ty ty;
    case (TCode.IADD()) then FCode.IADD();
    case (TCode.ISUB()) then FCode.ISUB();
    case (TCode.IMUL()) then FCode.IMUL();
    case (TCode.IDIV()) then FCode.IDIV();
    case (TCode.IMOD()) then FCode.IMOD();
    case (TCode.IAND()) then FCode.IAND();
    case (TCode.IOR()) then FCode.IOR();
    case (TCode.ILT()) then FCode.ILT();
    case (TCode.ILE()) then FCode.ILE();
    case (TCode.IEQ()) then FCode.IEQ();
    case (TCode.RADD()) then FCode.RADD();
    case (TCode.RSUB()) then FCode.RSUB();
    case (TCode.RMUL()) then FCode.RMUL();
    case (TCode.RDIV()) then FCode.RDIV();
    case (TCode.RLT()) then FCode.RLT();
    case (TCode.RLE()) then FCode.RLE();
    case (TCode.REQ()) then FCode.REQ();
    case (TCode.PADD(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PADD(ty_1);
    case (TCode.PSUB(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PSUB(ty_1);
    case (TCode.PDIFF(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PDIFF(ty_1);
    case (TCode.PLT(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PLT(ty_1);
    case (TCode.PLE(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PLE(ty_1);
    case (TCode.PEQ(ty))
      equation
        ty_1 = transTy(ty);
      then
        FCode.PEQ(ty_1);
  end matchcontinue;
end transBinop;

function transProcid<Type_a>
  input list<tuple<String, Bnd>> env;
  input String id;
  output String id_1;
algorithm
  PROC(id_1) := lookup(env, id);
end transProcid;

function transExp
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input TCode.Exp inExp;
  output FCode.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inTplStringBndLst,inExp)
    local
      Integer x,lev;
      FCode.Record rec;
      list<tuple<String, Bnd>> env;
      String id,id_1;
      FCode.UnOp unop_1;
      FCode.Exp exp_1,exp1_1,exp2_1;
      TCode.UnOp unop;
      TCode.Exp exp,exp1,exp2;
      FCode.BinOp binop_1;
      TCode.BinOp binop;
      list<FCode.Exp> args_1;
      list<TCode.Exp> args;
      Real r;
    case (_,TCode.ICON(x)) then FCode.ICON(x);
    case (_,TCode.RCON(r)) then FCode.RCON(r);
    case (env,TCode.ADDR(id))
      equation
        VAR(lev,rec) = lookup(env, id);
      then
        FCode.UNARY(FCode.OFFSET(rec,id),
          FCode.UNARY(FCode.TOPTR(FCode.REC(rec)),FCode.DISPLAY(lev)));
    case (env,TCode.UNARY(unop,exp))
      equation
        unop_1 = transUnop(unop);
        exp_1 = transExp(env, exp);
      then
        FCode.UNARY(unop_1,exp_1);
    case (env,TCode.BINARY(exp1,binop,exp2))
      equation
        binop_1 = transBinop(binop);
        exp1_1 = transExp(env, exp1);
        exp2_1 = transExp(env, exp2);
      then
        FCode.BINARY(exp1_1,binop_1,exp2_1);
    case (env,TCode.FCALL(id,args))
      equation
        id_1 = transProcid(env, id);
        args_1 = transArgs(env, args, {});
      then
        FCode.FCALL(id_1,args_1);
  end matchcontinue;
end transExp;

function transArgs
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<TCode.Exp> inTCodeExpLst;
  input list<FCode.Exp> inFCodeExpLst;
  output list<FCode.Exp> outFCodeExpLst;
algorithm
  outFCodeExpLst:=
  matchcontinue (inTplStringBndLst,inTCodeExpLst,inFCodeExpLst)
    local
      list<FCode.Exp> args_2,args_1;
      FCode.Exp arg_1;
      list<tuple<String, Bnd>> env;
      TCode.Exp arg;
      list<TCode.Exp> args;
    case (_,{},args_1)
      equation
        args_2 = listReverse(args_1);
      then
        args_2;
    case (env,(arg :: args),args_1)
      equation
        arg_1 = transExp(env, arg);
        args_2 = transArgs(env, args, (arg_1 :: args_1));
      then
        args_2;
  end matchcontinue;
end transArgs;

function transReturn
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Option<tuple<TCode.Ty, TCode.Exp>> inTplTCodeTyTCodeExpOption;
  output Option<tuple<FCode.Ty, FCode.Exp>> outTplFCodeTyFCodeExpOption;
algorithm
  outTplFCodeTyFCodeExpOption:=
  matchcontinue (inTplStringBndLst,inTplTCodeTyTCodeExpOption)
    local
      FCode.Ty ty_1;
      FCode.Exp exp_1;
      list<tuple<String, Bnd>> env;
      TCode.Ty ty;
      TCode.Exp exp;
    case (_,NONE()) then NONE();
    case (env,SOME((ty,exp)))
      equation
        ty_1 = transTy(ty);
        exp_1 = transExp(env, exp);
      then
        SOME((ty_1,exp_1));
  end matchcontinue;
end transReturn;

function transStmt
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input TCode.Stmt inStmt;
  output FCode.Stmt outStmt;
algorithm
  outStmt:=
  matchcontinue (inTplStringBndLst,inStmt)
    local
      FCode.Ty ty_1;
      FCode.Exp lhs_1,rhs_1,exp_1;
      list<tuple<String, Bnd>> env;
      TCode.Ty ty;
      TCode.Exp lhs,rhs,exp;
      String id_1,id;
      list<FCode.Exp> args_1;
      list<TCode.Exp> args;
      Option<tuple<FCode.Ty, FCode.Exp>> ret_1;
      Option<tuple<TCode.Ty, TCode.Exp>> ret;
      FCode.Stmt stmt_1,stmt1_1,stmt2_1;
      TCode.Stmt stmt,stmt1,stmt2;
    case (env,TCode.STORE(ty,lhs,rhs))
      equation
        ty_1 = transTy(ty);
        lhs_1 = transExp(env, lhs);
        rhs_1 = transExp(env, rhs);
      then
        FCode.STORE(ty_1,lhs_1,rhs_1);
    case (env,TCode.PCALL(id,args))
      equation
        id_1 = transProcid(env, id);
        args_1 = transArgs(env, args, {});
      then
        FCode.PCALL(id_1,args_1);
    case (env,TCode.RETURN(ret))
      equation
        ret_1 = transReturn(env, ret);
      then
        FCode.RETURN(ret_1);
    case (env,TCode.WHILE(exp,stmt))
      equation
        exp_1 = transExp(env, exp);
        stmt_1 = transStmt(env, stmt);
      then
        FCode.WHILE(exp_1,stmt_1);
    case (env,TCode.IF(exp,stmt1,stmt2))
      equation
        exp_1 = transExp(env, exp);
        stmt1_1 = transStmt(env, stmt1);
        stmt2_1 = transStmt(env, stmt2);
      then
        FCode.IF(exp_1,stmt1_1,stmt2_1);
    case (env,TCode.SEQ(stmt1,stmt2))
      equation
        stmt1_1 = transStmt(env, stmt1);
        stmt2_1 = transStmt(env, stmt2);
      then
        FCode.SEQ(stmt1_1,stmt2_1);
    case (_,TCode.SKIP()) then FCode.SKIP();
  end matchcontinue;
end transStmt;

function envPlusVars<Type_a>
  input list<tuple<String, Type_a>> inTplStringTypeALst;
  input Type_a inTypeA;
  input list<FCode.Var> inFCodeVarLst;
  output list<tuple<String, Type_a>> outTplStringTypeALst;
algorithm
  outTplStringTypeALst:=
  matchcontinue (inTplStringTypeALst,inTypeA,inFCodeVarLst)
    local
      Type_a bnd;
      list<tuple<String, Type_a>> env_1;
      String id;
      list<FCode.Var> vars;
      list<tuple<String, Type_a>> env;
    case (env,_,{}) then env;
    case (env,bnd,(FCode.VAR(id,_) :: vars))
      equation
        env_1 = envPlusVars(((id,bnd) :: env), bnd, vars);
      then
        env_1;
  end matchcontinue;
end envPlusVars;

function flattenProc
  input Scope inScope;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input TCode.Proc inProc;
  input list<FCode.Proc> inFCodeProcLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
  output list<FCode.Proc> outFCodeProcLst;
algorithm
  (outTplStringBndLst,outFCodeProcLst):=
  matchcontinue (inScope,inTplStringBndLst,inProc,inFCodeProcLst)
    local
      list<FCode.Var> formals_1,locals_1,vars_1;
      Option<FCode.Ty> tyopt_1;
      list<tuple<String, Bnd>> env0,env1,env2,env3;
      String id,id_1,prefix1,prefix0;
      list<TCode.Var> formals,locals;
      Option<TCode.Ty> tyopt;
      list<FCode.Proc> procs0,procs1;
      Integer level1,stamp,level0;
      FCode.Record r;
      FCode.Stmt stmt_1;
      list<TCode.Proc> procs;
      TCode.Stmt stmt;
    case (_,env0,TCode.PROC(id,formals,tyopt,NONE()),procs0)
      equation
        formals_1 = map(transVar, formals);
        tyopt_1 = transTyopt(tyopt);
      then
        (((id,PROC(id)) :: env0),(FCode.PROC(id,formals_1,tyopt_1,NONE()) :: procs0));
    case (SCOPE(level0,prefix0),env0,TCode.PROC(id,formals,tyopt,SOME(TCode.BLOCK(locals,procs,stmt))),procs0)
      equation
        level1 = level0 + 1;
        id_1 = stringAppend(prefix0, id);
        prefix1 = stringAppend(id_1, "_");
        formals_1 = map(transVar, formals);
        locals_1 = map(transVar, locals);
        vars_1 = listAppend(formals_1, locals_1);
        stamp = tick();
        r = FCode.RECORD(stamp,vars_1);
        env1 = ((id,PROC(id_1)) :: env0);
        env2 = envPlusVars(env1, VAR(level1,r), vars_1);
        (env3,procs1) = flattenProcs(SCOPE(level1,prefix1), env2, procs, procs0);
        stmt_1 = transStmt(env3, stmt);
        tyopt_1 = transTyopt(tyopt);
      then
        (env1,(FCode.PROC(id_1,formals_1,tyopt_1,SOME(FCode.BLOCK(level1,r,stmt_1))) :: procs1));
  end matchcontinue;
end flattenProc;

function flattenProcs
  input Scope inScope;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<TCode.Proc> inTCodeProcLst;
  input list<FCode.Proc> inFCodeProcLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
  output list<FCode.Proc> outFCodeProcLst;
algorithm
  (outTplStringBndLst,outFCodeProcLst):=
  matchcontinue (inScope,inTplStringBndLst,inTCodeProcLst,inFCodeProcLst)
    local
      list<tuple<String, Bnd>> env0,env1,env2;
      list<FCode.Proc> procs0,procs1,procs2;
      Scope scope;
      TCode.Proc proc;
      list<TCode.Proc> procs;
    case (_,env0,{},procs0) then (env0,procs0);
    case (scope,env0,(proc :: procs),procs0)
      equation
        (env1,procs1) = flattenProc(scope, env0, proc, procs0);
        (env2,procs2) = flattenProcs(scope, env1, procs, procs1);
      then
        (env2,procs2);
  end matchcontinue;
end flattenProcs;

function flatten
  input TCode.Prog inProg;
  output FCode.Prog outProg;
algorithm
  outProg:=
  matchcontinue (inProg)
    local
      list<FCode.Proc> procs_1;
      String id;
      TCode.Block block_;
    case (TCode.PROG(id,block_))
      equation
        (_,procs_1) = flattenProc(SCOPE(-1,""), envInit,
          TCode.PROC(id,{},NONE(),SOME(block_)), {});
      then
        FCode.PROG(procs_1,id);
  end matchcontinue;
end flatten;
end Flatten;

