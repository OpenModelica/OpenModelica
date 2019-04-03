package Static "static.rml"

import Absyn;
import TCode;

import Types;

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
      FuncTypeType_aToType_b R;
      Type_a x;
      list<Type_a> xs;
    case (_,{}) then {};
    case (R,(x :: xs))
      equation
        y = R(x);
        ys = map(R, xs);
      then
        (y :: ys);
  end matchcontinue;
end map;

protected
uniontype Con "
  Static environment
"
  record INTcon
    Integer integer;
  end INTcon;

  record REALcon
    Real real;
  end REALcon;

end Con;

protected
uniontype Bnd
  record VARbnd
    Types.Ty ty;
  end VARbnd;

  record CONSTbnd
    Con con;
  end CONSTbnd;

  record FUNCbnd
    list<Types.Ty> typesTyLst;
    Types.Ty ty;
  end FUNCbnd;

  record PROCbnd
    list<Types.Ty> typesTyLst;
  end PROCbnd;

  record TYPEbnd
    Types.Ty ty;
  end TYPEbnd;

  record NILbnd end NILbnd;

end Bnd;

protected constant list<tuple<String, Bnd>> envInit={("integer",TYPEbnd(Types.ARITH(Types.INT()))),
          ("real",TYPEbnd(Types.ARITH(Types.REAL()))),("char",TYPEbnd(Types.ARITH(Types.CHAR()))),
          ("read",FUNCbnd({},Types.ARITH(Types.INT()))),("write",PROCbnd({Types.ARITH(Types.INT())})),
          ("trunc",
          FUNCbnd({Types.ARITH(Types.REAL())},Types.ARITH(Types.INT()))),("nil",NILbnd())};

function lookup<Type_a,Type_b>
  input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
  input Type_a inTypeA;
  output Type_b outTypeB;
algorithm
  outTypeB:=
  matchcontinue (inTplTypeATypeBLst,inTypeA)
    local
      Type_a key1,key0;
      Type_b bnd;
      list<tuple<Type_a, Type_b>> env;
    case (((key1,bnd) :: env),key0)
      then if valueEq(key1, key0) then bnd else lookup(env, key0);
  end matchcontinue;
end lookup;

function elabConstant "Constants and Types
"
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Constant inConstant;
  output Con outCon;
algorithm
  outCon:=
  matchcontinue (inTplStringBndLst,inConstant)
    local
      Integer i;
      Real r;
      Con c;
      String id;
      list<tuple<String, Bnd>> env;
    case (env,Absyn.INTcon(i)) then INTcon(i);  /* env |- Const => Con */
    case (env,Absyn.REALcon(r)) then REALcon(r);
    case (env,Absyn.IDENTcon(id))
      equation
        CONSTbnd(c) = lookup(env, id);
      then
        c;
  end matchcontinue;
end elabConstant;

function elabConst
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.ConBnd inConBnd;
  output list<tuple<String, Bnd>> outTplStringBndLst;
algorithm
  outTplStringBndLst:=
  matchcontinue (inTplStringBndLst,inConBnd)
    local
      Con con;
      list<tuple<String, Bnd>> env0;
      String id;
      Absyn.Constant c;
    case (env0,Absyn.CONBND(id,c)) /* env |- Const => env\' */
      equation
        con = elabConstant(env0, c);
      then
        ((id,CONSTbnd(con)) :: env0);
  end matchcontinue;
end elabConst;

function elabConsts
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.ConBnd> inAbsynConBndLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
algorithm
  outTplStringBndLst:=
  matchcontinue (inTplStringBndLst,inAbsynConBndLst)
    local
      list<tuple<String, Bnd>> env_1,env_2;
      Absyn.ConBnd c;
      list<Absyn.ConBnd> consts;
      list<tuple<String, Bnd>> env;
    case (env,{}) then env;  /* env |- Const => env\' */
    case (env,(c :: consts))
      equation
        env_1 = elabConst(env, c);
        env_2 = elabConsts(env_1, consts);
      then
        env_2;
  end matchcontinue;
end elabConsts;

function elabTy
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Ty inTy;
  output Types.Ty outTy;
