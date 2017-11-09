// name: BuiltinAttribute3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute3
  Real x(start(y = 1));
end BuiltinAttribute3;

// Result:
// Error processing file: BuiltinAttribute3.mo
// [flattening/modelica/scodeinst/BuiltinAttribute3.mo:8:10-8:22:writable] Error: Modified element start.y not found in class Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
