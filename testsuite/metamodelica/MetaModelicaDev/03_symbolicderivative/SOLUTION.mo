package SymbolicDerivative

uniontype Exp "expressions"
  record INT "literal integers"
    Integer integer;
  end INT;
  record ADD "additions"
    Exp exp1;
    Exp exp2;
  end ADD;
  record SUB "subtractions"
    Exp exp1;
    Exp exp2;
  end SUB;
  record MUL "multiplications"
    Exp exp1;
    Exp exp2;
  end MUL;
  record DIV "divisions"
    Exp exp1;
    Exp exp2;
  end DIV;
  record NEG "negation"
    Exp exp;
  end NEG;
  record IDENT "identifiers"
    String id;
  end IDENT;
  record CALL "function calls"
    String id;
    list<Exp> args;
  end CALL;
end Exp;

function main
"Prints the expression and its derivative"
  input Exp expr;
  output Integer i;
protected
  Exp diffExpr;
  Exp simpleExpr;
algorithm
  print("f(x) = ");
  printExp(expr);
  print("\n");
  print("[Differentiating expression]\n");
  diffExpr := diff(expr,"x");
  print("f'(x) = ");
  printExp(diffExpr);
  print("\n");
  print("[Simplifying expression]\n");
  simpleExpr := simplifyExp(diffExpr);
  print("f'(x) = ");
  printExp(simpleExpr);
  print("\n");
  i := 0;
end main;

function diff
  input Exp expr;
  input String timevar;
  output Exp diffExpr;
algorithm
  diffExpr := matchcontinue (expr,timevar)
    local
      String id,id1,id2;
      Exp e1prim,e2prim,e1,e2;
      Integer i1,i2;
    // der of constant
    case (INT(_), _) then INT(0);
    // der of time variable
    case(IDENT(id1), id2)
      equation
        true = id1 == id2;
      then INT(1);
    // der of time-independent variable
    case (IDENT(_), _) then INT(0);
    // (e1+e2)' => e1'+e2'
    case (ADD(e1,e2),id)
      equation
        e1prim = diff(e1,id);
        e2prim = diff(e2,id);
      then ADD(e1prim,e2prim);
    // (e1/e2)' => (e1'*e2 - e1*e2')/e2*e2
    case (DIV(e1,e2),id)
      equation
        e1prim = diff(e1,id);
        e2prim = diff(e2,id);
      then DIV(SUB(MUL(e1prim,e2),MUL(e1,e2prim)), MUL(e2,e2));
    // (-e1)' => -(e1')
    case (NEG(e1),id)
      equation
        e1prim = diff(e1,id);
      then NEG(e1prim);

    // your code here

    // (e1-e2)' => e1'+e2'
    case (SUB(e1,e2),id)
      equation
        e1prim = diff(e1,id);
        e2prim = diff(e2,id);
      then SUB(e1prim,e2prim);
    // (e1*e2)' => e1'*e2 + e1*e2'
    case (MUL(e1,e2),id)
      equation
        e1prim = diff(e1,id);
        e2prim = diff(e2,id);
      then ADD(MUL(e1prim,e2),MUL(e1,e2prim));
    // sin(e1)' => cos(e1)*e1'
    case (CALL("sin", {e1}),id)
      equation
        e1prim = diff(e1,id);
      then MUL(CALL("cos",{e1}),e1prim);
    // cos(e1)' => -sin(e1)*e1'
    case (CALL("cos", {e1}),id)
      equation
        e1prim = diff(e1,id);
      then NEG(MUL(CALL("sin",{e1}),e1prim));
    // pow(e1,INT(i))' => i*e1'*pow(e1,INT(i-1))
    case (CALL("pow", {e1,INT(i1)}),id)
      equation
        e1prim = diff(e1,id);
        i2 = i1-1;
      then MUL(INT(i1),MUL(e1prim,CALL("pow",{e1,INT(i2)})));

    // default case, e1' => e1'
    case (e1,_) then CALL("der",{e1});
  end matchcontinue;
end diff;

function simplifyExp
"When differentating an expression, you often end up with lots of expressions
that you can simplify (e.g. 1*x = x).
simplifyExp simplifies leaf nodes first because if we did everything in one
function we would get something like:
(2*(0*sin(x))): (2*(0*sin(x))) => (2=>2 * (0*sin(x))=>0) => (2*0)
But we want to do this:
(2*(0*sin(x))): 2=>2, (0*sin(x)) => 0, (2*0) => 0"
  input Exp expr;
  output Exp simpleExpr;
algorithm
  simpleExpr := matchcontinue (expr)
    local
      Exp e,e1,e2,sim1,sim2,res;
      String id;
      list<Exp> exprList,simpleExprList;
    case ADD(e1,e2)
      equation
        sim1 = simplifyExp(e1);
        sim2 = simplifyExp(e2);
        res = simplifyExp2(ADD(sim1,sim2));
      then res;
    case SUB(e1,e2)
      equation
        sim1 = simplifyExp(e1);
        sim2 = simplifyExp(e2);
        res = simplifyExp2(SUB(sim1,sim2));
      then res;
    case MUL(e1,e2)
      equation
        sim1 = simplifyExp(e1);
        sim2 = simplifyExp(e2);
        res = simplifyExp2(MUL(sim1,sim2));
      then res;
    case DIV(e1,e2)
      equation
        sim1 = simplifyExp(e1);
        sim2 = simplifyExp(e2);
        res = simplifyExp2(DIV(sim1,sim2));
      then res;
    case NEG(e1)
      equation
        sim1 = simplifyExp(e1);
        res = simplifyExp2(NEG(sim1));
      then res;
    case CALL(id,exprList)
      equation
        simpleExprList = simplifyExpList(exprList);
        res = simplifyExp2(CALL(id,simpleExprList));
      then res;
    case e then e; // IDENT, INT
  end matchcontinue;