algorithm
  outTy:=
  matchcontinue (inTplStringBndLst,inTy)
    local
      Types.Ty ty_1;
      list<tuple<String, Bnd>> env;
      String id;
      Absyn.Ty ty;
      Integer sz,stamp;
      Absyn.Constant c;
      list<tuple<String, Types.Ty>> bnds_1;
      list<Absyn.VarBnd> bnds;
    case (env,Absyn.NAME(id)) /* env |- Absyn.Ty => Types.Ty */
      equation
        TYPEbnd(ty_1) = lookup(env, id);
      then
        ty_1;
    case (env,Absyn.PTR(ty))
      equation
        ty_1 = elabTy(env, ty);
      then
        Types.PTR(ty_1);
    case (env,Absyn.ARR(c,ty))
      equation
        INTcon(sz) = elabConstant(env, c);
        ty_1 = elabTy(env, ty);
      then
        Types.ARR(sz,ty_1);
    case (env,Absyn.REC(bnds))
      equation
        stamp = tick();
        bnds_1 = elabTyBnds(env, bnds, {});
      then
        Types.REC(Types.RECORD(stamp,bnds_1));
  end matchcontinue;
end elabTy;

function elabTyBnds
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.VarBnd> inAbsynVarBndLst;
  input list<tuple<String, Types.Ty>> inTplStringTypesTyLst;
  output list<tuple<String, Types.Ty>> outTplStringTypesTyLst;
algorithm
  outTplStringTypesTyLst:=
  matchcontinue (inTplStringBndLst,inAbsynVarBndLst,inTplStringTypesTyLst)
    local
      list<tuple<String, Types.Ty>> bnds_2,bnds_1;
      list<tuple<String, Bnd>> env;
      Types.Ty ty_1;
      String id;
      Absyn.Ty ty;
      list<Absyn.VarBnd> bnds;
    case (env,{},bnds_1)
      equation
        bnds_2 = listReverse(bnds_1);
      then
        bnds_2;
    case (env,(Absyn.VARBND(id,ty) :: bnds),bnds_1)
      equation
        ty_1 = elabTy(env, ty);
        bnds_2 = elabTyBnds(env, bnds, ((id,ty_1) :: bnds_1));
      then
        bnds_2;
  end matchcontinue;
end elabTyBnds;

function isunfold
  input Types.Ty inTy;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inTy)
    case (Types.UNFOLD(_)) then true;
    case (Types.ARITH(_)) then false;
    case (Types.PTR(_)) then false;
    case (Types.ARR(_,_)) then false;
    case (Types.REC(_)) then false;
  end matchcontinue;
end isunfold;

function checkTy
  input Types.Ty inTy;
algorithm
  _:=
  matchcontinue (inTy)
    local
      Types.Ty ty;
      list<tuple<String, Types.Ty>> bnds;
    case (Types.ARITH(_)) then ();
    case (Types.ARR(_,ty))
      equation
        checkTy(ty);
      then
        ();
    case (Types.REC(Types.RECORD(_,bnds)))
      equation
        checkBnds(bnds);
      then
        ();
    case (Types.PTR(ty))
      equation
        true = isunfold(ty);
      then
        ();
    case (Types.PTR(ty))
      equation
        false = isunfold(ty);
        checkTy(ty);
      then
        ();
  end matchcontinue;
end checkTy;

function checkBnds
  input list<tuple<String, Types.Ty>> inTplStringTypesTyLst;
algorithm
  _:=
  matchcontinue (inTplStringTypesTyLst)
    local
      Types.Ty ty;
      list<tuple<String, Types.Ty>> bnds;
    case {} then ();
    case (((_,ty) :: bnds))
      equation
        checkTy(ty);
        checkBnds(bnds);
      then
        ();
  end matchcontinue;
end checkBnds;

protected
uniontype IsRec
  record NOREC
    Absyn.Ty ty;
  end NOREC;

  record ISREC
    list<Absyn.VarBnd> absynVarBndLst;
  end ISREC;

end IsRec;

function isrec
  input Absyn.Ty inTy;
  output IsRec outIsRec;
algorithm
  outIsRec:=
  matchcontinue (inTy)
    local
      Absyn.Ty ty;
      list<Absyn.VarBnd> bnds;
    case ((ty as Absyn.NAME(_))) then NOREC(ty);
    case ((ty as Absyn.PTR(_))) then NOREC(ty);
    case ((ty as Absyn.ARR(_,_))) then NOREC(ty);
    case (Absyn.REC(bnds)) then ISREC(bnds);
  end matchcontinue;
end isrec;

function elabTybnd1
  input IsRec inIsRec;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input String inString;
  output Types.Ty outTy;
