// name: VectorizeBindings1
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize,vectorizeBindings
//

model M
  parameter Real p = 1;
  parameter Real q = 2;
end M;

model VectorizeBindings1
  parameter Real p = 2;
  M m[2,3](each p = 2*p);
end VectorizeBindings1;

// Result:
// class VectorizeBindings1
//   parameter Real p = 2.0;
//   parameter Real[2, 3] m.q = fill(2.0, 2, 3);
//   parameter Real[2, 3] m.p = array(array(2.0 * p for $m2 in 1:3) for $m1 in 1:2);
// end VectorizeBindings1;
// endResult
