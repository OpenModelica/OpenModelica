package Eval

import Absyn;

import Env;

function binaryLub "Type lattice;  int --> real"
  input Env.Value inValue1;
  input Env.Value inValue2;
  output Env.Value2 outValue2;
algorithm
  outValue2:=
  matchcontinue (inValue1,inValue2)
    local
      Integer v1,v2;
      Real r1,r2;
    case (Env.INTVAL(integer = v1),Env.INTVAL(integer = v2)) then Env.INTVAL2(v1,v2);
    case (Env.REALVAL(real = r1),Env.REALVAL(real = r2)) then Env.REALVAL2(r1,r2);
    case (Env.INTVAL(integer = v1),Env.REALVAL(real = r2))
      equation
        r1 = intReal(v1);
      then Env.REALVAL2(r1,r2);
    case (Env.REALVAL(real = r1),Env.INTVAL(integer = v2))
      equation
        r2 = intReal(v2);
      then Env.REALVAL2(r1,r2);
  end matchcontinue;
end binaryLub;

function promote "Promotion and type check"
  input Env.Value inValue;
  input Env.Type inType;
  output Env.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValue,inType)
    local
      Integer v;
      Real r;
      Boolean b;
    case (Env.INTVAL(integer = v),Env.INTTYPE()) then Env.INTVAL(v);
    case (Env.REALVAL(real = r),Env.REALTYPE()) then Env.REALVAL(r);
    case (Env.BOOLVAL(boolean = b),Env.BOOLTYPE()) then Env.BOOLVAL(b);
    case (Env.INTVAL(integer = v),Env.REALTYPE())
      equation
        r = intReal(v);
      then Env.REALVAL(r);
  end matchcontinue;
end promote;

function applyIntBinary "Auxiliary functions for applying the binary operators"
  input Absyn.BinOp inBinOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inBinOp1,inInteger2,inInteger3)
    local Integer v1,v2;
    case (Absyn.ADD(),v1,v2) then v1 + v2;
    case (Absyn.SUB(),v1,v2) then v1 - v2;
    case (Absyn.MUL(),v1,v2) then v1*v2;
    case (Absyn.DIV(),v1,v2) then intDiv(v1,v2);
  end matchcontinue;
end applyIntBinary;

function applyRealBinary
  input Absyn.BinOp inBinOp1;
  input Real inReal2;
  input Real inReal3;
  output Real outReal;
algorithm
  outReal := matchcontinue (inBinOp1,inReal2,inReal3)
    local Real v1,v2;
    case (Absyn.ADD(),v1,v2) then v1 + v2;
    case (Absyn.SUB(),v1,v2) then v1 - v2;
    case (Absyn.MUL(),v1,v2) then v1 * v2;
    case (Absyn.DIV(),v1,v2) then v1 / v2;
  end matchcontinue;
end applyRealBinary;

function applyIntUnary "Auxiliary functions for applying the unary operators"
  input Absyn.UnOp inUnOp;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inUnOp,inInteger)
    local Integer v1;
    case (Absyn.NEG(),v1) then -v1;
  end matchcontinue;
end applyIntUnary;

function applyRealUnary
  input Absyn.UnOp inUnOp;
  input Real inReal;
  output Real outReal;
algorithm
  outReal:=
  matchcontinue (inUnOp,inReal)
    local Real v1;
    case (Absyn.NEG(),v1) then -v1;
  end matchcontinue;
end applyRealUnary;

function applyIntRelation "Auxiliary functions for applying the function operators"
  input Absyn.RelOp inRelOp1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inRelOp1,inInteger2,inInteger3)
    local Integer v1,v2;
    case (Absyn.LT(),v1,v2) then (v1 < v2);
    case (Absyn.LE(),v1,v2) then (v1 <= v2);
    case (Absyn.GT(),v1,v2) then (v1 > v2);
    case (Absyn.GE(),v1,v2) then (v1 >= v2);
    case (Absyn.NE(),v1,v2) then (v1 <> v2);
    case (Absyn.EQ(),v1,v2) then (v1 == v2);
  end matchcontinue;
end applyIntRelation;

function applyRealRelation
  input Absyn.RelOp inRelOp1;
  input Real inReal2;
  input Real inReal3;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inRelOp1,inReal2,inReal3)
    local Real v1,v2;
    case (Absyn.LT(),v1,v2) then (v1 < v2);
    case (Absyn.LE(),v1,v2) then (v1 <= v2);
    case (Absyn.GT(),v1,v2) then (v1 > v2);
    case (Absyn.GE(),v1,v2) then (v1 >= v2);
    case (Absyn.NE(),v1,v2) then (v1 <> v2);
    case (Absyn.EQ(),v1,v2) then (v1 == v2);
  end matchcontinue;
end applyRealRelation;

