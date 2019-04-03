package Eval

import Absyn;

uniontype Value " Values, bindings and environment "
  record INTval "integer values"
    Integer x1;
  end INTval;
  record REALval "real values"
    Real x1;
  end REALval;
end Value;

type VarBnd = tuple<Absyn.Ident,Value>;

type Env = list<VarBnd>;

type VarBndList = list<VarBnd>;
constant VarBndList init_env={};

uniontype Ty2 " Ty2 is an auxiliary datatype used to handle types during evaluation "
  record INT2
    Integer x1;
    Integer x2;
  end INT2;
  record REAL2
    Real x1;
    Real x2;
  end REAL2;
end Ty2;

function lookup "lookup returns the value associated with an identifier.
  If no association is present, lookup will fail.
  Identifier id is found in the first pair of the list, and value is returned."
  input Env inEnv;
  input String inIdent;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inEnv,inIdent)
    local
      String id2,id;
      Value value;
      Env rest;
    case ((id2,value) :: rest, id)
      then if valueEq(id,id2) then value else lookup(rest, id);
  end matchcontinue;
end lookup;

function lookupextend
  input Env inEnv;
  input String inIdent;
  output Env outEnv;
  output Value outValue;
algorithm
  (outEnv,outValue):=
  matchcontinue (inEnv,inIdent)
    local
      Value value;
      Env env;
      String id;
    // Return value of id in env. If id not present, add id and return 0
    case (env,id)
      equation
        failure(_ = lookup(env, id));
        // failed to find id
        value = INTval(0);
      then ((id,value) :: env,value);
    case (env,id)
      equation
        // found id, return it
        value = lookup(env, id);
      then (env,value);
  end matchcontinue;
end lookupextend;

function update
  input Env in_env;
  input Absyn.Ident in_ident;
  input Value in_value;
  output Env out_env;
algorithm
  out_env:=
  matchcontinue (in_env,in_ident,in_value)
    local
      list<tuple<String,Value>> env;
      String id;
      Value value;
    case (env,id,value) then (id,value) :: env;
  end matchcontinue;
end update;

function type_lub
  input Value in_value1;
  input Value in_value2;
  output Ty2 out_ty2;
algorithm
  out_ty2:=
  matchcontinue (in_value1,in_value2)
    local
      Integer x,y;
      Real x2,y2,rx,ry;
    case (INTval(x),INTval(y)) then INT2(x,y);
    case (INTval(x),REALval(ry))
      equation
        x2 = intReal(x);
      then REAL2(x2,ry);
    case (REALval(rx),INTval(y))
      equation
        y2 = intReal(y);
      then REAL2(rx,y2);
    case (REALval(rx),REALval(ry))
      then REAL2(rx,ry);
  end matchcontinue;
end type_lub;

function apply_int_binop "************** Binary and unary operators **************"
  input Absyn.BinOp in_binop1;
  input Integer in_integer2;
  input Integer in_integer3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (in_binop1,in_integer2,in_integer3)
    local Integer x,y;
    case (Absyn.ADD(),x,y) then x + y;
    case (Absyn.SUB(),x,y) then x - y;
    case (Absyn.MUL(),x,y) then x * y;
    case (Absyn.DIV(),x,y) then intDiv(x, y);
  end matchcontinue;
end apply_int_binop;

function apply_real_binop
  input Absyn.BinOp in_binop1;
  input Real in_real2;
  input Real in_real3;
  output Real out_real;
algorithm
  out_real:=
  matchcontinue (in_binop1,in_real2,in_real3)
    local Real x,y;
    case (Absyn.ADD(),x,y) then x + y;
    case (Absyn.SUB(),x,y) then x - y;
    case (Absyn.MUL(),x,y) then x * y;
    case (Absyn.DIV(),x,y) then x / y;
  end matchcontinue;
end apply_real_binop;

function apply_int_unop
  input Absyn.UnOp AbsynNEG;
  input Integer x;
  output Integer y;
algorithm
  y := -x;
end apply_int_unop;

function apply_real_unop
  input Absyn.UnOp AbsynNEG;
  input Real x;
  output Real y;
algorithm
  y := -x;
end apply_real_unop;

function eval "************** Expression evaluation **************"
  input Env in_env;
  input Absyn.Exp in_exp;
  output Env out_env;
  output Value out_value;
algorithm
  (out_env,out_value):=
  matchcontinue (in_env,in_exp)
    local
      list<tuple<String,Value>> env,env2,env1;
      Integer ival,x,y,z;
      Real rval;
      Value value,v1,v2;
      String id;
      Absyn.Exp e1,e2,e,exp;
      Absyn.BinOp binop;
      Absyn.UnOp unop;
    // handle int
    case (env,Absyn.INT(ival)) then (env,INTval(ival));
    // handle real
    case (env,Absyn.REAL(rval)) then (env,REALval(rval));
    // variable id
    case (env,Absyn.IDENT(id))
      equation
        (env2,value) = lookupextend(env, id); then (env2,value);
    // int binop int
    case (env,Absyn.BINARY(e1,binop,e2))
      equation
        (env1,v1) = eval(env, e1);
        (env2,v2) = eval(env, e2);
        INT2(x,y) = type_lub(v1, v2);
        z = apply_int_binop(binop, x, y); then (env2,INTval(z));
    // int/real binop int/real
    case (env,Absyn.BINARY(e1,binop,e2))
      local Real rx,ry,rz;
      equation
        (env1,v1) = eval(env, e1);
        (env2,v2) = eval(env, e2);
        REAL2(rx,ry) = type_lub(v1, v2);
        rz = apply_real_binop(binop, rx, ry); then (env2,REALval(rz));
    // int unop exp
    case (env,Absyn.UNARY(unop,e))
      equation
        (env1,INTval(x)) = eval(env, e);
        y = apply_int_unop(unop, x); then (env1,INTval(y));
    // real unop exp
    case (env,Absyn.UNARY(unop,e))
      local Real rx,ry;
      equation
        (env1,REALval(rx)) = eval(env, e);
        ry = apply_real_unop(unop, rx); then (env1,REALval(ry));
    // eval of an assignment node returns the updated
    // environment and the assigned value id := exp
    case (env,Absyn.ASSIGN(id,exp))
      equation
        (env1,value) = eval(env, exp);
        env2 = update(env1, id, value); then (env2,value);
    case (_,_)
      equation
        print("eval failed\n");
      then fail();
  end matchcontinue;
end eval;
end Eval;

