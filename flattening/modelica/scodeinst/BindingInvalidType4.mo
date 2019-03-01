// name: BindingInvalidType4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BindingInvalidType4
  Real x[3] = 1;
end BindingInvalidType4;

// Result:
// Error processing file: BindingInvalidType4.mo
// [flattening/modelica/scodeinst/BindingInvalidType4.mo:8:3-8:16:writable] Error: Non-array modification ‘1‘ for array component ‘x‘, possibly due to missing ‘each‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
