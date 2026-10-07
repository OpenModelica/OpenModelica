// name: InvalidFunctionBinding
// keywords: function binding bug1773
// status: incorrect
//
// Checks that a component with an invalid binding causes the instantiation to
// fail.
//

function f
  input Real x;
  output Real y;
protected
  parameter Real z = true;
algorithm
  y := x * z;
end f;

model InvalidFunctionBinding
  Real x = f(4);
end InvalidFunctionBinding;

// Result:
// Error processing file: InvalidFunctionBinding.mo
// [flattening/modelica/algorithms-functions/InvalidFunctionBinding.mo:13:3-13:26:writable] Error: Type mismatch in binding z = true, expected subtype of Real, got type Boolean.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
