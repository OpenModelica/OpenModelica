// name: EquationInvalidType1
// keywords:
// status: incorrect
//

model EquationInvalidType1
  Real x;
  String s;
equation
  x = s;
end EquationInvalidType1;

// Result:
// Error processing file: EquationInvalidType1.mo
// [flattening/modelica/scodeinst/EquationInvalidType1.mo:10:3-10:8:writable] Error: Type mismatch in equation x = s of type Real = String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
