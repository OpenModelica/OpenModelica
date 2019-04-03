// name:     WrongSubscriptType1
// keywords: array subscript type
// status:   incorrect
//
// Tests that invalid subscript types are caught.
//

model WrongSubscriptType1
  Real x[3] = {1, 2, 3};
  Real y = x[3.0];
end WrongSubscriptType1;

// Result:
// Error processing file: WrongSubscriptType1.mo
// [flattening/modelica/arrays/WrongSubscriptType1.mo:10:3-10:18:writable] Error: Subscript 3.0 of type Real is not a subtype of Integer, Boolean or enumeration.
// [flattening/modelica/arrays/WrongSubscriptType1.mo:10:3-10:18:writable] Error: Variable x[3.0] not found in scope WrongSubscriptType1.
// Error: Error occurred while flattening model WrongSubscriptType1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
