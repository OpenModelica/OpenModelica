encapsulated package Pam "This version differs from the one in the book. The State is just the
 current environment, the input and output streams do not exist.
 Input is done through the function read which just calls a c function doing
 a call to scanf. Works if no backtracking occurs, as when print is used."

type Ident = String "Semantics oriented abstract syntax for the PAM language";

uniontype BinOp
  record ADD end ADD;
  record SUB end SUB;
  record MUL end MUL;
  record DIV end DIV;
end BinOp;

uniontype RelOp
  record EQ end EQ;
  record GT end GT;
  record LT end LT;
  record LE end LE;
  record GE end GE;
  record NE end NE;
end RelOp;

uniontype Exp
  record INT
    Integer integer;
  end INT;

  record IDENT
    Ident ident;
  end IDENT;

  record BINARY
    Exp exp1;
    BinOp binOp2;
    Exp exp3;
  end BINARY;

  record RELATION
    Exp exp1;
    RelOp relOp2;
    Exp exp3;
  end RELATION;

end Exp;

type IdentLst = list<Ident>;

uniontype Stmt
  record ASSIGN
    Ident ident;
    Exp id "Id := Exp";
  end ASSIGN;

  record IF
    Exp exp;
    Stmt stmt;
    Stmt if_ "if Exp then Stmt..";
  end IF;

  record WHILE
    Exp exp;
    Stmt while_ "while Exp do Stmt";
  end WHILE;

  record TODO
    Exp exp;
    Stmt to "to Exp do Stmt...";
  end TODO;

  record READ
    IdentLst read "read id1,id2,...";
  end READ;

  record WRITE
    IdentLst write "write id1,id2,..";
  end WRITE;

  record SEQ
    Stmt stmt;
    Stmt stmt1 "Stmt1; Stmt2";
  end SEQ;

  record SKIP "; empty stmt" end SKIP;

end Stmt;

type VarBnd = tuple<Ident,Value> "Types needed for modeling static and dynamic semantics
Variable binding and environment type";

type Env = list<VarBnd>;

uniontype Value "Value type needed for evaluation"
  record INTval
    Integer integer;
  end INTval;

  record BOOLval
    Boolean boolean;
  end BOOLval;

end Value;

type State = Env;

import Input;

function repeatEval "Auxiliary utility functions"
  input State inState;
  input Integer inInteger;
  input Stmt inStmt;
  output State outState;
algorithm
  outState:=
  matchcontinue (inState,inInteger,inStmt)
    local
      State state,state2,state3;
      Integer n,n2;
      Stmt stmt;
    case (state,n,stmt) "repeatedly evaluate stmt n times n <= 0"
      equation
        (n <= 0) = true; then state;
    case (state,n,stmt) "eval n times"
      equation
        (n > 0) = true;
        n2 = n - 1 "n > 0";
        state2 = evalStmt(state, stmt);
        state3 = repeatEval(state2, n2, stmt); then state3;
  end matchcontinue;
end repeatEval;

function error
  input String inString1;
  input String inString2;
algorithm
  _:=
  matchcontinue (inString1,inString2)
    local Ident str1,str2;
    case (str1,str2) "Print error messages str1 and str2, and fail"
      equation
        print("Error - ");
        print(str1);
        print(" ");
        print(str2);
        print("\n"); then fail();
  end matchcontinue;
end error;

function inputItem
  output Integer i;
algorithm
  i := matchcontinue ()
    case ()
      equation
        print("input: ");
        i = Input.read();
        print("\n");
      then i;
    case () then -1;
  end matchcontinue;
end inputItem;

function outputItem
  input Integer i;
protected
  Ident s;
algorithm
  s := intString(i);
  print(s);
end outputItem;

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

function update
  input Env inEnv;
  input Ident inIdent;
  input Value inValue;
  output Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inIdent,inValue)
    local
      State env;
      Ident id;
      Value value;
    case (env,id,value) then (id,value) :: env;
  end matchcontinue;
end update;

function applyBinop "Arithmetic and functional operators"
  input BinOp inBinOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinOp1,inInteger2,inInteger3)
    local Integer x,y;
    case (ADD(),x,y) then x + y;  /* Apply a binary arithmetic operator to constant integer arguments x+y*/
    case (SUB(),x,y) then x - y;  /* x-y */
    case (MUL(),x,y) then x * y;    /* xy */
    case (DIV(),x,y) then intDiv(x, y);    /* x/y */
  end matchcontinue;