end simplifyExp;

function simplifyExpList
  input list<Exp> exprList;
  output list<Exp> simpleExprList;
algorithm
  simpleExprList := matchcontinue(exprList)
    local
      list<Exp> rest,simpleRest;
      Exp simpleExpr,expr;
    case {} then {};
    case expr::rest
      equation
        simpleExpr = simplifyExp(expr);
        simpleRest = simplifyExpList(rest);
      then simpleExpr :: simpleRest;
  end matchcontinue;
end simplifyExpList;

function simplifyExp2
  input Exp expr;
  output Exp simpleExpr;
algorithm
  simpleExpr := matchcontinue (expr)
    local
      Exp e,e1,e2,sim1,sim2;
      Integer i,i1,i2;
    // Simplify addition
    case ADD(INT(i1),INT(i2)) equation i = i1 + i2; then INT(i);
    case ADD(INT(0),e) then e;
    case ADD(e,INT(0)) then e;
    // Simplify multiplication
    case MUL(INT(i1),INT(i2)) equation i = i1 * i2; then INT(i);
    case MUL(INT(0),e) then INT(0);
    case MUL(e,INT(0)) then INT(0);
    case MUL(INT(1),e) then e;
    case MUL(e,INT(1)) then e;
    // Simplify division
    // case DIV(INT(i1),INT(i2)) can give a real number, so don't simplify
    case DIV(e,INT(1)) then e;

    // Simplify some expressions of these types
    // SUB(INT,INT)
    // SUB(e,0)
    // SUB(0,e)
    // SUB(e1,NEG(e2))

    // NEG(INT)
    // NEG(NEG(e))

    // sin(0)
    // cos(0)
    // pow(x,0)
    // pow(x,1)

    // your code here
    case DIV(e,INT(1)) then e;
    case SUB(INT(i1),INT(i2)) equation i = i1-i2; then INT(i);
    case SUB(INT(0),e1) equation sim1 = simplifyExp2(NEG(e1)); then sim1;
    case SUB(e1,NEG(e2)) equation sim2 = simplifyExp2(e2); e = ADD(e1,sim2); then simplifyExp2(e);
    case NEG(INT(i1)) equation i = -i1; then INT(i);
    case NEG(NEG(e)) then e;
    case CALL("sin",{INT(0)}) then INT(0);
    case CALL("cos",{INT(0)}) then INT(1);
    case CALL("pow",{e,INT(0)}) then INT(1);
    case CALL("pow",{e,INT(1)}) then e;

    // Default case, we can't simplify anymore
    case e then e;
  end matchcontinue;
end simplifyExp2;

// Functions for printing expressions

function printExp
  input Exp exp;
protected
  String str;
algorithm
  str := expStr(exp);
  print(str);
end printExp;

function expStr
"Translates an Exp into a String"
  input Exp exp;
  output String str;
algorithm
  str := matchcontinue (exp)
    local
      Integer i;
      Exp e,lhs,rhs;
      String left,right,res,id;
      list<Exp> expList;
    case INT(i) then intString(i);
    case ADD(lhs,rhs) then binExpStr(lhs,"+",rhs);
    case SUB(lhs,rhs) then binExpStr(lhs,"-",rhs);
    case MUL(lhs,rhs) then binExpStr(lhs,"*",rhs);
    case DIV(lhs,rhs) then binExpStr(lhs,"/",rhs);
    case NEG(e) then "(-" + expStr(e) + ")";
    case IDENT(id) then id;
    case CALL("der",{e})
      equation
        res = expStr(e);
      then "(" + res + ")'";
    case CALL("pow",{e,INT(i)})
      equation
        res = expStr(e);
      then res + "^" + intString(i);
    case CALL(id,expList)
      equation
        res = expListStr(expList);
      then id + "(" + res + ")";
    case _ then "#UNKNOWN_EXP#";
  end matchcontinue;
end expStr;

function expListStr
"Translates a list of Exp into a comma-separated String"
  input list<Exp> expList;
  output String str;
algorithm
  str := matchcontinue (expList)
    local
      Exp e;
      list<Exp> rest;
      String res_1,res_2;
    case {} then "";
    case {e} then expStr(e);
    case e::rest
      equation
        res_1 = expStr(e);
        res_2 = expListStr(rest);
      then res_1 + "," + res_2;
  end matchcontinue;
end expListStr;

function binExpStr
"Translates a binary expression (lhs op rhs) into a String"
  input Exp lhs;
  input String op;
  input Exp rhs;
  output String str;
algorithm
  str := "(" + expStr(lhs) + op + expStr(rhs) + ")";
end binExpStr;

end SymbolicDerivative;
