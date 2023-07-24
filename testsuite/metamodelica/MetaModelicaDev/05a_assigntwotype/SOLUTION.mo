package AssignTwoType "file AssignTwoType.mo"

type ExpLst = list<Exp>;

// Abstract syntax for the Assigntwotype language

uniontype Program "a program"
  record PROGRAM
    ExpLst expLst;
    Exp exp;
  end PROGRAM;
end Program;

uniontype Exp "expressions"
  record INT "literal integers"
    Integer integer;
  end INT;

  record REAL "literal reals"
    Real real;
  end REAL;

  record BINARY "binary expressions"
    Exp exp1;
    BinOp binOp2;
    Exp exp3;
  end BINARY;

  record UNARY "unary expressions"
    UnOp unOp;
    Exp exp;
  end UNARY;

  record ASSIGN "assignment expressions"
    Ident ident;
    Exp exp;
  end ASSIGN;

  record IDENT "identifiers"
    Ident ident;
  end IDENT;

  record STRING "literal strings"
    String string;
  end STRING;

end Exp;

uniontype BinOp "binary operators"
  record ADD "addition operator" end ADD;
  record SUB "subtraction operator" end SUB;
  record MUL "multiplication operator" end MUL;
  record DIV "divition operator" end DIV;
end BinOp;

uniontype UnOp "unary operators"
  record NEG "negation operator" end NEG;
end UnOp;

type Ident = String;

uniontype Value "Values stored in environments"
  record INTval "integer values"
    Integer integer;
  end INTval;

  record REALval "real values"
    Real real;
  end REALval;
end Value;

type VarBnd = tuple<Ident,Value> "Bindings and environments";

type Env = list<VarBnd>;

uniontype Ty2 "Ty2 is an auxiliary datatype used to handle types during evaluation"

  record INT2
    Integer integer1;
    Integer integer2;
  end INT2;

  record REAL2
    Real real1;
    Real real2;
  end REAL2;

end Ty2;

function printvalue
  input Value inValue;
algorithm
  _:=
  matchcontinue (inValue)
    local
      Ident str;
      Integer i;
      Real r;
    case (INTval(integer = i))
      equation
        str = intString(i);
        print(str);
      then ();
    case (REALval(real = r))
      equation
        str = realString(r);
        print(str);
      then ();
  end matchcontinue;
end printvalue;

function evalprogram
  input Program inProgram;
algorithm
  _:=
  matchcontinue (inProgram)
    local
      ExpLst assignments_1,assignments;
      Env env2;
      Value value;
      Exp exp;
    case (PROGRAM(expLst = assignments,exp = exp))
      equation
        assignments_1 = listReverse(assignments);
        env2 = evals({}, assignments_1);
        (_,value) = eval(env2, exp);
        printvalue(value);
        print("\n");
      then ();
  end matchcontinue;
end evalprogram;

function evals
  input Env inEnv;
  input ExpLst inExpLst;
  output Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inExpLst)
    local
      Env e,env2,env3,env;
      Exp exp;
      ExpLst expl;
    case (e,{}) then e;
    case (env,exp :: expl)
      equation
        (env2,_) = eval(env, exp);
        env3 = evals(env2, expl); then env3;
  end matchcontinue;
end evals;

function eval
  input Env inEnv;
  input Exp inExp;
  output Env outEnv;
  output Value outValue;
algorithm
  (outEnv,outValue):=
  matchcontinue (inEnv,inExp)
    local
      Env env,env2,env1;
      Integer ival,x,y,z;
      Real rval,rx,ry,rz;
      String sval;
      Value value,v1,v2;
      Ident id;
      Exp e1,e2,e,exp;
      BinOp binop;
      UnOp unop;
    case (env,INT(integer = ival)) then (env,INTval(ival));
    case (env,REAL(real = rval)) then (env,REALval(rval));
    case (env,STRING(string = sval))
      equation
        ival = stringInt(sval);
      then (env,INTval(ival));
    case (env,IDENT(ident = id)) "variable id"
      equation
        (env2,value) = lookupextend(env, id); then (env2,value);
    case (env,BINARY(exp1 = e1,binOp2 = binop,exp3 = e2)) "int binop int"
      equation
        (env1,v1) = eval(env, e1);
        (env2,v2) = eval(env, e2);
        INT2(integer1 = x,integer2 = y) = typeLub(v1, v2);
        z = applyIntBinop(binop, x, y);
      then (env2,INTval(z));
    case (env,BINARY(exp1 = e1,binOp2 = binop,exp3 = e2)) "int/real binop int/real"
      equation
        (env1,v1) = eval(env, e1);
        (env2,v2) = eval(env, e2);
        REAL2(real1 = rx,real2 = ry) = typeLub(v1, v2);
        rz = applyRealBinop(binop, rx, ry);
      then (env2,REALval(rz));
    case (env,UNARY(unOp = unop,exp = e)) "int unop exp"
      equation
        (env1,INTval(integer = x)) = eval(env, e);
        y = applyIntUnop(unop, x);
      then (env1,INTval(y));
    case (env,UNARY(unOp = unop,exp = e)) "real unop exp"
      equation
        (env1,REALval(real = rx)) = eval(env, e);
        ry = applyRealUnop(unop, rx);
      then (env1,REALval(ry));
    case (env,ASSIGN(ident = id,exp = exp)) "eval of an assignment node returns the updated environment and
    the assigned value id := exp"
      equation
        (env1,value) = eval(env, exp);
        env2 = update(env1, id, value);
      then (env2,value);
  end matchcontinue;
