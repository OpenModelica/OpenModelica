// name: CompAsFunc.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that a proper error message is given when trying to use a component as
// a function.
//

model CompAsFunc
  Real x;
  Real y = x(2);
end CompAsFunc;

// Result:
// Error processing file: CompAsFunc.mo
// [flattening/modelica/scodeinst/CompAsFunc.mo:12:3-12:16:writable] Error: Expected x to be a function, but found component instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
