// name: FuncClassParam
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that function parameters are not allowed to be e.g. models.
//

model A
  Real x;
end A;

function f
  input A a;
  output Real x;
algorithm
  x := a.x;
end f;

model FuncClassParam
  A a;
  Real x = f(a);
end FuncClassParam;

// Result:
// Error processing file: FuncClassParam.mo
// [flattening/modelica/scodeinst/FuncClassParam.mo:14:3-14:12:writable] Error: Invalid type A for function component a.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