end eval;

function typeLub
  input Value inValue1;
  input Value inValue2;
  output Ty2 outTy2;
algorithm
  outTy2:=
  matchcontinue (inValue1,inValue2)
    local
      Integer x,y;
      Real x2,y2;
    case (INTval(integer = x),INTval(integer = y)) then INT2(x,y);
    case (INTval(integer = x),REALval(real = y2))
      equation
        x2 = intReal(x);
      then REAL2(x2,y2);
    case (REALval(real = x2),INTval(integer = y))
      equation
        y2 = intReal(y);
      then REAL2(x2,y2);
    case (REALval(real = x2),REALval(real = y2))
      then REAL2(x2,y2);
  end matchcontinue;
end typeLub;

function applyIntBinop
  input BinOp inBinOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinOp1,inInteger2,inInteger3)
    local Integer x,y;
    case (ADD(),x,y) then x + y;
    case (SUB(),x,y) then x - y;
    case (MUL(),x,y) then x * y;
    case (DIV(),x,y) then intDiv(x, y);
  end matchcontinue;
end applyIntBinop;

function applyRealBinop
  input BinOp inBinOp1;
  input Real inReal2;
  input Real inReal3;
  output Real outReal;
algorithm
  outReal:=
  matchcontinue (inBinOp1,inReal2,inReal3)
    local Real x,y;
    case (ADD(),x,y) then x + y;
    case (SUB(),x,y) then x - y;
    case (MUL(),x,y) then x * y;
    case (DIV(),x,y) then x / y;
  end matchcontinue;
end applyRealBinop;

function applyIntUnop
  input UnOp inUnOp;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inUnOp,inInteger)
    local Integer x;
    case (NEG(),x) then -x;
  end matchcontinue;
end applyIntUnop;

function applyRealUnop
  input UnOp inUnOp;
  input Real inReal;
  output Real outReal;
algorithm
  outReal:=
  matchcontinue (inUnOp,inReal)
    local Real x;
    case (NEG(),x) then -x;
  end matchcontinue;
end applyRealUnop;

function lookup "lookup returns the value associated with an identifier.
  If no association is present, lookup will fail.
  Identifier id is found in the first pair of the list, and value is returned."
  input Env inEnv;
  input Ident inIdent;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inEnv,inIdent)
    local
      Ident id2,id;
      Value value;
      Env rest;
    case ((id2,value) :: rest, id)
      then if valueEq(id,id2) then value else lookup(rest, id);
  end matchcontinue;
end lookup;

function lookupextend
  input Env inEnv;
  input Ident inIdent;
  output Env outEnv;
  output Value outValue;
algorithm
  (outEnv,outValue):=
  matchcontinue (inEnv,inIdent)
    local
      Value value;
      Env env;
      Ident id;
    // Return value of id in env. If id not present, add id and return 0
    case (env,id)
      equation
        failure(_ = lookup(env, id));
        value = INTval(0);
      then ((id,value) :: env,value);
    case (env,id)
      equation
        value = lookup(env, id);
      then (env,value);
  end matchcontinue;
end lookupextend;

function update
  input Env inEnv;
  input Ident inIdent;
  input Value inValue;
  output Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inIdent,inValue)
    local
      Env env;
      Ident id;
      Value value;
    case (env,id,value) then (id,value) :: env;
  end matchcontinue;
end update;

end AssignTwoType;