algorithm
  outTy:=
  matchcontinue (inIsRec,inTplStringBndLst,inString)
    local
      Integer stamp;
      list<tuple<String, Types.Ty>> bnds_1;
      list<Absyn.VarBnd> bnds;
      list<tuple<String, Bnd>> env0;
      String id;
      Types.Ty ty_1;
      Absyn.Ty ty;
    case (ISREC(bnds),env0,id)
      equation
        stamp = tick();
        bnds_1 = elabTyBnds(((id,TYPEbnd(Types.UNFOLD(stamp))) :: env0), bnds, {});
        checkBnds(bnds_1);
      then
        Types.REC(Types.RECORD(stamp,bnds_1));
    case (NOREC(ty),env0,id)
      equation
        ty_1 = elabTy(env0, ty);
      then
        ty_1;
  end matchcontinue;
end elabTybnd1;

function elabTybnd
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.TyBnd inTyBnd;
  output list<tuple<String, Bnd>> outTplStringBndLst;
algorithm
  outTplStringBndLst:=
  matchcontinue (inTplStringBndLst,inTyBnd)
    local
      IsRec xxx;
      Types.Ty ty_1;
      list<tuple<String, Bnd>> env0;
      String id;
      Absyn.Ty ty;
    case (env0,Absyn.TYBND(id,ty))
      equation
        xxx = isrec(ty);
        ty_1 = elabTybnd1(xxx, env0, id);
      then
        ((id,TYPEbnd(ty_1)) :: env0);
  end matchcontinue;
end elabTybnd;

function elabTypes
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.TyBnd> inAbsynTyBndLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
algorithm
  outTplStringBndLst:=
  matchcontinue (inTplStringBndLst,inAbsynTyBndLst)
    local
      Absyn.TyBnd tybnd;
      list<Absyn.TyBnd> tybnds;
      list<tuple<String, Bnd>> env,env_1,env_2;
    case (env,{}) then env;
    case (env,(tybnd :: tybnds))
      equation
        env_1 = elabTybnd(env, tybnd);
        env_2 = elabTypes(env_1, tybnds);
      then
        env_2;
  end matchcontinue;
end elabTypes;

function lvalueId<Type_a,Type_b> "
  Expressions

  function lvalueId =
  rule  Types.ty_cnv ty => ty\'
  ----------------
  lvalue_id(Types.ARR(_,ty), addr) => TCode.UNARY(TCode.TOPTR ty\', addr)

  axiom lvalue_id(Types.ARITH _, addr) => addr
  axiom lvalue_id(Types.PTR _, addr) => addr
  axiom lvalue_id(Types.REC _, addr) => addr
end"
  input Type_a inTypeA;
  input Type_b inTypeB;
  output Type_b outTypeB;
algorithm
  outTypeB:=
  matchcontinue (inTypeA,inTypeB)
    local Type_b addr;
    case (_,addr) then addr;
  end matchcontinue;
end lvalueId;

function mkload
  input Types.Ty ty;
  input TCode.Exp addr;
  output TCode.Exp outExp;
protected
  TCode.Ty ty_1;
algorithm
  ty_1 := Types.tyCnv(ty);
  outExp := TCode.UNARY(TCode.LOAD(ty_1),addr);
end mkload;

function rvalueVar
  input Types.Ty inTy;
  input TCode.Exp inExp;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inTy,inExp)
    local
      TCode.Exp exp,addr;
      Types.Ty ty;
      TCode.Ty ty_1;
    case ((ty as Types.ARITH(_)),addr)
      equation
        exp = mkload(ty, addr);
      then
        (exp,ty);
    case ((ty as Types.PTR(_)),addr)
      equation
        exp = mkload(ty, addr);
      then
        (exp,ty);
    case ((ty as Types.REC(_)),addr)
      equation
        exp = mkload(ty, addr);
      then
        (exp,ty);
    case (Types.ARR(_,ty),addr)
      equation
        ty_1 = Types.tyCnv(ty);
      then
        (TCode.UNARY(TCode.TOPTR(ty_1),addr),Types.PTR(ty));
  end matchcontinue;
end rvalueVar;

function rvalueId
  input Bnd inBnd;
  input String inString;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inBnd,inString)
    local
      Integer i;
      Real r;
      TCode.Exp exp_1;
      Types.Ty ty_1,ty;
      String id;
    case (CONSTbnd(INTcon(i)),_) then (TCode.ICON(i),Types.ARITH(Types.INT()));
    case (CONSTbnd(REALcon(r)),_) then (TCode.RCON(r),Types.ARITH(Types.REAL()));
    case (NILbnd(),_) then (TCode.ICON(0),Types.PTRNIL());
    case (VARbnd(ty),id)
      equation
        (exp_1,ty_1) = rvalueVar(ty, TCode.ADDR(id));
      then
        (exp_1,ty_1);
  end matchcontinue;
