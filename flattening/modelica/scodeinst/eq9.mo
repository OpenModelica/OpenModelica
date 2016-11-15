// name: eq9.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
//

model A
  constant Integer j;
  package P
    constant Integer i = j;
  end P;
end A;

model B
  A a[3];
  Real x[3], y[3];
equation
  x = a.P.i .* y;
end B;

model C
  B b[2](each a(j = {1, 2, 3}));
end C;

// Result:
// Error processing file: eq9.mo
// [flattening/modelica/scodeinst/eq9.mo:19:3-19:17:writable] Error: Lookup of element P is not allowed via component a when looking for a.P.i (only function calls may be looked up via a component).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
