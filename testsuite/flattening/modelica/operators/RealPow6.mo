// name: RealPow6
// keywords: real, power
// status: incorrect
//
//

model RealPow6
  constant Real x[:] = (-1).^{1.0, 2.0, 3.0};
end RealPow6;

// Result:
// Error processing file: RealPow6.mo
// [flattening/modelica/operators/RealPow6.mo:8:3-8:45:writable] Error: Invalid operation -1.0 ^ 1.0, exponent must be an Integer when the base is negative.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
