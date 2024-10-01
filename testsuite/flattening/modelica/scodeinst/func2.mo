// name: func2.mo
// keywords:
// status: incorrect
//


model A
  function f
  end f;

  Real x = f();
  Real y = min(2, 3);
end A;

model B
  A a;
  Real x = A.f();
end B;

// Result:
// Error processing file: func2.mo
// [flattening/modelica/scodeinst/func2.mo:11:3-11:15:writable] Error: Type mismatch in binding x = B.a.f(), expected subtype of Real, got type ().
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
