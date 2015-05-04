// name: IntDiv
// keywords: integer, division
// status: incorrect
//
// tests Integer division
//

model IntDiv
  constant Integer i = 4000 / 100;
end IntDiv;

// Result:
// Error processing file: IntDiv.mo
// [flattening/modelica/operators/IntDiv.mo:9:3-9:34:writable] Error: Type mismatch in binding i = 40.0, expected subtype of Integer, got type Real.
// Error: Error occurred while flattening model IntDiv
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
