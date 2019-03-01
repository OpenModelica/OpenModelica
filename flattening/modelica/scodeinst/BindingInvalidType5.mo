// name: BindingInvalidType5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BindingInvalidType5
  Real x[3] = {"1", "2", "3"};
end BindingInvalidType5;

// Result:
// Error processing file: BindingInvalidType5.mo
// [flattening/modelica/scodeinst/BindingInvalidType5.mo:8:3-8:30:writable] Error: Type mismatch in binding x = {"1", "2", "3"}, expected subtype of Real[3], got type String[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