end rvalueId;

function elabArg
  input list<tuple<String, Bnd>> env;
  input Absyn.Exp exp;
  input Types.Ty ty;
  output TCode.Exp exp_2;
protected
  TCode.Exp exp_1;
  Types.Ty ty_1;
algorithm
  (exp_1,ty_1) := elabRvalue(env, exp);
  exp_2 := Types.asgCnv(exp_1, ty_1, ty) "no auto decay" ;
end elabArg;

function elabArgs
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Types.Ty> inTypesTyLst;
  input list<TCode.Exp> inTCodeExpLst;
  output list<TCode.Exp> outTCodeExpLst;
algorithm
  outTCodeExpLst:=
  matchcontinue (inTplStringBndLst,inAbsynExpLst,inTypesTyLst,inTCodeExpLst)
    local
      list<TCode.Exp> args_2,args_1,exps_2,exps_1;
      TCode.Exp exp_1;
      list<tuple<String, Bnd>> env;
      Absyn.Exp exp;
      list<Absyn.Exp> exps;
      Types.Ty ty;
      list<Types.Ty> tys;
    case (_,{},{},args_1)
      equation
        args_2 = listReverse(args_1);
      then
        args_2;
    case (env,(exp :: exps),(ty :: tys),exps_1)
      equation
        exp_1 = elabArg(env, exp, ty);
        exps_2 = elabArgs(env, exps, tys, (exp_1 :: exps_1));
      then
        exps_2;
  end matchcontinue;
end elabArgs;

function elabUnaryRvalue
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.UnOp inUnOp;
  input Absyn.Exp inExp;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inTplStringBndLst,inUnOp,inExp)
    local
      list<tuple<String, Bnd>> env;
      Absyn.Exp exp;
      Types.Ty ty;
      TCode.Exp exp_1,exp_2;
      TCode.Ty ty_1;
    case (env,Absyn.ADDR(),exp)
      equation
        (exp_1,ty) = elabLvalue(env, exp);
      then
        (exp_1,Types.PTR(ty));
    case (env,Absyn.INDIR(),exp)
      equation
        (exp_1,Types.PTR(ty)) = elabRvalueDecay(env, exp);
        ty_1 = Types.tyCnv(ty);
      then
        (TCode.UNARY(TCode.LOAD(ty_1),exp_1),ty);
    case (env,Absyn.NOT(),exp)
      equation
        (exp_1,ty) = elabRvalueDecay(env, exp);
        exp_2 = Types.condCnv(exp_1, ty);
      then
        (TCode.BINARY(exp_2,TCode.IEQ(),TCode.ICON(0)),Types.ARITH(Types.INT()));
  end matchcontinue;
end elabUnaryRvalue;

