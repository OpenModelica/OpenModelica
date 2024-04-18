// name: FunctionInverseInvalid2
// keywords: inverse
// status: incorrect
// cflags: -d=newInst
//

function f
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := x * y;
  annotation(inverse(z = f_inv(x, y)));
end f;

function f_inv
  input Real x;
  input Real z;
  output Real y;
algorithm
  y := z / x;
end f_inv;

model FunctionInverseInvalid2
  Real x = f(1, 2);
end FunctionInverseInvalid2;

// Result:
// Error processing file: FunctionInverseInvalid2.mo
// [flattening/modelica/scodeinst/FunctionInverseInvalid2.mo:13:14-13:38:writable] Error: 'z' is not an input of function 'f'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
