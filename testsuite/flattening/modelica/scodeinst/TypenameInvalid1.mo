// name: TypenameInvalid1
// keywords:
// status: incorrect
//

model TypenameInvalid1
  Boolean b[Boolean];
equation
  b = Boolean;
end TypenameInvalid1;

// Result:
// Error processing file: TypenameInvalid1.mo
// [flattening/modelica/scodeinst/TypenameInvalid1.mo:9:3-9:14:writable] Error: Type name 'Boolean' is not allowed in this context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
