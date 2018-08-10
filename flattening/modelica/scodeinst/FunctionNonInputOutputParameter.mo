// name: FunctionNoOutput1
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

model M
  parameter Real p = f(1, 2);
end M;


// Result:
// function f
//   input Real a;
//   input Real b;
//   output Real y;
//   parameter Real z = 1.0;
// algorithm
//   y := a + b + z;
// end f;
//
// class M
//   parameter Real p = f(1.0, 2.0);
// end M;
// [flattening/modelica/scodeinst/FunctionNonInputOutputParameter.mo:11:3-11:23:writable] Warning: Invalid public variable z, function variables that are not input/output must be protected.
//
// endResult
