package ExpressionTest "test function like
  Expression.expAdd, Expression.expSub, Expression.makeDiv, Expression.expMul on some sample expressions"

  import DAE.*;

  function printResult
    input tuple<String,String> res;
  protected
    String s1,s2;
  algorithm
    (s1,s2) := res;
    print(stringAppendList({s1," == ",s2,"\n"}));
  end printResult;

  function test
  protected
    list<Exp> base, simpl, sumTest;
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
    Exp one = RCONST(1.0);
    Exp zero = RCONST(0.0);
    constant Exp rx = CREF(CREF_IDENT("x",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp ry = CREF(CREF_IDENT("y",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rz = CREF(CREF_IDENT("z",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rw = CREF(CREF_IDENT("w",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);
    constant Exp rv = CREF(CREF_IDENT("v",T_REAL_DEFAULT,{}),T_REAL_DEFAULT);

    Exp Exp1   = BINARY(one,mulr, rx) "1*x";
    Exp Exp1_1 = Expression.expMul(one, rx) "1*x";
    Exp Exp2 = BINARY(rx,mulr, one) "x*1";
    Exp Exp2_1 = Expression.expMul(rx, one) "x/1";
    Exp Exp3   = BINARY(zero,divr, rx) "0/x";
    Exp Exp3_1 = Expression.makeDiv(zero, rx) "0/x";
    Exp Exp4 = BINARY(rx,mulr, one) "x/1";
    Exp Exp4_1 = Expression.makeDiv(rx, one) "x/1";
    Exp Exp5 = BINARY(rx,addr,UNARY(usubr,ry))"x+(-y)";
    Exp Exp5_1 = Expression.expAdd(rx,Expression.negate(ry)) "x+(-y)";
    Exp Exp6 = BINARY(UNARY(usubr,ry),addr,rx)"(-y)+x";
    Exp Exp6_1 = Expression.expAdd(Expression.negate(ry),rx) "(-y)+x";
    Exp Exp7 = BINARY(rx,subr,UNARY(usubr,ry))"x-(-y)";
    Exp Exp7_1 = Expression.expSub(rx,Expression.negate(ry)) "x-(-y)";
    Exp Exp8 = BINARY(rx,addr,BINARY(UNARY(usubr,ry),mulr,rz))"x +(-y)*z";
    Exp Exp8_1 = Expression.expAdd(rx,BINARY(UNARY(usubr,ry),mulr,rz)) "x +(-y)*z";
    Exp Exp9 = BINARY(rx,addr,BINARY(UNARY(usubr,ry),divr,rz))"x +(-y)/z";
    Exp Exp9_1 = Expression.expAdd(rx,BINARY(UNARY(usubr,ry),divr,rz)) "x +(-y)/z";
    Exp Exp10 = BINARY(BINARY(UNARY(usubr,ry),mulr,rz), addr, rx)"(-y)*z + x";
    Exp Exp10_1 = Expression.expAdd(BINARY(UNARY(usubr,ry),mulr,rz),rx) "(-y)*z + x";
    Exp Exp11 = BINARY(BINARY(UNARY(usubr,ry),divr,rz),addr, rx)"x +(-y)/z";
    Exp Exp11_1 = Expression.expAdd(BINARY(UNARY(usubr,ry),divr,rz),rx) "x +(-y)/z";
    Exp Exp12   = BINARY(zero,divr, zero) "0/0";
    Exp Exp12_1 = Expression.makeDiv(zero, zero) "0/0";
    Exp Exp13   = BINARY(rx,divr, one) "rx/1";
    Exp Exp13_1 = Expression.makeDiv(rx, one) "rx/1";
    Exp Exp14 = BINARY(rx,subr,BINARY(UNARY(usubr,ry),mulr,rz))"x -(-y)*z";
    Exp Exp14_1 = Expression.expSub(rx,BINARY(UNARY(usubr,ry),mulr,rz)) "x -(-y)*z";
    Exp Exp15 = BINARY(rx,subr,BINARY(UNARY(usubr,ry),divr,rz))"x -(-y)/z";
    Exp Exp15_1 = Expression.expSub(rx,BINARY(UNARY(usubr,ry),divr,rz)) "x -(-y)/z";
    Exp Exp16 = BINARY(rx,powr,one)"x^1";
    Exp Exp16_1 = Expression.expPow(rx,one) "x^1";
    Exp Exp17 = BINARY(rx,powr,zero)"x^0";
    Exp Exp17_1 = Expression.expPow(rx,zero) "x^0";
    Exp Exp18 = BINARY(zero,powr,zero)"0^0";
    Exp Exp18_1 = Expression.expPow(zero,zero) "0^0";
    Exp Exp19 = BINARY(zero,powr,rx)"0^x";
    Exp Exp19_1 = Expression.expPow(zero,rx) "0^x";
    Exp Exp20 = BINARY(UNARY(usubr,rx),powr,RCONST(4.0))"(-e)^r";
    Exp Exp20_1 = Expression.expPow(UNARY(usubr,rx),RCONST(4.0))"(-e)^r";
    Exp Exp21 = BINARY(BINARY(rx,divr,ry),powr,UNARY(usubr,rz))"(x/y)^(-z) = (y/x)^z";
    Exp Exp21_1 = Expression.expPow(BINARY(rx,divr,ry),UNARY(usubr,rz))"(x/y)^(-z) = (y/x)^z";
    Exp Exp22 = BINARY(BINARY(rx,divr,ry),powr,RCONST(-7.0))"(x/y)^(-z) = (y/x)^z";
    Exp Exp22_1 = Expression.expPow(BINARY(rx,divr,ry),RCONST(-7.0))"(x/y)^(-z) = (y/x)^z";
    Exp ExpSum;
    Exp ExpSum_1;
    Exp ExpProduct;
    Exp ExpProduct_1;
    Exp ExpSumSimple;

    Exp ngExp1 = Expression.negate(Exp1);
    Exp ngExp2 = Expression.negate(Exp2);

    algorithm
    sumTest := {ngExp1, ngExp2, Exp3, Exp13, Exp22};
    ExpSum := BINARY(ngExp1,addr,BINARY(ngExp2,addr,BINARY(Exp3_1,addr,BINARY(Exp13,addr,Exp22))));
    ExpSum_1 := Expression.makeSum(sumTest);
    ExpSumSimple := Expression.makeSum1(sumTest);
    ExpProduct := BINARY(ngExp1,mulr,BINARY(ngExp2,mulr,BINARY(Exp3,mulr,BINARY(Exp13,mulr,Exp22))));
    ExpProduct_1 := Expression.makeProductLst(sumTest);

    base     := {Exp1, Exp2, Exp3, Exp4, Exp5, Exp6, Exp7, Exp8, Exp9, Exp10, Exp11, Exp12, Exp13, Exp14, Exp15, Exp16, Exp17, Exp18, Exp19, Exp20, Exp21, Exp22, ExpSum, ExpSum, ExpProduct};
    simpl    := {Exp1_1, Exp2_1, Exp3_1, Exp4_1, Exp5_1, Exp6_1, Exp7_1, Exp8_1, Exp9_1, Exp10_1, Exp11_1, Exp12_1, Exp13_1, Exp14_1, Exp15_1, Exp16_1, Exp17_1, Exp18_1,Exp19_1, Exp20_1, Exp21_1, Exp22_1, ExpSum_1, ExpSumSimple, ExpProduct_1};
    baseStr  := List.map(base, ExpressionDump.printExpStr);
    simplStr := List.map(simpl, ExpressionDump.printExpStr);
    List.map_0(List.threadTuple(baseStr,simplStr), printResult);

  end test;
end ExpressionTest;
