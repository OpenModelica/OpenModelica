// name: FuncMissingDefault1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that missing default arguments are detected.
// 

function f
  input Real x;
  input Real y;
  output Real z = x + y;
end f;

model M
  Real x = f(1.0);
end M;

// Result:
// Error processing file: FuncMissingDefault1.mo
// [flattening/modelica/scodeinst/FuncMissingDefault1.mo:16:3-16:18:writable] Error: Function parameter y was not given by the function call, and does not have a default value.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
