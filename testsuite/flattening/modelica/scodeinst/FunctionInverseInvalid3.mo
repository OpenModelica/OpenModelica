// name: FunctionInverseInvalid3
// keywords: inverse
// status: incorrect
// cflags: -d=newInst
//

function f
  input Real x;
  input Real y;
  output Real z1;
  output Real z2;
algorithm
  z1 := x * y;
  z2 := x + y;
  annotation(inverse(y = f_inv(x, z1, z2)));
end f;

function f_inv
  input Real x;
  input Real z;
  output Real y;
algorithm
  y := z / x;
end f_inv;

model FunctionInverseInvalid3
  Real x = f(1, 2);
end FunctionInverseInvalid3;

// Result:
// Error processing file: FunctionInverseInvalid3.mo
// [flattening/modelica/scodeinst/FunctionInverseInvalid3.mo:15:14-15:43:writable] Error: Invalid inverse annotation for 'f', only functions with exactly one output may have an inverse.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
