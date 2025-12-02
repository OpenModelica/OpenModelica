// name: BuiltinAttribute4
// keywords:
// status: incorrect
//

model BuiltinAttribute4
  Real x(x = 1);
end BuiltinAttribute4;

// Result:
// Error processing file: BuiltinAttribute4.mo
// [flattening/modelica/scodeinst/BuiltinAttribute4.mo:7:10-7:15:writable] Error: Modified element x not found in class Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
