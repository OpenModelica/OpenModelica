// name: OperatorFunction1
// keywords: operator
// status: correct
//
// tests the shorthand operator function keyword
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

model OperatorIllegal
  Rec r1,r2,r3;
equation
  r1.r = 1.0;
  r2.r = 2.0;
  r3 = r1 + r2;
end OperatorIllegal;

// Result:
// function Rec "Automatically generated record constructor for Rec"
//   input Real r;
//   output Rec res;
// end Rec;
//
// function Rec.'+'
//   input Rec r1;
//   input Rec r2;
//   output Rec res;
// algorithm
//   res := Rec(r1.r + r2.r);
// end Rec.'+';
//
// class OperatorIllegal
//   Real r1.r;
//   Real r2.r;
//   Real r3.r;
// equation
//   r1.r = 1.0;
//   r2.r = 2.0;
//   r3 = Rec.'+'(r1, r2);
// end OperatorIllegal;
// endResult