function evalExpr "EVALUATE A SINGLE EXPRESSION in an environment. Return
   the new value. Expressions do not change environments."
  input Env.Env inEnv;
  input Absyn.Expr inExpr;
  output Env.Value outValue;
algorithm
  outValue:=
  matchcontinue (inEnv,inExpr)
    local
      list<Env.Bind> env;
      Integer v,c1,c2,v3;
      Env.Value v1,v2;
      Absyn.Expr e1,e2;
      Absyn.BinOp binop;
      Absyn.UnOp unop;
      Absyn.RelOp relop;
      String id;
      Real r,r1,r2,r3;
      Boolean b;
    case (env,Absyn.INTCONST(integer = v)) then Env.INTVAL(v);
    case (env,Absyn.REALCONST(real = r)) then Env.REALVAL(r);
    case (env,Absyn.BINARY(expr1 = e1,binOp2 = binop,expr3 = e2)) "Binary operators"
      equation
        v1 = evalExpr(env, e1);
        v2 = evalExpr(env, e2);
        Env.INTVAL2(integer1 = c1,integer2 = c2) = binaryLub(v1, v2);
        v3 = applyIntBinary(binop, c1, c2);
      then Env.INTVAL(v3);
    case (env,Absyn.BINARY(expr1 = e1,binOp2 = binop,expr3 = e2))
      equation
        v1 = evalExpr(env, e1);
        v2 = evalExpr(env, e2);
        Env.REALVAL2(real1 = r1,real2 = r2) = binaryLub(v1, v2);
        r3 = applyRealBinary(binop, r1, r2);
      then Env.REALVAL(r3);
    case (_,Absyn.BINARY(expr1 = _))
      equation
        print("Error: binary operator applied to invalid type(s)\n"); then fail();
    case (env,Absyn.UNARY(unOp = unop,expr = e1)) "Unary operators"
      equation
        Env.INTVAL(integer = c1) = evalExpr(env, e1);
        c2 = applyIntUnary(unop, c1);
      then Env.INTVAL(c2);
    case (env,Absyn.UNARY(unOp = unop,expr = e1))
      equation
        Env.REALVAL(real = r1) = evalExpr(env, e1);
        r2 = applyRealUnary(unop, r1);
      then Env.REALVAL(r2);
    case (_,Absyn.UNARY(unOp = _))
      equation
        print("Error: unary operator applied to invalid type\n");
      then fail();
    case (env,Absyn.RELATION(expr1 = e1,relOp2 = relop,expr3 = e2)) "Relation operators"
      equation
        v1 = evalExpr(env, e1);
        v2 = evalExpr(env, e2);
        Env.INTVAL2(integer1 = c1,integer2 = c2) = binaryLub(v1, v2);
        b = applyIntRelation(relop, c1, c2);
      then Env.BOOLVAL(b);
    case (env,Absyn.RELATION(expr1 = e1,relOp2 = relop,expr3 = e2))
      equation
        v1 = evalExpr(env, e1);
        v2 = evalExpr(env, e2);
        Env.REALVAL2(real1 = r1,real2 = r2) = binaryLub(v1, v2);
        b = applyRealRelation(relop, r1, r2);
      then Env.BOOLVAL(b);
    case (_,Absyn.RELATION(expr1 = _))
      equation
        print("Error: relation operator applied to invalid type(s)\n"); then fail();
    case (env,Absyn.VARIABLE(ident = id)) "Variable lookup"
      equation
        v1 = Env.lookup(env, id);
      then v1;
    case (env,Absyn.VARIABLE(ident = id))
      equation
        failure(_ = Env.lookup(env, id));
        print("Error: undefined variable (");
        print(id);
        print(")\n");
      then fail();
  end matchcontinue;
end evalExpr;

function printValue "EVALUATING STATEMENTS
  Print a value - the \"write\" statement"
  input Env.Value inValue;
algorithm
  _:=
  matchcontinue (inValue)
    local
      String vstr;
      Integer v;
      Real r;
    case (Env.INTVAL(integer = v))
      equation
        vstr = intString(v);
        print(vstr);
        print("\n"); then ();
    case Env.REALVAL(real = r)
      equation
        vstr = realString(r);
        print(vstr);
        print("\n"); then ();
    case Env.BOOLVAL(boolean = true)
      equation
        print("true\n"); then ();
    case Env.BOOLVAL(boolean = false)
      equation
        print("false\n"); then ();
  end matchcontinue;
end printValue;

