// name: FunctionNonInputOutputParameter
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f
  input Real a;
  input Real b;
  output Real y;
  parameter Real z = 1;
algorithm
  y := a + b + z;
end f;

model FunctionNonInputOutputParameter
  parameter Real p = f(1, 2);
end FunctionNonInputOutputParameter;


// Result:
// Error processing file: FunctionNonInputOutputParameter.mo
// [flattening/modelica/scodeinst/FunctionNonInputOutputParameter.mo:11:3-11:23:writable] Error: Invalid public variable z, function variables that are not input/output must be protected.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
