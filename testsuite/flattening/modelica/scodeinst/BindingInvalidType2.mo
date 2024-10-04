// name: BindingInvalidType2
// keywords:
// status: incorrect
//

model BindingInvalidType2
  Real x = {1, 2, 3};
end BindingInvalidType2;

// Result:
// Error processing file: BindingInvalidType2.mo
// [flattening/modelica/scodeinst/BindingInvalidType2.mo:7:3-7:21:writable] Error: Type mismatch in binding 'x = {1, 2, 3}', expected array dimensions [], got [3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
