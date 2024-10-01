// name: TypenameInvalid2
// keywords:
// status: incorrect
//

model TypenameInvalid2
  type E = enumeration(one, two, three);
  Real x;
equation
  x = E;
end TypenameInvalid2;

// Result:
// Error processing file: TypenameInvalid2.mo
// [flattening/modelica/scodeinst/TypenameInvalid2.mo:10:3-10:8:writable] Error: Type name 'E' is not allowed in this context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
