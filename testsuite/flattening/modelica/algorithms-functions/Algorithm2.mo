// name:     Algorithm2
// keywords: algorithm
// status:   incorrect
//
// Type checks in algorithms.
//

class Algorithm2
  Integer i;
  Real x;
algorithm
  i := x;
end Algorithm2;
// Result:
// Error processing file: Algorithm2.mo
// [flattening/modelica/algorithms-functions/Algorithm2.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/Algorithm2.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/Algorithm2.mo:12:3-12:9:writable] Warning: Algorithm sections are deprecated in class.
// [flattening/modelica/algorithms-functions/Algorithm2.mo:12:3-12:9:writable] Error: Type mismatch in assignment in i := x of Integer := Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
