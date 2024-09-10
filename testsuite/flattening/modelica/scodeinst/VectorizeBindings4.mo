// name: VectorizeBindings4
// keywords:
// status: correct
// cflags: -d=newInst,evaluateAllParameters,-nfScalarize,vectorizeBindings
//

model A
  parameter Real p1 = 10 + 5;
  parameter Real p2;
  Real X(start = p1, fixed = true);
end A;

model VectorizeBindings4
  final parameter Real p = 3;
  A a[4,5,6](each X(start = 20, fixed = true), each p2 = 2*p);
end VectorizeBindings4;

// Result:
// class VectorizeBindings4
//   final parameter Real p = 3.0;
//   final parameter Real[4, 5, 6] a.p1 = fill(15.0, 4, 5, 6);
//   final parameter Real[4, 5, 6] a.p2 = fill(6.0, 4, 5, 6);
//   Real[4, 5, 6] a.X(start = fill(20.0, 4, 5, 6), fixed = fill(true, 4, 5, 6));
// end VectorizeBindings4;
// endResult
