// name: OperatorComponents
// keywords: operator
// status: correct
//
// Tests operator overloading, operators can only contain function declarations
//

operator record Rec
  Real r;
  operator '+'
    function add
      input Rec r1;
      input Rec r2;
      output Rec res;
  protected
    Real factor = 3.0;
    algorithm
      res := Rec(r = r1.r + r2.r + factor);
    end add;
  end '+';
end Rec;

model OperatorComplex
  Rec r1,r2,r3;
equation
  r1 = Rec(r = 2.0);
  r2 = Rec(r = 3.0);
  r3 = r1 + r2;
end OperatorComplex;

// Result:
// function Rec "Automatically generated record constructor for Rec"
//   input Real r;
//   output Rec res;
// end Rec;
//
// function Rec.'+'.add
//   input Rec r1;
//   input Rec r2;
//   output Rec res;
//   protected Real factor = 3.0;
// algorithm
//   res := Rec(r1.r + r2.r + factor);
// end Rec.'+'.add;
//
// class OperatorComplex
//   Real r1.r;
//   Real r2.r;
//   Real r3.r;
// equation
//   r1.r = 2.0;
//   r2.r = 3.0;
//   r3 = Rec.'+'.add(r1, r2);
// end OperatorComplex;
// endResult
