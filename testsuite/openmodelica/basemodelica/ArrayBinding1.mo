// name: ArrayBinding1
// status: correct
// cflags: -d=newInst -f -d=-nfScalarize,vectorizeBindings,evaluateAllParameters

model A
  parameter Real p;
end A;

model ArrayBinding1
  final parameter Real P = 1;
  A a[4,4,4](each p = P);
end ArrayBinding1;

// Result:
// //! base 0.1.0
// package 'ArrayBinding1'
//   model 'ArrayBinding1'
//     final parameter Real 'P' = 1.0;
//     parameter Real[4, 4, 4] 'a.p' = fill(1.0, 4, 4, 4);
//   end 'ArrayBinding1';
// end 'ArrayBinding1';
// endResult
