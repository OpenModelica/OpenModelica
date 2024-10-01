// name: arrfunc.mo
// keywords:
// status: incorrect
//
//


model A
  constant Real z;

  function f
    input Real x;
    output Real y;
  algorithm
    y := x * z;
  end f;
end A;

model B
  A a[2](z = {1, 2});
  Real x1 = a[1].f(3);
  Real x2 = a[2].f(3);
end B;

// Result:
// Error processing file: arrfunc.mo
// [flattening/modelica/scodeinst/arrfunc.mo:21:3-21:22:writable] Error: Function call a[1].f contains subscripts.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
