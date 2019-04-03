// name: redeclare3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Invalid usage of time inside function not checked.
//

package A
  function f
    replaceable input Real x;
    output Real y = x;
  end f;
end A;

model B
  function f = A.f(redeclare Real x = time);
  Real x = f();
end B;

// Result:
// Error processing file: redeclare3.mo
// [flattening/modelica/scodeinst/redeclare3.mo:17:20-17:43:writable] Error: time is not allowed in a function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
