// name: BindingInvalidType3
// keywords:
// status: incorrect
//

model BindingInvalidType3
  Real x[3] = {1, 2};
end BindingInvalidType3;

// Result:
// Error processing file: BindingInvalidType3.mo
// [flattening/modelica/scodeinst/BindingInvalidType3.mo:7:3-7:21:writable] Error: Type mismatch in binding 'x = {1.0, 2.0}', expected array dimensions [3], got [2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
