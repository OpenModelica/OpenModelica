// status: incorrect

model M

function f
  input Integer i;
  input FuncT func;

  partial function FuncT
    input String s;
  end FuncT;
algorithm
  func(String(i));
end f;

function wrongType
  input Integer i;
  input Integer i2 = 1;
algorithm
  print(String(i) + "\n");
  print(String(i2) + "\n");
end wrongType;

algorithm
  f(1, function wrongType());
end M;

// Result:
// Error processing file: Ticket4786.mo
// [flattening/modelica/algorithms-functions/Ticket4786.mo:16:1-22:14:writable] Warning: Pure function 'M.wrongType' contains a call to impure function 'print'.
// [flattening/modelica/algorithms-functions/Ticket4786.mo:25:3-25:29:writable] Error: Type mismatch for positional argument 2 in M.f(func=M.wrongType). The argument has type:
//   M.wrongType<function>(Integer i, Integer i2) => ()
// expected type:
//   func<function>(String s) => ()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
