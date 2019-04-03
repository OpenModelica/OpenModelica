// name: BuiltinAttribute9
// keywords:
// status: incorrect
// cflags: -d=newInst
//


model BuiltinAttribute9
  Real x;
  Real y(start = x);
end BuiltinAttribute9;

// Result:
// Error processing file: BuiltinAttribute9.mo
// [flattening/modelica/scodeinst/BuiltinAttribute9.mo:10:10-10:19:writable] Error: Component start of variability parameter has binding 'x' of higher variability continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
