// name:     Type8
// keywords: types
// status:   incorrect
//
// This checks that Real and RealType are handled differently
//

class Type8
  Real x;
equation
  x = x.start;
end Type8;
// Result:
// Error processing file: Type8.mo
// [flattening/modelica/types/Type8.mo:11:3-11:14:writable] Error: Variable x.start not found in scope Type8.
// Error: Error occurred while flattening model Type8
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
