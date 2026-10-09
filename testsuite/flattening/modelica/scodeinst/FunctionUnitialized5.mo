// name: FunctionUnitialized5
// keywords:
// status: incorrect
//
//

function f
  input Real x[:];
  input Integer n;
  output Real y[size(x, 1), size(x, 1)];
algorithm
  for i in 1:size(x, 1) loop
    y[i, i] := x[i];
  end for;
end f;

model FunctionUnitialized5
  constant Real y[:, :] = f({1, 2, 3}, 1);
end FunctionUnitialized5;

// Result:
// Error processing file: FunctionUnitialized5.mo
// [flattening/modelica/scodeinst/FunctionUnitialized5.mo:10:3-10:40:writable] Error: Output parameter y[1, 2] was not assigned a value. This is deprecated and will become an error in future releases.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
