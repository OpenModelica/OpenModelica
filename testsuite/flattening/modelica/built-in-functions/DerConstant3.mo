// name:     DerConstant3
// keywords: derivative
// status:   incorrect
//
// Operator der cannot be applied to Integer expressions which are not constant or parametric
//

model A
  discrete Integer pa = 1;
  Real a = der(pa);
end A;
// Result:
// Error processing file: DerConstant3.mo
// [flattening/modelica/built-in-functions/DerConstant3.mo:10:3-10:19:writable] Error: Argument 'pa' of der is not differentiable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
