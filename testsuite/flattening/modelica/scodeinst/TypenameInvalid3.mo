// name: TypenameInvalid3
// keywords:
// status: incorrect
//

model TypenameInvalid3
  type E = enumeration(one, two, three);
  Real x[E] = E;
end TypenameInvalid3;

// Result:
// Error processing file: TypenameInvalid3.mo
// [flattening/modelica/scodeinst/TypenameInvalid3.mo:8:3-8:16:writable] Error: Type name 'E' is not allowed in this context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
