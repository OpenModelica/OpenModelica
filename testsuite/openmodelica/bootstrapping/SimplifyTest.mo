package SimplifyTest "Run ExpressionSimplify.simplify on some sample expressions"
  import DAE.*;
  /*    Exp addMul =
"x * 1.0 + 1.0 * x + 1.0 + 1.0 + 1.0 + 1.0 + 1.0 + x * 1.0 + 1.0 * x + x * x * 1.0 + (x * 1.0 + 1.0 * x) * x + 1.0 + 1.0 + 1.0";
"rxAddrx + add5r1 + rxAddrx + rxPow2Mul1 + rxAddrxMulrx + add3r1"
 */

  function printResult
    input tuple<String,String> res;
  protected
    String s1,s2;
  algorithm
    (s1,s2) := res;
    print(stringAppendList({"simplify(",s1,") = ",s2,"\n"}));
  end printResult;

  function test
  protected
    list<Exp> base,simpl;
    list<String> baseStr,simplStr;
    constant Operator usubr = UMINUS(T_REAL_DEFAULT);
    constant Operator addr = ADD(T_REAL_DEFAULT);
    constant Operator subr = SUB(T_REAL_DEFAULT);
    constant Operator mulr = MUL(T_REAL_DEFAULT);
    constant Operator divr = DIV(T_REAL_DEFAULT);
    constant Operator powr = POW(T_REAL_DEFAULT);
    Exp i1 = ICONST(1);
    Exp i2 = ICONST(2);
    Exp i3 = ICONST(3);
    Exp add1_2 = BINARY(i1,ADD(T_INTEGER_DEFAULT),i2);
    Exp r1 = RCONST(1.0);
    constant Exp rx = CREF(CREF_IDENT("x",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp ry = CREF(CREF_IDENT("y",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rz = CREF(CREF_IDENT("z",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rw = CREF(CREF_IDENT("w",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rv = CREF(CREF_IDENT("v",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp absrx = Expression.makePureBuiltinCall("abs",{rx},T_REAL_DEFAULT);
    constant Exp absry = Expression.makePureBuiltinCall("abs",{ry},T_REAL_DEFAULT);
    constant Exp exprx = Expression.makePureBuiltinCall("exp",{rx},T_REAL_DEFAULT);
    constant Exp expry = Expression.makePureBuiltinCall("exp",{ry},T_REAL_DEFAULT);
    constant Exp sqrtrx = Expression.makePureBuiltinCall("sqrt",{rx},T_REAL_DEFAULT);
    constant Exp sinrx = Expression.makePureBuiltinCall("sin",{rx},T_REAL_DEFAULT);
    constant Exp cosrx = Expression.makePureBuiltinCall("cos",{rx},T_REAL_DEFAULT);
    constant Exp tanrx = Expression.makePureBuiltinCall("tan",{rx},T_REAL_DEFAULT);
    constant Exp tanhrx = Expression.makePureBuiltinCall("tanh",{rx},T_REAL_DEFAULT);
    constant Exp sinhrx = Expression.makePureBuiltinCall("sinh",{rx},T_REAL_DEFAULT);
    constant Exp coshrx = Expression.makePureBuiltinCall("cosh",{rx},T_REAL_DEFAULT);
    constant Exp lnInvrx = Expression.makePureBuiltinCall("log",{BINARY(RCONST(1.0),divr,rx)},T_REAL_DEFAULT);
    constant Exp lnrx = Expression.makePureBuiltinCall("log",{rx},T_REAL_DEFAULT);
    constant Exp lnSqrtrx = Expression.makePureBuiltinCall("log",{sqrtrx},T_REAL_DEFAULT);
    constant Exp lnExprx = Expression.makePureBuiltinCall("exp",{lnrx},T_REAL_DEFAULT);
    constant Exp lnExpMulrx = Expression.makePureBuiltinCall("exp",{BINARY(lnrx,mulr,ry)},T_REAL_DEFAULT);
    constant Exp lnExpMulMulrx = Expression.makePureBuiltinCall("exp",{BINARY(rz,mulr,BINARY(lnrx,mulr,ry))},T_REAL_DEFAULT);
    constant Exp lnExpMulMulDivrx = Expression.makePureBuiltinCall("exp",{BINARY(BINARY(rz,mulr,BINARY(lnrx,mulr,ry)),divr,rw)},T_REAL_DEFAULT);
    constant Exp lnExpNegMulMulDivrx = Expression.makePureBuiltinCall("exp",{BINARY(BINARY(rz,mulr,UNARY(usubr,BINARY(lnrx,mulr,ry))),divr,rw)},T_REAL_DEFAULT);
    constant Exp lnExpDivrx = Expression.makePureBuiltinCall("exp",{BINARY(lnrx,divr,ry)},T_REAL_DEFAULT);
    Exp rxMulr1 = BINARY(rx,MUL(T_REAL_DEFAULT),r1) "x*1.0";
    Exp r1Mulrx = BINARY(r1,MUL(T_REAL_DEFAULT),rx) "1.0*x";
    Exp rxAddrx = BINARY(rxMulr1,addr,r1Mulrx) "x*1.0 + 1.0*x";
    Exp rxAddrxMulrx = BINARY(rxAddrx,MUL(T_REAL_DEFAULT),rx) "(x*1.0 + 1.0*x)*x";
    Exp add2r1 = BINARY(r1,addr,r1) "1.0+1.0";
    Exp add3r1 = BINARY(r1,addr,add2r1) "1.0+1.0+1.0";
    Exp add4r1 = BINARY(r1,addr,add3r1) "1.0+1.0+1.0+1.0";
    Exp add5r1 = BINARY(r1,addr,add4r1) "1.0+1.0+1.0+1.0+1.0";
    Exp rxPow2 = BINARY(rx,MUL(T_REAL_DEFAULT),rx) "x*x";
    Exp rxPow2Mul1 = BINARY(rxPow2,MUL(T_REAL_DEFAULT),r1) "x*x*1.0";
    Exp bigExp = BINARY(rxAddrx,addr,BINARY(add5r1,addr,BINARY(rxAddrx,addr,BINARY(rxPow2Mul1,addr,BINARY(rxAddrxMulrx,addr,add3r1)))));
    Exp divExp = BINARY(BINARY(UNARY(usubr,rx),DIV(T_REAL_DEFAULT),ry),SUB(T_REAL_DEFAULT),BINARY(rx,DIV(T_REAL_DEFAULT),rz)) "((-x)/y) - (x/z)";
    Exp Exp1 = BINARY(BINARY(rx,mulr,ry),addr,BINARY(rx,mulr,rz)) "(x*y) + (x*z) => x*(y+z)";
    Exp Exp2 = BINARY(BINARY(rx,mulr,ry),addr,BINARY(rz,mulr,rx)) "(x*y) + (z*x) = x*(y+z)";
    Exp Exp3 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(rz,mulr,rx)) "(y*x) + (x*z) = x*(y+z)";
    Exp Exp4 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(rx,mulr,rz))"(y*x) + (x*z) = x*(y+z)";
    Exp Exp5 = BINARY(BINARY(ry,powr,rx),mulr,BINARY(rz,powr,rx)) "y^x*z^x => (y*z)^x";
    Exp Exp6 = BINARY(BINARY(rx,powr,ry),mulr,BINARY(rx,powr,rz))"x^y*x^z => x^(y+z)";
    Exp Exp7 = BINARY(BINARY(rx,powr,ry),divr,BINARY(rx,powr,rz))"x^y/x^z => x^(y-z)";

    Exp Exp8_1 = BINARY(BINARY(ry,divr,rx),addr,BINARY(rz,divr,rx)) "(y op2 x) op1 (z op3 x) => (y op1 z) op2 x";
    Exp Exp8_2 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(rz,mulr,rx)) "(y op2 x) op1 (z op3 x) => (y op1 z) op2 x";
    Exp Exp8_3 = BINARY(BINARY(ry,mulr,rx),subr,BINARY(rz,mulr,rx)) "(y op2 x) op1 (z op3 x) => (y op1 z) op2 x";
    Exp Exp8_4 = BINARY(BINARY(ry,divr,rx),subr,BINARY(rz,divr,rx)) "(y op2 x) op1 (z op3 x) => (y op1 z) op2 x";

    Exp Exp9_1 = BINARY(BINARY(rx,mulr,ry),subr,BINARY(rx,divr,rz)) "(x * y) op1 (x / z) => x*(y op1 (1/ z))";
    Exp Exp9_2 = BINARY(BINARY(rx,mulr,ry),addr,BINARY(rx,divr,rz)) "(x * y) op1 (x / z) => x*(y op1 (1/ z))";

    Exp Exp10_1 = BINARY(BINARY(rx,divr,ry),subr,BINARY(rx,mulr,rz)) "(x / y) op1 (x * z) => x*(1/y op1 z)";
    Exp Exp10_2 = BINARY(BINARY(rx,divr,ry),addr,BINARY(rx,mulr,rz)) "(x / y) op1 (x * z) => x*(1/y op1 z)";

    Exp Exp11_1 = BINARY(BINARY(rx,mulr,rz),addr,BINARY(ry,mulr,rz))"[x op2 z] op1 [y op2 z] => (x op1 y) op2 z";
    Exp Exp11_2 = BINARY(BINARY(rx,mulr,rz),subr,BINARY(ry,mulr,rz))"[x op2 z] op1 [y op2 z] => (x op1 y) op2 z";
    Exp Exp11_3 = BINARY(BINARY(rx,divr,rz),addr,BINARY(ry,divr,rz))"[x op2 z] op1 [y op2 z] => (x op1 y) op2 z";
    Exp Exp11_4 = BINARY(BINARY(rx,divr,rz),subr,BINARY(ry,divr,rz))"[x op2 z] op1 [y op2 z] => (x op1 y) op2 z";

    Exp Exp12_1 = BINARY(BINARY(BINARY(ry,divr,rx),mulr,rz),subr,BINARY(rw,divr,rx))"[(y op2 x) * z] op1 [w op2 x] => (e1*e3 op1 e4*e5) op2 e";
    Exp Exp12_2 = BINARY(BINARY(BINARY(ry,divr,rx),mulr,rz),addr,BINARY(rw,divr,rx))"[(y op2 x) * z] op1 [w op2 x] => (e1*e3 op1 e4*e5) op2 e";
    Exp Exp12_3 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),subr,BINARY(rw,mulr,rx))"[(y op2 x) * z] op1 [w op2 x] => (e1*e3 op1 e4*e5) op2 e";
    Exp Exp12_4 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),addr,BINARY(rw,mulr,rx))"[(y op2 x) * z] op1 [w op2 x] => (e1*e3 op1 e4*e5) op2 e";
    Exp Exp13_1 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),addr,BINARY(BINARY(rw,mulr,rx),mulr,rv))"[(y op2 x) * z] op1 [(w op2 x) * v] => (y*z op1 w*v) op2 x";
    Exp Exp13_2 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),subr,BINARY(BINARY(rw,mulr,rx),mulr,rv))"[(y op2 x) * z] op1 [(w op2 x) * v] => (y*z op1 w*v) op2 x";
    Exp Exp13_3 = BINARY(BINARY(BINARY(ry,divr,rx),mulr,rz),addr,BINARY(BINARY(rw,divr,rx),mulr,rv))"[(y op2 x) * z] op1 [(w op2 x) * v] => (y*z op1 w*v) op2 x";
    Exp Exp13_4 = BINARY(BINARY(BINARY(ry,divr,rx),mulr,rz),subr,BINARY(BINARY(rw,divr,rx),mulr,rv))"[(y op2 x) * z] op1 [(w op2 x) * v] => (y*z op1 w*v) op2 x";

    Exp Exp14_1 = BINARY(BINARY(ry,mulr,rx),subr,BINARY(BINARY(rz,mulr,rx),mulr,rw))"[y op2 x] op1 [(z op2 x) * w] => (y op1 z*w) op2 x";
    Exp Exp14_2 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(BINARY(rz,mulr,rx),mulr,rw))"[y op2 x] op1 [(z op2 x) * w] => (y op1 z*w) op2 x";
    Exp Exp14_3 = BINARY(BINARY(ry,divr,rx),subr,BINARY(BINARY(rz,divr,rx),mulr,rw))"[y op2 x] op1 [(z op2 x) * w] => (y op1 z*w) op2 x";
    Exp Exp14_4 = BINARY(BINARY(ry,divr,rx),addr,BINARY(BINARY(rz,divr,rx),mulr,rw))"[y op2 x] op1 [(z op2 x) * w] => (y op1 z*w) op2 x";

    Exp Exp15 = BINARY(BINARY(rx, mulr, ry),subr,BINARY(rx,mulr,rz)) "(x*y) - (x*z) => x*(y-z)";
    Exp Exp16 = BINARY(BINARY(rx, mulr, ry),subr,BINARY(rz,mulr,ry)) "(x*y) - (z*x) => x*(y-z)";

    Exp Exp17_1 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),subr,BINARY(rw,mulr,rx)) "y*x op2 z op1 w*x";
    Exp Exp17_2 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),addr,BINARY(rw,mulr,rx)) "y*x op2 z op1 w*x";
    Exp Exp17_3 = BINARY(BINARY(BINARY(ry,mulr,rx),divr,rz),subr,BINARY(rw,mulr,rx)) "y*x op2 z op1 w*x";
    Exp Exp17_4 = BINARY(BINARY(BINARY(ry,mulr,rx),divr,rz),addr,BINARY(rw,mulr,rx)) "y*x op2 z op1 w*x";
    Exp Exp17_5 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),subr,BINARY(rx,mulr,rw)) "y*x op2 z op1 x*w";
    Exp Exp17_6 = BINARY(BINARY(BINARY(ry,mulr,rx),mulr,rz),addr,BINARY(rx,mulr,rw)) "y*x op2 z op1 x*w";
    Exp Exp17_7 = BINARY(BINARY(BINARY(ry,mulr,rx),divr,rz),subr,BINARY(rx,mulr,rw)) "y*x op2 z op1 x*w";
    Exp Exp17_8 = BINARY(BINARY(BINARY(ry,mulr,rx),divr,rz),addr,BINARY(rx,mulr,rw)) "y*x op2 z op1 x*w";

    Exp Exp18_1 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),subr,BINARY(rw,mulr,rx)) "y*(x op2 z) op1 w*x";
    Exp Exp18_2 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),addr,BINARY(rw,mulr,rx)) "y*(x op2 z) op1 w*x";
    Exp Exp18_3 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),subr,BINARY(rw,mulr,rx)) "y*(x op2 z) op1 w*x";
    Exp Exp18_4 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),addr,BINARY(rw,mulr,rx)) "y*(x op2 z) op1 w*x";
    Exp Exp18_5 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),subr,BINARY(rx,mulr,rw)) "y*(x op2 z) op1 w*x";
    Exp Exp18_6 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),addr,BINARY(rx,mulr,rw)) "y*(x op2 z) op1 w*x";
    Exp Exp18_7 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),subr,BINARY(rx,mulr,rw)) "y*(x op2 z) op1 w*x";
    Exp Exp18_8 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),addr,BINARY(rx,mulr,rw)) "y*(x op2 z) op1 w*x";

    Exp Exp19_1 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),subr,BINARY(rw,mulr,BINARY(rx,mulr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_2 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),addr,BINARY(rw,mulr,BINARY(rx,mulr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_3 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),subr,BINARY(rw,mulr,BINARY(rx,mulr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_4 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),addr,BINARY(rw,mulr,BINARY(rx,mulr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_5 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),subr,BINARY(rw,mulr,BINARY(rx,divr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_6 = BINARY(BINARY(ry,mulr,BINARY(rx,mulr,rz)),addr,BINARY(rw,mulr,BINARY(rx,divr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_7 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),subr,BINARY(rw,mulr,BINARY(rx,divr,rv)))"y*(x op2 z) op1 w*(x op3 v)";
    Exp Exp19_8 = BINARY(BINARY(ry,mulr,BINARY(rx,divr,rz)),addr,BINARY(rw,mulr,BINARY(rx,divr,rv)))"y*(x op2 z) op1 w*(x op3 v)";

    Exp Exp20_1 = BINARY(BINARY(ry,mulr,rx),subr,BINARY(rz,mulr,BINARY(rx,mulr,rw)))"y*x op1 z*(x op3 w)";
    Exp Exp20_2 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(rz,mulr,BINARY(rx,mulr,rw)))"y*x op1 z*(x op3 w)";
    Exp Exp20_3 = BINARY(BINARY(ry,mulr,rx),subr,BINARY(rz,mulr,BINARY(rx,divr,rw)))"y*x op1 z*(x op3 w)";
    Exp Exp20_4 = BINARY(BINARY(ry,mulr,rx),addr,BINARY(rz,mulr,BINARY(rx,divr,rw)))"y*x op1 z*(x op3 w)";

    Exp Exp21 = BINARY(rx,divr,BINARY(ry,powr,UNARY(usubr,rz))) "x/(y^(-z)) => x*(y^z)";

    Exp Exp22_1 = BINARY(BINARY(BINARY(ry,mulr,rx),addr,rz),divr,rx)"(y*x op1 z)/x => y op1 z/x";
    Exp Exp22_2 = BINARY(BINARY(BINARY(ry,mulr,rx),subr,rz),divr,rx)"(y*x op1 z)/x => y op1 z/x";

    Exp Exp23_1 = BINARY(BINARY(ry,addr,BINARY(rz,mulr,rx)),divr,rx)"(y op1 z*x)/x =>  y/x  op1 z";
    Exp Exp23_2 = BINARY(BINARY(ry,subr,BINARY(rz,mulr,rx)),divr,rx)"(y op1 z*x)/x =>  y/x  op1 z";

    Exp Exp24_1 = BINARY(absrx,mulr,absry) "|x| op2 |y| => |x op2 y|";
    Exp Exp24_2 = BINARY(absrx,divr,absry) "|x| op2 |y| => |x op2 y|";

    Exp Exp25 = BINARY(ry,divr,exprx) "y / exp(x) => y*exp(-x)";

    Exp Exp26 = BINARY(exprx,mulr,expry)"exp(x) * exp(y) => exp(x + y)";
    Exp Exp27 = BINARY(exprx,divr,expry)"exp(x) * exp(y)";
    Exp Exp28 = BINARY(rx,subr,rx)" x - x";
    Exp Exp29 = BINARY(rx,addr,rx)" x + x";
    Exp Exp30 = BINARY(rx,mulr,rx)" x * x";
    Exp Exp31 = BINARY(rx,divr,rx)" x / x";
    Exp Exp32 = BINARY(RCONST(0.0),divr,RCONST(0.0))" 0 / 0";
    Exp Exp33 = BINARY(sqrtrx,mulr,rx)" sqrt(x) * x";
    Exp Exp34 = BINARY(rx,divr,sqrtrx)" x / sqrt(x)";
    Exp Exp35_1 = BINARY(rx,divr,absrx)" x / abs(x)";
    Exp Exp35_2 = BINARY(absrx,divr,rx)" abs(x) / x";
    Exp Exp35_3 = BINARY(Exp35_1,mulr,Exp35_2)" sign(x) * sign(x)";

    Exp Exp36_1 = BINARY(sinrx,mulr,cosrx) "sin(2*x) = 2*sin(x)*cos(x)";
    Exp Exp36_2 = BINARY(cosrx,mulr,sinrx) "sin(2*x) = 2*sin(x)*cos(x)";

    Exp Exp37_1 = BINARY(BINARY(sinrx,powr,RCONST(2.0)),addr,BINARY(cosrx,powr,RCONST(2.0))) "sin^2 + cos^2 = 1";
    Exp Exp37_2 = BINARY(BINARY(cosrx,powr,RCONST(2.0)),addr,BINARY(sinrx,powr,RCONST(2.0))) "cos^2 + sin^2 = 1";

    Exp Exp38_1 = BINARY(cosrx, mulr, tanrx) "sin(x)*tan(x)";
    Exp Exp38_2 = BINARY(tanrx, mulr, cosrx) "sin(x)*tan(x)";

    Exp Exp39_1 = BINARY(BINARY(coshrx,powr,RCONST(2.0)),addr,UNARY(usubr,BINARY(sinhrx,powr,RCONST(2.0)))) "cosh^2(x) + (-sinh^2(x)) = 1";
    Exp Exp39_2 = BINARY(UNARY(usubr,BINARY(sinhrx,powr,RCONST(2.0))),addr,BINARY(coshrx,powr,RCONST(2.0))) "(-sinh^2(x)) + cosh^2(x) = 1";

    Exp Exp40_1 = BINARY(cosrx, mulr, tanrx) "tanh(x)*cosh(x) = sinh(x)";
    Exp Exp40_2 = BINARY(tanrx, mulr, cosrx) "tanh(x)*cosh(x) = sinh(x)";

    Exp Exp41_1 = BINARY(rx, addr, UNARY(usubr,ry))"x+(-y)";
    Exp Exp41_2 = BINARY(UNARY(usubr,ry), addr, rx)"x+(-y)";

    Exp Exp42_1 = BINARY(rx,addr,BINARY(UNARY(usubr,ry),mulr,rz))"x + ((-y) op2 z) = x - (y op2 z)";
    Exp Exp42_2 = BINARY(rx,addr,BINARY(UNARY(usubr,ry),divr,rz))"x + ((-y) op2 z) = x - (y op2 z)";

    Exp Exp43_1 = BINARY(BINARY(rx,mulr,ry),mulr,rx)"(x * y) * x ";
    Exp Exp43_2 = BINARY(rx,mulr,BINARY(rx,mulr,ry))"(x * y) * x ";

    Exp Exp44_1 = BINARY(ry, addr, BINARY(rx,mulr,ry))"y + (x*y)";
    Exp Exp44_2 = BINARY(ry, addr, BINARY(ry,mulr,rx))"y + (x*y)";
    Exp Exp44_3 = BINARY(BINARY(rx,mulr,ry), addr, ry)"y + (x*y)";
    Exp Exp44_4 = BINARY(BINARY(ry,mulr,rx), addr, ry)"y + (x*y)";

    Exp Exp45_1 = BINARY(rx,mulr,BINARY(rx,powr,ry))"x*x^y";
    Exp Exp45_2 = BINARY(BINARY(rx,powr,ry), mulr, rx)"x*x^y";

    Exp Exp46_1 = BINARY(rx,mulr,sqrtrx)"sqrt(x) * x";
    Exp Exp46_2 = BINARY(sqrtrx, mulr, rx)"sqrt(x) * x";

    Exp Exp47_1 = BINARY(BINARY(BINARY(ry, mulr, BINARY(rz,mulr,rx)), addr, rw),divr,rx)"(y * (z*x) op1 w)/x";
    Exp Exp47_2 = BINARY(BINARY(BINARY(ry, mulr, BINARY(rz,mulr,rx)), subr, rw),divr,rx)"(y * (z*x) op1 w)/x";

    Exp Exp48 = BINARY(rx, subr, BINARY(UNARY(usubr,ry),mulr, rz))"x-(-y)*z";
    Exp Exp49 = BINARY(rx, subr, BINARY(UNARY(usubr,ry),divr, rz))"x-(-y)/z";

    Exp Exp50 = BINARY(UNARY(usubr,rx), mulr,BINARY(rx,subr,rz))"-x*(y-z) = x*(z -y)";
    Exp Exp51 = BINARY(UNARY(usubr,rx), divr,BINARY(rx,subr,rz))"-x/(y-z) = x/(z -y)";

    Exp Exp52 = BINARY(UNARY(usubr,rx),powr,RCONST(2.0)) "(-x)^2";
    Exp Exp53 = BINARY(sqrtrx, powr, RCONST(2.0)) "sqrt(x) ^ 2.0";
    Exp Exp54 = BINARY(sqrtrx, powr, ry) "sqrt(x) ^ y";
    Exp Exp55 = BINARY(rx, divr, BINARY(rx, powr, ry))"x/x^y => x^(1-y)";

    Exp Exp56 = BINARY(lnInvrx, addr, lnrx) "ln(1/x) + ln(x)";
    Exp Exp57 = lnInvrx "ln(1/x)";
    Exp Exp58 = lnSqrtrx "ln(sqrt(x))";
    Exp Exp59 = BINARY(BINARY(lnInvrx, subr, lnrx),addr,BINARY(RCONST(4.0),mulr,lnSqrtrx)) "ln(1/x) - ln(x) + 2*ln(sqrt(x))";

    Exp Exp60 = lnExpMulrx;
    Exp Exp61 = lnExpMulMulrx;
    Exp Exp62 = lnExpDivrx;
    Exp Exp63 = BINARY(lnExpMulMulrx,mulr,lnExpMulrx);
    Exp Exp64 = lnExpMulMulDivrx;
    Exp Exp65 = BINARY(BINARY(lnExpMulMulrx,mulr,lnExpMulrx),mulr,lnExpMulMulDivrx);
    Exp Exp66 = lnExpNegMulMulDivrx;
    Exp Exp67 = BINARY(lnExpNegMulMulDivrx,powr,lnExpNegMulMulDivrx);


    Exp Exp68h_0 = BINARY(exprx,addr,absrx);
    Exp Exp68h_1 = BINARY(UNARY(usubr,ry),addr, absrx);
    Exp Exp68h_4 = BINARY(UNARY(usubr,exprx),mulr, absrx);
    Exp Exp68h_2 = BINARY(rx,addr, RCONST(1.0));
    Exp Exp68h_3 = BINARY(Exp68h_4, mulr, coshrx);
    Exp Exp68 = IFEXP(RELATION(absrx,LESSEQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_1 = IFEXP(RELATION(RCONST(0.0),LESS(T_REAL_DEFAULT),absrx,-1,NONE()), rx, ry);
    Exp Exp68_2 = IFEXP(RELATION(absrx,GREATEREQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_3 = IFEXP(RELATION(RCONST(0.0),GREATER(T_REAL_DEFAULT),absrx,-1,NONE()), rx, ry);
    Exp Exp68_4 = IFEXP(RELATION(Exp68h_0,LESSEQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_5 = IFEXP(RELATION(RCONST(0.0),LESS(T_REAL_DEFAULT),Exp68h_0,-1,NONE()), rx, ry);
    Exp Exp68_6 = IFEXP(RELATION(Exp68h_0,GREATEREQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_7 = IFEXP(RELATION(RCONST(0.0),GREATER(T_REAL_DEFAULT),Exp68h_0,-1,NONE()), rx, ry);
    Exp Exp68_8 = IFEXP(RELATION(exprx,LESSEQ(T_REAL_DEFAULT),absrx,-1,NONE()), rx, ry);
    Exp Exp68_9 = IFEXP(RELATION(absrx,LESS(T_REAL_DEFAULT),exprx,-1,NONE()), rx, ry);
    Exp Exp68_10 = IFEXP(RELATION(absrx,GREATEREQ(T_REAL_DEFAULT),exprx,-1,NONE()), rx, ry);
    Exp Exp68_11 = IFEXP(RELATION(absrx,GREATER(T_REAL_DEFAULT),exprx,-1,NONE()), rx, ry);
    Exp Exp68_12 = IFEXP(RELATION(Exp68h_1,LESSEQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_13 = IFEXP(RELATION(RCONST(0.0),LESS(T_REAL_DEFAULT),Exp68h_1,-1,NONE()), rx, ry);
    Exp Exp68_14 = IFEXP(RELATION(Exp68h_1,GREATEREQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_15 = IFEXP(RELATION(RCONST(0.0),GREATER(T_REAL_DEFAULT),Exp68h_1,-1,NONE()), rx, ry);
    Exp Exp68_16 = IFEXP(RELATION(Exp68h_2,LESSEQ(T_REAL_DEFAULT),rx,-1,NONE()), rx, ry);
    Exp Exp68_17 = IFEXP(RELATION(rx,LESS(T_REAL_DEFAULT),Exp68h_2,-1,NONE()), rx, ry);
    Exp Exp68_18 = IFEXP(RELATION(Exp68h_2,GREATEREQ(T_REAL_DEFAULT),rx,-1,NONE()), rx, ry);
    Exp Exp68_19 = IFEXP(RELATION(rx,GREATER(T_REAL_DEFAULT),Exp68h_2,-1,NONE()), rx, ry);
    Exp Exp68_20 = IFEXP(RELATION(Exp68h_3,LESSEQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_21 = IFEXP(RELATION(RCONST(0.0),LESS(T_REAL_DEFAULT),Exp68h_3,-1,NONE()), rx, ry);
    Exp Exp68_22 = IFEXP(RELATION(Exp68h_3,GREATEREQ(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_23 = IFEXP(RELATION(RCONST(0.0),GREATER(T_REAL_DEFAULT),Exp68h_3,-1,NONE()), rx, ry);
    Exp Exp68_24 = IFEXP(RELATION(RCONST(0.0),LESSEQ(T_REAL_DEFAULT),Exp68h_3,-1,NONE()), rx, ry);
    Exp Exp68_25 = IFEXP(RELATION(Exp68h_3,LESS(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);
    Exp Exp68_26 = IFEXP(RELATION(RCONST(0.0),GREATEREQ(T_REAL_DEFAULT),Exp68h_3,-1,NONE()), rx, ry);
    Exp Exp68_27 = IFEXP(RELATION(Exp68h_3,GREATER(T_REAL_DEFAULT),RCONST(0.0),-1,NONE()), rx, ry);


  algorithm
    base     := {i1,i2,i3,add1_2,r1,rx,rxMulr1,r1Mulrx,rxAddrx,rxAddrxMulrx,add2r1,add3r1,add4r1,add5r1,rxPow2,rxPow2Mul1,bigExp,divExp,Exp1,Exp2, Exp3, Exp4, Exp5, Exp6, Exp7, Exp8_1, Exp8_2, Exp8_3, Exp8_4, Exp9_1, Exp9_2, Exp10_1, Exp10_2, Exp11_1, Exp11_2, Exp11_3, Exp11_4, Exp12_1, Exp12_2, Exp12_3, Exp12_4, Exp13_1, Exp13_2, Exp13_3, Exp13_4, Exp14_1, Exp14_2, Exp14_3, Exp14_4, Exp15, Exp16, Exp17_1, Exp17_2, Exp17_3, Exp17_4, Exp17_5,Exp17_6,Exp17_7, Exp17_8, Exp18_1, Exp18_2, Exp18_3, Exp18_4, Exp18_5, Exp18_6, Exp18_7, Exp18_8, Exp19_1, Exp19_2, Exp19_2, Exp19_3, Exp19_4, Exp19_5, Exp19_6, Exp19_7, Exp19_8, Exp20_1, Exp20_2, Exp20_3, Exp20_4, Exp21, Exp22_1, Exp22_2, Exp23_1, Exp23_2, Exp24_1, Exp24_2, Exp25, Exp26, Exp27, Exp28, Exp29, Exp30, Exp31,Exp32, Exp33, Exp34, Exp35_1, Exp35_2, Exp35_3, Exp36_1, Exp36_1, Exp37_1, Exp37_2, Exp38_1, Exp38_2, Exp39_1, Exp39_2, Exp40_1, Exp40_2, Exp41_1, Exp41_2, Exp42_1, Exp42_2, Exp43_1, Exp43_2, Exp44_1, Exp44_2, Exp44_3, Exp44_4, Exp45_1, Exp45_2, Exp46_1, Exp46_2, Exp47_1, Exp47_2, Exp48, Exp49, Exp50, Exp51, Exp52, Exp53, Exp54, Exp55, Exp56, Exp57, Exp58, Exp59, Exp60, Exp61, Exp62, Exp63, Exp64, Exp65, Exp66, Exp67, Exp68, Exp68_1, Exp68_2, Exp68_3, Exp68_4, Exp68_5, Exp68_6, Exp68_7, Exp68_8, Exp68_9, Exp68_10, Exp68_11, Exp68_12, Exp68_13, Exp68_14, Exp68_15, Exp68_16, Exp68_17, Exp68_18, Exp68_19, Exp68_20, Exp68_21, Exp68_22, Exp68_23, Exp68_24, Exp68_25, Exp68_26, Exp68_27};
    simpl    := ExpressionSimplify.simplifyList(base);
    baseStr  := List.map(base, ExpressionDump.printExpStr);
    simplStr := List.map(simpl, ExpressionDump.printExpStr);
    List.map_0(List.threadTuple(baseStr,simplStr), printResult);
  end test;
end SimplifyTest;
