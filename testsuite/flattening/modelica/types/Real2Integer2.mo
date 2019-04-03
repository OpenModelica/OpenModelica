// name:     Real2Integer2
// keywords: type
// status:   incorrect
//
// No implicit conversion from Real to Integer. Division via '/' always
// gives a Real.
//

class Real2Integer2
  Integer n1, n2;
algorithm
  n1 := 6;
  n2 := n1 / 2;
end Real2Integer2;
// Result:
// Error processing file: Real2Integer2.mo
// [flattening/modelica/types/Real2Integer2.mo:13:3-13:15:writable] Error: Type mismatch in assignment in n2 := 0.5 * /*Real*/(n1) of Integer := Real
// Error: Error occurred while flattening model Real2Integer2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
