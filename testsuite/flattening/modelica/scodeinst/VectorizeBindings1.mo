// name: VectorizeBindings1
// keywords:
// status: correct
//

model M
  parameter Real p = 1;
  parameter Real q = 2;
end M;

model VectorizeBindings1
  parameter Real p = 2;
  M m[2,3](each p = 2*p);
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize,vectorizeBindings");
end VectorizeBindings1;

// Result:
// class VectorizeBindings1
//   parameter Real p = 2.0;
//   parameter Real[2, 3] m.p = fill(2.0 * p, 2, 3);
//   parameter Real[2, 3] m.q = fill(2.0, 2, 3);
// end VectorizeBindings1;
// endResult