function elabRvalue
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Exp inExp;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inTplStringBndLst,inExp)
    local
      Integer i;
      Real r;
      Bnd bnd;
      TCode.Exp exp,exp_1,exp_2,exp1_1,exp2_1,exp3;
      Types.Ty ty,ty_1,ty_2,rty,rty1,rty2,rty3,resty;
      String id;
      Absyn.Exp aexp,exp1,exp2;
      Absyn.UnOp unop;
      Absyn.BinOp binop;
      Absyn.RelOp relop;
      list<Types.Ty> argtys;
      list<TCode.Exp> args_1;
      list<Absyn.Exp> args;
      list<tuple<String, Bnd>> env;
      Absyn.Ty aty;
    case (env,Absyn.INT(i)) then (TCode.ICON(i),Types.ARITH(Types.INT()));
    case (env,Absyn.REAL(r)) then (TCode.RCON(r),Types.ARITH(Types.REAL()));
    case (env,Absyn.IDENT(id))
      equation
        bnd = lookup(env, id);
        (exp,ty) = rvalueId(bnd, id);
      then
        (exp,ty);
    case (env,Absyn.CAST(aty,aexp))
      equation
        (exp_1,ty_1) = elabRvalueDecay(env, aexp);
        ty_2 = elabTy(env, aty);
        exp_2 = Types.castCnv(exp_1, ty_1, ty_2);
      then
        (exp_2,ty_2);
    case (env,Absyn.FIELD(aexp,id))
      equation
        (exp_1,ty) = elabField(env, aexp, id);
        (exp_2,ty_1) = rvalueVar(ty, exp_1);
      then
        (exp_2,ty_1);
    case (env,Absyn.UNARY(unop,aexp))
      equation
        (exp_1,rty) = elabUnaryRvalue(env, unop, aexp);
      then
        (exp_1,rty);
    case (env,Absyn.BINARY(exp1,binop,exp2))
      equation
        (exp1_1,rty1) = elabRvalueDecay(env, exp1);
        (exp2_1,rty2) = elabRvalueDecay(env, exp2);
        (exp3,rty3) = Types.binCnv(exp1_1, rty1, binop, exp2_1, rty2);
      then
        (exp3,rty3);
    case (env,Absyn.RELATION(exp1,relop,exp2))
      equation
        (exp1_1,rty1) = elabRvalueDecay(env, exp1);
        (exp2_1,rty2) = elabRvalueDecay(env, exp2);
        exp3 = Types.relCnv(exp1_1, rty1, relop, exp2_1, rty2);
      then
        (exp3,Types.ARITH(Types.INT()));
    case (env,Absyn.EQUALITY(exp1,exp2))
      equation
        (exp1_1,rty1) = elabRvalueDecay(env, exp1);
        (exp2_1,rty2) = elabRvalueDecay(env, exp2);
        exp3 = Types.eqCnv(exp1_1, rty1, exp2_1, rty2);
      then
        (exp3,Types.ARITH(Types.INT()));
    case (env,Absyn.FCALL(id,args))
      equation
        FUNCbnd(argtys,resty) = lookup(env, id);
        args_1 = elabArgs(env, args, argtys, {});
      then
        (TCode.FCALL(id,args_1),resty);
  end matchcontinue;
end elabRvalue;

function elabRvalueDecay
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Exp inExp;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy) := matchcontinue (inTplStringBndLst,inExp)
    local
      TCode.Exp exp_1,exp_2;
      Types.Ty ty,ty_1;
      list<tuple<String, Bnd>> env;
      Absyn.Exp exp;
    case (env,exp)
      equation
        (exp_1,ty) = elabRvalue(env, exp);
        (exp_2,ty_1) = Types.decay(exp_1, ty);
      then
        (exp_2,ty_1);
  end matchcontinue;
end elabRvalueDecay;

function elabLvalue "
  LValue Expressions.
  Elaboration results in (exp,ty), where exp evaluates to
  _a_pointer_to_ the lvalue, and ty is its type.
"
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Exp inExp;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inTplStringBndLst,inExp)
    local
      Types.Ty ty;
      TCode.Exp exp_1;
      list<tuple<String, Bnd>> env;
      String id;
      Absyn.Exp exp;
    case (env,Absyn.IDENT(id)) /* env |- exp => ptr_exp,ty */
      equation
        VARbnd(ty) = lookup(env, id);
        exp_1 = lvalueId(ty, TCode.ADDR(id));
      then
        (exp_1,ty);
    case (env,Absyn.FIELD(exp,id))
      equation
        (exp_1,ty) = elabField(env, exp, id);
      then
        (exp_1,ty);
    case (env,Absyn.UNARY(Absyn.INDIR(),exp))
      equation
        (exp_1,Types.PTR(ty)) = elabRvalueDecay(env, exp);
      then
        (exp_1,ty);
  end matchcontinue;
end elabLvalue;

function elabField
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Exp inExp;
  input String inString;
  output TCode.Exp outExp;
  output Types.Ty outTy;
algorithm
  (outExp,outTy):=
  matchcontinue (inTplStringBndLst,inExp,inString)
    local
      TCode.Exp exp_1,exp_2;
      Types.Record r;
      list<tuple<String, Types.Ty>> bnds;
      Types.Ty ty;
      TCode.Record r_1;
      list<tuple<String, Bnd>> env;
      Absyn.Exp exp;
      String id;
    case (env,exp,id)
      equation
        (exp_1,Types.REC(r)) = elabLvalue(env, exp);
        bnds = Types.unfoldRec(r);
        ty = lookup(bnds, id) "N.B." ;
        r_1 = Types.recCnv(r);
        exp_2 = lvalueId(ty, TCode.UNARY(TCode.OFFSET(r_1,id),exp_1));
      then
        (exp_2,ty);
  end matchcontinue;
end elabField;

function elabStmt "
  Statements
"
  input Option<Types.Ty> inTypesTyOption;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Stmt inStmt;
  output TCode.Stmt outStmt;
