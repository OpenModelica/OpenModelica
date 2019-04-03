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
// [flattening/modelica/algorithms-functions/InvalidFunctionBinding.mo:13:3-13:26:writable] Error: Type mismatch in modifier of component .z, expected type Real, got modifier =true of type Boolean.
// [flattening/modelica/algorithms-functions/InvalidFunctionBinding.mo:19:3-19:16:writable] Error: Class f not found in scope InvalidFunctionBinding (looking for a function or record).
// Error: Error occurred while flattening model InvalidFunctionBinding
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
