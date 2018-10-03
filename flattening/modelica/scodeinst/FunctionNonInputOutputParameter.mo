// name: FunctionNonInputOutputParameter
// keywords:
// status: correct
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
// class FunctionNonInputOutputParameter
//   parameter Real p = 4.0;
// end FunctionNonInputOutputParameter;
// [flattening/modelica/scodeinst/FunctionNonInputOutputParameter.mo:11:3-11:23:writable] Warning: Invalid public variable z, function variables that are not input/output must be protected.
//
// endResult
