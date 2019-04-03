// name: OperatorFunction2
// keywords: operator
// status: correct
//
// tests the shorthand operator function keyword, extension should be illegal
//

operator record Rec
  Real r;
  operator function '+'
    input Rec r1;
    input Rec r2;
    output Rec res;
  algorithm
    res := Rec(r = r1.r + r2.r);
  end '+';
end Rec;

record MyRec
  extends Rec; //ILLEGAL
  Real k;
end MyRec;

model OperatorIllegal
  MyRec mr;
equation
  MyRec.r = 2.0;
  MyRec.k = 1.0;
end OperatorIllegal;
