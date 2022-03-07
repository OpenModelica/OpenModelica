// name: InnerOuterReplaceable1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  outer Real x;
  Real y;
equation
  x = y;
end A;

model B
  outer Real x;
  Real y;
equation
  x = 2 * y;
end B;

model C
  replaceable A a;
  inner Real x;
end C;

model InnerOuterReplaceable1
  C c(redeclare B a);
end InnerOuterReplaceable1;


// Result:
// class InnerOuterReplaceable1
//   Real c.a.y;
//   Real c.x;
// equation
//   c.x = 2.0 * c.a.y;
// end InnerOuterReplaceable1;
// endResult
