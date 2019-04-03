// name: FuncWrongType
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that type checking works for functions.
//

function f
  input Real x;
  output Real y = x;
end f;

model FuncWrongType
  Real x = f(true);
end FuncWrongType;

// Result:
// Error processing file: FuncWrongType.mo
// [flattening/modelica/scodeinst/FuncWrongType.mo:15:3-15:19:writable] Error: Type mismatch for positional argument 1 in f(x=true). The argument has type:
//   Boolean
// expected type:
//   Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