end applyBinop;

function applyRelop
  input RelOp inRelOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inRelOp1,inInteger2,inInteger3)
    local Integer x,y;
    case (LT(),x,y) then (x < y);  /*Apply a function operator, returning a boolean value x<y*/
    case (LE(),x,y) then (x <= y);  /* x<=y */
    case (EQ(),x,y) then (x == y);  /* x=y */
    case (NE(),x,y) then (x <> y);  /* x<>y */
    case (GE(),x,y) then (x >= y);  /* x>=y */
    case (GT(),x,y) then (x > y);  /* x>y */
  end matchcontinue;
end applyRelop;

function eval "Expression evaluation"
  input Env inEnv;
  input Exp inExp;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inEnv,inExp)
    local
      Integer v,v1,v2,v3;
      State env;
      Ident id;
      Exp e1,e2;
      BinOp binop;
      RelOp relop;
      Value val;
      Boolean b;
    case (_,INT(integer = v)) then INTval(v);   /* integer constant */
    case (env,IDENT(ident = id)) "identifier id"
      equation
        val = lookup(env, id);
      then val;
    case (env,IDENT(ident = id)) "If id not declared, give an error message and fail through error undefined variable id"
      equation
        failure(_ = lookup(env, id));
        error("Undefined identifier", id);
      then INTval(0);
    case (env,BINARY(exp1 = e1,binOp2 = binop,exp3 = e2)) "expr1 binop expr2"
      equation
        INTval(integer = v1) = eval(env, e1);
        INTval(integer = v2) = eval(env, e2);
        v3 = applyBinop(binop, v1, v2);
      then INTval(v3);
    case (env,RELATION(exp1 = e1,relOp2 = relop,exp3 = e2)) "expr1 relop expr2"
      equation
        INTval(integer = v1) = eval(env, e1);
        INTval(integer = v2) = eval(env, e2);
        b = applyRelop(relop, v1, v2);
      then BOOLval(b);
  end matchcontinue;
end eval;

function evalStmt "Statement evaluation"
  input State inState;
  input Stmt inStmt;
  output State outState;
algorithm
  outState:=
  matchcontinue (inState,inStmt)
    local
      Value v1;
      State env2,env,state2,state1,state,state3;
      Ident id;
      Exp e1,comp;
      Stmt s1,s2,stmt1,stmt2;
      Integer n1,v2;
      IdentLst rest;
    case (env,ASSIGN(ident = id,id = e1)) "Statement evaluation: map the current state into a new state Assignment"
      equation
        v1 = eval(env, e1);
        env2 = update(env, id, v1); then env2;
    case ((state1 as env),IF(exp = comp,stmt = s1,if_ = s2)) "IF true ..."
      equation
        BOOLval(boolean = true) = eval(env, comp);
        state2 = evalStmt(state1, s1); then state2;
    case ((state1 as env),IF(exp = comp,stmt = s1,if_ = s2)) "IF false ..."
      equation
        BOOLval(boolean = false) = eval(env, comp);
        state2 = evalStmt(state1, s2); then state2;
    case (state,WHILE(exp = comp,while_ = s1)) "WHILE ..."
      equation
        state2 = evalStmt(state, IF(comp,SEQ(s1,WHILE(comp,s1)),SKIP())); then state2;
    case ((state as env),TODO(exp = e1,to = s1)) "TO e1 DO s1 .."
      equation
        INTval(integer = n1) = eval(env, e1);
        state2 = repeatEval(state, n1, s1); then state2;
    case (state,READ(read = {})) then state;  /* READ {} */
    case (env,READ(read = id :: rest)) "READ id1,.."
      equation
        v2 = inputItem();
        env2 = update(env, id, INTval(v2));
        state2 = evalStmt(env2, READ(rest)); then state2;
    case (state,WRITE(write = {})) then state;  /* WRITE {} */
    case (env,WRITE(write = id :: rest)) "WRITE id1,."
      equation
        INTval(integer = v2) = lookup(env, id);
        outputItem(v2);
        state2 = evalStmt(env, WRITE(rest)); then state2;
    case (state,SEQ(stmt = stmt1,stmt1 = stmt2)) "stmt1 ; stmt2"
      equation
        state2 = evalStmt(state, stmt1);
        state3 = evalStmt(state2, stmt2); then state3;
    case (state,SKIP()) then state;  /* ; empty statement */
  end matchcontinue;
end evalStmt;
end Pam;

