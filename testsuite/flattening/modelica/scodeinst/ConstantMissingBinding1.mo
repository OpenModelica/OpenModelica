// name: ConstantMissingBinding1
// keywords:
// status: incorrect
//

model ConstantMissingBinding1
  constant Real x;
  Real y(start = 1.0);
equation
  y = x*der(y);
end ConstantMissingBinding1;

// Result:
// Error processing file: ConstantMissingBinding1.mo
// [flattening/modelica/scodeinst/ConstantMissingBinding1.mo:7:3-7:18:writable] Error: Constant 'x' has no value.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
