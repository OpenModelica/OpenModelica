// name: IllegalSubscript
// status: incorrect

model IllegalSubscript
  Real r[1];
equation
  r[0] = 1.0;
end IllegalSubscript;

// Result:
// Error processing file: IllegalSubscript.mo
// [flattening/modelica/others/IllegalSubscript.mo:7:3-7:13:writable] Error: Subscript '0' for dimension 1 (size = 1) of r is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
