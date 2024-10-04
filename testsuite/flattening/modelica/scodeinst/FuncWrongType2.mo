// name: FuncWrongType2
// keywords:
// status: incorrect
//
// Checks that type checking works for functions.
//

record A
  Real a1;
end A;

record B
  Real b1;
end B;

function F
  input A in_a;
end F;

model FuncWrongType2
  B b(b1 = time);
algorithm
  F(b);
end FuncWrongType2;

// Result:
// Error processing file: FuncWrongType2.mo
// [flattening/modelica/scodeinst/FuncWrongType2.mo:23:3-23:7:writable] Error: Type mismatch for positional argument 1 in F(in_a=b). The argument has type:
//   B
// expected type:
//   A
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
