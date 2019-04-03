// name: CevalFuncRecursive2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := f(x + 1);
end f;

model CevalFuncRecursive2
  constant Real x = f(3.0);
end CevalFuncRecursive2;

// Result:
// Error processing file: CevalFuncRecursive2.mo
// [flattening/modelica/scodeinst/CevalFuncRecursive2.mo:8:1-13:6:writable] Error: The recursion limit (--evalRecursionLimit=256) was exceeded during evaluation of f.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