algorithm
  outStmt := matchcontinue (inTypesTyOption,inTplStringBndLst,inStmt)
    local
      TCode.Exp lval,rval,rval_1,exp_1,exp_2;
      Types.Ty lvalty,rvalty,ety,rty;
      TCode.Ty lvalty_1,rty_1;
      list<tuple<String, Bnd>> env;
      Absyn.Exp lhs,rhs,exp;
      list<Types.Ty> fty,argtys;
      list<TCode.Exp> args_1;
      String id;
      list<Absyn.Exp> args;
      TCode.Stmt stmt_1,stmt1_1,stmt2_1;
      Absyn.Stmt stmt,stmt1,stmt2;
      Option<Types.Ty> oty;
    case (_,env,Absyn.ASSIGN(lhs,rhs)) /* ty_opt,env |- stmt => stmt\' */
      equation
        (lval,lvalty) = elabLvalue(env, lhs);
        (rval,rvalty) = elabRvalue(env, rhs);
        rval_1 = Types.asgCnv(rval, rvalty, lvalty) "no auto decay" ;
        lvalty_1 = Types.tyCnv(lvalty);
      then
        TCode.STORE(lvalty_1,lval,rval_1);
    case (_,env,Absyn.PCALL(id,args))
      equation
        PROCbnd(argtys) = lookup(env, id);
        args_1 = elabArgs(env, args, argtys, {});
      then
        TCode.PCALL(id,args_1);
    case (SOME(rty),env,Absyn.FRETURN(exp))
      equation
        (exp_1,ety) = elabRvalue(env, exp);
        exp_2 = Types.asgCnv(exp_1, ety, rty) "no auto decay" ;
        rty_1 = Types.tyCnv(rty);
      then
        TCode.RETURN(SOME((rty_1,exp_2)));
    case (NONE(),env,Absyn.PRETURN()) then TCode.RETURN(NONE());
    case (oty,env,Absyn.WHILE(exp,stmt))
      equation
        (exp_1,ety) = elabRvalueDecay(env, exp);
        exp_2 = Types.condCnv(exp_1, ety);
        stmt_1 = elabStmt(oty, env, stmt);
      then
        TCode.WHILE(exp_2,stmt_1);
    case (oty,env,Absyn.IF(exp,stmt1,stmt2))
      equation
        (exp_1,ety) = elabRvalueDecay(env, exp);
        exp_2 = Types.condCnv(exp_1, ety);
        stmt1_1 = elabStmt(oty, env, stmt1);
        stmt2_1 = elabStmt(oty, env, stmt2);
      then
        TCode.IF(exp_2,stmt1_1,stmt2_1);
    case (oty,env,Absyn.SEQ(stmt1,stmt2))
      equation
        stmt1_1 = elabStmt(oty, env, stmt1);
        stmt2_1 = elabStmt(oty, env, stmt2);
      then
        TCode.SEQ(stmt1_1,stmt2_1);
    case (oty,env,Absyn.SKIP()) then TCode.SKIP();
  end matchcontinue;
end elabStmt;

function elabVar "
  Declarations
"
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.VarBnd inVarBnd;
  output String outString;
  output Types.Ty outTy;
algorithm
  (outString,outTy):=
  matchcontinue (inTplStringBndLst,inVarBnd)
    local
      Types.Ty ty_1;
      list<tuple<String, Bnd>> env;
      String id;
      Absyn.Ty ty;
    case (env,Absyn.VARBND(id,ty)) /* env |- Var => (id,ty) */
      equation
        ty_1 = elabTy(env, ty);
      then
        (id,ty_1);
  end matchcontinue;
end elabVar;

function elabVars
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.VarBnd> inAbsynVarBndLst;
  input list<tuple<String, Types.Ty>> inTplStringTypesTyLst;
  output list<tuple<String, Types.Ty>> outTplStringTypesTyLst;
algorithm
  outTplStringTypesTyLst:=
  matchcontinue (inTplStringBndLst,inAbsynVarBndLst,inTplStringTypesTyLst)
    local
      String id;
      Types.Ty ty;
      list<tuple<String, Bnd>> env;
      Absyn.VarBnd var;
      list<Absyn.VarBnd> vars;
      list<tuple<String, Types.Ty>> vars_2,vars_1;
    case (_,{},vars_1)
      equation
        vars_2 = listReverse(vars_1);
      then
        vars_2;
    case (env,(var :: vars),vars_1)
      equation
        (id,ty) = elabVar(env, var);
        vars_2 = elabVars(env, vars, ((id,ty) :: vars_1));
      then
        vars_2;
  end matchcontinue;
