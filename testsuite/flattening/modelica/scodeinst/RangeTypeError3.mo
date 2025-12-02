// name: RangeTypeError3.mo
// keywords:
// status: incorrect
//
//

model RangeTypeError3
  Real x[3] = "1":"3";
end RangeTypeError3;

// Result:
// Error processing file: RangeTypeError3.mo
// [flattening/modelica/scodeinst/RangeTypeError3.mo:8:3-8:22:writable] Error: Range has invalid type String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
