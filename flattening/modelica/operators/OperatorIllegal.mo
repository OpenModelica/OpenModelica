// name: OperatorIllegal
// keywords: operator
// status: incorrect
//
// extending from a record containing operator overloads should be illegal
//

operator record Rec
  Real r;
  operator '+'
    function add
      input Rec r1;
      input Rec r2;
      output Rec res;
    algorithm
      res := Rec(r = r1.r + r2.r);
    end add;
  end '+';
end Rec;

record MyRec
  extends Rec; // ILLEGAL
  Real k;
end MyRec;

model OperatorIllegal
  MyRec mr;
equation
  mr.r = 1.0;
  mr.k = 2.0;
end OperatorIllegal;
