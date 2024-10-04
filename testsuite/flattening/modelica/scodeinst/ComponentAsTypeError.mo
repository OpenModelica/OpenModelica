// name: ComponentAsTypeError
// keywords: type error
// status: incorrect
//
// Checks that an error is output if a component is used as type.
//

model ComponentAsTypeError
  Real x;
  x y;
end ComponentAsTypeError;

// Result:
// Error processing file: ComponentAsTypeError.mo
// [flattening/modelica/scodeinst/ComponentAsTypeError.mo:10:3-10:6:writable] Error: Expected x to be a class, but found component instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
