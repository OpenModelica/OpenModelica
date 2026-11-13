// name: RealPow4
// keywords: real, power
// status: incorrect
//
//

model RealPow4
  constant Real x = (-1.0)^2.0;
end RealPow4;

// Result:
// Error processing file: RealPow4.mo
// [flattening/modelica/operators/RealPow4.mo:8:3-8:31:writable] Error: Invalid operation -1.0 ^ 2.0, exponent must be an Integer when the base is negative.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
