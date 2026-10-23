// name: RealPow5
// keywords: real, power
// status: incorrect
//
//

model RealPow5
  parameter Real a = -1.0;
  parameter Real b = 2.0;
  parameter Real x = a ^ b annotation(Evaluate=true);
end RealPow5;

// Result:
// Error processing file: RealPow5.mo
// [flattening/modelica/operators/RealPow5.mo:10:3-10:53:writable] Error: Invalid operation -1.0 ^ 2.0, exponent must be an Integer when the base is negative.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
