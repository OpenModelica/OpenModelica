// name: BindingInvalidType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BindingInvalidType1
  Real x = "wrong";
end BindingInvalidType1;

// Result:
// Error processing file: BindingInvalidType1.mo
// [flattening/modelica/scodeinst/BindingInvalidType1.mo:8:3-8:19:writable] Error: Type mismatch in binding x = "wrong", expected subtype of Real, got type String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
