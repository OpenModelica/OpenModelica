// name:     Encapsulated4
// keywords: encapsulated
// status:   incorrect
//
// Checks that the look up stops when encountering an encapsulated scope, except
// for builtin types and functions.
//

function fn
  input Real x;
  output Real y;
algorithm
  y := x;
end fn;

encapsulated model Encapsulated4
  Real r1 = abs(-5.0);
  Real r2 = fn(-5.0);
end Encapsulated4;

// Result:
// Error processing file: Encapsulated4.mo
// [flattening/modelica/packages/Encapsulated4.mo:18:3-18:21:writable] Error: Class fn not found in scope Encapsulated4 (looking for a function or record).
// Error: Error occurred while flattening model Encapsulated4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
