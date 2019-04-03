// name: BuiltinAttribute4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute4
  Real x(x = 1);
end BuiltinAttribute4;

// Result:
// Error processing file: BuiltinAttribute4.mo
// [flattening/modelica/scodeinst/BuiltinAttribute4.mo:8:10-8:15:writable] Error: Modified element x not found in class Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
