package Assignment "Assignment.mo"

type ExpLst = list<Exp> "a list of expressions";

// Abstract syntax for the Assignments language
uniontype Program "a program"
  record PROGRAM
    ExpLst expLst;
    Exp exp;
  end PROGRAM;
end Program;

uniontype Exp "expressions"
  record INT "integer literals"
    Integer integer;
  end INT;

  record BINARY "binary expressions"
    Exp exp1;
    BinOp binOp2;
    Exp exp3;
  end BINARY;

  record UNARY "unary expresions"
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
end Exp;

uniontype BinOp "binary operators"
  record ADD "addition" end ADD;
  record SUB "substraction" end SUB;
  record MUL "multiplication" end MUL;
  record DIV "division" end DIV;
end BinOp;

uniontype UnOp "unary operators"
  record NEG "negation operator" end NEG;
end UnOp;

type Ident = String;

type Value = Integer "Values stored in environments";

type VarBnd = tuple<Ident,Value> "a binding is a tuple of id and value";

type Env = list<VarBnd> "an environment is a list of bindings";

function lookup "lookup returns the value associated with an identifier.
  If no association is present, lookup will fail."
  input Env inEnv;
  input Ident inIdent;
  output Value outValue;
algorithm
  outValue :=
  matchcontinue (inEnv,inIdent)
    local
      Ident id2,id;
      Value value;
      Env rest;
    case ((id2,value) :: rest,id)
      then if id == id2 then value else lookup(rest, id);
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
      Env env;
      Ident id;
      Value value;
    case (env,id)
      equation
        failure(_ = lookup(env, id));
      then ((id,0) :: env,0);
    case (env,id)
      equation
        value = lookup(env, id);
      then (env,value);
  end matchcontinue;
end lookupextend;

function update
  input Env env;
  input Ident id;
  input Value value;
  output Env outEnv;
algorithm
  outEnv := (id,value) :: env;
end update;

function applyBinop
  input BinOp inBinOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinOp1,inInteger2,inInteger3)
    local Value v1,v2;
    case (ADD(),v1,v2) then v1+v2;
    case (SUB(),v1,v2) then v1-v2;
    case (MUL(),v1,v2) then v1*v2;
    case (DIV(),v1,v2) then intDiv(v1,v2);
  end matchcontinue;
end applyBinop;

function applyUnop
  input UnOp inUnOp;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger := match (inUnOp,inInteger)
    local Value v;
    case (NEG(),v) then -v;
  end match;
end applyUnop;

function eval
  input Env inEnv;
  input Exp inExp;
  output Env outEnv;
  output Integer outInteger;
algorithm
  (outEnv,outInteger):=
  matchcontinue (inEnv,inExp)
    local
      Env env,env2,env3,env1;
      Value ival,value,v1,v2,v3;
      Ident s,id;
      Exp exp,e1,e2,e;
      BinOp binop;
      UnOp unop;
    // eval of integer record returns the integer value
    case (env,INT(integer = ival)) then (env,ival);
    // eval of an identifier node will lookup the identifier and return a
    // value if present; otherwise insert a binding to zero, and return zero.
    case (env,IDENT(ident = id))
      equation
        (env2,value) = lookupextend(env, id);
      then (env2,value);
    // eval of an assignment node returns the updated environment and the assigned value.
    case (env,ASSIGN(ident = id,exp = exp))
      equation
        (env2,value) = eval(env, exp);
        env3 = update(env2, id, value);
      then (env3,value);
    // eval of a node e1,ADD,e2 , etc. in an environment env
    case (env1,BINARY(exp1 = e1,binOp2 = binop,exp3 = e2))
      equation
        (env2,v1) = eval(env1, e1);
        (env3,v2) = eval(env2, e2);
        v3 = applyBinop(binop, v1, v2);
      then (env3,v3);
    // eval of a node NEG,e etc. in an environment env
    case (env1,UNARY(unOp = unop,exp = e))
      equation
        (env2,v1) = eval(env1, e);
        v2 = applyUnop(unop, v1);
      then (env2,v2);
  end matchcontinue;
end eval;

function evals
  input Env inEnv;
  input ExpLst inExpLst;
  output Env outEnv;
algorithm
  outEnv :=
  matchcontinue (inEnv,inExpLst)
    local
      Env e,env2,env3,env;
      Value v;
      Ident s;
      Exp exp;
      ExpLst expl;
    // the environment stay the same if there are no expressions
    case (e,{}) then e;
    // the head expression is evaluated in the current environment
    // generating a new environment in which the rest of the expression
    // list is evaluated. the last environment is returned
    case (env,exp :: expl)
      equation
        (env2,v) = eval(env, exp);
        env3 = evals(env2, expl);
      then env3;
  end matchcontinue;
end evals;

function evalprogram
  input Program inProgram;
  output Integer outInteger;
algorithm
  outInteger := match (inProgram)
    local
      ExpLst assignments_1,assignments;
      Env env2;
      Value value;
      Exp exp;
    case (PROGRAM(expLst = assignments,exp = exp))
      equation
        assignments_1 = listReverse(assignments);
        // your code here -> print assignments_1 and exp
        // print("The assignments: ");
        // printAssignments(assignments_1);
        // print("The expression: ");
        // printAssignments({exp});
        env2 = evals({}, assignments_1);
        // your code here -> print env2
        // print("The environment: ");
        // printEnvironment(env2);
        (_,value) = eval(env2, exp);
      then value;
  end match;
end evalprogram;

// your code here

end Assignment;

