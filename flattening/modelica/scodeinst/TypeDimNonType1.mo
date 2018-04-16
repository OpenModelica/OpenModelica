// name: TypeDimNonType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real a;
end A;

model TypeDimNonType1
  model B = A[3];
  B b;
end TypeDimNonType1;

// Result:
// Error processing file: TypeDimNonType1.mo
// [flattening/modelica/scodeinst/TypeDimNonType1.mo:12:3-12:17:writable] Error: Invalid dimensions on ‘model B‘, only types may have dimensions.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
