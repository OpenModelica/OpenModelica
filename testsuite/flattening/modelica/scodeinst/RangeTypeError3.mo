// name: RangeTypeError3.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model RangeTypeError3
  Real x[3] = "1":"3";
end RangeTypeError3;

// Result:
// Error processing file: RangeTypeError3.mo
// [flattening/modelica/scodeinst/RangeTypeError3.mo:9:3-9:22:writable] Error: Range has invalid type String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
