// name: InnerOuterPartialOuter2
// keywords:
// status: correct
//

partial record BaseR
  constant Integer n;
  parameter Real x[n];
end BaseR;

record R
  extends BaseR(n = 1, x = ones(n));
end R;

model A
  outer BaseR r;
end A;

model InnerOuterPartialOuter2
  A a;
  inner R r;
end InnerOuterPartialOuter2;

// Result:
// class InnerOuterPartialOuter2
//   constant Integer r.n = 1;
//   parameter Real r.x[1] = 1.0;
// end InnerOuterPartialOuter2;
// endResult
