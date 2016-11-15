// name: func8.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not all builtin functions have the correct number of arguments yet.
//

model A
  function f
    input Real x;
    input Real y;
    output Real z;
  algorithm
    z := x;
  end f;

  Real x, y;
equation
  x = f(2, 4);
  y = min(4, 2);
end A;

// Result:
// [func8.mo:20:3-20:16]: SCodeInst.makeFunctionSlots: Too many arguments to function min
// Error processing file: func8.mo
// Error: Error occurred while flattening model A
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
