// name: CevalFuncAssert2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Integer n;
  output Integer res;
algorithm
  assert(n <= 2, "f got n larger than 2", AssertionLevel.error);
  res := n;
end f;

model CevalFuncAssert2
  constant Real x = f(10);
end CevalFuncAssert2;

// Result:
// Error processing file: CevalFuncAssert2.mo
// [flattening/modelica/scodeinst/CevalFuncAssert2.mo:12:3-12:64:writable] Error: assert triggered: f got n larger than 2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
