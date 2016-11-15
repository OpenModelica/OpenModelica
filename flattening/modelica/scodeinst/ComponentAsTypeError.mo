// name: ComponentAsTypeError
// keywords: type error
// status: incorrect
// cflags: -d=newInst
//
// Checks that an error is output if a component is used as type.
//

model ComponentAsTypeError
  Real x;
  x y;
end ComponentAsTypeError;

// Result:
// Error processing file: ComponentAsTypeError.mo
// [flattening/modelica/scodeinst/ComponentAsTypeError.mo:11:3-11:6:writable] Error: Class x not found in scope <unknown>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