end elabVars;

function mkvar
  input tuple<String, Types.Ty> inTplStringTypesTy;
  output TCode.Var outVar;
algorithm
  outVar:=
  matchcontinue (inTplStringTypesTy)
    local
      TCode.Ty ty_1;
      String id;
      Types.Ty ty;
    case ((id,ty))
      equation
        ty_1 = Types.tyCnv(ty);
      then
        TCode.VAR(id,ty_1);
  end matchcontinue;
end mkvar;

function mkvarbnd<Type_a>
  input tuple<Type_a, Types.Ty> inTplTypeATypesTy;
  output tuple<Type_a, Bnd> outTplTypeABnd;
algorithm
  outTplTypeABnd:=
  matchcontinue (inTplTypeATypesTy)
    local
      Type_a id;
      Types.Ty ty;
    case ((id,ty)) then ((id,VARbnd(ty)));
  end matchcontinue;
end mkvarbnd;

function decayFormalTy
  input Types.Ty inTy;
  output Types.Ty outTy;
algorithm
  outTy:=
  matchcontinue (inTy)
    local Types.Ty ty;
    case (Types.ARR(_,ty)) then Types.PTR(ty);
    case ((ty as Types.ARITH(_))) then ty;
    case ((ty as Types.PTR(_))) then ty;
    case ((ty as Types.REC(_))) then ty;
  end matchcontinue;
end decayFormalTy;

function decayFormal<Type_a>
  input tuple<Type_a, Types.Ty> inTplTypeATypesTy;
  output tuple<Type_a, Types.Ty> outTplTypeATypesTy;
algorithm
  outTplTypeATypesTy:=
  matchcontinue (inTplTypeATypesTy)
    local
      Types.Ty ty_1,ty;
      Type_a id;
    case ((id,ty))
      equation
        ty_1 = decayFormalTy(ty);
      then
        ((id,ty_1));
  end matchcontinue;
end decayFormal;

function snd<Type_a,Type_b>
  input tuple<Type_a, Type_b> inTplTypeATypeB;
  output Type_b outTypeB;
algorithm
  outTypeB:=
  matchcontinue (inTplTypeATypeB)
    local Type_b y;
    case ((_,y)) then y;
  end matchcontinue;
end snd;

function elabFormals
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.VarBnd> inAbsynVarBndLst;
  output list<TCode.Var> outTCodeVarLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
  output list<Types.Ty> outTypesTyLst;
algorithm
  (outTCodeVarLst,outTplStringBndLst,outTypesTyLst):=
  matchcontinue (inTplStringBndLst,inAbsynVarBndLst)
    local
      list<tuple<String, Types.Ty>> pre_formals,pre_formals_1;
      list<TCode.Var> formals_1;
      list<tuple<String, Bnd>> argenv,env;
      list<Types.Ty> argtys;
      list<Absyn.VarBnd> formals;
    case (env,formals)
      equation
        pre_formals = elabVars(env, formals, {});
        pre_formals_1 = map(decayFormal, pre_formals);
        formals_1 = map(mkvar, pre_formals_1);
        argenv = map(mkvarbnd, pre_formals_1);
        argtys = map(snd, pre_formals_1);
      then
        (formals_1,argenv,argtys);
  end matchcontinue;
end elabFormals;

function elabSubbnd
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.SubBnd inSubBnd;
  output list<tuple<String, Bnd>> outTplStringBndLst;
  output TCode.Proc outProc;
algorithm
  (outTplStringBndLst,outProc):=
  matchcontinue (inTplStringBndLst,inSubBnd)
    local
      Types.Ty ty0,ty1;
      TCode.Ty ty2;
      list<TCode.Var> formals_1;
      list<tuple<String, Bnd>> argenv,env1,env2,env0;
      list<Types.Ty> argtys;
      Option<TCode.Block> block_1;
      String id;
      list<Absyn.VarBnd> formals;
      Absyn.Ty ty;
      Option<Absyn.Block> block_;
    case (env0,Absyn.FUNCBND(id,formals,ty,block_))
      equation
        ty0 = elabTy(env0, ty);
        ty1 = decayFormalTy(ty0);
        ty2 = Types.tyCnv(ty1) "ret ARR ==> ret PTR" ;
        (formals_1,argenv,argtys) = elabFormals(env0, formals);
        env1 = ((id,FUNCbnd(argtys,ty1)) :: env0);
        env2 = listAppend(argenv, env1);
        block_1 = elabBody(SOME(ty1), env2, block_);
      then
        (env1,TCode.PROC(id,formals_1,SOME(ty2),block_1));
    case (env0,Absyn.PROCBND(id,formals,block_))
      equation
        (formals_1,argenv,argtys) = elabFormals(env0, formals);
        env1 = ((id,PROCbnd(argtys)) :: env0);
        env2 = listAppend(argenv, env1);
        block_1 = elabBody(NONE(), env2, block_);
      then
        (env1,TCode.PROC(id,formals_1,NONE(),block_1));
  end matchcontinue;
