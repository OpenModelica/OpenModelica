// name: BindingInvalidType3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BindingInvalidType3
  Real x[3] = {1, 2};
end BindingInvalidType3;

// Result:
// Error processing file: BindingInvalidType3.mo
// [flattening/modelica/scodeinst/BindingInvalidType3.mo:8:3-8:21:writable] Error: Type mismatch in binding ‘x = {1, 2}‘, expected array dimensions [3], got [2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
