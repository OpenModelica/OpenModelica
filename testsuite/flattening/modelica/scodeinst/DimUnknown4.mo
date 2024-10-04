// name: DimUnknown4
// keywords:
// status: incorrect
//
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model DimUnknown4
  B b[4](each a(each x = 3.0));
end DimUnknown4;

// Result:
// Error processing file: DimUnknown4.mo
// [flattening/modelica/scodeinst/DimUnknown4.mo:8:3-8:15:writable] Error: Dimension 1 of 'x' could not be deduced from the component's binding equation '3.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
