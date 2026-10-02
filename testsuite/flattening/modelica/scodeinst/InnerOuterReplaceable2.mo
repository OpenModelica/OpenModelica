// name: InnerOuterReplaceable2
// keywords:
// status: correct
//

model A
  outer Real x;
end A;

model B
  parameter A a;
  inner replaceable Real x;
end B;

model InnerOuterReplaceable2
  extends B(redeclare Real x = 2);
end InnerOuterReplaceable2;


// Result:
// class InnerOuterReplaceable2
//   Real x = 2.0;
// end InnerOuterReplaceable2;
// endResult