function evalStmt "Evaluate a single statement. Pass environment forward."
  input Env.Env inEnv;
  input Absyn.Stmt inStmt;
  output Env.Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inStmt)
    local
      Env.Value v,v2;
      Env.Type ty;
      list<Env.Bind> env1,env,env2;
      String id;
      Absyn.Expr e;
      list<Absyn.Stmt> c,a,ss;
    case (env,Absyn.ASSIGN(ident = id,expr = e))
      equation
        v = evalExpr(env, e);
        ty = Env.lookuptype(env, id);
        v2 = promote(v, ty);
        env1 = Env.update(env, id, ty, v2); then env1;
    case (env,Absyn.ASSIGN(ident = id,expr = e))
      equation
        v = evalExpr(env, e);
        print("Error: assignment mismatch or variable missing\n"); then fail();
    case (env,Absyn.WRITE(expr = e))
      equation
        v = evalExpr(env, e);
        printValue(v); then env;
    case (env,Absyn.NOOP()) then env;
    case (env,Absyn.IF(expr1 = e,stmtLst2 = c))
      equation
        Env.BOOLVAL(boolean = true) = evalExpr(env, e);
        env1 = evalStmtList(env, c); then env1;
    case (env,Absyn.IF(expr1 = e,stmtLst3 = a))
      equation
        Env.BOOLVAL(boolean = false) = evalExpr(env, e);
        env1 = evalStmtList(env, a); then env1;
    case (env,Absyn.WHILE(expr = e,stmtLst = ss))
      equation
        Env.BOOLVAL(boolean = true) = evalExpr(env, e);
        env1 = evalStmtList(env, ss);
        env2 = evalStmt(env1, Absyn.WHILE(e,ss)); then env2;
    case (env,Absyn.WHILE(expr = e,stmtLst = ss))
      equation
        Env.BOOLVAL(boolean = false) = evalExpr(env, e); then env;
    case (env,Absyn.IF(expr1 = e,stmtLst3 = a))
      equation
        Env.BOOLVAL(boolean = false) = evalExpr(env, e);
        env1 = evalStmtList(env, a); then env1;
    case (env,Absyn.WHILE(expr = e,stmtLst = ss))
      equation
        Env.BOOLVAL(boolean = true) = evalExpr(env, e);
        env1 = evalStmtList(env, ss);
        env2 = evalStmt(env1, Absyn.WHILE(e,ss)); then env2;
    case (env,Absyn.WHILE(expr = e,stmtLst = ss))
      equation
        Env.BOOLVAL(boolean = false) = evalExpr(env, e); then env;
  end matchcontinue;
end evalStmt;

function evalStmtList "Evaluate a list of statements in an environent.
   Pass environment forward"
  input Env.Env inEnv;
  input Absyn.StmtList inStmtList;
  output Env.Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inStmtList)
    local
      list<Env.Bind> env,env1,env2;
      Absyn.Stmt s;
      list<Absyn.Stmt> ss;
    case (env,{}) then env;
    case (env,(s :: ss))
      equation
        env1 = evalStmt(env, s);
        env2 = evalStmtList(env1, ss); then env2;
  end matchcontinue;
end evalStmtList;

function evalDecl "EVALUATING DECLARATIONS
  Evaluate a single statement. Pass environment forward."
  input Env.Env inEnv;
  input Absyn.Decl inDecl;
  output Env.Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inDecl)
    local
      list<Env.Bind> env2,env;
      String var;
    case (env,Absyn.NAMEDECL(ident1 = var,ident2 = "integer"))
      equation
        env2 = Env.update(env, var, Env.INTTYPE(), Env.INTVAL(0)); then env2;
    case (env,Absyn.NAMEDECL(ident1 = var,ident2 = "real"))
      equation
        env2 = Env.update(env, var, Env.REALTYPE(), Env.REALVAL(0.0)); then env2;
    case (env,Absyn.NAMEDECL(ident1 = var,ident2 = "boolean"))
      equation
        env2 = Env.update(env, var, Env.BOOLTYPE(), Env.BOOLVAL(false)); then env2;
  end matchcontinue;
end evalDecl;

function evalDeclList "Evaluate a list of declarations, extending the environent."
  input Env.Env inEnv;
  input Absyn.DeclList inDeclList;
  output Env.Env outEnv;
algorithm
  outEnv:=
  matchcontinue (inEnv,inDeclList)
    local
      list<Env.Bind> env,env1,env2;
      Absyn.Decl s;
      list<Absyn.Decl> ss;
    case (env,{}) then env;
    case (env,(s :: ss))
      equation
        env1 = evalDecl(env, s);
        env2 = evalDeclList(env1, ss); then env2;
  end matchcontinue;
end evalDeclList;

function evalprog "EVALUTATING A PROGRAM means to evaluate the list of statements,
   with an initial environment containing just standard defs."
  input Absyn.Prog inProg;
algorithm
  _:=
  matchcontinue (inProg)
    local
      list<Env.Bind> env1,env2,env3;
      list<Absyn.Decl> decls;
      list<Absyn.Stmt> stmts;
    case (Absyn.PROG(declList = decls,stmtList = stmts))
      equation
        env1 = Env.initial_();
        env2 = evalDeclList(env1, decls);
        env3 = evalStmtList(env2, stmts); then ();
  end matchcontinue;
end evalprog;
end Eval;