end elabSubbnd;

function elabSubbnds
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input list<Absyn.SubBnd> inAbsynSubBndLst;
  input list<TCode.Proc> inTCodeProcLst;
  output list<tuple<String, Bnd>> outTplStringBndLst;
  output list<TCode.Proc> outTCodeProcLst;
algorithm
  (outTplStringBndLst,outTCodeProcLst):=
  matchcontinue (inTplStringBndLst,inAbsynSubBndLst,inTCodeProcLst)
    local
      list<TCode.Proc> subbnds_2,subbnds_1;
      list<tuple<String, Bnd>> env,env_1,env_2;
      TCode.Proc subbnd_1;
      Absyn.SubBnd subbnd;
      list<Absyn.SubBnd> subbnds;
    case (env,{},subbnds_1)
      equation
        subbnds_2 = listReverse(subbnds_1);
      then
        (env,subbnds_2);
    case (env,(subbnd :: subbnds),subbnds_1)
      equation
        (env_1,subbnd_1) = elabSubbnd(env, subbnd);
        (env_2,subbnds_2) = elabSubbnds(env_1, subbnds, (subbnd_1 :: subbnds_1));
      then
        (env_2,subbnds_2);
  end matchcontinue;
end elabSubbnds;

function elabBody
  input Option<Types.Ty> inTypesTyOption;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Option<Absyn.Block> inAbsynBlockOption;
  output Option<TCode.Block> outTCodeBlockOption;
algorithm
  outTCodeBlockOption:=
  matchcontinue (inTypesTyOption,inTplStringBndLst,inAbsynBlockOption)
    local
      TCode.Block block_1;
      Option<Types.Ty> fty;
      list<tuple<String, Bnd>> env;
      Absyn.Block block_;
    case (_,_,NONE()) then NONE();
    case (fty,env,SOME(block_))
      equation
        block_1 = elabBlock(fty, env, block_);
      then
        SOME(block_1);
  end matchcontinue;
end elabBody;

function elabBlock
  input Option<Types.Ty> inTypesTyOption;
  input list<tuple<String, Bnd>> inTplStringBndLst;
  input Absyn.Block inBlock;
  output TCode.Block outBlock;
algorithm
  outBlock := matchcontinue (inTypesTyOption,inTplStringBndLst,inBlock)
    local
      list<tuple<String, Bnd>> env1,env2,varenv,env3,env4,env0;
      list<tuple<String, Types.Ty>> pre_vars;
      list<TCode.Var> vars_1;
      list<TCode.Proc> subbnds_1;
      TCode.Stmt stmt_1;
      Option<Types.Ty> fty;
      list<Absyn.ConBnd> consts;
      list<Absyn.TyBnd> types;
      list<Absyn.VarBnd> vars;
      list<Absyn.SubBnd> subbnds;
      Absyn.Stmt stmt;
    case (fty,env0,Absyn.BLOCK(consts,types,vars,subbnds,stmt))
      equation
        env1 = elabConsts(env0, consts);
        env2 = elabTypes(env1, types);
        pre_vars = elabVars(env2, vars, {});
        vars_1 = map(mkvar, pre_vars);
        varenv = map(mkvarbnd, pre_vars);
        env3 = listAppend(varenv, env2);
        (env4,subbnds_1) = elabSubbnds(env3, subbnds, {});
        stmt_1 = elabStmt(fty, env4, stmt);
      then
        TCode.BLOCK(vars_1,subbnds_1,stmt_1);
  end matchcontinue;
end elabBlock;

function elaborate
  input Absyn.Prog inProg;
  output TCode.Prog outProg;
algorithm
  outProg:=
  matchcontinue (inProg)
    local
      TCode.Block block_1;
      String id;
      Absyn.Block block_;
    case (Absyn.PROG(id,block_))
      equation
        block_1 = elabBlock(NONE(), envInit, block_);
      then
        TCode.PROG(id,block_1);
  end matchcontinue;
end elaborate;
end Static;

